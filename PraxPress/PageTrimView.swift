//  PageTrimView.swift
//  PraxPDF - Prax=1220-1

import SwiftUI
import PDFKit
import AppKit
internal import Combine

struct PageTrimStatus: View {
    let pdfModel: PDFModel
    
    var body: some View {
        GroupBox {
            HStack {
                // Left: Page indicator
                Text("Page \(pdfModel.currentIndex + 1) of \(pdfModel.pdfDocument?.pageCount ?? 0)")
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
            
            HStack(spacing: 0) {
                PDFPageListView(document: pdfModel.pdfDocument, selectedIndex: $pdfModel.currentIndex)
                    .frame(width: 180)
                    .background(.quaternary)
                Divider()
                if let doc = pdfModel.pdfDocument, let page = doc.page(at: pdfModel.currentIndex) {
                    CropOverlayPDFView(page: page, trims: Binding(get: { pdfModel.trims(for: pdfModel.currentIndex) }, set: { pdfModel.setTrims($0, for: pdfModel.currentIndex) }))
                        .background(Color(nsColor: .windowBackgroundColor))
                } else {
                    ContentUnavailableView("No page", systemImage: "doc")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            .onAppear {
                _ = url.startAccessingSecurityScopedResource()
                pdfModel.pdfDocument = PDFDocument(url: url)
                if (pdfModel.pdfDocument?.pageCount ?? 0) > 0 { pdfModel.currentIndex = 0 }
                recomputeMergedMetrics()
            }
            .onChange(of: url) { _, newURL in
                // Stop access for the old URL if needed
                url.stopAccessingSecurityScopedResource()
                // Start access and load new document
                _ = newURL.startAccessingSecurityScopedResource()
                pdfModel.pdfDocument = PDFDocument(url: newURL)
                // Reset page index
                if (pdfModel.pdfDocument?.pageCount ?? 0) > 0 { pdfModel.currentIndex = 0 }
                // Clear trims for the new document
                pdfModel.trims = [:]
                // Recompute merged metrics if available
                DispatchQueue.main.async {
                    recomputeMergedMetrics()
                }
            }
            .onDisappear {
                url.stopAccessingSecurityScopedResource()
            }
            .onChange(of: pdfModel.currentIndex) { _, _ in
                DispatchQueue.main.async {
                    recomputeMergedMetrics()
                }
            }
            .onChange(of: pdfModel.trims) { _, _ in
                DispatchQueue.main.async {
                    recomputeMergedMetrics()
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
            let media = page.bounds(for: .mediaBox)
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
        private let handleSize: CGFloat = 8
        private let hitInset: CGFloat = 6
        
        enum Handle {
            case topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left
        }
        enum DragMode {
            case none
            case move
            case resize(Handle)
        }
        
        var onFinish: ((CGRect) -> Void)?
        var currentRect: CGRect? { didSet { needsDisplay = true } }
        
        private var dragMode: DragMode = .none
        private var dragStart: CGPoint?
        private var originalRect: CGRect?
        
        override var acceptsFirstResponder: Bool { true }
        override func hitTest(_ point: NSPoint) -> NSView? { return self } // capture events over pdfView
        
        private func handleRects(for rect: CGRect) -> [Handle: CGRect] {
            var dict: [Handle: CGRect] = [:]
            let hs = handleSize
            let x = rect.minX
            let y = rect.minY
            let w = rect.width
            let h = rect.height
            dict[.topLeft] = CGRect(x: x - hs/2, y: y + h - hs/2, width: hs, height: hs)
            dict[.top] = CGRect(x: x + w/2 - hs/2, y: y + h - hs/2, width: hs, height: hs)
            dict[.topRight] = CGRect(x: x + w - hs/2, y: y + h - hs/2, width: hs, height: hs)
            dict[.right] = CGRect(x: x + w - hs/2, y: y + h/2 - hs/2, width: hs, height: hs)
            dict[.bottomRight] = CGRect(x: x + w - hs/2, y: y - hs/2, width: hs, height: hs)
            dict[.bottom] = CGRect(x: x + w/2 - hs/2, y: y - hs/2, width: hs, height: hs)
            dict[.bottomLeft] = CGRect(x: x - hs/2, y: y - hs/2, width: hs, height: hs)
            dict[.left] = CGRect(x: x - hs/2, y: y + h/2 - hs/2, width: hs, height: hs)
            return dict
        }
        
        private func hitTestHandle(_ point: CGPoint, in rect: CGRect) -> Handle? {
            let handles = handleRects(for: rect)
            for (handle, handleRect) in handles {
                let hitRect = handleRect.insetBy(dx: -hitInset, dy: -hitInset)
                if hitRect.contains(point) {
                    return handle
                }
            }
            return nil
        }
        
        override func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)
            guard let r = currentRect else { return }
            
            NSColor.systemBlue.setStroke()
            NSColor.systemBlue.withAlphaComponent(0.15).setFill()
            
            // Fill rect semi-transparent
            r.fill()
            
            // Draw rect border
            let path = NSBezierPath(rect: r)
            path.lineWidth = 2
            path.stroke()
            
            // Draw handles as small squares
            NSColor.white.setFill()
            NSColor.systemBlue.setStroke()
            for handleRect in handleRects(for: r).values {
                let handlePath = NSBezierPath(rect: handleRect)
                handlePath.fill()
                handlePath.lineWidth = 1.5
                handlePath.stroke()
            }
        }
        
        override func mouseDown(with event: NSEvent) {
            let point = convert(event.locationInWindow, from: nil)
            dragStart = point
            
            guard let rect = currentRect else {
                // No existing rect, start new one
                dragMode = .resize(.bottomLeft) // use bottomLeft as a stand-in for creation drag
                currentRect = CGRect(origin: point, size: .zero)
                originalRect = nil
                return
            }
            
            if let handle = hitTestHandle(point, in: rect) {
                dragMode = .resize(handle)
                originalRect = rect
            } else if rect.insetBy(dx: hitInset, dy: hitInset).contains(point) {
                dragMode = .move
                originalRect = rect
            } else {
                // Start new rect creation
                dragMode = .resize(.bottomLeft)
                currentRect = CGRect(origin: point, size: .zero)
                originalRect = nil
            }
        }
        
        override func mouseDragged(with event: NSEvent) {
            guard let dragStart = dragStart else { return }
            let point = convert(event.locationInWindow, from: nil)
         //  let pageBounds = superview?.convert(superview?.bounds ?? .zero, to: self) ?? bounds
            let pageRect = pageBoundsInView()
            
            switch dragMode {
            case .none:
                break
                
            case .move:
                guard let originalRect = originalRect else { return }
                let deltaX = point.x - dragStart.x
                let deltaY = point.y - dragStart.y
                var newRect = originalRect.offsetBy(dx: deltaX, dy: deltaY)
                newRect = newRect.intersection(pageRect)
                if newRect.width < handleSize * 2 || newRect.height < handleSize * 2 {
                    // Prevent rectangle from becoming too small or zero-size after intersection:
                    newRect = originalRect
                }
                currentRect = newRect
                
            case .resize(let handle):
                let r = originalRect ?? CGRect(origin: dragStart, size: .zero)
                
                var minX = r.minX
                var maxX = r.maxX
                var minY = r.minY
                var maxY = r.maxY
                
                func clampX(_ x: CGFloat) -> CGFloat {
                    return max(pageRect.minX, min(pageRect.maxX, x))
                }
                func clampY(_ y: CGFloat) -> CGFloat {
                    return max(pageRect.minY, min(pageRect.maxY, y))
                }
                
                let x = clampX(point.x)
                let y = clampY(point.y)
                
                switch handle {
                case .topLeft:
                    minX = min(x, maxX - handleSize * 2)
                    maxY = max(y, minY + handleSize * 2)
                case .top:
                    maxY = max(y, minY + handleSize * 2)
                case .topRight:
                    maxX = max(x, minX + handleSize * 2)
                    maxY = max(y, minY + handleSize * 2)
                case .right:
                    maxX = max(x, minX + handleSize * 2)
                case .bottomRight:
                    maxX = max(x, minX + handleSize * 2)
                    minY = min(y, maxY - handleSize * 2)
                case .bottom:
                    minY = min(y, maxY - handleSize * 2)
                case .bottomLeft:
                    minX = min(x, maxX - handleSize * 2)
                    minY = min(y, maxY - handleSize * 2)
                case .left:
                    minX = min(x, maxX - handleSize * 2)
                }
                
                let newRect = CGRect(x: minX,
                                     y: minY,
                                     width: maxX - minX,
                                     height: maxY - minY).intersection(pageRect)
                
                if newRect.width >= handleSize * 2 && newRect.height >= handleSize * 2 {
                    currentRect = newRect
                }
                
            }
        }
        
        override func mouseUp(with event: NSEvent) {
            dragMode = .none
            dragStart = nil
            originalRect = nil
            
            if let rect = currentRect {
                onFinish?(rect)
            }
        }
        
        private func pageBoundsInView() -> CGRect {
            // The CropOverlayPDFNSView will call this for clamping
            // We assume superview is CropOverlayPDFNSView and it has pageBoundsInView()
            if let superview = superview as? CropOverlayPDFNSView {
                return superview.pageBoundsInView()
            } else {
                return bounds
            }
        }
    }
}
