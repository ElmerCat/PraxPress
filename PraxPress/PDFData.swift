//
//  PDFData.swift
//  PraxPress
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
            print("Julie d'Prax")
            
            if let id = viewModel.selectedFiles.first, let entry = viewModel.listOfFiles.first(where: { $0.id == id }) {
                pdfModel.computePageMetrics(for: entry.url)
                
                pdfModel.fileURL = entry.url
                
                // Regenerate merged preview for the newly selected file using current trims
                autoUpdatePreviewOnTrimsChange(viewModel: viewModel, pdfModel: pdfModel)
            }
            
        }
    }


    private func autoUpdatePreviewOnTrimsChange(viewModel: ViewModel, pdfModel: PDFModel) {
         
        guard let id = viewModel.selectedFiles.first, let entry = viewModel.listOfFiles.first(where: { $0.id == id }) else { return }
        do {
            let fm = FileManager.default
            let tmp = fm.temporaryDirectory.appendingPathComponent("preview-merged-\(UUID().uuidString)").appendingPathExtension("pdf")
            try pdfModel.mergeAllPagesVerticallyIntoSinglePage(
                sourceURL: entry.url,
                destinationURL: tmp,
                trimTop: 0,
                trimBottom: 0,
                interPageGap: 0,
                perPageTrims: pdfModel.trims
            )
            if let old = pdfModel.lastPreviewURL { try? fm.removeItem(at: old) }
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
