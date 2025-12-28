//  PDFModel.swift
//  PraxPDF - Prax=1220-1

import Foundation
import CoreGraphics
import PDFKit
import UniformTypeIdentifiers

internal import Combine

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
    

    func trims(for index: Int) -> EdgeTrims { trims[index] ?? .zero }
    func setTrims(_ value: EdgeTrims, for index: Int) { trims[index] = value }
    
    
    func saveMergedPagesAs(viewModel: ViewModel) {
        
    }
    
    
    func handleMergePagesOverwrite(viewModel: ViewModel) {
        
        print("Juliette M. Belanger")
        
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
            throw NSError(domain: "PraxPDF", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Unable to open source PDF for merging."])
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
        
        // Use mediaBox consistently (matches the Trim Tool and thumbnails)
        var pageRects: [CGRect] = []
        pageRects.reserveCapacity(pageCount)
        
        for i in 0..<pageCount {
            guard let page = sourceDoc.page(at: i) else { continue }
            let rect = page.bounds(for: .mediaBox)
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
            throw NSError(domain: "PraxPDF", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to create data consumer."])
        }
        guard let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw NSError(domain: "PraxPDF", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDF context."])
        }
        
        ctx.beginPDFPage([kCGPDFContextMediaBox as String: mediaBox] as CFDictionary)
        
        // Stack pages from top to bottom. Track the Y origin of each placed slice for annotation mapping.
        var currentTop = canvasHeight
        var placedOriginsY: [CGFloat] = Array(repeating: 0, count: pageCount)
        
        for i in 0..<pageCount {
            guard let page = sourceDoc.page(at: i) else { continue }
            let rect = pageRects[i]
            let per = perPageTrims[i] ?? .zero
            let seamTop: CGFloat = (i == 0) ? 0 : trimTop
            let seamBottom: CGFloat = (i == pageCount - 1) ? 0 : trimBottom
            
            let vis = PDFGeometry.visibleRect(media: rect, trims: per, seamTop: seamTop, seamBottom: seamBottom)
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
                page.draw(with: .mediaBox, to: ctx)
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
            let per = trims[i] ?? .zero
            let seamTop: CGFloat = (i == 0) ? 0 : trimTop
            let seamBottom: CGFloat = (i == pageCount - 1) ? 0 : trimBottom
            
            let vis = PDFGeometry.visibleRect(media: rect, trims: per, seamTop: seamTop, seamBottom: seamBottom)
            let dx = 0 - vis.minX
            let dy = placedOriginsY[i] - vis.minY
            
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
