//
//  SplitViewDelegate.swift
//  PraxPress
//
//  Created by Elmer Cat on 3/19/26.
//

import AppKit


final class SplitViewDelegate: NSObject, NSSplitViewDelegate {
    var splitView: NSSplitView?

    var dividerZeroMinPos: CGFloat = 100
    var dividerZeroMaxPos: CGFloat = 400
    var dividerZeroPos: CGFloat = 100   /*{
        didSet {
            splitView!.setPosition(dividerOnePos + 10 , ofDividerAt: 1)
            splitView!.adjustSubviews()
        }
    }*/
    var dividerOneMinPos: CGFloat = 400
    var dividerOneMaxPos: CGFloat = 700
    var dividerOnePos: CGFloat = 400
    
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
        if dividerIndex == 0 {
            print ("splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: ", proposedMinimumPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)
            if proposedMinimumPosition < dividerZeroMinPos { return dividerZeroMinPos }
            else {
                dividerZeroPos = proposedMinimumPosition
                return proposedMinimumPosition }
        }
        else {
            
            let frameWidth = splitView.frame.width
            
            let minPositiion = min(dividerOneMinPos + dividerZeroPos, dividerOnePos)
            print ("minPosition: ", minPositiion, "  splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: ", proposedMinimumPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)
            
            
            if proposedMinimumPosition < minPositiion {
           //     splitView.setPosition(minPositiion, ofDividerAt: dividerIndex)
                return minPositiion }
            else {
                dividerOnePos = proposedMinimumPosition
                return proposedMinimumPosition }
        }
    }
   
    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        print ("splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: ", proposedMaximumPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)
        
        if dividerIndex == 0 {
            if proposedMaximumPosition > 400 { return 400 }
            else { return proposedMaximumPosition }
        }
        else {
            if proposedMaximumPosition > 800 { return 800 }
            else { return proposedMaximumPosition }
        }
    }

    
    func splitView(_ splitView: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        print ("\nsplitView: NSSplitView, constrainSplitPosition proposedPosition: ", proposedPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)
        if dividerIndex == 0 {
            if proposedPosition < dividerZeroMinPos { return dividerZeroMinPos }
            else {
                dividerZeroPos = proposedPosition
                return proposedPosition }

        }
        else {
            if proposedPosition < dividerOneMinPos + dividerZeroPos { return dividerOneMinPos + dividerZeroPos }
            else {
                dividerOnePos = proposedPosition
                return proposedPosition }
        
        }
    }

    
/*    func splitView(_ splitView: NSSplitView, resizeSubviewsWithOldSize oldSize: NSSize) {
        print ("splitView: NSSplitView, resizeSubviewsWithOldSize oldSize:  ", oldSize)

    }
*/
    
    func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
        print ("splitView: NSSplitView, shouldAdjustSizeOfSubview view: : ")
        
        return false
    }

    
    func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
        print ("splitView: NSSplitView, shouldHideDividerAt dividerIndex:   ", dividerIndex)
        
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

    
    func splitViewWillResizeSubviews(_ notification: Notification) {
        print ("splitViewWillResizeSubviews(_ notification: Notification) ")
        
    }

    
    func splitViewDidResizeSubviews(_ notification: Notification) {
        print ("splitViewDidResizeSubviews(_ notification: Notification) ")
        
    }
*/
    
}
