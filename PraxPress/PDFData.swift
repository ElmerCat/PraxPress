//
//  PDFData.swift
//  PraxPress - Prax=1229-3
//
//  Created by Elmer Cat on 12/22/25.
//

import SwiftUI
import PDFKit
internal import Combine

// Minimal SwiftUI wrapper around PDFView
struct PDFViewContainer: View {
    let viewModel: ViewModel
    let pdfModel: PDFModel
    
    var body: some View {
        Group {
            if let url = pdfModel.fileURL {
                PDFViewRepresentable(url: url)
            } else {
                ContentUnavailableView { Text("No PDF available") }
            }
        }

        .onChange(of: pdfModel.trims) {
            DispatchQueue.main.async {
                autoUpdatePreviewOnTrimsChange(viewModel: viewModel, pdfModel: pdfModel)
            }
        }
        
        .onChange(of: viewModel.selectedFiles) {
            // Resolve selected entries in selection order
            let selectedIDs = Array(viewModel.selectedFiles)
            let entries: [PDFEntry] = selectedIDs.compactMap { id in
                viewModel.listOfFiles.first(where: { $0.id == id })
            }
            let urls = entries.map { $0.url }

            if urls.isEmpty {
                // Clean up any previous temp artifacts
                pdfModel.cleanupTemporaryArtifacts()
                pdfModel.fileURL = nil
                return
            }

            if urls.count == 1, let first = urls.first {
                // Clean up any previous combined temp when switching back to a single source
                pdfModel.cleanupTemporaryArtifacts()
                pdfModel.computePageMetrics(for: first)
                pdfModel.fileURL = first
            } else {
                if let combined = try? pdfModel.buildTemporaryCombinedPDF(from: urls) {
                    pdfModel.computePageMetrics(for: combined)
                    pdfModel.fileURL = combined
                }
            }

            // Regenerate merged preview for the newly selected source using current trims
            autoUpdatePreviewOnTrimsChange(viewModel: viewModel, pdfModel: pdfModel)
        }
    }

    private func autoUpdatePreviewOnTrimsChange(viewModel: ViewModel, pdfModel: PDFModel) {
         
        // Resolve all selected URLs in selection order
        let selectedIDs = Array(viewModel.selectedFiles)
        let entries: [PDFEntry] = selectedIDs.compactMap { id in
            viewModel.listOfFiles.first(where: { $0.id == id })
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
                sourceURL = try pdfModel.buildTemporaryCombinedPDF(from: urls)
            }
            try pdfModel.mergeAllPagesVerticallyIntoSinglePage(
                sourceURL: sourceURL,
                destinationURL: tmp,
                trimTop: 0,
                trimBottom: 0,
                interPageGap: 0,
                perPageTrims: pdfModel.trims
            )
            if let old = pdfModel.lastPreviewURL { try? fm.removeItem(at: old) }
            // If the currently displayed file was the combined source, we can keep it; preview is separate.
            // Nothing else required here.
            pdfModel.fileURL = tmp
            pdfModel.lastPreviewURL = tmp
        } catch {
            viewModel.saveError = error.localizedDescription
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

