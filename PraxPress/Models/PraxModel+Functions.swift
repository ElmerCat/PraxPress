//
//  PraxModel+Functions.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/13/26.
//

import Foundation
import CoreGraphics
import PDFKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

extension PraxModel {
    
   
    func handleMergePagesOverwrite() {
        
        
        fatalError("Julie d'Prax: This function is not currently implemented")
        //guard let id = selectedFiles.first, let entry = listOfFiles.first(where: { $0.id == id }) else { return }
        //mergeDocumentPages()
        // Recompute metrics based on the new single-page doc
        //computePageMetrics(for: entry.url)
        
    }
    
    func setEditingPDFDocumentFromPDFPageSections() {
        isLoadingPDF = true
        var insertIndex = 0
        let pdfDocument = PDFDocument()
        pdfPageSections.forEach {
            pdfPageSection in
            pdfPageSection.pdfPageItems.forEach {
                pdfPageItem in
                pdfDocument.insert(pdfPageItem.pdfPage, at: insertIndex)
                insertIndex += 1
            }
        }
        editingPDFDocument = pdfDocument
    }
    
    func setEditingPDFDocumentFromSelectedFiles () {
        isLoadingPDF = true
        pdfPageSections.removeAll()
        selectionIndexPaths = []
        var insertIndex = 0
        var pdfDocument = PDFDocument()
        
        let entries: [PDFEntry] = selectedFiles.compactMap { id in
            listOfFiles.first(where: { $0.id == id })
        }
        let urls = entries.map { $0.url }
        
        if urls.isEmpty {
            
            let document = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)!
            insertIndex = addPDFPageSection(for: document, at: insertIndex, into: &pdfDocument)
        }
        
        else {
            for url in urls {
                let needsStop = url.startAccessingSecurityScopedResource()
                defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
                guard let document = PDFDocument(url: url) else { fatalError("Could not load PDF at \(url)") }
                insertIndex = addPDFPageSection(for: document, at: insertIndex, into: &pdfDocument)
            }
        }
        
        pdfDocument.write(to: editingPDFURL)
        editingPDFDocument = pdfDocument
    }
    
    func mergeDocumentPagesForSections() -> PDFDocument {
        
        let mergedDocument = PDFDocument()
        let sectionCount = pdfPageSections.count
        for sectionIndex in 0..<sectionCount {
            
            print ("Julia Parr - pdfPageSection: ", sectionIndex)
            
            let pageCount = pdfPageSections[sectionIndex].pdfPageItems.count
            var removedPerPage: [[PDFAnnotation]] = Array(repeating: [], count: pageCount)
            var pageRects: [CGRect] = []
            pageRects.reserveCapacity(pageCount)
            
            
            for pageIndex in 0..<pageCount {
                let page = pdfPageSections[sectionIndex].pdfPageItems[pageIndex].pdfPage
                let rect = page.bounds(for: .cropBox)
                pageRects.append(rect)
                removedPerPage[pageIndex] = page.annotations
                for annotation in page.annotations {
                    page.removeAnnotation(annotation)
                }
            }
            // Create a one-page PDF context
            var mediaBox = CGRect(x: 0, y: 0, width: pdfPageSections[sectionIndex].mergedWidthPts, height: pdfPageSections[sectionIndex].mergedHeightPts)
            let tmpOut = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf")
            guard let consumer = CGDataConsumer(url: tmpOut as CFURL) else { fatalError("CGDataConsumer failed") }
            guard let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { fatalError("CGContext failed") }
            
            ctx.beginPDFPage([kCGPDFContextMediaBox as String: mediaBox] as CFDictionary)
            
            
            // Stack pages from top to bottom. Track the Y origin of each placed slice for annotation mapping.
            var currentTop = pdfPageSections[sectionIndex].mergedHeightPts
            var placedOriginsY: [CGFloat] = Array(repeating: 0, count: pageCount)
            
            for pageIndex in 0..<pageCount {
                let page = pdfPageSections[sectionIndex].pdfPageItems[pageIndex].pdfPage
                let rect = pageRects[pageIndex]
                let per = pdfPageSections[sectionIndex].pdfPageItems[pageIndex].trim
                let seamTop: CGFloat = 0
                let seamBottom: CGFloat = 0
                
                let vis = PDFGeometry.visibleRect(media: rect, trims: per, seamTop: seamTop, seamBottom: seamBottom)
                //       print("merge draw page \(i) rect:", rect.debugDescription, "trims:", per, "vis:", vis.debugDescription)
                let visibleWidth = vis.width
                let visibleHeight = vis.height
                guard visibleWidth > 0, visibleHeight > 0 else {
                    currentTop -= (max(0, visibleHeight)) // + interPageGap)
                    continue
                }
                
                // Place the slice at the LEFT edge (x = 0) and directly under the running top
                let destX: CGFloat = 0
                let destY: CGFloat = currentTop - visibleHeight
                placedOriginsY[pageIndex] = destY
                
                ctx.saveGState()
                // Translate so that (vis.minX, vis.minY) in page space lands at (destX, destY) in canvas space
                ctx.translateBy(x: destX - vis.minX, y: destY - vis.minY)
                // Clip in the CURRENT (translated) coordinate system using a rect defined in PAGE space coordinates
                // Because we translated by (-vis.minX, -vis.minY), the clip rect is simply:
                ctx.clip(to: vis)
                
                if let cgPage = page.pageRef {
                    ctx.drawPDFPage(cgPage)
                } else {
                    page.draw(with: .cropBox, to: ctx)
                }
                ctx.restoreGState()
                
                currentTop -= visibleHeight // (visibleHeight + interPageGap)
            }
            
            ctx.endPDFPage()
            ctx.closePDF()
            
            // Restore annotations to source pages
            for pageIndex in 0..<pageCount {
                let p = pdfPageSections[sectionIndex].pdfPageItems[pageIndex].pdfPage
                for a in removedPerPage[pageIndex] { p.addAnnotation(a) }
            }
            
            // Second pass: reopen merged and re-add cloned annotations with the SAME translation used above
            
            guard let tempDoc = PDFDocument(url: tmpOut) else { fatalError("PDFDocument(url: tmpOut) failed") }
            guard let mergedPage = tempDoc.page(at: 0) else { fatalError("mergedDoc.page(at: 0) failed") }
            
            for pageIndex in 0..<pageCount {
                let srcPage = pdfPageSections[sectionIndex].pdfPageItems[pageIndex].pdfPage
                let rect = pageRects[pageIndex]
                let per = pdfPageSections[sectionIndex].pdfPageItems[pageIndex].trim
                let seamTop: CGFloat = 0
                let seamBottom: CGFloat = 0
                
                let vis = PDFGeometry.visibleRect(media: rect, trims: per, seamTop: seamTop, seamBottom: seamBottom)
                let dx = 0 - vis.minX
                let dy = placedOriginsY[pageIndex] - vis.minY
                //   print("merge annot page \(i) rect:", rect.debugDescription, "trims:", per, "vis:", vis.debugDescription, "dx:", dx, "dy:", dy)
                
                for annot in srcPage.annotations {
                    guard annot.fieldName != nil else { continue }
                    guard let copied = annot.copy() as? PDFAnnotation else { continue }
                    copied.bounds = annot.bounds.offsetBy(dx: dx, dy: dy)
                    mergedPage.addAnnotation(copied)
                    if copied.widgetFieldType == .text {
                        if let v = copied.widgetStringValue, !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            copied.widgetStringValue = v
                        }
                    }
                }
            }
 
            pdfPageSections[sectionIndex].pdfPage = mergedPage
            mergedDocument.insert(mergedPage, at: sectionIndex)
            
            do { try FileManager.default.removeItem(at: tmpOut) }
            catch {  print("FileManager.default.removeItem(at: tmpOut) failed", error.localizedDescription) }
        }
        
        mergedDocument.write(to: mergedPDFURL)
        return mergedDocument
    }
    
    func recomputeMergedMetrics() {
        let count = editingPDFDocument.pageCount
        guard count > 0 else { fatalError("No pages in PDF!")}
        
        var pageIndex = 0
        let sectionCount = pdfPageSections.count
        for sectionIndex in 0..<sectionCount {
            var maxVisibleWidth: CGFloat = 0
            var totalVisibleHeight: CGFloat = 0

            pdfPageSections[sectionIndex].pdfPageItems.forEach {
                pdfPageItem in
                let media = pdfPageItem.pdfPage.bounds(for: .cropBox)
                let per = pdfPageItem.trim
                let seamTop: CGFloat = (pageIndex == 0) ? 0 : 0
                let seamBottom: CGFloat = (pageIndex == count - 1) ? 0 : 0
                let vis = PDFGeometry.visibleRect(media: media, trims: per, seamTop: seamTop, seamBottom: seamBottom)
                maxVisibleWidth = max(maxVisibleWidth, vis.width)
                totalVisibleHeight += vis.height
                pageIndex += 1
            }
            pdfPageSections[sectionIndex].mergedWidthPts = maxVisibleWidth
            pdfPageSections[sectionIndex].mergedHeightPts = totalVisibleHeight
        }
    }
    
 /*   func cleanupTemporaryArtifacts() {
        print("\n\ncleanupTemporaryArtifacts()\n\n")
        
        let fm = FileManager.default
        if let oldPreview = lastPreviewURL {
            try? fm.removeItem(at: oldPreview)
            lastPreviewURL = nil
        }
        if let oldCombined = lastCombinedSourceURL {
            try? fm.removeItem(at: oldCombined)
            lastCombinedSourceURL = nil
        }
    }
*/
    
}
