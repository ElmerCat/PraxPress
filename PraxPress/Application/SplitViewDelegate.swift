//
//  SplitViewDelegate.swift
//  PraxPress
//
//  Created by Elmer Cat on 3/19/26.
//

import AppKit


final class SplitViewDelegate: NSObject, NSSplitViewDelegate {
    let prax: PraxModel
    
    init(prax: PraxModel, splitView: NSSplitView? = nil) {
        self.prax = prax
        self.splitView = splitView
    }
    
    var splitView: NSSplitView?

    
    
/*    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        print ("splitView(_ splitView: NSSplitView, canCollapseSubview subview: ", subview )
        
        return false
    }
*/
   
    func splitView(_ splitView: NSSplitView, shouldCollapseSubview subview: NSView, forDoubleClickOnDividerAt dividerIndex: Int) -> Bool {
   //     print ("plitView: NSSplitView, shouldCollapseSubview subview: ", subview, "  forDoubleClickOnDividerAt dividerIndex:  ", dividerIndex)
        
        return false
    }

    
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
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
   
    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        
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

    
    func splitView(_ splitView: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
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

    
/*    func splitView(_ splitView: NSSplitView, resizeSubviewsWithOldSize oldSize: NSSize) {
        print ("splitView: NSSplitView, resizeSubviewsWithOldSize oldSize:  ", oldSize)

    }
*/
    
    func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
        //     print ("splitView: NSSplitView, shouldAdjustSizeOfSubview view: : ")
        
        return false
    }

    
    func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
        //     print ("splitView: NSSplitView, shouldHideDividerAt dividerIndex:   ", dividerIndex)
        
        return false
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
    func splitViewWillResizeSubviews(_ notification: Notification) {
        prax.splitViewFrameWidth = self.splitView?.frame.width ?? 1000
 //       print ("splitViewWillResizeSubviews(_ notification: Notification) ")
        
    }
/*
    
    func splitViewDidResizeSubviews(_ notification: Notification) {
        print ("splitViewDidResizeSubviews(_ notification: Notification) ")
        
    }
*/
    
}
