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
    
    func pdfDocumentFromPDFPageSections(sections: [PDFPageSection]) -> PDFDocument {
        isLoadingPDF = true
        var insertIndex = 0
        let pdfDocument = PDFDocument()
        sections.forEach {
            section in
            section.pdfPageItems.forEach {
                page in
                if page.merge != .mergeSkip {
                    pdfDocument.insert(page.pdfPage, at: insertIndex)
                    insertIndex += 1
                }
            }
        }
        return pdfDocument
    }
    
    func mergeDocumentPagesForSections() -> PDFDocument {
        
        let mergedDocument = PDFDocument()
        
        var pageItems: [PDFPageItem] = []
        for sectionIndex in 0..<pdfPageSections.count {
            for pageIndex in 0..<pdfPageSections[sectionIndex].pdfPageItems.count{
                if pdfPageSections[sectionIndex].pdfPageItems[pageIndex].merge != .mergeSkip {
                    pageItems.append(pdfPageSections[sectionIndex].pdfPageItems[pageIndex])
                }
            }
          //  var removedPerPage: [[PDFAnnotation]] = Array(repeating: [], count: pageItems.count)
            var pageRects: [CGRect] = []
            pageRects.reserveCapacity(pageItems.count)
          
            for pageIndex in 0..<pageItems.count{
                    let page = pageItems[pageIndex].pdfPage
                    let rect = page.bounds(for: .cropBox)
                    pageRects.append(rect)
              //      removedPerPage[pageIndex] = page.annotations
              //      for annotation in page.annotations {
                //    page.removeAnnotation(annotation)
               //     }
            }
            
            var mediaBox = CGRect(x: 0, y: 0, width: pdfPageSections[sectionIndex].mergedWidthPts, height: pdfPageSections[sectionIndex].mergedHeightPts)
            let tmpOut = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf")
            guard let consumer = CGDataConsumer(url: tmpOut as CFURL) else { fatalError("CGDataConsumer failed") }
            guard let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { fatalError("CGContext failed") }
            
            ctx.beginPDFPage([kCGPDFContextMediaBox as String: mediaBox] as CFDictionary)
            // Stack pages from top to bottom. Track the Y origin of each placed slice for annotation mapping.
            var currentTop = pdfPageSections[sectionIndex].mergedHeightPts
            var placedOriginsY: [CGFloat] = Array(repeating: 0, count: pageItems.count)
            
             for pageIndex in 0..<pageItems.count {
                    let page = pageItems[pageIndex].pdfPage
                    let rect = pageRects[pageIndex]
                    let per = pageItems[pageIndex].trim
                    let seamTop: CGFloat = 0
                    let seamBottom: CGFloat = 0
                 
                    let vis = rect.trimmed(per) //: per, seamTop: seamTop, seamBottom: seamBottom)
                    
                 //   let vis = PDFGeometry.visibleRect(media: rect, trims: per, seamTop: seamTop, seamBottom: seamBottom)
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
       //     for pageIndex in 0..<pageItems.count {
       //         let p = pageItems[pageIndex].pdfPage
      //          for a in removedPerPage[pageIndex] { p.addAnnotation(a) }
       //     }
            
            // Second pass: reopen merged and re-add cloned annotations with the SAME translation used above
            
            guard let tempDoc = PDFDocument(url: tmpOut) else { fatalError("PDFDocument(url: tmpOut) failed") }
            guard let mergedPage = tempDoc.page(at: 0) else { fatalError("mergedDoc.page(at: 0) failed") }
            
            for pageIndex in 0..<pageItems.count {
                    let srcPage = pageItems[pageIndex].pdfPage
                    let pageRect = pageRects[pageIndex]
                    let trim = pageItems[pageIndex].trim
                 //   let seamTop: CGFloat = 0
                 //   let seamBottom: CGFloat = 0
                    
                let trimmedPageRect = pageRect.trimmed(trim)
                
                    let dx = 0 - trimmedPageRect.minX
                    let dy = placedOriginsY[pageIndex] - trimmedPageRect.minY
                    //   print("merge annot page \(i) rect:", rect.debugDescription, "trims:", per, "vis:", vis.debugDescription, "dx:", dx, "dy:", dy)
                    
                for annotation in srcPage.annotations {
                    // Only handle form fields; skip others as before
                    guard annotation.fieldName != nil else { continue }
                    guard let copiedAnnotation = annotation.copy() as? PDFAnnotation else { continue }
                    
                    // Translate annotation bounds from source page space into merged page space
                    let translatedBounds = annotation.bounds.offsetBy(dx: dx, dy: dy)
                    
                    // Destination rect for this slice in merged page coordinates
                    let destSliceRect = CGRect(x: 0,
                                               y: placedOriginsY[pageIndex],
                                               width: trimmedPageRect.width,
                                               height: trimmedPageRect.height)
                    
                    // Fit while preserving center as much as possible
                    let minSize: CGFloat = 2.0
                    
                    // Start from original center
                    let centerX = translatedBounds.midX
                    let centerY = translatedBounds.midY
                    
                    // Compute the max size that fits within the slice while centered at (centerX, centerY)
                    var targetWidth = translatedBounds.width
                    var targetHeight = translatedBounds.height
                    
                    // Limit size to slice dimensions
                    targetWidth = min(targetWidth, destSliceRect.width)
                    targetHeight = min(targetHeight, destSliceRect.height)
                    
                    // Ensure minimum size
                    targetWidth = max(targetWidth, minSize)
                    targetHeight = max(targetHeight, minSize)
                    
                    // Build a rect of the target size centered at original center
                    var fitted = CGRect(x: centerX - targetWidth / 2.0,
                                        y: centerY - targetHeight / 2.0,
                                        width: targetWidth,
                                        height: targetHeight)
                    
                    // If this centered rect spills outside the slice, clamp position while keeping size
                    if fitted.minX < destSliceRect.minX {
                        fitted.origin.x = destSliceRect.minX
                    }
                    if fitted.maxX > destSliceRect.maxX {
                        fitted.origin.x = destSliceRect.maxX - fitted.width
                    }
                    if fitted.minY < destSliceRect.minY {
                        fitted.origin.y = destSliceRect.minY
                    }
                    if fitted.maxY > destSliceRect.maxY {
                        fitted.origin.y = destSliceRect.maxY - fitted.height
                    }
                    
                    // Final safety: ensure we still overlap the slice (in case slice is extremely small)
                    guard fitted.intersects(destSliceRect) else { continue }
                    
                    copiedAnnotation.bounds = fitted
                    mergedPage.addAnnotation(copiedAnnotation)
                    
                    // Preserve text values for text widgets

                    if copiedAnnotation.widgetFieldType == .text {
                        if let v = copiedAnnotation.widgetStringValue, !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            copiedAnnotation.widgetStringValue = v
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
                if pdfPageItem.merge != .mergeSkip {
                    let media = pdfPageItem.pdfPage.bounds(for: .cropBox)
                    let per = pdfPageItem.trim
                    let seamTop: CGFloat = (pageIndex == 0) ? 0 : 0
                    let seamBottom: CGFloat = (pageIndex == count - 1) ? 0 : 0
                    let vis = PDFGeometry.visibleRect(media: media, trims: per, seamTop: seamTop, seamBottom: seamBottom)
                    maxVisibleWidth = max(maxVisibleWidth, vis.width)
                    totalVisibleHeight += vis.height
                    pageIndex += 1
                }
            }
            pdfPageSections[sectionIndex].mergedWidthPts = maxVisibleWidth
            pdfPageSections[sectionIndex].mergedHeightPts = totalVisibleHeight
        }
    }
    
    /*
     var fileURL: URL?
     var lastPreviewURL: URL? = nil
     var lastCombinedSourceURL: URL? = nil
     */
    
    func cleanupTemporaryArtifacts() {
        print("\n\ncleanupTemporaryArtifacts()\n\n")
        
        /*        let fm = FileManager.default
         if let oldPreview = lastPreviewURL {
         try? fm.removeItem(at: oldPreview)
         lastPreviewURL = nil
         }
         if let oldCombined = lastCombinedSourceURL {
         try? fm.removeItem(at: oldCombined)
         lastCombinedSourceURL = nil
         }
         */
    }
    
    
}
