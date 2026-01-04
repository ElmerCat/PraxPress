//  PDFModel.swift
//  PraxPress - Prax=0104-1
//

import Foundation
import CoreGraphics
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

internal import Combine

extension Notification.Name { static let praxWidthGuideChanged = Notification.Name("PraxWidthGuideChanged") }

struct EdgeTrims: Codable, Hashable {
    var left: CGFloat
    var right: CGFloat
    var top: CGFloat
    var bottom: CGFloat

    static let zero = EdgeTrims(left: 0, right: 0, top: 0, bottom: 0)
}

@Observable class PDFModel {
    
    var fileURL: URL?
    var lastPreviewURL: URL? = nil
    var lastCombinedSourceURL: URL? = nil
    
    var pdfDocument: PDFDocument? 

    var currentIndex: Int = 0
    var mergedWidthPts: CGFloat = 0
    var mergedHeightPts: CGFloat = 0
    
    var pageCount: Int? = nil
    var totalHeightPoints: CGFloat? = nil
    var maxWidthPoints: CGFloat? = nil

    var mergeTopMargin: Double = 0
    var mergeBottomMargin: Double = 0
    var mergeInterPageGap: Double = 0
    
    // Keyed by page index in the source PDF
    var trims: [Int: EdgeTrims] = [:]

    // Width Guide support
    var widthGuidePageIndex: Int? = nil
    var widthGuideLeftX: CGFloat? = nil
    var widthGuideRightX: CGFloat? = nil
    
    func trims(for index: Int) -> EdgeTrims { trims[index] ?? .zero }
    func setTrims(_ value: EdgeTrims, for index: Int) { trims[index] = value }
    
    /// Compute and store the width guide X positions (in page space of the guide page)
    func setWidthGuide(fromPage index: Int) {
        guard let doc = pdfDocument, let page = doc.page(at: index) else { return }
        let media = page.bounds(for: .cropBox)
        let per = trims[index] ?? .zero
        let vis = PDFGeometry.visibleRect(media: media, trims: per, seamTop: 0, seamBottom: 0)
        widthGuidePageIndex = index
        widthGuideLeftX = vis.minX
        widthGuideRightX = vis.maxX
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .praxWidthGuideChanged, object: nil)
        }
    }

    /// Remove any active width guide
    func clearWidthGuide() {
        widthGuidePageIndex = nil
        widthGuideLeftX = nil
        widthGuideRightX = nil
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .praxWidthGuideChanged, object: nil)
        }
    }
    
    func handleMergePagesOverwrite(viewModel: ViewModel) {
        guard let id = viewModel.selectedFiles.first, let entry = viewModel.listOfFiles.first(where: { $0.id == id }) else { return }
        do {
            try mergeAllPagesVerticallyIntoSinglePage(
                sourceURL: entry.url,
                destinationURL: entry.url,
                trimTop: CGFloat(mergeTopMargin),
                trimBottom: CGFloat(mergeBottomMargin),
                interPageGap: CGFloat(mergeInterPageGap),
                perPageTrims: trims
            )
            // Recompute metrics based on the new single-page doc
            computePageMetrics(for: entry.url)
        } catch {
            viewModel.saveError = error.localizedDescription
        }
    }


    
    func mergeAllPagesVerticallyIntoSinglePage(sourceURL: URL, destinationURL: URL, trimTop: CGFloat = 0, trimBottom: CGFloat = 0, interPageGap: CGFloat = 0, perPageTrims: [Int: EdgeTrims] = [:]) throws {
        let needsStopSource = sourceURL.startAccessingSecurityScopedResource()
        defer { if needsStopSource { sourceURL.stopAccessingSecurityScopedResource() } }
        guard let sourceDoc = PDFDocument(url: sourceURL) else {
            throw NSError(domain: "PraxPress", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Unable to open source PDF for merging."])
        }
        
        let pageCount = sourceDoc.pageCount
        if pageCount == 0 {
            let empty = PDFDocument()
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try? FileManager.default.removeItem(at: destinationURL)
            }
            empty.write(to: destinationURL)
            return
        }
        
         var pageRects: [CGRect] = []
        pageRects.reserveCapacity(pageCount)
        
        for i in 0..<pageCount {
            guard let page = sourceDoc.page(at: i) else { continue }
            let rect = page.bounds(for: .cropBox)
            pageRects.append(rect)
        }
        
        let canvas = PDFGeometry.canvasSize(for: pageRects, trims: perPageTrims, trimTop: trimTop, trimBottom: trimBottom, interPageGap: interPageGap)
        let canvasWidth = canvas.width
        let canvasHeight = canvas.height
        
        // Temporarily remove annotations to avoid drawing their appearances twice
        var removedPerPage: [[PDFAnnotation]] = Array(repeating: [], count: pageCount)
        for i in 0..<pageCount {
            if let p = sourceDoc.page(at: i) {
                removedPerPage[i] = p.annotations
                for a in p.annotations { p.removeAnnotation(a) }
            }
        }
        
        // Create a one-page PDF context
        let fm = FileManager.default
        var mediaBox = CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight)
        let tmpOut = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf")
        guard let consumer = CGDataConsumer(url: tmpOut as CFURL) else {
            throw NSError(domain: "PraxPress", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to create data consumer."])
        }
        guard let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw NSError(domain: "PraxPress", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDF context."])
        }
        
        ctx.beginPDFPage([kCGPDFContextMediaBox as String: mediaBox] as CFDictionary)
        
        // Stack pages from top to bottom. Track the Y origin of each placed slice for annotation mapping.
        var currentTop = canvasHeight
        var placedOriginsY: [CGFloat] = Array(repeating: 0, count: pageCount)
        
        for i in 0..<pageCount {
            guard let page = sourceDoc.page(at: i) else { continue }
            let rect = pageRects[i]
            let per = perPageTrims[i] ?? .zero
            let seamTop: CGFloat = 0
            let seamBottom: CGFloat = 0
            
            let vis = PDFGeometry.visibleRect(media: rect, trims: per, seamTop: seamTop, seamBottom: seamBottom)
            print("merge draw page \(i) rect:", rect.debugDescription, "trims:", per, "vis:", vis.debugDescription)
            let visibleWidth = vis.width
            let visibleHeight = vis.height
            guard visibleWidth > 0, visibleHeight > 0 else {
                currentTop -= (max(0, visibleHeight) + interPageGap)
                continue
            }
            
            // Place the slice at the LEFT edge (x = 0) and directly under the running top
            let destX: CGFloat = 0
            let destY: CGFloat = currentTop - visibleHeight
            placedOriginsY[i] = destY
            
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
            
            currentTop -= (visibleHeight + interPageGap)
        }
        
        ctx.endPDFPage()
        ctx.closePDF()
        
        // Restore annotations to source pages
        for i in 0..<pageCount {
            if let p = sourceDoc.page(at: i) {
                for a in removedPerPage[i] { p.addAnnotation(a) }
            }
        }
        
        // Move temp to destination
        let needsStopDest = destinationURL.startAccessingSecurityScopedResource()
        defer { if needsStopDest { destinationURL.stopAccessingSecurityScopedResource() } }
        if fm.fileExists(atPath: destinationURL.path) { try? fm.removeItem(at: destinationURL) }
        try fm.moveItem(at: tmpOut, to: destinationURL)
        
        // Second pass: reopen merged and re-add cloned annotations with the SAME translation used above
        let needsStopDest2 = destinationURL.startAccessingSecurityScopedResource()
        defer { if needsStopDest2 { destinationURL.stopAccessingSecurityScopedResource() } }
        guard let mergedDoc = PDFDocument(url: destinationURL), let mergedPage = mergedDoc.page(at: 0) else { return }
        
        for i in 0..<pageCount {
            guard let srcPage = sourceDoc.page(at: i) else { continue }
            let rect = pageRects[i]
            let per = perPageTrims[i] ?? .zero
            let seamTop: CGFloat = 0
            let seamBottom: CGFloat = 0
            
            let vis = PDFGeometry.visibleRect(media: rect, trims: per, seamTop: seamTop, seamBottom: seamBottom)
            let dx = 0 - vis.minX
            let dy = placedOriginsY[i] - vis.minY
            print("merge annot page \(i) rect:", rect.debugDescription, "trims:", per, "vis:", vis.debugDescription, "dx:", dx, "dy:", dy)
            
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
        
        // Save final merged doc safely
        let tmpFinal = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf")
        guard mergedDoc.write(to: tmpFinal) else { return }
        if fm.fileExists(atPath: destinationURL.path) { try? fm.removeItem(at: destinationURL) }
        try fm.moveItem(at: tmpFinal, to: destinationURL)
    }
    
     func computePageMetrics(for url: URL) {
        let needsStop = url.startAccessingSecurityScopedResource()
        defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
        guard let doc = PDFDocument(url: url) else {
            pageCount = nil
            totalHeightPoints = nil
            maxWidthPoints = nil
            return
        }
        let count = doc.pageCount
        let totalH: CGFloat = 0
        let maxW: CGFloat = 0
        /*        let knownFields = KnownFormFields.all
         var foundUnknowns = Set<String>()
         for i in 0..<count {
         guard let page = doc.page(at: i) else { continue }
         let rect = page.bounds(for: .mediaBox)
         totalH += rect.height
         if rect.width > maxW { maxW = rect.width }
         for annot in page.annotations {
         if let name = annot.fieldName, !name.isEmpty, !knownFields.contains(name) {
         foundUnknowns.insert(name)
         }
         }
         } */
        pageCount = count
        totalHeightPoints = totalH
        maxWidthPoints = maxW
        //     let sortedUnknowns = Array(foundUnknowns).sorted()
        //    unknownFieldNames = sortedUnknowns
        //    showUnknownFieldsAlert = !sortedUnknowns.isEmpty
    }
    
    /// Build a temporary combined PDF by concatenating pages from the given URLs in order.
    /// Returns the temporary file URL on success.
    func buildTemporaryCombinedPDF(from urls: [URL]) throws -> URL {
        if let old = lastCombinedSourceURL {
            try? FileManager.default.removeItem(at: old)
            lastCombinedSourceURL = nil
        }

        let fm = FileManager.default
        let tempURL = fm.temporaryDirectory.appendingPathComponent("combined-\(UUID().uuidString)").appendingPathExtension("pdf")
        defer {
            // No cleanup here; caller may want to keep it until replaced.
        }
        let combined = PDFDocument()
        var insertIndex = 0
        for url in urls {
            let needsStop = url.startAccessingSecurityScopedResource()
            defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
            guard let doc = PDFDocument(url: url) else { continue }
            for i in 0..<doc.pageCount {
                if let page = doc.page(at: i) {
                    combined.insert(page, at: insertIndex)
                    insertIndex += 1
                }
            }
        }
        // Write to disk
        guard combined.write(to: tempURL) else {
            throw NSError(domain: "PraxPress", code: 2001, userInfo: [NSLocalizedDescriptionKey: "Failed to write combined PDF."])
        }
        lastCombinedSourceURL = tempURL
        return tempURL
    }
    
    func cleanupTemporaryArtifacts() {
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
}

struct PageTrimStatus: View {
    let pdfModel: PDFModel
    
    var body: some View {
        GroupBox {
            VStack {
                HStack {
                    // Left: Page indicator
                    Text("Page \(pdfModel.currentIndex + 1) of \(pdfModel.pdfDocument?.pageCount ?? 0)")
                        .font(.subheadline)
                    
                    
                    
                    Spacer()
                    
                    if let trimsForPage = pdfModel.trims[pdfModel.currentIndex] {
                        Text(String(format: "EdgeTrims Left: %.0f  Right %.0f  Top: %.2f  Bottom: %.2f", trimsForPage.left, trimsForPage.right, trimsForPage.top, trimsForPage.bottom))
                            .font(.subheadline)
                    }

                }
                .padding(8)
                HStack {
     
                    if let g = pdfModel.widthGuidePageIndex {
                        Text("Guide: page \(g + 1)")
                            .font(.subheadline)
                            
                        Spacer()
                        Text("Guide Left: \(pdfModel.widthGuideLeftX!)  Right: \(pdfModel.widthGuideRightX!)")
                            .font(.subheadline)
                            
                    }
                    else {
                        Text("No Guide Page Set")
                            .font(.subheadline)
                        //  .foregroundStyle(.tertiary)
                    }
                    
                }
                .padding(8)

            }
        }
        .background(Color(red: 0.0, green: 0.0, blue: 0.8, opacity: 1.0))
        .foregroundStyle(Color.white)
    }
}



struct DocumentTrimStatus: View {
    let pdfModel: PDFModel
    
    var body: some View {
        GroupBox {
            HStack {
                // Left: Page indicator
                Text("Document pages: \(pdfModel.pdfDocument?.pageCount ?? 0)")
                    .font(.subheadline)
                
                Spacer()
                
                // Right: Live merged size using trims
                if pdfModel.mergedWidthPts > 0, pdfModel.mergedHeightPts > 0 {
                    let wIn = pdfModel.mergedWidthPts / 72.0
                    let hIn = pdfModel.mergedHeightPts / 72.0
                    Text(String(format: "Merged size: %.0f × %.0f pts (%.2f × %.2f in)", pdfModel.mergedWidthPts, pdfModel.mergedHeightPts, wIn, hIn))
                        .font(.subheadline)
                    //    .foregroundStyle(Color.white)
                } else {
                    Text("Merged size: —")
                        .font(.subheadline)
                    //  .foregroundStyle(.tertiary)
                }
            }
            .padding(8)
        }
        .background(Color(red: 0.0, green: 0.0, blue: 0.8, opacity: 1.0))
        .foregroundStyle(Color.white)
    }
}



func isPDF(_ url: URL) -> Bool {
    if let type = UTType(filenameExtension: url.pathExtension) {
        return type.conforms(to: .pdf)
    }
    return url.pathExtension.lowercased() == "pdf"
}


struct PDFEntry: Identifiable, Hashable {
    let id: UUID
    let url: URL
    let bookmarkData: Data
    var fileName: String { url.lastPathComponent }
    let pcardHolderName: String?
    let documentNumber: String?
    let date: String?
    let amount: String?
    let vendor: String?
    let glAccount: String?
    let costObject: String?
    let description: String?
    
    init(id: UUID = UUID(), url: URL, bookmarkData: Data, pcardHolderName: String?, documentNumber: String?, date: String?, amount: String?, vendor: String?, glAccount: String?, costObject: String?, description: String?) {
        self.id = id
        self.url = url
        self.bookmarkData = bookmarkData
        self.pcardHolderName = pcardHolderName
        self.documentNumber = documentNumber
        self.date = date
        self.amount = amount
        self.vendor = vendor
        self.glAccount = glAccount
        self.costObject = costObject
        self.description = description
    }
}

struct PDFGeometry {
    /// Compute the visible rect in page space given media box and trims.
    static func visibleRect(media: CGRect, trims: EdgeTrims, seamTop: CGFloat, seamBottom: CGFloat) -> CGRect {
        let minX = media.minX + trims.left
        let maxX = media.maxX - trims.right
        let minY = media.minY + trims.bottom + seamBottom
        let maxY = media.maxY - trims.top - seamTop
        let w = max(0, maxX - minX)
        let h = max(0, maxY - minY)
        return CGRect(x: minX, y: minY, width: w, height: h)
    }
}

extension PDFGeometry {
    /// Computes the final canvas size for the merged PDF using the same rules as the merge routine.
    static func canvasSize(for pageRects: [CGRect], trims: [Int: EdgeTrims], trimTop: CGFloat, trimBottom: CGFloat, interPageGap: CGFloat) -> CGSize {
        var maxVisibleWidth: CGFloat = 0
        var totalVisibleHeight: CGFloat = 0
        let count = pageRects.count
        for i in 0..<count {
            let per = trims[i] ?? .zero
            let seamTop: CGFloat = (i == 0) ? 0 : trimTop
            let seamBottom: CGFloat = (i == count - 1) ? 0 : trimBottom
            let vis = visibleRect(media: pageRects[i], trims: per, seamTop: seamTop, seamBottom: seamBottom)
            maxVisibleWidth = max(maxVisibleWidth, vis.width)
            totalVisibleHeight += vis.height
        }
        let internalSeams = max(0, count - 1)
        let gapsTotal = interPageGap * CGFloat(internalSeams)
        return CGSize(width: maxVisibleWidth, height: totalVisibleHeight + gapsTotal)
    }
}

