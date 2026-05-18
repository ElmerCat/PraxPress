//
//  PDFPageOverlayView.swift
//  PraxPress - Prax=0104-1
//


import SwiftUI
import PDFKit
import AppKit

// Minimal trim overlay handle view reused per page by the provider
final class PDFPageOverlayView: NSView {
    let pageItem: PageItem
    let prax: PraxModel
    init(pageItem: PageItem) {
        self.pageItem = pageItem
        self.prax = pageItem.prax
        super.init(frame: .zero)
        
        trimsObserver = NotificationCenter.default.addObserver(
            forName: .praxPageItemTrimsChanged,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            guard let changed = note.object as? PageItem, changed === self.pageItem else { return }
            self.setCurrentRectFromPageItemTrims()
            self.needsDisplay = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if let trimsObserver {
            NotificationCenter.default.removeObserver(trimsObserver)
        }
    }
    
    private var trimsObserver: NSObjectProtocol?
    
    // --- PATCH 1: replace pdfView property with stale-async guard + size clamping ---
    var pdfView: PDFView? {
        didSet {
            let assignedPDFView = pdfView
            DispatchQueue.main.async { [weak self, weak pageItem, weak assignedPDFView] in
                guard let self, let pageItem, let pdfView = assignedPDFView else { return }
                guard self.pdfView === pdfView else { return } // ignore stale async update

                let crop = pageItem.pdfPage.bounds(for: .cropBox)
                let cropInView = pdfView.convert(crop, from: pageItem.pdfPage)
                let cropInOverlay = self.convert(cropInView, from: pdfView)
                self.clampRect = cropInOverlay

                let trims = pageItem.trims
                let visibleInPage = CGRect(
                    x: crop.minX + trims.left,
                    y: crop.minY + trims.bottom,
                    width: max(0, crop.width - trims.left - trims.right),
                    height: max(0, crop.height - trims.top - trims.bottom)
                )

                let visibleInView = pdfView.convert(visibleInPage, from: pageItem.pdfPage)
                let visibleInOverlay = self.convert(visibleInView, from: pdfView)
                self.currentRect = visibleInOverlay
                self.needsDisplay = true
            }
        }
    }
    
    // --- PATCH 2: replace setCurrentRectFromPageItemTrims() with clamped-size version ---
    func setCurrentRectFromPageItemTrims() {
        guard let pdfView else { return }
        let crop = pageItem.pdfPage.bounds(for: .cropBox)
        let visibleInPage = CGRect(
            x: crop.minX + pageItem.trims.left,
            y: crop.minY + pageItem.trims.bottom,
            width: max(0, crop.width - pageItem.trims.left - pageItem.trims.right),
            height: max(0, crop.height - pageItem.trims.top - pageItem.trims.bottom)
        )

        let visibleInView = pdfView.convert(visibleInPage, from: pageItem.pdfPage)
        let visibleInOverlay = self.convert(visibleInView, from: pdfView)
        currentRect = visibleInOverlay
    }
    
    var currentRect: CGRect? { didSet { needsDisplay = true } }
    var clampRect: CGRect?
    
    // Optional vertical guideline x-positions in overlay coordinates
    var guideXLeft: CGFloat?
    var guideXRight: CGFloat?
    var guideXWidthFromLeft: CGFloat?
    var guideXWidthFromRight: CGFloat?
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
    
    private var isSelectedOverlay: Bool { prax.selectedPageItem == pageItem }
    private let activeOutsideMaskAlpha: CGFloat = 0.22
    private let inactiveOutsideMaskAlpha: CGFloat = 0.42
    
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
 /*       Observation.withObservationTracking {
          //  print("Observation.withObservationTracking Trims: \(pageItem.trims)")
                    // Access properties here to start tracking
                } onChange: {
                    // 3. React to changes
                    DispatchQueue.main.async {
                        self.setCurrentRectFromPageItemTrims()
                        self.setNeedsDisplay(self.bounds)
                        print("Observation.withObservationTracking Trims: Property changed, Trims: \(self.pageItem.trims)")
                    }
                }
 */
        
        guard let r = currentRect else { return }

        let isActive = isSelectedOverlay
        let outer = clampRect ?? bounds
        let inner = r.intersection(outer)
        guard !inner.isEmpty else { return }

        // Mask OUTSIDE currentRect, with stronger opacity when not selected
        NSColor.black
            .withAlphaComponent(isActive ? activeOutsideMaskAlpha : inactiveOutsideMaskAlpha)
            .setFill()

        let mask = NSBezierPath(rect: outer)
        mask.append(NSBezierPath(rect: inner))
        mask.windingRule = .evenOdd
        mask.fill()

        // Border (subtler when not selected)
        NSColor.systemBlue.withAlphaComponent(isActive ? 1.0 : 0.45).setStroke()
        let border = NSBezierPath(rect: inner)
        border.lineWidth = isActive ? 2 : 1
        border.stroke()

        if isActive {
            // Handles only for selected page item
            NSColor.white.setFill()
            NSColor.systemBlue.setStroke()
            for handleRect in handleRects(for: inner).values {
                let handlePath = NSBezierPath(rect: handleRect)
                handlePath.fill()
                handlePath.lineWidth = 1.5
                handlePath.stroke()
            }

            // Guidelines only for selected page item
            computeGuidelines()

            if let gxL = guideXLeft {
                NSColor.systemRed.withAlphaComponent(0.9).setStroke()
                let path = NSBezierPath()
                path.move(to: CGPoint(x: gxL, y: bounds.minY))
                path.line(to: CGPoint(x: gxL, y: bounds.maxY))
                path.lineWidth = 4
                path.stroke()
            }
            if let gxR = guideXRight {
                NSColor.systemRed.withAlphaComponent(0.9).setStroke()
                let path = NSBezierPath()
                path.move(to: CGPoint(x: gxR, y: bounds.minY))
                path.line(to: CGPoint(x: gxR, y: bounds.maxY))
                path.lineWidth = 4
                path.stroke()
            }
            if let gx = guideXWidthFromLeft {
                NSColor.systemPurple.withAlphaComponent(0.9).setStroke()
                let p = NSBezierPath()
                p.move(to: CGPoint(x: gx, y: bounds.minY))
                p.line(to: CGPoint(x: gx, y: bounds.maxY))
                p.lineWidth = 4
                p.stroke()
            }
            if let gx = guideXWidthFromRight {
                NSColor.systemBlue.withAlphaComponent(0.9).setStroke()
                let p = NSBezierPath()
                p.move(to: CGPoint(x: gx, y: bounds.minY))
                p.line(to: CGPoint(x: gx, y: bounds.maxY))
                p.lineWidth = 4
                p.stroke()
            }
        } else {
            // Clear cached guides so stale lines can't reappear
            guideXLeft = nil
            guideXRight = nil
            guideXWidthFromLeft = nil
            guideXWidthFromRight = nil
        }
    }
    
    
    private enum HSide { case left, right }
    private enum VSide { case top, bottom }

    private var minRectWidth: CGFloat { handleSize * 2 }
    private var minRectHeight: CGFloat { handleSize * 2 }

    // Keep this aligned everywhere trims are produced/compared.
    // 1.0 = integer trims, 100.0 = 2 decimal places.
    private let trimQuantizationScale: CGFloat = 1.0
    
    private func allFourTrimsAreSet() -> Bool {
        let t = pageItem.trims
        return quantizeTrim(t.left) != 0 &&
               quantizeTrim(t.right) != 0 &&
               quantizeTrim(t.top) != 0 &&
               quantizeTrim(t.bottom) != 0
    }

    private func quantizeTrim(_ value: CGFloat) -> CGFloat {
        let clamped = max(0, value)
        let q = (clamped * trimQuantizationScale).rounded(.toNearestOrAwayFromZero) / trimQuantizationScale
        return q == 0 ? 0 : q
    }

    private func clampMovedRectPreservingSize(_ rect: CGRect, in pageRect: CGRect) -> CGRect {
        var r = rect

        // Fallback: if rect is larger than clamp area, intersection is safest.
        if r.width > pageRect.width || r.height > pageRect.height {
            return r.intersection(pageRect)
        }

        r.origin.x = min(max(r.origin.x, pageRect.minX), pageRect.maxX - r.width)
        r.origin.y = min(max(r.origin.y, pageRect.minY), pageRect.maxY - r.height)
        return r
    }
    
    private func nearestPrimaryGuide(to clickX: CGFloat) -> (side: HSide, x: CGFloat)? {
        guard let gxL = guideXLeft, let gxR = guideXRight else { return nil }
        let dL = abs(clickX - gxL)
        let dR = abs(clickX - gxR)
        // tie -> left
        return (dL <= dR) ? (.left, gxL) : (.right, gxR)
    }

    private func nearestWidthGuide(to clickX: CGFloat) -> CGFloat? {
        let candidates = [guideXWidthFromLeft, guideXWidthFromRight].compactMap { $0 }
        guard !candidates.isEmpty else { return nil }
        return candidates.min { a, b in
            let da = abs(clickX - a), db = abs(clickX - b)
            if da == db { return a < b } // tie -> leftmost
            return da < db
        }
    }

    /// Converts current left/right primary guide x positions (overlay coords) into
    /// trim values for this pageItem, so "exact match" can be checked against pageItem.trims.
    private func guideTrimsForCurrentPageItem() -> (left: CGFloat, right: CGFloat)? {
        guard let pdfView, let gxL = guideXLeft, let gxR = guideXRight else { return nil }

        let crop = pageItem.pdfPage.bounds(for: .cropBox)

        let markerL = CGRect(x: gxL, y: bounds.midY, width: 0.5, height: 0.5)
        let markerR = CGRect(x: gxR, y: bounds.midY, width: 0.5, height: 0.5)

        let markerLInView = convert(markerL, to: pdfView)
        let markerRInView = convert(markerR, to: pdfView)

        let markerLInPage = pdfView.convert(markerLInView, to: pageItem.pdfPage)
        let markerRInPage = pdfView.convert(markerRInView, to: pageItem.pdfPage)

        let leftTrim = quantizeTrim(markerLInPage.midX - crop.minX)
        let rightTrim = quantizeTrim(crop.maxX - markerRInPage.midX)

        return (left: leftTrim, right: rightTrim)
    }

    private func setRightEdge(_ x: CGFloat, rect: CGRect, pageRect: CGRect) -> CGRect {
        var r = rect
        var newMaxX = max(pageRect.minX, min(pageRect.maxX, x))
        if newMaxX - r.minX < minRectWidth { newMaxX = r.minX + minRectWidth }
        r.size.width = newMaxX - r.minX
        return r.intersection(pageRect)
    }

    private func setTopEdge(_ y: CGFloat, rect: CGRect, pageRect: CGRect) -> CGRect {
        var r = rect
        var newMaxY = max(pageRect.minY, min(pageRect.maxY, y))
        if newMaxY - r.minY < minRectHeight { newMaxY = r.minY + minRectHeight }
        r.size.height = newMaxY - r.minY
        return r.intersection(pageRect)
    }

    private func setLeftEdge(_ x: CGFloat, rect: CGRect, pageRect: CGRect) -> CGRect {
        let oldMaxX = rect.maxX
        var newMinX = max(pageRect.minX, min(pageRect.maxX, x))
        if oldMaxX - newMinX < minRectWidth { newMinX = oldMaxX - minRectWidth }

        var r = rect
        r.origin.x = newMinX
        r.size.width = oldMaxX - newMinX
        return r.intersection(pageRect)
    }

    private func setBottomEdge(_ y: CGFloat, rect: CGRect, pageRect: CGRect) -> CGRect {
        let oldMaxY = rect.maxY
        var newMinY = max(pageRect.minY, min(pageRect.maxY, y))
        if oldMaxY - newMinY < minRectHeight { newMinY = oldMaxY - minRectHeight }

        var r = rect
        r.origin.y = newMinY
        r.size.height = oldMaxY - newMinY
        return r.intersection(pageRect)
    }
    

    
    /// Applies Rules 1–5 on click. Returns true if handled.
    private func applyRuleDrivenClick(at point: CGPoint) -> Bool {
        if allFourTrimsAreSet() { return false }
        
        guard var rect = currentRect else { return false }
        let pageRect = clampRect ?? bounds

        // Make sure guides are up-to-date before evaluating rules.
        computeGuidelines()

        let trims = pageItem.trims

        let qLeft = quantizeTrim(trims.left)
        let qRight = quantizeTrim(trims.right)
        let qTop = quantizeTrim(trims.top)
        let qBottom = quantizeTrim(trims.bottom)

        let leftSet = qLeft != 0
        let rightSet = qRight != 0
        let topZero = qTop == 0
        let bottomZero = qBottom == 0

        // Rule 4/5: once both horizontal trims are set, vertical rules apply.
        if leftSet && rightSet && (topZero || bottomZero) {
            let targetV: VSide
            if topZero && bottomZero {
                // tie -> top
                let dTop = abs(point.y - rect.maxY)
                let dBottom = abs(point.y - rect.minY)
                targetV = (dTop <= dBottom) ? .top : .bottom
            } else if topZero {
                targetV = .top
            } else {
                targetV = .bottom
            }

            rect = (targetV == .top)
                ? setTopEdge(point.y, rect: rect, pageRect: pageRect)
                : setBottomEdge(point.y, rect: rect, pageRect: pageRect)

            currentRect = rect
            setTrims()
            return true
        }

        // Horizontal phase (Rule 1/2/3)
        // Rule 1: none set -> nearest primary (tie left)
        if !leftSet && !rightSet {
            guard let target = nearestPrimaryGuide(to: point.x) else { return false }
            rect = (target.side == .left)
                ? setLeftEdge(target.x, rect: rect, pageRect: pageRect)
                : setRightEdge(target.x, rect: rect, pageRect: pageRect)

            currentRect = rect
            setTrims()
            return true
        }

        // Rule 2: if one side exactly matches guide trim, set opposite side to opposite primary guide.
        if let g = guideTrimsForCurrentPageItem() {
            let leftMatches = leftSet && (qLeft == g.left)
            let rightMatches = rightSet && (qRight == g.right)

            if leftMatches, let gxR = guideXRight {
                rect = setRightEdge(gxR, rect: rect, pageRect: pageRect)
                currentRect = rect
                setTrims()
                return true
            }

            if rightMatches, let gxL = guideXLeft {
                rect = setLeftEdge(gxL, rect: rect, pageRect: pageRect)
                currentRect = rect
                setTrims()
                return true
            }
        }

        // Rule 3: side is set to non-guide value -> nearest width guide.
        guard let widthX = nearestWidthGuide(to: point.x) else { return false }

        if leftSet && !rightSet {
            rect = setRightEdge(widthX, rect: rect, pageRect: pageRect)
        } else if rightSet && !leftSet {
            rect = setLeftEdge(widthX, rect: rect, pageRect: pageRect)
        } else {
            // fallback (should be rare in this phase): move nearer edge
            let dL = abs(point.x - rect.minX)
            let dR = abs(point.x - rect.maxX)
            rect = (dL <= dR)
                ? setLeftEdge(widthX, rect: rect, pageRect: pageRect)   // tie -> left
                : setRightEdge(widthX, rect: rect, pageRect: pageRect)
        }

        currentRect = rect
        setTrims()
        return true
    }
    
    
/*    private func clampedGuideX(_ x: CGFloat?) -> CGFloat? {
        guard let x, x.isFinite else { return nil }
        guard x >= bounds.minX - 2000, x <= bounds.maxX + 2000 else { return nil }
        return max(bounds.minX, min(bounds.maxX, x))
    }
*/
    
    private func computeGuidelines() {
        guard
            let pdfView,
            let guideLeftX = prax.document.widthGuideLeftX,
            let guideRightX = prax.document.widthGuideRightX,
            let widthGuidePage = prax.document.widthGuidePage()
        else {
            guideXLeft = nil
            guideXRight = nil
            guideXWidthFromLeft = nil
            guideXWidthFromRight = nil
            return
        }

        func sanitize(_ x: CGFloat?) -> CGFloat? {
            guard let x, x.isFinite else { return nil }
            guard x >= bounds.minX - 2000, x <= bounds.maxX + 2000 else { return nil }
            return max(bounds.minX, min(bounds.maxX, x))
        }

        func overlayX(pageX: CGFloat, page: PDFPage, crop: CGRect) -> CGFloat {
            let line = CGRect(x: pageX, y: crop.minY, width: 0.5, height: crop.height)
            let inView = pdfView.convert(line, from: page)
            let inOverlay = self.convert(inView, from: pdfView)
            return inOverlay.midX
        }

        // Keep your existing left/right behavior
        let guideCrop = widthGuidePage.pdfPage.bounds(for: .cropBox)
        let currentCrop = widthGuidePage.pdfPage.bounds(for: .cropBox)

        guard guideCrop.width > 0, currentCrop.width > 0 else {
            guideXLeft = nil
            guideXRight = nil
            guideXWidthFromLeft = nil
            guideXWidthFromRight = nil

            return
        }

        let leftNorm = (guideLeftX - guideCrop.minX) / guideCrop.width
        let rightNorm = (guideRightX - guideCrop.minX) / guideCrop.width
        let currentLeftX = currentCrop.minX + leftNorm * currentCrop.width
        let currentRightX = currentCrop.minX + rightNorm * currentCrop.width

        guideXLeft = sanitize(overlayX(pageX: currentLeftX, page: widthGuidePage.pdfPage, crop: currentCrop))
        guideXRight = sanitize(overlayX(pageX: currentRightX, page: widthGuidePage.pdfPage, crop: currentCrop))

        // ---- 3rd line: guide page width + pageItem current trims ----
        // Reset width candidates each pass
        guideXWidthFromLeft = nil
        guideXWidthFromRight = nil

        // --- width from guide page (in overlay coords) ---
        let gMin = min(guideLeftX, guideRightX)
        let gMax = max(guideLeftX, guideRightX)

        let gMinRect = CGRect(x: gMin, y: guideCrop.minY, width: 0.5, height: guideCrop.height)
        let gMaxRect = CGRect(x: gMax, y: guideCrop.minY, width: 0.5, height: guideCrop.height)

        let gMinOverlayX = self.convert(pdfView.convert(gMinRect, from: widthGuidePage.pdfPage), from: pdfView).midX
        let gMaxOverlayX = self.convert(pdfView.convert(gMaxRect, from: widthGuidePage.pdfPage), from: pdfView).midX

        // signed width is safer if rotation flips x direction
        let guideWidthSigned = gMaxOverlayX - gMinOverlayX
        guard guideWidthSigned.isFinite, guideWidthSigned != 0 else { return }

        // --- current pageItem trimmed edges (in overlay coords) ---
        let itemCrop = pageItem.pdfPage.bounds(for: .cropBox)
        guard itemCrop.width > 0 else { return }

        let itemLeftPageX = itemCrop.minX + pageItem.trims.left
        let itemRightPageX = itemCrop.maxX - pageItem.trims.right

        let itemLeftRect = CGRect(x: itemLeftPageX, y: itemCrop.minY, width: 0.5, height: itemCrop.height)
        let itemRightRect = CGRect(x: itemRightPageX, y: itemCrop.minY, width: 0.5, height: itemCrop.height)

        let itemLeftOverlayX = self.convert(pdfView.convert(itemLeftRect, from: pageItem.pdfPage), from: pdfView).midX
        let itemRightOverlayX = self.convert(pdfView.convert(itemRightRect, from: pageItem.pdfPage), from: pdfView).midX

        // candidate A: move right edge only
        let cA = itemLeftOverlayX + guideWidthSigned
        // candidate B: move left edge only
        let cB = itemRightOverlayX - guideWidthSigned

        func clampGuide(_ x: CGFloat) -> CGFloat? {
            if !x.isFinite { return nil }
            if x < self.bounds.minX - 2000 || x > self.bounds.maxX + 2000 { return nil }
            return max(self.bounds.minX, min(self.bounds.maxX, x))
        }

        guideXWidthFromLeft = clampGuide(cA)
        guideXWidthFromRight = clampGuide(cB)
    }
    
    
    private func rectAdjusted(byClick point: CGPoint, from rect: CGRect, allowGuideSnap: Bool = true) -> CGRect {
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
        if allowGuideSnap {
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
    
    private func dragSnapGuideXs() -> [CGFloat] {
        [guideXLeft, guideXRight, guideXWidthFromLeft, guideXWidthFromRight]
            .compactMap { $0 }
            .filter { $0.isFinite }
    }

    private func snappedXToNearestGuide(_ x: CGFloat) -> CGFloat {
        let guides = dragSnapGuideXs()
        guard !guides.isEmpty else { return x }

        guard let nearest = guides.min(by: { abs($0 - x) < abs($1 - x) }) else { return x }
        return abs(nearest - x) <= snapThreshold ? nearest : x
    }
    
    override func mouseEntered(with event: NSEvent) {
        print("PDFPageOverlayView - mouseEntered")
    }
    
    
    override func mouseDown(with event: NSEvent) {
 

        if prax.selectedPageItem != pageItem {
            print("OverlayView Changing selectedPageItem to :", pageItem.name)
            prax.selectedPageItem = pageItem
            return
            
        }
 
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



            if applyRuleDrivenClick(at: point) {
                dragMode = .none
                originalRect = nil
                return
            }

            // Click-to-expand/contract behavior using existing helper if present; otherwise move/resize fallback
            if let adjustedMethod = Optional(rectAdjusted) {
                let allowClickGuideSnap = !allFourTrimsAreSet()
                let adjusted = adjustedMethod(point, rect, allowClickGuideSnap)
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
            let moved = originalRect.offsetBy(dx: point.x - dragStart.x, dy: point.y - dragStart.y)
            let newRect = clampMovedRectPreservingSize(moved, in: pageRect)
            if newRect.width >= handleSize * 2 && newRect.height >= handleSize * 2 {
                currentRect = newRect
            }
            // --- PATCH 3: mouseDragged .resize case - refresh guides + re-enforce min width after snapping ---
            // Find your existing ".resize(let handle):" block and apply these edits:

            case .resize(let handle):
                computeGuidelines() // keep guide positions fresh while dragging

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

                // Snap dragged horizontal edge(s) to nearest guide (primary + width guides)
                switch handle {
                case .left, .topLeft, .bottomLeft:
                    minX = snappedXToNearestGuide(minX)
                case .right, .topRight, .bottomRight:
                    maxX = snappedXToNearestGuide(maxX)
                case .top, .bottom:
                    break
                }

                // Re-enforce minimum width AFTER snapping
                if maxX - minX < minRectWidth {
                    switch handle {
                    case .left, .topLeft, .bottomLeft:
                        minX = maxX - minRectWidth
                    case .right, .topRight, .bottomRight:
                        maxX = minX + minRectWidth
                    case .top, .bottom:
                        break
                    }
                }

                let newRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY).intersection(pageRect)
                if newRect.width >= handleSize * 2 && newRect.height >= handleSize * 2 {
                    currentRect = newRect
                }
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        dragMode = .none
        dragStart = nil
        originalRect = nil
        setTrims()
    }
    
    private func handleRects(for rect: CGRect) -> [Handle: CGRect] {
        var dict: [Handle: CGRect] = [:]

        let hs = handleSize
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        let half = hs / 2

        // Corners (keep square handles)
        dict[.topLeft]     = CGRect(x: x - half,     y: y + h - half, width: hs, height: hs)
        dict[.topRight]    = CGRect(x: x + w - half, y: y + h - half, width: hs, height: hs)
        dict[.bottomRight] = CGRect(x: x + w - half, y: y - half,     width: hs, height: hs)
        dict[.bottomLeft]  = CGRect(x: x - half,     y: y - half,     width: hs, height: hs)

        // Full-edge handles (thin strips, draggable anywhere along edge)
        let edgeThickness = max(6, hs * 0.9)
        let etHalf = edgeThickness / 2

        dict[.top]    = CGRect(x: x,         y: y + h - etHalf, width: w, height: edgeThickness)
        dict[.bottom] = CGRect(x: x,         y: y - etHalf,     width: w, height: edgeThickness)
        dict[.left]   = CGRect(x: x - etHalf,y: y,              width: edgeThickness, height: h)
        dict[.right]  = CGRect(x: x + w - etHalf, y: y,         width: edgeThickness, height: h)

        return dict
    }
    
    private func hitTestHandle(_ point: CGPoint, in rect: CGRect) -> Handle? {
        let handles = handleRects(for: rect)
        let order: [Handle] = [
            .topLeft, .topRight, .bottomRight, .bottomLeft, // corners first
            .top, .right, .bottom, .left
        ]

        for handle in order {
            if let hr = handles[handle],
               hr.insetBy(dx: -hitInset, dy: -hitInset).contains(point) {
                return handle
            }
        }
        return nil
    }
    
    private func trimsForPageRect(_ pageRect: CGRect, media: CGRect) -> EdgeTrims {
        return EdgeTrims(
            left: quantizeTrim(pageRect.minX - media.minX),
            right: quantizeTrim(media.maxX - pageRect.maxX),
            top: quantizeTrim(media.maxY - pageRect.maxY),
            bottom: quantizeTrim(pageRect.minY - media.minY)
        )
    }
    
    private func setTrims() {
        
        guard let currentRect else {
            print("overlayView.onFinish - No Page Item")
            return
        }
        // Convert overlay-local rect to PDFView coordinates
        let rectInView = convert(currentRect, to: prax.editingDocumentPDFView)
        
        // Clamp to page bounds in PDFView coordinates
        let pageBoundsInView = prax.editingDocumentPDFView.convert(pageItem.pdfPage.bounds(for: .cropBox), from: pageItem.pdfPage)
        let clamped = rectInView.intersection(pageBoundsInView)
        guard !clamped.isEmpty else { return }
        
        // Convert to page coords
        let pageRect = prax.editingDocumentPDFView.convert(clamped, to: pageItem.pdfPage)
        let media = pageItem.pdfPage.bounds(for: .cropBox)
        
        let trims = trimsForPageRect(pageRect, media: media)
        pageItem.trims = trims
    }
}

class OverlayControlNSView: NSView, HostingViewContainer {
    let pageItem: PageItem
    var hostingView: NSHostingView<OverlayControlView>?
    
    init(pageItem: PageItem) {
        self.pageItem = pageItem
        super.init(frame: CGRect(x: 100, y: 300, width: 400, height: 400))
        wantsLayer = true
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    override var wantsDefaultClipping: Bool { false }
    
    func buildRootView() -> OverlayControlView {
        OverlayControlView(pageItem: pageItem)
    }
    
    func configure() {
        attachHostingView()
    }
    
    override func viewWillMove(toSuperview newSuperview: NSView?) {
        super.viewWillMove(toSuperview: newSuperview)
        if newSuperview == nil {
            detachHostingView()
        }
    }
}


struct OverlayControlView: View {
    @Environment(MergedPDFDocument.self) var document
    @Environment(PraxModel.self) private var praxModel
    let pageItem: PageItem
    
    @State var hoveredButton: Int?
    let praxTheme = PraxTheme(.erika)
    
    var body: some View {
        @Bindable var prax = praxModel
        @Bindable var document = document
        
        GroupBox {
            GeometryReader { proxy in
                VStack {
                    Button("", systemImage: "ruler", action: {
                        document.clickedGuidePageButton(pageItem)
                    })                .buttonStyle(SelectableButtonStyle(isSelected: false, isHovering: hoveredButton == 4, isFocused: false))
                        .onHover { hovering in
                            hoveredButton = hovering ? 4 : nil
                        }
                        .help("Set width guide")
                    //  .position(x: 0, y: 16)
                    Spacer()
                        Text("Trims")
                            .font(Font.custom("BrushScriptMT", size: 30))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                    Text("\(pageItem.name)  L-\(Int(pageItem.trims.left)) T-\(Int(pageItem.trims.top)) B-\(Int(pageItem.trims.bottom)) R-\(Int(pageItem.trims.right))")
                        .font(.system(size: 4, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .init(horizontal: .center, vertical: .center))
                }
            }
        }
        
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .zIndex(1000)
        .padding(0)
        .background(PraxGradient())
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.blue, lineWidth: 5).opacity(0.5)
        )

    }
        
}

