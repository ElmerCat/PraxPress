//
//  MergedDocumentView.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/12/26.
//


import SwiftUI
import PDFKit
import UniformTypeIdentifiers
internal import Combine

// Minimal SwiftUI wrapper around PDFView
struct MergedDocumentView: View {

    @State private var prax = PraxModel.shared
    
    var body: some View {
        
        let _ = Self._printChanges()
        
        Group {
            if let url = prax.fileURL {
                PDFViewRepresentable(url: url)
            } else {
                ContentUnavailableView { Text("No PDF available") }
            }
        }

        .onAppear() {
            print("Lessie Sheffield - MergedDocumentView .onAppear()  ")
        }
        
        .onChange(of: prax.trims) {
            DispatchQueue.main.async {
                print("Lessie Sheffield - MergedDocumentView .onChange(of: prax.trims) ")
                updateMergedDocument()
            }
        }
        
        .onChange(of: prax.selectedFiles) {
            
            print("\nJulie d'Prax - Da Prax is wrong!\n")
            
            return
            
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
            updateMergedDocument()
        }
    }

    private func updateMergedDocument() {
        
        
        print ("\nupdateMergedDocument Julie d'Prax - Da Prax is wrong!\n")
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
            prax.mergeDocumentPages()
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

final class Coordinator: NSObject {
    @State private var prax = PraxModel.shared
    
    @objc func fileSelectionChanged(_ note: Notification) {
        print("MergedDocumentView - fileSelectionChanged")
         
    }
}

// Keep existing representable
struct PDFViewRepresentable: NSViewRepresentable {
    let url: URL
    
    @State private var prax = PraxModel.shared
    
    func makeNSView(context: Context) -> PDFView {
        print("PDFViewRepresentable - makeNSView")
        prax.mergedPDFView = PDFView()
        prax.mergedPDFView!.displaysPageBreaks = true
        prax.mergedPDFView!.displayMode = .singlePageContinuous
        prax.mergedPDFView!.autoScales = true
        prax.mergedPDFView!.backgroundColor = .clear
        return prax.mergedPDFView!
    }
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        print("PDFViewRepresentable - updateNSView")
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }
        let needsReload = (pdfView.document == nil) || (pdfView.document?.documentURL != url)
        if needsReload {
            if let doc = PDFDocument(url: url) {
                pdfView.document = doc
                pdfView.layoutDocumentView()
                pdfView.autoScales = true
            } else {
                pdfView.document = nil
            }
        } else {
            pdfView.layoutDocumentView()
        }
    }
}

/*
 
 
 func makeCoordinator() -> Coordinator {
 print("Lessie Sheffield - MergedDocumentView makeCoordinator")
 return Coordinator()
 }
 
 func makeNSView(context: Context) -> PDFView {
 print("Lessie Sheffield - MergedDocumentView makeNSView")
 let pdfView = PDFView()
 prax.mergedPDFView = pdfView
 pdfView.displaysPageBreaks = true
 pdfView.displayMode = .singlePageContinuous
 pdfView.autoScales = true
 pdfView.backgroundColor = .clear
 
 NotificationCenter.default.addObserver(
 context.coordinator,
 selector: #selector(Coordinator.fileSelectionChanged(_:)),
 name: .praxFileSelectionChanged,
 object: nil
 )
 let julieDPrax = prax.pdfDisplayMode
 return pdfView
 
 }
 
 func updateNSView(_ pdfView: PDFView, context: Context) {
 print("Lessie Sheffield - MergedDocumentView updateNSView")
 
 print("\nJulie d'Prax - Da Prax is wrong!\n")
 
 if !prax.selectedFiles.isEmpty {
 let needsReload = (pdfView.document == nil) || (pdfView.document?.documentURL != prax.mergedPDFURL)
 if needsReload {
 if let doc = PDFDocument(url: prax.mergedPDFURL) {
 pdfView.document = doc
 pdfView.layoutDocumentView()
 pdfView.autoScales = true
 } else {
 pdfView.document = nil
 }
 } else {
 pdfView.layoutDocumentView()
 }
 }
 }

 */
