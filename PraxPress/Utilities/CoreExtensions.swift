//
//  CoreExtensions.swift
//  PraxPress
//
//  Created by Elmer Cat on 10/2/26.
//

import SwiftUI
import PDFKit


enum FieldName: Hashable {
    case exportFilenamePrefix
    case exportFilenameBody
    case exportFilenameSuffix
}

struct FocusedField: FocusedValueKey {
    // We store a closure that your view will provide
    typealias Value = () -> Void
}

extension FocusedValues {
    var setExportFilenameBody: (() -> Void)? {
        get { self[FocusedField.self] }
        set { self[FocusedField.self] = newValue }
    }
}

extension CGSize {
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize { return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height) }
    static func - (lhs: CGSize, rhs: CGSize) -> CGSize { return CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height) }
    static func += (lhs: inout CGSize, rhs: CGSize) { lhs = lhs + rhs }
    static func -= (lhs: inout CGSize, rhs: CGSize) { lhs = lhs - rhs }
}


extension PDFView {
    var documentScrollView: NSScrollView? { return subviews.first(where: { $0 is NSScrollView }) as? NSScrollView }
    var verticalScroller: NSScroller? { return documentScrollView?.verticalScroller }
}



struct PDFScrollState {
    let pageIndex: Int
    let percentX: CGFloat // 0.0 (left) to 1.0 (right)
    let percentY: CGFloat // 0.0 (bottom) to 1.0 (top)
}

extension PDFView {
    
    /// Captures the scroll position based on normalized percentages of the current page's bounds
    func captureNormalizedScrollState() -> PDFScrollState? {
        guard let document = self.document,
              let currentPage = self.currentPage else { return nil }
        
        let pageIndex = document.index(for: currentPage)
        
        // Find the center point of the visible PDFView frame
        let viewCenter = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        
        // Convert that center point into coordinates relative to this specific page
        let pageCenter = self.convert(viewCenter, to: currentPage)
        
        // Normalize the coordinates against the page's full physical dimensions
        let pageBounds = currentPage.bounds(for: self.displayBox)
        
        Swift.print("\nviewCenter: \(viewCenter), \npageCenter: \(pageCenter), \npageBounds: \(pageBounds)")
        guard pageBounds.width > 0 && pageBounds.height > 0 else { return nil }
        
        let percentX = (pageCenter.x - pageBounds.minX) / pageBounds.width
        let percentY = (pageCenter.y - pageBounds.minY) / pageBounds.height
        Swift.print("\npercentX: \(percentX), \npercentY: \(percentY)")
        
        return PDFScrollState(pageIndex: pageIndex, percentX: percentX, percentY: percentY)
    }
    
    /// Scales the saved percentages against the new page dimensions to seamlessly restore the view
    func restoreNormalizedScrollState(_ state: PDFScrollState?) {
        guard let state = state,
              let document = self.document,
              state.pageIndex < document.pageCount,
              let targetPage = document.page(at: state.pageIndex) else { return }
        
        // Fetch the brand new bounds of the modified page
        let newPageBounds = targetPage.bounds(for: self.displayBox)
        
        // Map the saved percentages back into absolute coordinates on the new page layout
        let targetX = newPageBounds.minX + (state.percentX * newPageBounds.width)
        let targetY = newPageBounds.minY + (state.percentY * newPageBounds.height)
        
        // Define a small bounding box centered around our target point to guide the scroll engine
        let targetRect = CGRect(x: targetX - 10, y: targetY - 10, width: 20, height: 20)
        
        Swift.print("\newPageBounds: \(newPageBounds),  targetX: \(targetX),  targetY: \(targetY),  targetRect: \(targetRect)")
        
        // Center the view precisely onto the new page coordinates
        self.go(to: targetRect, on: targetPage)
    }
}

extension NSScroller {
    
    var scrollPositon: CGFloat {
        print("scrollPositon: \(self.doubleValue)")
        return self.doubleValue
    }
}

