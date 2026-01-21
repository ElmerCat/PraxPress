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
    
    var indexPath: IndexPath?
    
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("page-item-reuse-identifier")
    
    @IBOutlet weak open var guidePageButton: NSButton?
    @IBOutlet weak open var trimLabel: NSTextField?
    
    
    
    
    @IBAction func clickedGuidePageButton(_ sender: Any) {
        print ("PageItem - clickedGuidePageButton indexPath: ", indexPath.debugDescription)
        
        if prax.pdfPageItem(indexPath: indexPath!) == prax.widthGuidePage {
            prax.clearWidthGuide()
        }
        else {
            prax.setWidthGuide(fromPage: prax.pdfPageItem(indexPath: indexPath!)!)
        }
    }
    
    private var observeWidthGuidePageIndex: Task<Void, Never>?
    private var observePageItemTrim: Task<Void, Never>?
   
    override func viewWillAppear() {
        super.viewWillAppear()
        
        print ("PageItem - viewWillAppear pdfPageItem: ", prax.pdfPageItem(indexPath: indexPath!)?.name ?? "None")
        
        observePageItemTrim = Task {
            for await _ in Observations({ self.prax.pdfPageItem(indexPath: self.indexPath!)?.trim }) {
                trimLabel?.stringValue = String("\(prax.pdfPageItem(indexPath: indexPath!)?.trim.left)")
                
                print("PageItem observePageItemTrim  ", prax.pdfPageItem(indexPath: indexPath!)?.trim ?? "None")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //     pdfPageItem = representedObject as? PDFPageItem
        
        print ("PageItem - viewDidLoad" )
        

        
        observeWidthGuidePageIndex = Task {
            for await _ in Observations({ self.prax.widthGuidePage }) {
                print("PagesViewController observeWidthGuidePageIndex  ", self.prax.widthGuidePage?.name ?? "None")
                guidePageButton?.state = self.prax.widthGuidePage == prax.pdfPageItem(indexPath: indexPath!) ? .on : .off
                
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
    
    var indexPath: IndexPath?
    
    @IBOutlet weak var label: NSTextField!
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("pages-section-footer-reuse-identifierr")
    private var observePageItemTrim: Task<Void, Never>?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Lightweight setup only; start observations when configured if possible
    }
    
    // Called by the collection view before the view is reused
    override func prepareForReuse() {
        super.prepareForReuse()
        observePageItemTrim?.cancel()
        observePageItemTrim = nil
        label?.stringValue = ""
        indexPath = nil
    }
    
    override func viewWillMove(toSuperview newSuperview: NSView?) {
        super.viewWillMove(toSuperview: newSuperview)
        if newSuperview == nil {
            // Being removed from superview — good time to stop observers
            observePageItemTrim?.cancel()
            observePageItemTrim = nil
        }
    }
    
    deinit {
        observePageItemTrim?.cancel()
    }
    
    // Call this from your data source when configuring the footer
    func configure(for indexPath: IndexPath) {
        self.indexPath = indexPath
        // Restart observation for this indexPath
        observePageItemTrim?.cancel()
        observePageItemTrim = Task { [weak self] in
            guard let self else { return }
            for await _ in Observations({ PraxModel.shared.pdfPageItem(indexPath: indexPath)?.trim }) {
                let section = indexPath.section
                let w = PraxModel.shared.pdfPageSections[section].mergedWidthPts
                let text: String
                if w > 0 {
                    let h = PraxModel.shared.pdfPageSections[section].mergedHeightPts
                    text = String(format: "Page %d  —  %.2f\" × %.2f\"", section + 1, w / 72.0, h / 72.0)
                } else {
                    text = "Merged size: Zero"
                }
                self.label?.stringValue = text
            }
        }
    }
}
