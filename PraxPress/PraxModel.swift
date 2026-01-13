//  PraxModel.swift
//  PraxPress - Prax=0104-1
//

import Foundation
import CoreGraphics
import PDFKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

internal import Combine

extension Notification.Name {
    static let praxWidthGuideChanged = Notification.Name("PraxWidthGuideChanged")
    static let praxFileSelectionChanged = Notification.Name("PraxFileSelectionChanged")
}

struct EdgeTrims: Codable, Hashable {
    var left: CGFloat
    var right: CGFloat
    var top: CGFloat
    var bottom: CGFloat
    
    static let zero = EdgeTrims(left: 0, right: 0, top: 0, bottom: 0)
}

struct PDFPageSection: Hashable {
    let title: String
    let id = UUID()
}

struct PDFPageItem: Hashable {
    let index: Int
    let name: String
    let id = UUID()
}

//@Model
@Observable
final class PraxModel: Sendable {
    init() { }
    static let shared = PraxModel()
    
    var mergedPDFView: PDFView?
    
    var editingPDFView: PDFView?
    
    func zoomToFitEditingPDFView() {
        if let editingPDFView {
            editingPDFView.scaleFactor = editingPDFView.scaleFactorForSizeToFit
            pdfAutoScales = true
        }
    }
    func zoomInEditingPDFView() {
        if let editingPDFView {
            editingPDFView.zoomIn(self)
            pdfAutoScales = false
        }
    }
    func zoomOutEditingPDFView() {
        if let editingPDFView {
            editingPDFView.zoomOut(self)
            pdfAutoScales = false
        }
    }
    
    var isOn = false
    var isLarge: Bool = false
    var showingImporter: Bool = false
    var isShowingInspector: Bool = false
    var showSavePanel: Bool = false
    var columnVisibility: NavigationSplitViewVisibility = .all
    
    var listOfFiles: [PDFEntry] = [] {
        didSet {
            print ("PraxModel listOfFiles didSet ") //, listOfFiles.description)
        }
    }
    var selectedFiles = Set<PDFEntry.ID>() {
        didSet {
            print ("PraxModel selectedFiles didSet ") //, selectedFiles.description)
            
            editingPDFDocument = createMergedDocumentFromSelectedFiles()
            
            if (editingPDFDocument?.pageCount ?? 0) > 0 { currentIndex = 0 }
            trims = [:]
            clearWidthGuide()
            
            DispatchQueue.main.async {
                self.recomputeMergedMetrics()
                self.mergedPDFDocument = self.editingPDFDocument
                NotificationCenter.default.post(name: .praxFileSelectionChanged, object: nil)
            }
            
        }
    }
    
    var fileURL: URL?
    var lastPreviewURL: URL? = nil
    var lastCombinedSourceURL: URL? = nil
    
    var pdfDisplayMode: PDFDisplayMode = .singlePageContinuous
    var pdfAutoScales: Bool = true
    var pdfDisplayPageBreaks: Bool = true
    var pdfDisplaysAsBook: Bool = false
    
    var pdfBackgroundColor: NSColor = .clear
    var saveError: String?
    
    var pdfSections: [PDFPageSection] = []
    var pdfPages: [PDFPageItem] = [] {
        didSet {
            print ("pdfPages didSet ") //, pdfPages.description)
        }
    }
    
    var mergedPDFURL: URL = {
        
        
        FileManager.default.temporaryDirectory.appendingPathComponent("praxpress-merged-\(UUID().uuidString)").appendingPathExtension("pdf")
    }()
    
    var mergedPDFDocument: PDFDocument? {
        didSet {
            print ("mergedPDFDocument didSet ")
            DispatchQueue.main.async {
                
                self.mergeDocumentPages()
                
                let pv = PDFDocument(url: self.mergedPDFURL)!
                self.mergedPDFView?.document = pv
                
                self.mergedPDFView?.layoutDocumentView()
                print ("Prax Model - mergedPDFDocument layoutDocumentView ")
            }
            
        }
    }
    
    var editingPDFDocument: PDFDocument? {
        didSet {
            print ("editingPDFDocument didSet ")
            pdfSections.removeAll()
            pdfPages.removeAll()
            if let editingPDFDocument {
                pdfSections.append(PDFPageSection(title: "Julie d'Prax"))
                for idx in 0..<editingPDFDocument.pageCount {
                    pdfPages.append(PDFPageItem(index: idx, name:"Page \(idx + 1)"))
                }
            }
        }
    }
    
    func updateCurrentIndex(indexPaths: Set<IndexPath>) -> Void {
        if let first = indexPaths.first {
            currentIndex = first.item
        }
        
    }
    
    func pages(in section: PDFPageSection) -> [PDFPageItem] {
        return pdfPages
    }
    
    var currentIndex: Int = 0
    
    var trims: [Int: EdgeTrims] = [:]
    func trims(for index: Int) -> EdgeTrims { trims[index] ?? .zero }
    func setTrims(_ value: EdgeTrims, for index: Int) { trims[index] = value }
    
    var mergedWidthPts: CGFloat = 0
    var mergedHeightPts: CGFloat = 0
    
    var pageCount: Int? = nil
    var totalHeightPoints: CGFloat? = nil
    var maxWidthPoints: CGFloat? = nil
    
    var mergeTopMargin: Double = 0
    var mergeBottomMargin: Double = 0
    var mergeInterPageGap: Double = 0
    
    // Width Guide support
    var widthGuidePageIndex: Int? = nil
    var widthGuideLeftX: CGFloat? = nil
    var widthGuideRightX: CGFloat? = nil
    
    /// Compute and store the width guide X positions (in page space of the guide page)
    func setWidthGuide(fromPage index: Int) {
        guard let doc = editingPDFDocument, let page = doc.page(at: index) else { return }
        let media = page.bounds(for: .cropBox)
        let per = trims[index] ?? .zero
        let vis = PDFGeometry.visibleRect(media: media, trims: per, seamTop: 0, seamBottom: 0)
        widthGuidePageIndex = index
        widthGuideLeftX = vis.minX
        widthGuideRightX = vis.maxX
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .praxWidthGuideChanged, object: self.mergedPDFView)
        }
    }
    
    /// Remove any active width guide
    func clearWidthGuide() {
        widthGuidePageIndex = nil
        widthGuideLeftX = nil
        widthGuideRightX = nil
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .praxWidthGuideChanged, object: self.mergedPDFView)
        }
    }
    
    func handleMergePagesOverwrite() {
        
        fatalError("Julie d'Prax: This function is not currently implemented")
        guard let id = selectedFiles.first, let entry = listOfFiles.first(where: { $0.id == id }) else { return }
        mergeDocumentPages()
        // Recompute metrics based on the new single-page doc
        computePageMetrics(for: entry.url)
        
    }
    
    func createMergedDocumentFromSelectedFiles () -> PDFDocument? {
        let entries: [PDFEntry] = selectedFiles.compactMap { id in
            listOfFiles.first(where: { $0.id == id })
        }
        let urls = entries.map { $0.url }
        guard !urls.isEmpty else { return nil }
        
        let mergedDoc = PDFDocument()
        mergedDoc.write(to: mergedPDFURL)
        var insertIndex = 0
        for url in urls {
            let needsStop = url.startAccessingSecurityScopedResource()
            defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
            guard let doc = PDFDocument(url: url) else { continue }
            for i in 0..<doc.pageCount {
                if let page = doc.page(at: i) {
                    mergedDoc.insert(page, at: insertIndex)
                    insertIndex += 1
                }
            }
        }
        return mergedDoc
    }
    
    func mergeDocumentPages() {
        
        
        
        guard let pageCount = editingPDFDocument?.pageCount else { return }
        
        var pageRects: [CGRect] = []
        pageRects.reserveCapacity(pageCount)
        
        for i in 0..<pageCount {
            guard let page = editingPDFDocument?.page(at: i) else { continue }
            let rect = page.bounds(for: .cropBox)
            pageRects.append(rect)
        }
        
        let canvas = PDFGeometry.canvasSize(for: pageRects, trims: trims, trimTop: 0, trimBottom: 0, interPageGap: 0)
        let canvasWidth = canvas.width
        let canvasHeight = canvas.height
        
        // Temporarily remove annotations to avoid drawing their appearances twice
        var removedPerPage: [[PDFAnnotation]] = Array(repeating: [], count: pageCount)
        for i in 0..<pageCount {
            if let p = mergedPDFDocument?.page(at: i) {
                removedPerPage[i] = p.annotations
                for a in p.annotations { p.removeAnnotation(a) }
            }
        }
        
        // Create a one-page PDF context
        let fm = FileManager.default
        var mediaBox = CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight)
        let tmpOut = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf")
        guard let consumer = CGDataConsumer(url: tmpOut as CFURL) else { return }
        guard let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return }
        
        ctx.beginPDFPage([kCGPDFContextMediaBox as String: mediaBox] as CFDictionary)
        
        // Stack pages from top to bottom. Track the Y origin of each placed slice for annotation mapping.
        var currentTop = canvasHeight
        var placedOriginsY: [CGFloat] = Array(repeating: 0, count: pageCount)
        
        for i in 0..<pageCount {
            guard let page = mergedPDFDocument?.page(at: i) else { continue }
            let rect = pageRects[i]
            let per = trims[i] ?? .zero
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
            
            currentTop -= visibleHeight // (visibleHeight + interPageGap)
        }
        
        ctx.endPDFPage()
        ctx.closePDF()
        
        // Restore annotations to source pages
        for i in 0..<pageCount {
            if let p = mergedPDFDocument?.page(at: i) {
                for a in removedPerPage[i] { p.addAnnotation(a) }
            }
        }
        
        // Move temp to destination
        let needsStopDest = mergedPDFURL.startAccessingSecurityScopedResource()
        defer { if needsStopDest { mergedPDFURL.stopAccessingSecurityScopedResource() } }
        if fm.fileExists(atPath: mergedPDFURL.path) { try? fm.removeItem(at: mergedPDFURL) }
        do {
            print ("Move at ", tmpOut, " to ", mergedPDFURL)
            try fm.moveItem(at: tmpOut, to: mergedPDFURL)
        }
        catch {
            print("Julie d'Prax: Move temp to destination failed", error.localizedDescription)
        }
        
        // Second pass: reopen merged and re-add cloned annotations with the SAME translation used above
        let needsStopDest2 = mergedPDFURL.startAccessingSecurityScopedResource()
        defer { if needsStopDest2 { mergedPDFURL.stopAccessingSecurityScopedResource() } }
        guard let mergedDoc = PDFDocument(url: mergedPDFURL), let mergedPage = mergedDoc.page(at: 0) else { return }
        
        for i in 0..<pageCount {
            guard let srcPage = mergedPDFDocument?.page(at: i) else { continue }
            let rect = pageRects[i]
            let per = trims[i] ?? .zero
            let seamTop: CGFloat = 0
            let seamBottom: CGFloat = 0
            
            let vis = PDFGeometry.visibleRect(media: rect, trims: per, seamTop: seamTop, seamBottom: seamBottom)
            let dx = 0 - vis.minX
            let dy = placedOriginsY[i] - vis.minY
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
        
        // Save final merged doc safely
        let tmpFinal = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf")
        guard mergedDoc.write(to: tmpFinal) else { return }
        if fm.fileExists(atPath: mergedPDFURL.path) { try? fm.removeItem(at: mergedPDFURL) }
        do {
            try fm.moveItem(at: tmpFinal, to: mergedPDFURL)
        }
        catch {
            fatalError("Julie d'Prax: Mave final merged doc safely failed")
        }
        print("Julie d'Prax: Mave final merged doc safely ", mergedPDFURL)
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
    
    private func recomputeMergedMetrics() {
        guard let doc = editingPDFDocument else {
            mergedWidthPts = 0
            mergedHeightPts = 0
            return
        }
        let count = doc.pageCount
        guard count > 0 else {
            mergedWidthPts = 0
            mergedHeightPts = 0
            return
        }
        var maxVisibleWidth: CGFloat = 0
        var totalVisibleHeight: CGFloat = 0
        for i in 0..<count {
            guard let page = doc.page(at: i) else { continue }
            let media = page.bounds(for: .cropBox)
            let per = trims(for: i)
            let seamTop: CGFloat = (i == 0) ? 0 : 0
            let seamBottom: CGFloat = (i == count - 1) ? 0 : 0
            let vis = PDFGeometry.visibleRect(media: media, trims: per, seamTop: seamTop, seamBottom: seamBottom)
            maxVisibleWidth = max(maxVisibleWidth, vis.width)
            totalVisibleHeight += vis.height
        }
        mergedWidthPts = maxVisibleWidth
        mergedHeightPts = totalVisibleHeight
    }
    
    private func recomputeWidthGuideIfNeeded() {
        guard let guideIndex = widthGuidePageIndex else { return }
        // Recompute guide edges using current trims
        setWidthGuide(fromPage: guideIndex)
    }
    
    // Rebuild sections and page items from the current editingPDFDocument
    // After any reordering, call this to keep the model in sync with the document.
    func rebuildPagesFromDocument() {
        pdfSections.removeAll()
        pdfPages.removeAll()
        guard let doc = editingPDFDocument else { return }
        // For now, single section; later, construct real sections as needed.
        pdfSections.append(PDFPageSection(title: "Julie d'Prax"))
        for i in 0..<doc.pageCount {
            pdfPages.append(PDFPageItem(index: i, name: "Page \(i + 1)"))
        }
        // After reordering, trims are keyed by page index; ensure width guide stays consistent
        recomputeWidthGuideIfNeeded()
    }
    
    // Remap trims using a permutation that maps from old logical indices to new positions.
    // newOrder is an array where position p contains the old logical index now at p.
    func remapTrims(using newOrder: [Int]) {
        // Build inverse mapping: oldIndex -> newIndex
        var newIndexForOld: [Int: Int] = [:]
        for (newIndex, oldIndex) in newOrder.enumerated() {
            newIndexForOld[oldIndex] = newIndex
        }
        var newTrims: [Int: EdgeTrims] = [:]
        for (oldIndex, value) in trims {
            if let newIndex = newIndexForOld[oldIndex] {
                newTrims[newIndex] = value
            }
        }
        trims = newTrims
        recomputeWidthGuideIfNeeded()
    }
    
}

