//
//  PageItem.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/9/26.
//



//import Cocoa
import SwiftUI

class PageItem: NSCollectionViewItem {
    
    @State private var pdfModel = PDFModel.shared
    
    var pageIndex: Int? = nil
        
    

    static let reuseIdentifier = NSUserInterfaceItemIdentifier("page-item-reuse-identifier")

    @IBOutlet weak open var guidePageButton: NSButton?
    
    @IBAction func clickedGuidePageButton(_ sender: Any) {
        
        if pageIndex == pdfModel.widthGuidePageIndex {
            pdfModel.clearWidthGuide()
        }
        else {
            pdfModel.setWidthGuide(fromPage: pageIndex!)
        }
    }
    
    private var observeWidthGuidePageIndex: Task<Void, Never>?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        observeWidthGuidePageIndex = Task {
            for await _ in Observations({ self.pdfModel.widthGuidePageIndex }) {
                print("PagesViewController observeWidthGuidePageIndex  ", self.pdfModel.widthGuidePageIndex ?? "None")
                guidePageButton?.state = self.pdfModel.widthGuidePageIndex == self.pageIndex ? .on : .off
                
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
