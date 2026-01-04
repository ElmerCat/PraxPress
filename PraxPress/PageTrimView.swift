//
//  PageTrimView.swift
//  PraxPress - Prax=0104-0
//

import SwiftUI
import PDFKit
import AppKit
internal import Combine
import QuartzCore

struct PageTrimView: View {
    @Bindable var viewModel:  ViewModel
    @Bindable var pdfModel: PDFModel
    
    var body: some View {
        
        if viewModel.selectedFiles.isEmpty {
            Text("Plese Select a File to Merge")
                .font(Font.largeTitle.bold())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        else {
            let id = viewModel.selectedFiles.first
            let entry = viewModel.listOfFiles.first(where: { $0.id == id })
            let url = entry!.url
            
            PageTrimStatus(pdfModel: pdfModel)
            
            // Break complex subviews into locals to help the type checker
            let documentView = PDFDocumentView(viewModel: viewModel, pdfModel: pdfModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            documentView
            
                .toolbar {
                    ToolbarItemGroup(placement: .automatic) {
                        Menu {
                            Button("Single Page") { viewModel.pdfDisplayMode = .singlePage }
                            Button("Single Page Continuous") { viewModel.pdfDisplayMode = .singlePageContinuous }
                            Button("Two Up") { viewModel.pdfDisplayMode = .twoUp }
                            Button("Two Up Continuous") { viewModel.pdfDisplayMode = .twoUpContinuous }
                        } label: {
                            Label("Display Mode", systemImage: "rectangle.split.2x1")
                        }
                        
                        Toggle(isOn: $viewModel.pdfAutoScales) {
                            Label("Auto Scales", systemImage: "arrow.up.left.and.down.right.magnifyingglass")
                        }
                        
                        Toggle(isOn: $viewModel.pdfDisplaysAsBook) {
                            Label("Book Mode", systemImage: "book")
                        }
                    }

                }
                .onAppear {
                    let selectedIDs = Array(viewModel.selectedFiles)
                    let selectedEntries: [PDFEntry] = selectedIDs.compactMap { id in
                        viewModel.listOfFiles.first(where: { $0.id == id })
                    }
                    let urls = selectedEntries.map { $0.url }
                    
                    if let first = urls.first, urls.count == 1 {
                        _ = first.startAccessingSecurityScopedResource()
                        pdfModel.pdfDocument = PDFDocument(url: first)
                    } else if !urls.isEmpty {
                        do {
                            let combinedURL = try pdfModel.buildTemporaryCombinedPDF(from: urls)
                            _ = combinedURL.startAccessingSecurityScopedResource()
                            pdfModel.pdfDocument = PDFDocument(url: combinedURL)
                        } catch {
                            // Fall back to empty document on error
                            pdfModel.pdfDocument = PDFDocument()
                        }
                    } else {
                        pdfModel.pdfDocument = nil
                    }
                    
                    if (pdfModel.pdfDocument?.pageCount ?? 0) > 0 { pdfModel.currentIndex = 0 }
                    pdfModel.trims = [:]
                    pdfModel.clearWidthGuide()
                    DispatchQueue.main.async { recomputeMergedMetrics() }
                }
                .onChange(of: pdfModel.pdfDocument) { _, _ in
                    DispatchQueue.main.async { /* advance runloop to stabilize bindings */ }
                }
                .onChange(of: viewModel.selectedFiles) { _, _ in
                    let selectedIDs = Array(viewModel.selectedFiles)
                    let selectedEntries: [PDFEntry] = selectedIDs.compactMap { id in
                        viewModel.listOfFiles.first(where: { $0.id == id })
                    }
                    let urls = selectedEntries.map { $0.url }
                    
                    if let first = urls.first, urls.count == 1 {
                        first.stopAccessingSecurityScopedResource()
                        _ = first.startAccessingSecurityScopedResource()
                        pdfModel.pdfDocument = PDFDocument(url: first)
                    } else if !urls.isEmpty {
                        do {
                            let combinedURL = try pdfModel.buildTemporaryCombinedPDF(from: urls)
                            _ = combinedURL.startAccessingSecurityScopedResource()
                            pdfModel.pdfDocument = PDFDocument(url: combinedURL)
                        } catch {
                            pdfModel.pdfDocument = PDFDocument()
                        }
                    } else {
                        pdfModel.pdfDocument = nil
                    }
                    
                    if (pdfModel.pdfDocument?.pageCount ?? 0) > 0 { pdfModel.currentIndex = 0 }
                    pdfModel.trims = [:]
                    pdfModel.clearWidthGuide()
                    DispatchQueue.main.async { recomputeMergedMetrics() }
                }
                .onDisappear {
                    url.stopAccessingSecurityScopedResource()
                }
                .onChange(of: pdfModel.currentIndex) { _, _ in
                    DispatchQueue.main.async {
                        recomputeMergedMetrics()
                        recomputeWidthGuideIfNeeded()
                    }
                }
                .onChange(of: pdfModel.trims) { _, _ in
                    DispatchQueue.main.async {
                        recomputeMergedMetrics()
                        recomputeWidthGuideIfNeeded()
                    }
                }
            
        }
    }
    
    
    private func recomputeMergedMetrics() {
        guard let doc = pdfModel.pdfDocument else {
            pdfModel.mergedWidthPts = 0
            pdfModel.mergedHeightPts = 0
            return
        }
        let count = doc.pageCount
        guard count > 0 else {
            pdfModel.mergedWidthPts = 0
            pdfModel.mergedHeightPts = 0
            return
        }
        var maxVisibleWidth: CGFloat = 0
        var totalVisibleHeight: CGFloat = 0
        for i in 0..<count {
            guard let page = doc.page(at: i) else { continue }
            let media = page.bounds(for: .cropBox)
            let per = pdfModel.trims(for: i)
            let seamTop: CGFloat = (i == 0) ? 0 : 0
            let seamBottom: CGFloat = (i == count - 1) ? 0 : 0
            let vis = PDFGeometry.visibleRect(media: media, trims: per, seamTop: seamTop, seamBottom: seamBottom)
            maxVisibleWidth = max(maxVisibleWidth, vis.width)
            totalVisibleHeight += vis.height
        }
        pdfModel.mergedWidthPts = maxVisibleWidth
        pdfModel.mergedHeightPts = totalVisibleHeight
    }
    
    private func recomputeWidthGuideIfNeeded() {
        guard let guideIndex = pdfModel.widthGuidePageIndex else { return }
        // Recompute guide edges using current trims
        pdfModel.setWidthGuide(fromPage: guideIndex)
    }
}

