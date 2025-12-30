//  PDFDocumentWithTrimOverlay.swift
//  PraxPress - Prax=1229-3
//
//  A full-document PDFView with an interactive trim overlay on top, reusing
//  the same coordinate conversion logic as CropOverlayPDFNSView.

import SwiftUI
import PDFKit
import AppKit

struct PDFDocumentWithTrimOverlay: NSViewRepresentable {
    @Binding var document: PDFDocument?
    @Binding var currentIndex: Int
    @Binding var trims: [Int: EdgeTrims]

    var displayMode: PDFDisplayMode = .singlePageContinuous
    var displaysPageBreaks: Bool = true
    var autoScales: Bool = true
    var backgroundColor: NSColor = .clear
    var displaysAsBook: Bool = false

    var onPDFViewReady: (PDFView) -> Void = { _ in }

    func makeCoordinator() -> Coordinator { Coordinator(currentIndex: $currentIndex, trims: $trims) }

    func makeNSView(context: Context) -> NSView {
        let container = NSView()

        let pdfView = PDFView()
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.autoScales = autoScales
        pdfView.displayMode = displayMode
        pdfView.displaysPageBreaks = displaysPageBreaks
        pdfView.backgroundColor = backgroundColor
        pdfView.displaysAsBook = displaysAsBook
        container.addSubview(pdfView)
        context.coordinator.pdfView = pdfView

        let overlay = TrimOverlayView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.isHidden = false
        container.addSubview(overlay)
        context.coordinator.overlay = overlay

        overlay.onFinish = { [weak pdfView, weak coordinator = context.coordinator] rectInView in
            guard let pdfView = pdfView, let coordinator = coordinator,
                  let page = pdfView.currentPage else { return }
            // Clamp to page bounds
            let pageBoundsInView = coordinator.pageBoundsInView()
            let clamped = rectInView.intersection(pageBoundsInView)
            guard !clamped.isEmpty else { return }
            // Convert to page space and compute trims
            let pageRect = pdfView.convert(clamped, to: page)
            let media = page.bounds(for: .mediaBox)
            let left = max(0, pageRect.minX - media.minX)
            let right = max(0, media.maxX - pageRect.maxX)
            let bottom = max(0, pageRect.minY - media.minY)
            let top = max(0, media.maxY - pageRect.maxY)
            let newTrims = EdgeTrims(left: left, right: right, top: top, bottom: bottom)
            if let idx = coordinator.currentIndexValue {
                coordinator.trims[idx] = newTrims
            }
            overlay.currentRect = clamped
            overlay.needsDisplay = true
        }

        NSLayoutConstraint.activate([
            pdfView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: container.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            overlay.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: container.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: Notification.Name.PDFViewPageChanged,
            object: pdfView
        )
        
        DispatchQueue.main.async { [weak pdfView] in
            if let pdfView = pdfView { self.onPDFViewReady(pdfView) }
        }

        return container
    }

    func updateNSView(_ container: NSView, context: Context) {
        guard let pdfView = context.coordinator.pdfView,
              let overlay = context.coordinator.overlay else { return }

        // Update document and display options
        if pdfView.document !== document { pdfView.document = document }
        if pdfView.displayMode != displayMode { pdfView.displayMode = displayMode }
        if pdfView.displaysPageBreaks != displaysPageBreaks { pdfView.displaysPageBreaks = displaysPageBreaks }
        if pdfView.backgroundColor != backgroundColor { pdfView.backgroundColor = backgroundColor }
        if pdfView.displaysAsBook != displaysAsBook { pdfView.displaysAsBook = displaysAsBook }
        if pdfView.autoScales != autoScales { pdfView.autoScales = autoScales }

        // Sync current page (model -> view)
        if let doc = document, currentIndex >= 0, currentIndex < doc.pageCount {
            let page = doc.page(at: currentIndex)!
            if pdfView.currentPage !== page { pdfView.go(to: page) }
        }

        // Update overlay rect from trims for the current page
        if let doc = document, currentIndex >= 0, currentIndex < doc.pageCount,
           let page = doc.page(at: currentIndex) {
            let media = page.bounds(for: .mediaBox)
            let t = trims[currentIndex] ?? .zero
            let visible = CGRect(
                x: media.minX + t.left,
                y: media.minY + t.bottom,
                width: media.width - t.left - t.right,
                height: media.height - t.top - t.bottom
            )
            let rectInView = pdfView.convert(visible, from: page)
            overlay.currentRect = rectInView
            context.coordinator.currentIndexValue = currentIndex
        } else {
            overlay.currentRect = nil
        }
    }

    final class Coordinator: NSObject {
        weak var pdfView: PDFView?
        fileprivate weak var overlay: TrimOverlayView?
        @Binding var currentIndex: Int
        @Binding var trims: [Int: EdgeTrims]
        var currentIndexValue: Int?

        init(currentIndex: Binding<Int>, trims: Binding<[Int: EdgeTrims]>) {
            _currentIndex = currentIndex
            _trims = trims
        }

        @objc func pageChanged(_ note: Notification) {
            guard let pdfView = note.object as? PDFView,
                  let doc = pdfView.document,
                  let page = pdfView.currentPage else { return }
            let idx = doc.index(for: page)
            if idx != NSNotFound, idx != currentIndex { currentIndex = idx }
        }

        func pageBoundsInView() -> CGRect {
            guard let pdfView, let page = pdfView.currentPage else { return .zero }
            let media = page.bounds(for: .mediaBox)
            return pdfView.convert(media, from: page)
        }
    }
}

// Transparent overlay that captures mouse and draws the selection rectangle
final class TrimOverlayView: NSView {
    var onFinish: ((CGRect) -> Void)?
    var currentRect: CGRect? { didSet { needsDisplay = true } }

    private let handleSize: CGFloat = 8
    private let hitInset: CGFloat = 6

    private enum Handle { case topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left }
    private enum DragMode { case none, move, resize(Handle) }

    private var dragMode: DragMode = .none
    private var dragStart: CGPoint?
    private var originalRect: CGRect?

    override var acceptsFirstResponder: Bool { true }
    override func hitTest(_ point: NSPoint) -> NSView? { return self }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let r = currentRect else { return }
        NSColor.systemBlue.setStroke()
        NSColor.systemBlue.withAlphaComponent(0.15).setFill()
        r.fill()
        let path = NSBezierPath(rect: r)
        path.lineWidth = 2
        path.stroke()
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
        if let rect = currentRect {
            if let handle = hitTestHandle(point, in: rect) {
                dragMode = .resize(handle)
                originalRect = rect
            } else if rect.insetBy(dx: hitInset, dy: hitInset).contains(point) {
                dragMode = .move
                originalRect = rect
            } else {
                dragMode = .resize(.bottomLeft)
                currentRect = CGRect(origin: point, size: .zero)
                originalRect = nil
            }
        } else {
            dragMode = .resize(.bottomLeft)
            currentRect = CGRect(origin: point, size: .zero)
            originalRect = nil
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let dragStart = dragStart else { return }
        let point = convert(event.locationInWindow, from: nil)
        let pageRect = pageBoundsInView()
        switch dragMode {
        case .none:
            break
        case .move:
            guard let originalRect = originalRect else { return }
            var newRect = originalRect.offsetBy(dx: point.x - dragStart.x, dy: point.y - dragStart.y)
            // Clamp to pageRect but keep size constant
            if newRect.minX < pageRect.minX {
                newRect.origin.x = pageRect.minX
            }
            if newRect.maxX > pageRect.maxX {
                newRect.origin.x = pageRect.maxX - newRect.width
            }
            if newRect.minY < pageRect.minY {
                newRect.origin.y = pageRect.minY
            }
            if newRect.maxY > pageRect.maxY {
                newRect.origin.y = pageRect.maxY - newRect.height
            }
            if newRect.width >= handleSize * 2 && newRect.height >= handleSize * 2 { currentRect = newRect }
        case .resize(let handle):
            let r = originalRect ?? CGRect(origin: dragStart, size: .zero)
            var minX = r.minX, maxX = r.maxX, minY = r.minY, maxY = r.maxY
            func clampX(_ x: CGFloat) -> CGFloat { max(pageRect.minX, min(pageRect.maxX, x)) }
            func clampY(_ y: CGFloat) -> CGFloat { max(pageRect.minY, min(pageRect.maxY, y)) }
            let x = clampX(point.x), y = clampY(point.y)
            switch handle {
            case .topLeft:      minX = min(x, maxX - handleSize * 2); maxY = max(y, minY + handleSize * 2)
            case .top:          maxY = max(y, minY + handleSize * 2)
            case .topRight:     maxX = max(x, minX + handleSize * 2); maxY = max(y, minY + handleSize * 2)
            case .right:        maxX = max(x, minX + handleSize * 2)
            case .bottomRight:  maxX = max(x, minX + handleSize * 2); minY = min(y, maxY - handleSize * 2)
            case .bottom:       minY = min(y, maxY - handleSize * 2)
            case .bottomLeft:   minX = min(x, maxX - handleSize * 2); minY = min(y, maxY - handleSize * 2)
            case .left:         minX = min(x, maxX - handleSize * 2)
            }
            let newRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY).intersection(pageRect)
            if newRect.width >= handleSize * 2 && newRect.height >= handleSize * 2 { currentRect = newRect }
        }
    }

    override func mouseUp(with event: NSEvent) {
        dragMode = .none
        dragStart = nil
        originalRect = nil
        if let rect = currentRect { onFinish?(rect) }
    }

    private func handleRects(for rect: CGRect) -> [Handle: CGRect] {
        var dict: [Handle: CGRect] = [:]
        let hs = handleSize
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
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
            if hitRect.contains(point) { return handle }
        }
        return nil
    }

    private func pageBoundsInView() -> CGRect {
        return superview?.bounds ?? bounds
    }
}

