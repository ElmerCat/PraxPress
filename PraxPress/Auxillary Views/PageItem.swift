//
//  PageItem.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/9/26.
//



//import Cocoa
import SwiftUI
import Combine
import UniformTypeIdentifiers

/*class PageItem: NSCollectionViewItem {
    
    @State private var prax = PraxModel.shared
    
    var indexPath: IndexPath?
    
//    static let reuseIdentifier = NSUserInterfaceItemIdentifier("page-item-reuse-identifier")
    
    @IBOutlet weak open var guidePageButton: NSButton?
    @IBOutlet weak open var trimLabel: NSTextField?
    
    
    
    
    @IBAction func clickedGuidePageButton(_ sender: Any) {
        print ("PageItem - clickedGuidePageButton indexPath: ", indexPath.debugDescription)
        guard let indexPath = indexPath else { return }
        if prax.pdfPageItem(indexPath: indexPath) == prax.widthGuidePage {
            prax.clearWidthGuide()
        }
        else {
            prax.setWidthGuide(fromPage: prax.pdfPageItem(indexPath: indexPath)!)
        }
    }
    
    private var observeWidthGuidePageIndex: Task<Void, Never>?
    private var observePageItemTrim: Task<Void, Never>?
    
    override func viewWillAppear() {
        super.viewWillAppear()
        guard let indexPath = indexPath else { return }
        print ("PageItem - viewWillAppear pdfPageItem: ", prax.pdfPageItem(indexPath: indexPath)?.name ?? "None")
        
        observePageItemTrim = Task { [weak self] in
            guard let self else { return }
            for await _ in Observations({ self.prax.pdfPageItem(indexPath: indexPath)?.trim }) {
                if Task.isCancelled { return }
                let left = self.prax.pdfPageItem(indexPath: indexPath)?.trim.left ?? 0
                await MainActor.run {
                    if Task.isCancelled { return }
                    self.trimLabel?.stringValue = "\(left)"
                    print("await MainActor PageItem observePageItemTrim  ", self.prax.pdfPageItem(indexPath: indexPath)?.trim ?? "None")
                }
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print ("PageItem - viewDidLoad" )
        
        observeWidthGuidePageIndex = Task { [weak self] in
            guard let self else { return }
            for await _ in Observations({ self.prax.widthGuidePage }) {
                if Task.isCancelled { return }
                guard let indexPath = self.indexPath else { continue }
                let on = self.prax.widthGuidePage == self.prax.pdfPageItem(indexPath: indexPath)
                await MainActor.run {
                    if Task.isCancelled { return }
                    self.guidePageButton?.state = on ? .on : .off
                } } }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        observePageItemTrim?.cancel()
        observePageItemTrim = nil
        observeWidthGuidePageIndex?.cancel()
        observeWidthGuidePageIndex = nil
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
        view.layer?.backgroundColor = showAsHighlighted ? NSColor.orange.cgColor : nil
    }
}
*/


protocol PagesSectionHeaderDragDelegate: AnyObject {
    func sectionHeaderPasteboardItems(for section: Int) -> [NSDraggingItem]
}

class PagesSectionHeader: NSView, NSCollectionViewElement, NSDraggingSource, PagesSectionHeaderDragDelegate {
    @IBOutlet weak var label: NSTextField!
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("pages-section-headeer-reuse-identifier")
    weak var dragDelegate: PagesSectionHeaderDragDelegate?
    var sectionIndex: Int = 0
    
    // Exposed hooks to configure selection and handle toggles
    var isSelected: Bool = false {
        didSet { updateAppearance() }
    }
    var onToggleSelection: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let dragGesture = NSPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(dragGesture)
        
        wantsLayer = true
        layer?.cornerRadius = 6
        
        let click = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
        addGestureRecognizer(click)
        
        updateAppearance()
    }
    
    @objc private func handlePan(_ gesture: NSPanGestureRecognizer) {
        switch gesture.state {
        case .began:
  //          guard let window = window else { return }
  //          let location = gesture.location(in: self)
            // Get dragging items from delegate (controller)
            let items = sectionHeaderPasteboardItems(for: sectionIndex)
            guard !items.isEmpty else { return }
            beginDraggingSession(with: items, event: NSApp.currentEvent ?? NSEvent(), source: self)
        default:
            break
        }
    }
    
    
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        switch context {
        case .outsideApplication: return [.copy]
        case .withinApplication: return [.move, .copy]
        @unknown default: return [.copy]
        }
    }

    private func updateAppearance() {
        layer?.backgroundColor = isSelected ? NSColor.selectedControlColor.cgColor : NSColor.clear.cgColor
        label.textColor = isSelected ? .selectedControlTextColor : .labelColor
    }
    
    @objc private func handleClick() {
        onToggleSelection?()
    }
    
    
    func sectionHeaderPasteboardItems(for section: Int) -> [NSDraggingItem] {
        // 1) Your internal custom item
        let sectionItem = NSPasteboardItem()
        guard let idxData = try? NSKeyedArchiver.archivedData(
            withRootObject: IndexPath(item: 0, section: section),
            requiringSecureCoding: false
        ) else { return [] }
        sectionItem.setData(idxData, forType: .pdfPageSectionType)
        let sectionDraggingItem = NSDraggingItem(pasteboardWriter: sectionItem)
        
        // 2) File promise for Finder
        let typeIdentifier = UTType.pdf.identifier
        let provider = FilePromiseProvider()
        provider.pdfDocument = PraxModel.shared.mergedPDFDocument
        provider.fileName = "PraxPress-PageSection.pdf"
        provider.fileType = typeIdentifier
        provider.delegate = provider // it already conforms in your code
        
        
        // Pass enough info to write the correct section on drop
        provider.userInfo = [
            FilePromiseProvider.UserInfoKeys.indexPathKey: idxData,
            FilePromiseProvider.UserInfoKeys.urlKey: PraxModel.shared.mergedPDFURL as Any
        ]
        
        let filePromiseDraggingItem = NSDraggingItem(pasteboardWriter: provider)
        
        // Optional: preview image
        if let rep = self.bitmapImageRepForCachingDisplay(in: bounds) {
            self.cacheDisplay(in: bounds, to: rep)
            let img = NSImage(size: bounds.size)
            img.addRepresentation(rep)
            sectionDraggingItem.setDraggingFrame(bounds, contents: img)
            filePromiseDraggingItem.setDraggingFrame(bounds, contents: img)
        }
        
        return [sectionDraggingItem, filePromiseDraggingItem]
    }
    
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
                if Task.isCancelled { return }
                
                    let sections = PraxModel.shared.pdfPageSections
                    guard indexPath.section >= 0 && indexPath.section < sections.count else { return }
                    
                    let sectionModel = sections[indexPath.section]
                    let w = sectionModel.mergedWidthPts
                    if w > 0 {
                        let h = sectionModel.mergedHeightPts
                        self.label?.stringValue = String(format: "Page %d  —  %.2f\" × %.2f\"",
                                                         indexPath.section + 1, w / 72.0, h / 72.0)
                    } else {
                        self.label?.stringValue = "Merged size: Zero"
                    }}}
    }
}
