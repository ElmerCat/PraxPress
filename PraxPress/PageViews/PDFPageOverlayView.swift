//
//  PDFPageOverlayView.swift
//  PraxPress - Prax=0104-1
//


import SwiftUI
import PDFKit
import AppKit

// Minimal trim overlay handle view reused per page by the provider
final class PDFPageOverlayView: NSView {
    var document: MergedPDFDocument?
    var pageItem: PageItem?
    var pdfView: PDFView?
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
        
        if let guideLeftX = document!.widthGuideLeftX,
           let guideRightX = document!.widthGuideRightX,
           let widthGuidePage = document!.widthGuidePage()  {
            
            // Normalize guide x's by the guide page's crop box, then map to the current page's crop box
            
            let guideCrop = widthGuidePage.pdfPage.bounds(for: .cropBox)
            let currentCrop = widthGuidePage.pdfPage.bounds(for: .cropBox)
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
            let leftInView = (pdfView?.convert(leftRectInPage, from: widthGuidePage.pdfPage))!
            let rightInView = (pdfView?.convert(rightRectInPage, from: widthGuidePage.pdfPage))!
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
    
    private func rectAdjusted(byClick point: CGPoint, from rect: CGRect) -> CGRect {
        let pageRect = clampRect ?? bounds
        var newRect = rect
        
        let minWidth = handleSize * 2
        let minHeight = handleSize * 2
        
        // Determine if the click is inside or outside the existing rect
        let isInside = rect.contains(point)
        
        if isInside {
            // Contract: move the nearest single edge toward the click
            let distances: [(edge: String, dist: CGFloat)] = [
                ("left", abs(point.x - rect.minX)),
                ("right", abs(point.x - rect.maxX)),
                ("bottom", abs(point.y - rect.minY)),
                ("top", abs(point.y - rect.maxY))
            ].sorted { $0.dist < $1.dist }
            
            switch distances.first?.edge {
            case "left":
                let newMinX = min(point.x, rect.maxX - minWidth)
                newRect.origin.x = newMinX
                newRect.size.width = max(minWidth, rect.maxX - newMinX)
            case "right":
                let newMaxX = max(point.x, rect.minX + minWidth)
                newRect.size.width = newMaxX - rect.minX
            case "bottom":
                let newMinY = min(point.y, rect.maxY - minHeight)
                newRect.origin.y = newMinY
                newRect.size.height = max(minHeight, rect.maxY - newMinY)
            case "top":
                let newMaxY = max(point.y, rect.minY + minHeight)
                newRect.size.height = newMaxY - rect.minY
            default:
                break
            }
        } else {
            // Expand: extend edges outward to include the click point
            var minX = rect.minX
            var maxX = rect.maxX
            var minY = rect.minY
            var maxY = rect.maxY
            
            if point.x < rect.minX { minX = point.x }
            if point.x > rect.maxX { maxX = point.x }
            if point.y < rect.minY { minY = point.y }
            if point.y > rect.maxY { maxY = point.y }
            
            newRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
            
            // Ensure minimum size by expanding around the rect center if needed
            if newRect.width < minWidth {
                let centerX = rect.midX
                newRect.origin.x = centerX - minWidth / 2
                newRect.size.width = minWidth
            }
            if newRect.height < minHeight {
                let centerY = rect.midY
                newRect.origin.y = centerY - minHeight / 2
                newRect.size.height = minHeight
            }
        }
        
        // Clamp to page bounds
        newRect = newRect.intersection(pageRect)
        
        // Snap left/right to vertical guidelines if within threshold
        if let gxL = guideXLeft {
            if abs(newRect.minX - gxL) <= snapThreshold {
                let snappedWidth = newRect.maxX - gxL
                if snappedWidth >= minWidth {
                    newRect.origin.x = gxL
                    newRect.size.width = snappedWidth
                }
            }
            if abs(newRect.maxX - gxL) <= snapThreshold {
                let snappedWidth = gxL - newRect.minX
                if snappedWidth >= minWidth {
                    newRect.size.width = snappedWidth
                }
            }
        }
        if let gxR = guideXRight {
            if abs(newRect.minX - gxR) <= snapThreshold {
                let snappedWidth = newRect.maxX - gxR
                if snappedWidth >= minWidth {
                    newRect.origin.x = gxR
                    newRect.size.width = snappedWidth
                }
            }
            if abs(newRect.maxX - gxR) <= snapThreshold {
                let snappedWidth = gxR - newRect.minX
                if snappedWidth >= minWidth {
                    newRect.size.width = snappedWidth
                }
            }
        }
        
        return newRect
    }
    
    
    private func initialRectForClick(_ point: CGPoint) -> CGRect {
        // Start with full page rect (clampRect if provided, else bounds)
        let pageRect = clampRect ?? bounds
        // Clamp the click into the pageRect to avoid NaNs/out-of-bounds
        let clampedX = max(pageRect.minX, min(pageRect.maxX, point.x))
        let clampedY = max(pageRect.minY, min(pageRect.maxY, point.y))
        let p = CGPoint(x: clampedX, y: clampedY)
        
        // Choose the opposite corner that maximizes area: pick the farthest corner from the click
        let corners = [
            CGPoint(x: pageRect.minX, y: pageRect.minY),
            CGPoint(x: pageRect.minX, y: pageRect.maxY),
            CGPoint(x: pageRect.maxX, y: pageRect.minY),
            CGPoint(x: pageRect.maxX, y: pageRect.maxY)
        ]
        let farCorner = corners.max { a, b in
            let da = hypot(a.x - p.x, a.y - p.y)
            let db = hypot(b.x - p.x, b.y - p.y)
            return da < db
        } ?? CGPoint(x: pageRect.maxX, y: pageRect.maxY)
        
        // Build rect with p and farCorner as opposite corners
        let minX = min(p.x, farCorner.x)
        let maxX = max(p.x, farCorner.x)
        let minY = min(p.y, farCorner.y)
        let maxY = max(p.y, farCorner.y)
        var rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        
        // Enforce minimum size using existing handleSize*2 constraint
        let minWidth = handleSize * 2
        let minHeight = handleSize * 2
        if rect.width < minWidth {
            // Expand toward farCorner along X if possible
            if farCorner.x > p.x {
                rect.size.width = minWidth
            } else {
                rect.origin.x = max(pageRect.minX, rect.maxX - minWidth)
                rect.size.width = minWidth
            }
        }
        if rect.height < minHeight {
            // Expand toward farCorner along Y if possible
            if farCorner.y > p.y {
                rect.size.height = minHeight
            } else {
                rect.origin.y = max(pageRect.minY, rect.maxY - minHeight)
                rect.size.height = minHeight
            }
        }
        
        // Finally, clamp to pageRect
        rect = rect.intersection(pageRect)
        
        // Optional: snap left/right edges to vertical guides if within threshold
        var snapped = rect
        if let gxL = guideXLeft {
            if abs(snapped.minX - gxL) <= snapThreshold {
                let newW = snapped.maxX - gxL
                if newW >= minWidth { snapped.origin.x = gxL; snapped.size.width = newW }
            }
            if abs(snapped.maxX - gxL) <= snapThreshold {
                let newW = gxL - snapped.minX
                if newW >= minWidth { snapped.size.width = newW }
            }
        }
        if let gxR = guideXRight {
            if abs(snapped.minX - gxR) <= snapThreshold {
                let newW = snapped.maxX - gxR
                if newW >= minWidth { snapped.origin.x = gxR; snapped.size.width = newW }
            }
            if abs(snapped.maxX - gxR) <= snapThreshold {
                let newW = gxR - snapped.minX
                if newW >= minWidth { snapped.size.width = newW }
            }
        }
        
        return snapped
    }
    
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        dragStart = point
        
        // If we have an existing rect, allow click-to-adjust as before (expand/contract),
        // otherwise initialize to the largest crop with one corner at the click.
        if let rect = currentRect {
            if let handle = hitTestHandle(point, in: rect) {
                // Preserve handle-based resize on handle hit
                dragMode = .resize(handle)
                originalRect = rect
                return
            }
            // Click-to-expand/contract behavior using existing helper if present; otherwise move/resize fallback
            if let adjustedMethod = Optional(rectAdjusted) {
                let adjusted = adjustedMethod(point, rect)
                if adjusted.width >= handleSize * 2 && adjusted.height >= handleSize * 2 {
                    currentRect = adjusted
                    setTrims()
                    return
                }
            }
            // Fallback to move/resize start if adjustment did not apply
            if rect.insetBy(dx: hitInset, dy: hitInset).contains(point) {
                dragMode = .move
                originalRect = rect
            } else {
                dragMode = .resize(.bottomLeft)
                currentRect = CGRect(origin: point, size: .zero)
                originalRect = nil
            }
        } else {
            // Initialize to full-page-based largest crop with click as a corner
            let initRect = initialRectForClick(point)
            currentRect = initRect
            setTrims()
            dragMode = .none
            originalRect = nil
            return
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
        if let rect = currentRect { setTrims()}
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
    
    
    private func setTrims() {
        
        guard let pageItem, let currentRect, let document else {
            print("overlayView.onFinish - No Page Item")
            return
        }
        // Convert overlay-local rect to PDFView coordinates
        let rectInView = convert(currentRect, to: document.prax.editingDocumentPDFView)
        
        // Clamp to page bounds in PDFView coordinates
        let pageBoundsInView = document.prax.editingDocumentPDFView.convert(pageItem.pdfPage.bounds(for: .cropBox), from: pageItem.pdfPage)
        let clamped = rectInView.intersection(pageBoundsInView)
        guard !clamped.isEmpty else { return }
        
        // Convert to page coords
        let pageRect = document.prax.editingDocumentPDFView.convert(clamped, to: pageItem.pdfPage)
        let media = pageItem.pdfPage.bounds(for: .cropBox)
        
        let left = max(0, pageRect.minX - media.minX)
        let right = max(0, media.maxX - pageRect.maxX)
        let bottom = max(0, pageRect.minY - media.minY)
        let top = max(0, media.maxY - pageRect.maxY)
        
        let trims = EdgeTrims(left: left, right: right, top: top, bottom: bottom)
        print("overlayView.onFinish - trims l:", trims.left, " r:", trims.right, " b:", trims.bottom, " t:", trims.top, "pdfPageItem.name: ", pageItem.name)
        
        pageItem.trims = trims
        /*
         // var pdfPageItem = prax.pdfPageItem(for: page)!
         let indexPath = self.document.pdfPageIndexPath(for: page)
         guard let indexPath = indexPath else { return }
         self.document.pageSections[indexPath.section].pdfPageItems[indexPath.item].trims = trims
         */
    }
}
