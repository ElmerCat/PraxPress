//
//  SplitViewDelegate.swift
//  PraxPress
//
//  Created by Elmer Cat on 3/19/26.
//

import AppKit
import SwiftUI

extension NSSplitView {
    func widthOfView(_ index: Int) -> CGFloat {
        self.arrangedSubviews[index].frame.width
    }
}


final class SplitViewDelegate: NSObject, NSSplitViewDelegate {
    let prax: PraxModel
    
    init(prax: PraxModel, splitView: NSSplitView? = nil) {
        self.prax = prax
        self.splitView = splitView
    }
    
    var firstViewMinWidth = 100.0
    var firstViewMaxWidth = 200.0
    var secondViewMinWidth = 200.0
    var secondViewMaxWidth = 400.0

    var splitView: NSSplitView?

    func splitView(_ splitView: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {

        print ("splitView: NSSplitView, constrainSplitPosition proposedPosition: ", proposedPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)

        var newPosition = proposedPosition
        switch(dividerIndex) {
        case 0:
            
            if proposedPosition < firstViewMinWidth {
                newPosition = firstViewMinWidth
            }
            else if proposedPosition > firstViewMaxWidth {
                newPosition = firstViewMaxWidth
            }
           
            let otherSplitPosition = splitView.widthOfView(1) + newPosition
            DispatchQueue.main.async {
                splitView.setPosition(otherSplitPosition, ofDividerAt: 1)
             }
            
        case 1:
            if proposedPosition < splitView.widthOfView(0) + secondViewMinWidth {
                newPosition = splitView.widthOfView(0) + secondViewMinWidth
            }
            else if proposedPosition > splitView.widthOfView(0) + secondViewMaxWidth {
                newPosition = splitView.widthOfView(0) + secondViewMaxWidth
            }
            
            
        default:
            break
        }

        return newPosition
        
    }
    

    
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
  //      print ("splitView(_ splitView: NSSplitView, canCollapseSubview subview: ", subview )
        
        return false
    }

   
    func splitView(_ splitView: NSSplitView, shouldCollapseSubview subview: NSView, forDoubleClickOnDividerAt dividerIndex: Int) -> Bool {
        print ("plitView: NSSplitView, shouldCollapseSubview subview: ", subview, "  forDoubleClickOnDividerAt dividerIndex:  ", dividerIndex)
        
        return false
    }

 
    
    func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
        var subViewIndex = 0
        for subview in splitView.arrangedSubviews {
            if view != subview {
                subViewIndex += 1
            }
        }
        
//        print ("splitView: NSSplitView, shouldAdjustSizeOfSubview view: ", subViewIndex)
        
        if subViewIndex < 2 {
            return true
        }
        else {
            return false
        }
    }

    
    func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
//             print ("splitView: NSSplitView, shouldHideDividerAt dividerIndex:   ", dividerIndex)
        
        return false
    }


    
}



final class StubsSplitViewDelegate: NSObject, NSSplitViewDelegate {
    
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        print ("splitView(_ splitView: NSSplitView, canCollapseSubview subview: ", subview )
        
        return false
    }

   
    func splitView(_ splitView: NSSplitView, shouldCollapseSubview subview: NSView, forDoubleClickOnDividerAt dividerIndex: Int) -> Bool {
        print ("plitView: NSSplitView, shouldCollapseSubview subview: ", subview, "  forDoubleClickOnDividerAt dividerIndex:  ", dividerIndex)
        
        return false
    }

    
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        print ("splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: ", proposedMinimumPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)
        
        return proposedMinimumPosition
    }

    
    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        print ("splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: ", proposedMaximumPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)
        
        return proposedMaximumPosition
    }

    
    func splitView(_ splitView: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        print ("splitView: NSSplitView, constrainSplitPosition proposedPosition: ", proposedPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)
        
        return proposedPosition
    }

    
 /*   func asplitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
    //    print ("splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: ", proposedMinimumPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)
        if dividerIndex == 0 {
            if proposedMinimumPosition < prax.dividerZeroMinPos {
                //     print ("splitView: NSSplitView, constrainMinCoordinate:  ", prax.dividerZeroMinPos, "  proposedMinimumPosition: ", proposedMinimumPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)
                    return prax.dividerZeroMinPos
            }
            else {
                prax.dividerZeroPos = proposedMinimumPosition
                return proposedMinimumPosition }
        }
        else {
            
            if proposedMinimumPosition < prax.dividerOneMinPos {
                //     print ("splitView: NSSplitView, constrainMinCoordinate:  ", prax.dividerOneMinPos, "   proposedMinimumPosition: ", proposedMinimumPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)

                return prax.dividerOneMinPos }
            else {
                prax.dividerOnePos = proposedMinimumPosition
                return proposedMinimumPosition }
        }
    }
   
    func asplitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        
        if dividerIndex == 0 {
            if proposedMaximumPosition > prax.dividerZeroMaxPos {
                //     print ("splitView: NSSplitView, constrainMaxCoordinate:  ", prax.dividerZeroMaxPos, "   proposedMaximumPosition: ", proposedMaximumPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)
                return prax.dividerZeroMaxPos }
            else {
                prax.dividerZeroPos = proposedMaximumPosition
                return proposedMaximumPosition }
        }
        else {
            if proposedMaximumPosition > prax.dividerOneMaxPos {
                //     print ("splitView: NSSplitView, constrainMaxCoordinate:  ", prax.dividerOneMaxPos, "   proposedMaximumPosition: ", proposedMaximumPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)
                return prax.dividerOneMaxPos }
            else {
                prax.dividerOnePos = proposedMaximumPosition
                return proposedMaximumPosition }
        }
    }

    
    func asplitView(_ splitView: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
         if dividerIndex == 0 {
            if proposedPosition < prax.dividerZeroMinPos {
                //     print ("\nsplitView: NSSplitView, constrain dividerZeroMinPos:  ", prax.dividerZeroMinPos, "  proposedPosition: ", proposedPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)
                 return prax.dividerZeroMinPos }
   
             else if proposedPosition > prax.dividerZeroMaxPos {
                 //     print ("\nsplitView: NSSplitView, constrain dividerZeroMaxPos:  ", prax.dividerZeroMaxPos, "  proposedPosition: ", proposedPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)
                  return prax.dividerZeroMaxPos }
             else {
                prax.dividerZeroPos = proposedPosition
                return proposedPosition }

        }
        else {
            if proposedPosition < prax.dividerOneMinPos {
                //     print ("\nsplitView: NSSplitView, constrain dividerOneMinPos:  ", prax.dividerOneMinPos, "  proposedPosition: ", proposedPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)
                 return prax.dividerOneMinPos }
      
            else if proposedPosition > prax.dividerOneMaxPos {
                //     print ("\nsplitView: NSSplitView, constrain dividerOneMinPos:  ", prax.dividerOneMaxPos, "  proposedPosition: ", proposedPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)
                return prax.dividerOneMaxPos }
            else {
                prax.dividerOnePos = proposedPosition
                return proposedPosition }
        
        }
    }
*/

    func splitView(_ splitView: NSSplitView, resizeSubviewsWithOldSize oldSize: NSSize) {
        print ("splitView: NSSplitView, resizeSubviewsWithOldSize oldSize:  ", oldSize)

    }

    
    func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
        print ("splitView: NSSplitView, shouldAdjustSizeOfSubview view: : ")
        
        return false
    }

    
    func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
        print ("splitView: NSSplitView, shouldHideDividerAt dividerIndex:   ", dividerIndex)
        
        return false
    }

    
    func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        print ("ssplitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex:   ", dividerIndex)
        
        return proposedEffectiveRect
    }

    
    func splitView(_ splitView: NSSplitView, additionalEffectiveRectOfDividerAt dividerIndex: Int) -> NSRect {
        print ("splitView: NSSplitView, additionalEffectiveRectOfDividerAt dividerIndex:   ", dividerIndex)
        
        return NSRect.zero
    }
    
    
    
/*    func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        print ("ssplitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex:   ", dividerIndex)
        
        return proposedEffectiveRect
    }

    
    func splitView(_ splitView: NSSplitView, additionalEffectiveRectOfDividerAt dividerIndex: Int) -> NSRect {
        print ("splitView: NSSplitView, additionalEffectiveRectOfDividerAt dividerIndex:   ", dividerIndex)
        
        return NSRect.zero
    }

*/
//    func splitViewWillResizeSubviews(_ notification: Notification) {
//        prax.splitViewFrameWidth = self.splitView?.frame.width ?? 1000
 //       print ("splitViewWillResizeSubviews(_ notification: Notification) ")
        
//    }
/*
    
    func splitViewDidResizeSubviews(_ notification: Notification) {
        print ("splitViewDidResizeSubviews(_ notification: Notification) ")
        
    }
*/

    
    func splitViewWillResizeSubviews(_ notification: Notification) {
        print ("splitViewWillResizeSubviews(_ notification: Notification) ")
        
    }

    
    func splitViewDidResizeSubviews(_ notification: Notification) {
        print ("splitViewDidResizeSubviews(_ notification: Notification) ")
        
    }
}


struct MyEqualWidthHStack: Layout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        // Return a size.
        guard !subviews.isEmpty else { return .zero }

        let maxSize = maxSize(subviews: subviews)
        let spacing = spacing(subviews: subviews)
        let totalSpacing = spacing.reduce(0) { $0 + $1 }

        return CGSize(
            width: maxSize.width * CGFloat(subviews.count) + totalSpacing,
            height: maxSize.height)
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        // Place child views.
        guard !subviews.isEmpty else { return }
      
        let maxSize = maxSize(subviews: subviews)
        let spacing = spacing(subviews: subviews)

        let placementProposal = ProposedViewSize(width: maxSize.width, height: maxSize.height)
        var x = bounds.minX + maxSize.width / 2
      
        for index in subviews.indices {
            subviews[index].place(
                at: CGPoint(x: x, y: bounds.midY),
                anchor: .center,
                proposal: placementProposal)
            x += maxSize.width + spacing[index]
        }
    }
    
    
    private func maxSize(subviews: Subviews) -> CGSize {
        let subviewSizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let maxSize: CGSize = subviewSizes.reduce(.zero) { currentMax, subviewSize in
            CGSize(
                width: max(currentMax.width, subviewSize.width),
                height: max(currentMax.height, subviewSize.height))
        }
        
        return maxSize
    }
    
    private func spacing(subviews: Subviews) -> [CGFloat] {
        subviews.indices.map { index in
            guard index < subviews.count - 1 else { return 0 }
            return subviews[index].spacing.distance(
                to: subviews[index + 1].spacing,
                along: .horizontal)
        }
    }
    
}
