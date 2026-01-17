//
//  PDFPageOverlayView.swift
//  PraxPress - Prax=0104-1
//


import SwiftUI
import PDFKit
import AppKit

// Minimal trim overlay handle view reused per page by the provider
final class PDFPageOverlayView: NSView {
    
    @State private var prax = PraxModel.shared
    
    var pdfView: PDFView?
    var onFinish: ((CGRect) -> Void)?
    var currentRect: CGRect? { didSet { needsDisplay = true } }
    var clampRect: CGRect?
    
    // Optional vertical guideline x-positions in overlay coordinates
    var guideXLeft: CGFloat?
    var guideXRight: CGFloat?
    private let snapThreshold: CGFloat = 16.0
    
    private let handleSize: CGFloat = 8
    private let hitInset: CGFloat = 6
    private enum Handle { case topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left }
    private enum DragMode { case none, move, resize(Handle) }
    private var dragMode: DragMode = .none
    private var dragStart: CGPoint?
    private var originalRect: CGRect?
    
    override var acceptsFirstResponder: Bool { true }
    override func hitTest(_ point: NSPoint) -> NSView? { self }
    
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
        
        computeGuidelines()
        // Draw guidelines if provided
        if let gxL = guideXLeft {
            NSColor.systemRed.withAlphaComponent(0.6).setStroke()
            let path = NSBezierPath()
            path.move(to: CGPoint(x: gxL, y: bounds.minY))
            path.line(to: CGPoint(x: gxL, y: bounds.maxY))
            path.lineWidth = 2
            path.stroke()
        }
        if let gxR = guideXRight {
            NSColor.systemRed.withAlphaComponent(0.6).setStroke()
            let path = NSBezierPath()
            path.move(to: CGPoint(x: gxR, y: bounds.minY))
            path.line(to: CGPoint(x: gxR, y: bounds.maxY))
            path.lineWidth = 2
            path.stroke()
        }
    }
    
    private func computeGuidelines() {
        
        if let guideIndex = prax.widthGuidePageIndex,
           let guideLeftX = prax.widthGuideLeftX,
           let guideRightX = prax.widthGuideRightX,
           let guidePage = prax.editingPDFDocument.page(at: guideIndex) {
            // Normalize guide x's by the guide page's crop box, then map to the current page's crop box
            
            let guideCrop = guidePage.bounds(for: .cropBox)
            let currentCrop = guidePage.bounds(for: .cropBox)
            guard guideCrop.width > 0, currentCrop.width > 0 else {
                guideXLeft = nil
                guideXRight = nil
                return
            }
            let leftNorm = (guideLeftX - guideCrop.minX) / guideCrop.width
            let rightNorm = (guideRightX - guideCrop.minX) / guideCrop.width
            let currentLeftX = currentCrop.minX + leftNorm * currentCrop.width
            let currentRightX = currentCrop.minX + rightNorm * currentCrop.width
            // Build tall thin rects at mapped x positions in current page space
            let leftRectInPage = CGRect(x: currentLeftX, y: currentCrop.minY, width: 0.5, height: currentCrop.height)
            let rightRectInPage = CGRect(x: currentRightX, y: currentCrop.minY, width: 0.5, height: currentCrop.height)
            // Convert to view space and then overlay space
            let leftInView = (pdfView?.convert(leftRectInPage, from: guidePage))!
            let rightInView = (pdfView?.convert(rightRectInPage, from: guidePage))!
            let leftInOverlay = self.convert(leftInView, from: pdfView)
            let rightInOverlay = self.convert(rightInView, from: pdfView)
            guideXLeft = leftInOverlay.midX
            guideXRight = rightInOverlay.midX
            
            // Skip drawing if lines would be far outside clamp; otherwise clamp to bounds
            if let gxL = guideXLeft {
                if gxL.isNaN || gxL.isInfinite { guideXLeft = nil }
                else if gxL < self.bounds.minX - 2000 || gxL > self.bounds.maxX + 2000 { guideXLeft = nil }
                else { guideXLeft = max(self.bounds.minX, min(self.bounds.maxX, gxL)) }
            }
            if let gxR = guideXRight {
                if gxR.isNaN || gxR.isInfinite { guideXRight = nil }
                else if gxR < self.bounds.minX - 2000 || gxR > self.bounds.maxX + 2000 { guideXRight = nil }
                else { guideXRight = max(self.bounds.minX, min(self.bounds.maxX, gxR)) }
            }
            
            
            
        } else {
            guideXLeft = nil
            guideXRight = nil
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
        let pageRect = clampRect ?? bounds
        switch dragMode {
        case .none: break
        case .move:
            guard let originalRect = originalRect else { return }
            var newRect = originalRect.offsetBy(dx: point.x - dragStart.x, dy: point.y - dragStart.y)
            newRect = newRect.intersection(pageRect)
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
            // Snap left/right to guidelines if within threshold
            if let gxL = guideXLeft {
                if abs(minX - gxL) <= snapThreshold { minX = gxL }
                if abs(maxX - gxL) <= snapThreshold { maxX = gxL }
            }
            if let gxR = guideXRight {
                if abs(minX - gxR) <= snapThreshold { minX = gxR }
                if abs(maxX - gxR) <= snapThreshold { maxX = gxR }
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
            if handleRect.insetBy(dx: -hitInset, dy: -hitInset).contains(point) { return handle }
        }
        return nil
    }
}
