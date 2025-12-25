//  PageTrimView.swift
//  PraxPDF - Prax=1220-1

import SwiftUI
import PDFKit
import AppKit
internal import Combine

struct PageTrimStatus: View {
    let model: PerPageTrimModel
    
    var body: some View {
        GroupBox {
            HStack {
                // Left: Page indicator
                Text("Page \(model.currentIndex + 1) of \(model.pdfDocument?.pageCount ?? 0)")
                    .font(.subheadline)
                    
                    
                
                Spacer()
                
                // Right: Live merged size using trims
                if model.mergedWidthPts > 0, model.mergedHeightPts > 0 {
                    let wIn = model.mergedWidthPts / 72.0
                    let hIn = model.mergedHeightPts / 72.0
                    Text(String(format: "Merged size: %.0f × %.0f pts (%.2f × %.2f in)", model.mergedWidthPts, model.mergedHeightPts, wIn, hIn))
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

struct PageTrimView: View {
    @Bindable var viewModel:  ViewModel
    @Bindable var model: PerPageTrimModel
    
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
            
            PageTrimStatus(model: model)
            
            HStack(spacing: 0) {
                PDFPageListView(document: model.pdfDocument, selectedIndex: $model.currentIndex)
                    .frame(width: 180)
                    .background(.quaternary)
                Divider()
                if let doc = model.pdfDocument, let page = doc.page(at: model.currentIndex) {
                    CropOverlayPDFView(page: page, trims: Binding(get: { model.trims(for: model.currentIndex) }, set: { model.setTrims($0, for: model.currentIndex) }))
                        .background(Color(nsColor: .windowBackgroundColor))
                } else {
                    ContentUnavailableView("No page", systemImage: "doc")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            
            .onAppear {
                _ = url.startAccessingSecurityScopedResource()
                model.pdfDocument = PDFDocument(url: url)
                if (model.pdfDocument?.pageCount ?? 0) > 0 { model.currentIndex = 0 }
                recomputeMergedMetrics()
            }
            .onChange(of: url) { _, newURL in
                // Stop access for the old URL if needed
                url.stopAccessingSecurityScopedResource()
                // Start access and load new document
                _ = newURL.startAccessingSecurityScopedResource()
                model.pdfDocument = PDFDocument(url: newURL)
                // Reset page index
                if (model.pdfDocument?.pageCount ?? 0) > 0 { model.currentIndex = 0 }
                // Clear trims for the new document
                model.trims = [:]
                // Recompute merged metrics if available
                DispatchQueue.main.async {
                    recomputeMergedMetrics()
                }
            }
            .onDisappear {
                url.stopAccessingSecurityScopedResource()
            }
            .onChange(of: model.currentIndex) { _, _ in
                DispatchQueue.main.async {
                    recomputeMergedMetrics()
                }
            }
            .onChange(of: model.trims) { _, _ in
                DispatchQueue.main.async {
                    recomputeMergedMetrics()
                }
            }
        }
    }
    
    private func recomputeMergedMetrics() {
        guard let doc = model.pdfDocument else {
            model.mergedWidthPts = 0
            model.mergedHeightPts = 0
            return
        }
        let count = doc.pageCount
        guard count > 0 else {
            model.mergedWidthPts = 0
            model.mergedHeightPts = 0
            return
        }
        var maxVisibleWidth: CGFloat = 0
        var totalVisibleHeight: CGFloat = 0
        for i in 0..<count {
            guard let page = doc.page(at: i) else { continue }
            let media = page.bounds(for: .mediaBox)
            let per = model.trims(for: i)
            let seamTop: CGFloat = (i == 0) ? 0 : 0
            let seamBottom: CGFloat = (i == count - 1) ? 0 : 0
            let vis = PDFGeometry.visibleRect(media: media, trims: per, seamTop: seamTop, seamBottom: seamBottom)
            maxVisibleWidth = max(maxVisibleWidth, vis.width)
            totalVisibleHeight += vis.height
        }
        model.mergedWidthPts = maxVisibleWidth
        model.mergedHeightPts = totalVisibleHeight
    }
}

private struct PDFPageListView: View {
    let document: PDFDocument?
    @Binding var selectedIndex: Int
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                if let doc = document {
                    ForEach(0..<(doc.pageCount), id: \.self) { i in
                        Button(action: { selectedIndex = i }) {
                            HStack(alignment: .top, spacing: 8) {
                                if let thumb = doc.page(at: i)?.thumbnail(of: NSSize(width: 120, height: 160), for: .mediaBox) {
                                    Image(nsImage: thumb)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 120)
                                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(selectedIndex == i ? Color.accentColor : .clear, lineWidth: 3))
                                }
                                Text("Page \(i + 1)")
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }.padding(8)
        }
    }
}

// A PDFKit-backed view that shows a single page and lets the user drag a rectangle to set trims.
struct CropOverlayPDFView: NSViewRepresentable {
    let page: PDFPage
    @Binding var trims: EdgeTrims
    
    func makeNSView(context: Context) -> CropOverlayPDFNSView {
        let v = CropOverlayPDFNSView()
        v.configure(page: page, trims: trims)
        v.onTrimsChanged = { self.trims = $0 }
        return v
    }
    
    func updateNSView(_ nsView: CropOverlayPDFNSView, context: Context) {
        nsView.configure(page: page, trims: trims)
    }
}

final class CropOverlayPDFNSView: NSView {
    private let pdfView = PDFView()
    private let overlay = OverlayView()
    private var page: PDFPage?
    var onTrimsChanged: ((EdgeTrims) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        pdfView.autoScales = true
        addSubview(pdfView)
        addSubview(overlay)
        overlay.isHidden = false
        overlay.wantsLayer = true
        overlay.onFinish = { [weak self] rectInView in
            guard let self, let page = self.page else { return }
            // Clamp rect to page bounds in view coordinates
            let pageBoundsInView = self.pageBoundsInView()
            let clamped = rectInView.intersection(pageBoundsInView)
            guard !clamped.isEmpty else { return }
            // Convert to page space and compute trims
            let pageRect = self.pdfView.convert(clamped, to: page)
            let media = page.bounds(for: .mediaBox)
            let left = max(0, pageRect.minX - media.minX)
            let right = max(0, media.maxX - pageRect.maxX)
            let bottom = max(0, pageRect.minY - media.minY)
            let top = max(0, media.maxY - pageRect.maxY)
            let trims = EdgeTrims(left: left, right: right, top: top, bottom: bottom)
            self.overlay.currentRect = clamped
            self.onTrimsChanged?(trims)
        }
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func layout() {
        super.layout()
        pdfView.frame = bounds
        overlay.frame = bounds
        overlay.needsDisplay = true
    }
    
    func configure(page: PDFPage, trims: EdgeTrims) {
        if self.page !== page {
            let doc = PDFDocument()
            doc.insert(page, at: 0)
            pdfView.document = doc
            pdfView.go(to: page)
            self.page = page
        }
        // Draw existing trims as a selection rectangle
        if let page = self.page {
            let media = page.bounds(for: .mediaBox)
            let visible = CGRect(x: media.minX + trims.left,
                                 y: media.minY + trims.bottom,
                                 width: media.width - trims.left - trims.right,
                                 height: media.height - trims.top - trims.bottom)
            let rInView = pdfView.convert(visible, from: page)
            overlay.currentRect = rInView
            overlay.needsDisplay = true
        }
    }
    
    private func pageBoundsInView() -> CGRect {
        guard let page else { return .zero }
        let media = page.bounds(for: .mediaBox)
        return pdfView.convert(media, from: page)
    }
    
    // Transparent overlay that captures mouse and draws the selection rectangle
    private final class OverlayView: NSView {
        var onFinish: ((CGRect) -> Void)?
        var currentRect: CGRect? { didSet { needsDisplay = true } }
        private var dragStart: CGPoint?
        
        override var acceptsFirstResponder: Bool { true }
        override func hitTest(_ point: NSPoint) -> NSView? { return self } // capture events over pdfView
        
        override func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)
            guard let r = currentRect else { return }
            NSColor.systemBlue.setStroke()
            let path = NSBezierPath(rect: r)
            path.lineWidth = 2
            path.stroke()
            NSColor.systemBlue.withAlphaComponent(0.15).setFill()
            r.fill()
        }
        
        override func mouseDown(with event: NSEvent) {
            dragStart = convert(event.locationInWindow, from: nil)
            currentRect = CGRect(origin: dragStart!, size: .zero)
        }
        
        override func mouseDragged(with event: NSEvent) {
            guard let start = dragStart else { return }
            let cur = convert(event.locationInWindow, from: nil)
            currentRect = CGRect(x: min(start.x, cur.x),
                                 y: min(start.y, cur.y),
                                 width: abs(cur.x - start.x),
                                 height: abs(cur.y - start.y))
        }
        
        override func mouseUp(with event: NSEvent) {
            guard let rect = currentRect else { return }
            onFinish?(rect)
        }
    }
}
