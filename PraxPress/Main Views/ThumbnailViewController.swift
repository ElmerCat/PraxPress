//
//  ThumbnailViewController.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/8/26.
//


import Cocoa
import PDFKit
import AppKit
import SwiftUI
import Observation
import UniformTypeIdentifiers


class ThumbnailViewController: NSViewController, NSCollectionViewDelegate {
 
    private var selectedSections = Set<Int>()
    
    static let sectionHeaderElementKind = "section-header-element-kind"
    static let sectionFooterElementKind = "section-footer-element-kind"
    static let sectionBackgroundElementKind = "section-background-element-kind"
    
    @IBOutlet weak var collectionView: NSCollectionView!
    
    private var dataSource: NSCollectionViewDiffableDataSource<PDFPageSection, PDFPageItem>! = nil
    private var observeDocumentChange: Task<Void, Never>?
    private var observeCurrentIndexChange: Task<Void, Never>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureHierarchy()
        configureDataSource()
        
        collectionView.isSelectable = true
        collectionView.allowsEmptySelection = false
        collectionView.allowsMultipleSelection = true
        collectionView.setDraggingSourceOperationMask([.copy], forLocal: false)
        collectionView.backgroundView = CollectionViewBackgroundView()
        
        updateUI(animated: false)
        
        observeDocumentChange = Task {
            for await _ in Observations({ PraxModel.shared.pdfPageSections }) {
                print("ThumbnailViewController observeDocumentChange  ") //, PraxModel.shared.pdfPageSections)
                updateUI()
            }
        }
        observeCurrentIndexChange = Task {
            for await _ in Observations({ PraxModel.shared.selectedPageItems }) {
                print("ThumbnailViewController observeCurrentIndexChange  ") //, PraxModel.shared.selectedPageItems)
                
                if let firstIndexPath = PraxModel.shared.selectedPageItems.first {
                    if PraxModel.shared.editingPDFDocument.pageCount > firstIndexPath.item {
                        PraxModel.shared.editingPDFView.go(to: PraxModel.shared.editingPDFDocument.page(at: (firstIndexPath.item))!)
                        
                    }
                }
            }
        }
    }
    
    
    
    private func createLayout() -> NSCollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalWidth(1.3))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 2, bottom: 20, trailing: 2)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(1.3))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 5
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
        
        let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .absolute(50))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerFooterSize,
            elementKind: ThumbnailViewController.sectionHeaderElementKind,
            alignment: .top)
        let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerFooterSize,
            elementKind: ThumbnailViewController.sectionFooterElementKind,
            alignment: .bottom)
        
        let sectionBackground = NSCollectionLayoutDecorationItem.background(elementKind: ThumbnailViewController.sectionBackgroundElementKind)
        
        
        section.boundarySupplementaryItems = [sectionHeader, sectionFooter]
        
        section.decorationItems = [sectionBackground]
        
        section.visibleItemsInvalidationHandler = { visibleItems, scrollOffset, layoutEnvironment in
            // Perform animations on the visible items.
            print("Julie")
        }
        
        sectionHeader.pinToVisibleBounds = true
        sectionHeader.zIndex = 2
        sectionFooter.pinToVisibleBounds = true
        sectionFooter.zIndex = 2
        let layout = NSCollectionViewCompositionalLayout(section: section)
        layout.register(SectionBackgroundDecorationView.self, forDecorationViewOfKind: ThumbnailViewController.sectionBackgroundElementKind)
        
        return layout
        
    }
    
    private func configureHierarchy() {
        collectionView.register(CollectionViewPDFPageItemThumbnail.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier("PageThumbnail"))
        collectionView.register(SectionHeader.self, forSupplementaryViewOfKind: ThumbnailViewController.sectionHeaderElementKind, withIdentifier: NSUserInterfaceItemIdentifier("SectionHeader"))
        collectionView.register(SectionFooter.self, forSupplementaryViewOfKind: ThumbnailViewController.sectionFooterElementKind, withIdentifier: NSUserInterfaceItemIdentifier("SectionFooter"))
        
        
        collectionView.collectionViewLayout = createLayout()
        
        collectionView.registerForDraggedTypes(
            NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        
        collectionView.registerForDraggedTypes([
            .fileURL, // Accept dragging of image file URLs from other apps.
            .pdfPageDragType,
            .pdfPageSectionType]) // Intra drag of row items numbers within the collection view.
        
        collectionView.setDraggingSourceOperationMask([.copy, .delete], forLocal: false)
    }
    
    private func configureDataSource() {
        dataSource = NSCollectionViewDiffableDataSource<PDFPageSection, PDFPageItem>(collectionView: collectionView) {
            (collectionView: NSCollectionView, indexPath: IndexPath, identifier: PDFPageItem) -> NSCollectionViewItem? in
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("PageThumbnail"), for: indexPath)
            guard let pageItem = item as? CollectionViewPDFPageItemThumbnail else { return nil }
            pageItem.configure(at: indexPath,
                               isSelected: collectionView.selectionIndexPaths.contains(indexPath))
            return pageItem
        }
        dataSource.supplementaryViewProvider = { [weak self]
            (collectionView: NSCollectionView, kind: String, indexPath: IndexPath) -> (NSView & NSCollectionViewElement)? in
            guard let self else { return nil }
            
            // Ensure section index is valid for current model snapshot
            let sections = PraxModel.shared.pdfPageSections
            guard indexPath.section >= 0 && indexPath.section < sections.count else {
                // The layout asked for a view that doesn’t match current state; return nil safely.
                return nil
            }
            
            if kind == ThumbnailViewController.sectionHeaderElementKind {
                guard let header = collectionView.makeSupplementaryView(
                    ofKind: kind,
                    withIdentifier: NSUserInterfaceItemIdentifier("SectionHeader"),
                    for: indexPath) as? SectionHeader else { return nil }
                
                //               header.label.stringValue = PraxModel.shared.pdfPageSections[indexPath.section].title
                header.configure(at: indexPath,
                                 isSelected: self.selectedSections.contains(indexPath.section))
                
                header.onToggleSelection = { [weak self] in
                    guard let self else { return }
                    if self.selectedSections.contains(indexPath.section) {
                        self.selectedSections.remove(indexPath.section)
                    } else {
                        self.selectedSections.insert(indexPath.section)
                    }
                    // Refresh just this section’s header to reflect the new state.
                    self.collectionView.reloadSections(IndexSet(integer: indexPath.section))
                }
                
                return header
                
            }
            else if kind == ThumbnailViewController.sectionFooterElementKind {
                if let footer = collectionView.makeSupplementaryView(
                    ofKind: kind,
                    withIdentifier: NSUserInterfaceItemIdentifier("SectionFooter"),
                    for: indexPath) as? SectionFooter {
                    
                    footer.configure(at: indexPath,
                                     isSelected: self.selectedSections.contains(indexPath.section))
                    return footer
                }
            }
            fatalError("Cannot create new supplementary view of kind: \(kind)")
        }
    }
    
    func updateUI(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<PDFPageSection, PDFPageItem>()
        let secs = PraxModel.shared.pdfPageSections
        secs.forEach {
            snapshot.appendSections([$0])
            snapshot.appendItems($0.pdfPageItems)
        }
        dataSource.apply(snapshot, animatingDifferences: animated)
        
        print("ThumbnailViewController pdateUI indexPaths ", collectionView.selectionIndexPaths, " prax: ", PraxModel.shared.selectedPageItems )
        
 /*       DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.collectionView.selectionIndexPaths.isEmpty,
               let firstSection = secs.first,
               !firstSection.pdfPageItems.isEmpty {
                let firstIndexPath = IndexPath(item: 0, section: 0)
                self.collectionView.selectionIndexPaths = [firstIndexPath]
                self.collectionView.scrollToItems(at: [firstIndexPath], scrollPosition: .top)
                PraxModel.shared.selectedPageItems = self.collectionView.selectionIndexPaths
            }
            print("DispatchQueue ThumbnailViewController pdateUI indexPaths ", collectionView.selectionIndexPaths, " prax: ", PraxModel.shared.selectedPageItems )
        }
  */
        
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>){
        print("ThumbnailViewController didSelectItemsAt indexPaths ", indexPaths)
        
        PraxModel.shared.selectedPageItems = collectionView.selectionIndexPaths
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>){
        print("ThumbnailViewController didDeselectItemsAt indexPaths ", indexPaths)
        PraxModel.shared.selectedPageItems = collectionView.selectionIndexPaths
    }
    
    
    
}



class CollectionViewBackgroundView: NSView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        
        print("CollectionViewBackgroundView - draggingEntered")
        layer?.backgroundColor = NSColor.green.cgColor
        return .copy
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?)  {
        print("CollectionViewBackgroundView - draggingExited")
        layer?.backgroundColor = NSColor.cyan.cgColor
    }
    
    override func concludeDragOperation(_ sender: NSDraggingInfo?)  {
        print("CollectionViewBackgroundView - concludeDragOperation")
        layer?.backgroundColor = NSColor.cyan.cgColor
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo)  {
        print("CollectionViewBackgroundView - draggingEnded")
        layer?.backgroundColor = NSColor.cyan.cgColor
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("CollectionViewBackgroundView - prepareForDragOperation")
        return true
    }
    
    func wantsPeriodicUpdates() -> Bool {
        print("CollectionViewBackgroundView - wantsPeriodicUpdates")
        return true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pboard = sender.draggingPasteboard
        
        // Extract file URLs from the pasteboard
        if let urls = pboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
            for url in urls {
                print("CollectionViewBackgroundView - Dropped file: \(url.path)")
            }
            return true // Drop was successful
        }
        return false // Drop rejected
    }
    
}

extension CollectionViewBackgroundView {
    func configure() {
        registerForDraggedTypes([.fileURL])
        
        self.wantsLayer = true
        layer?.backgroundColor = NSColor.cyan.cgColor
        layer?.borderColor = NSColor.black.cgColor
        layer?.borderWidth = 1
        layer?.cornerRadius = 12
    }
}


class SectionBackgroundDecorationView: NSView, NSCollectionViewElement {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
 
}

extension SectionBackgroundDecorationView {
    func configure() {
       
        self.wantsLayer = true
        layer?.backgroundColor = NSColor.yellow.cgColor
        layer?.borderColor = NSColor.black.cgColor
        layer?.borderWidth = 1
        layer?.cornerRadius = 12
    }
}



#Preview {
    
    ThumbnailViewController()
    
}

