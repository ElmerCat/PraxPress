//
//  PDFData.swift
//  PraxPress - Prax=0104-1
//
//  Created by Elmer Cat on 12/22/25.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers
internal import Combine

// Minimal SwiftUI wrapper around PDFView
struct MergedDocumentView: View {
    @State private var prax = PraxModel.shared
    
    var body: some View {
        Group {
            if let url = prax.fileURL {
                PDFViewRepresentable(url: url)
            } else {
                ContentUnavailableView { Text("No PDF available") }
            }
        }

        .onChange(of: prax.trims) {
            DispatchQueue.main.async {
                autoUpdatePreviewOnTrimsChange()
            }
        }
        
        .onChange(of: prax.selectedFiles) {
            // Resolve selected entries in selection order
            let selectedIDs = Array(prax.selectedFiles)
            let entries: [PDFEntry] = selectedIDs.compactMap { id in
                prax.listOfFiles.first(where: { $0.id == id })
            }
            let urls = entries.map { $0.url }

            if urls.isEmpty {
                // Clean up any previous temp artifacts
                prax.cleanupTemporaryArtifacts()
                prax.fileURL = nil
                return
            }

            if urls.count == 1, let first = urls.first {
                // Clean up any previous combined temp when switching back to a single source
                prax.cleanupTemporaryArtifacts()
                prax.computePageMetrics(for: first)
                prax.fileURL = first
            } else {
                if let combined = try? prax.buildTemporaryCombinedPDF(from: urls) {
                    prax.computePageMetrics(for: combined)
                    prax.fileURL = combined
                }
            }

            // Regenerate merged preview for the newly selected source using current trims
            autoUpdatePreviewOnTrimsChange()
        }
    }

    private func autoUpdatePreviewOnTrimsChange() {
         
        // Resolve all selected URLs in selection order
        let selectedIDs = Array(prax.selectedFiles)
        let entries: [PDFEntry] = selectedIDs.compactMap { id in
            prax.listOfFiles.first(where: { $0.id == id })
        }
        let urls = entries.map { $0.url }
        guard !urls.isEmpty else { return }
        do {
            let fm = FileManager.default
            let tmp = fm.temporaryDirectory.appendingPathComponent("preview-merged-\(UUID().uuidString)").appendingPathExtension("pdf")
            let sourceURL: URL
            if urls.count == 1, let first = urls.first {
                sourceURL = first
            } else {
                sourceURL = try prax.buildTemporaryCombinedPDF(from: urls)
            }
            try prax.mergeAllPagesVerticallyIntoSinglePage(
                sourceURL: sourceURL,
                destinationURL: tmp,
                trimTop: 0,
                trimBottom: 0,
                interPageGap: 0,
                perPageTrims: prax.trims
            )
            if let old = prax.lastPreviewURL { try? fm.removeItem(at: old) }
            // If the currently displayed file was the combined source, we can keep it; preview is separate.
            // Nothing else required here.
            prax.fileURL = tmp
            prax.lastPreviewURL = tmp
        } catch {
            prax.saveError = error.localizedDescription
        }
    }
}


// Keep existing representable
struct PDFViewRepresentable: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displaysPageBreaks = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        pdfView.backgroundColor = .clear
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }
        let needsReload = (nsView.document == nil) || (nsView.document?.documentURL != url)
        if needsReload {
            if let doc = PDFDocument(url: url) {
                nsView.document = doc
                nsView.layoutDocumentView()
                nsView.autoScales = true
            } else {
                nsView.document = nil
            }
        } else {
            nsView.layoutDocumentView()
        }
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

