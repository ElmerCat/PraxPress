//
//  PageItem.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/9/26.
//



//import Cocoa
import SwiftUI
internal import Combine

class PageItem: NSCollectionViewItem {
    
    @State private var prax = PraxModel.shared
    
    var pageIndex: Int? = nil
        
    

    static let reuseIdentifier = NSUserInterfaceItemIdentifier("page-item-reuse-identifier")

    @IBOutlet weak open var guidePageButton: NSButton?
    
    @IBAction func clickedGuidePageButton(_ sender: Any) {
        
        if pageIndex == prax.widthGuidePageIndex {
            prax.clearWidthGuide()
        }
        else {
            prax.setWidthGuide(fromPage: pageIndex!)
        }
    }
    
    private var observeWidthGuidePageIndex: Task<Void, Never>?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        observeWidthGuidePageIndex = Task {
            for await _ in Observations({ self.prax.widthGuidePageIndex }) {
  //              print("PagesViewController observeWidthGuidePageIndex  ", self.prax.widthGuidePageIndex ?? "None")
                guidePageButton?.state = self.prax.widthGuidePageIndex == self.pageIndex ? .on : .off
                
            }
        }
        
    }
    
    override var highlightState: NSCollectionViewItem.HighlightState {
        didSet {
            updateSelectionHighlighting()
        }
    }

    override var isSelected: Bool {
        didSet {
            updateSelectionHighlighting()
        }
    }

    private func updateSelectionHighlighting() {
        if !isViewLoaded {
            return
        }

        let showAsHighlighted = (highlightState == .forSelection) ||
            (isSelected && highlightState != .forDeselection) ||
            (highlightState == .asDropTarget)

        textField?.textColor = showAsHighlighted ? .selectedControlTextColor : .labelColor
        view.layer?.backgroundColor = showAsHighlighted ? NSColor.selectedControlColor.cgColor : nil
    }
}
class PagesSectionHeader: NSView, NSCollectionViewElement {
    @State private var prax = PraxModel.shared
        

    
    @IBOutlet weak var label: NSTextField!
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("pages-section-headeer-reuse-identifier")
}

class PagesSectionFooter: NSView, NSCollectionViewElement {
    @IBOutlet weak var label: NSTextField!
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("pages-section-footer-reuse-identifierr")
}
