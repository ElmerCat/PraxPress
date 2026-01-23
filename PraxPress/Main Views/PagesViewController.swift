//
//  PagesViewController.swift
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

class PagesViewController: NSViewController, NSCollectionViewDelegate {
    
    private var prax = PraxModel.shared
    
    private var selectedSections = Set<Int>()
    
    static let sectionHeaderElementKind = "section-header-element-kind"
    static let sectionFooterElementKind = "section-footer-element-kind"
    
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
        
        updateUI(animated: false)
        
        observeDocumentChange = Task {
            for await _ in Observations({ self.prax.editingPDFDocument }) {
                print("PagesViewController observeDocumentChange  ", self.prax.editingPDFDocument)
                updateUI()
            }
        }
        observeCurrentIndexChange = Task {
            for await _ in Observations({ self.prax.selectionIndexPaths }) {
                print("PagesViewController observeCurrentIndexChange  ", self.prax.selectionIndexPaths)
                
                if let firstIndexPath = prax.selectionIndexPaths.first {
                    prax.editingPDFView?.go(to: prax.editingPDFDocument.page(at: (firstIndexPath.item))!)
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
            elementKind: PagesViewController.sectionHeaderElementKind,
            alignment: .top)
        let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerFooterSize,
            elementKind: PagesViewController.sectionFooterElementKind,
            alignment: .bottom)
        section.boundarySupplementaryItems = [sectionHeader, sectionFooter]
        sectionHeader.pinToVisibleBounds = true
        sectionHeader.zIndex = 2
        sectionFooter.pinToVisibleBounds = true
        sectionFooter.zIndex = 2
        let layout = NSCollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    private func configureHierarchy() {
        var itemNib = NSNib(nibNamed: "PageItem", bundle: nil)
        collectionView.register(itemNib, forItemWithIdentifier: PageItem.reuseIdentifier)
        
        itemNib = NSNib(nibNamed: "PagesSectionHeader", bundle: nil)
        collectionView.register(itemNib,
                                forSupplementaryViewOfKind: PagesViewController.sectionHeaderElementKind,
                                withIdentifier: PagesSectionHeader.reuseIdentifier)
        itemNib = NSNib(nibNamed: "PagesSectionFooter", bundle: nil)
        collectionView.register(itemNib,
                                forSupplementaryViewOfKind: PagesViewController.sectionFooterElementKind,
                                withIdentifier: PagesSectionFooter.reuseIdentifier)
        
        collectionView.collectionViewLayout = createLayout()
        
        collectionView.registerForDraggedTypes(
            NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        
        collectionView.registerForDraggedTypes([
            .fileURL, // Accept dragging of image file URLs from other apps.
            .pdfPageDragType,
            .pdfPageSectionType]) // Intra drag of row items numbers within the collection view.
        
        // Determine the kind of source drag originating from this app.
        // Note, if you want to allow your app to drag items to the Finder's trash can, add ".delete".
        collectionView.setDraggingSourceOperationMask([.copy, .delete], forLocal: false)
    }
    
    private func configureDataSource() {
        dataSource = NSCollectionViewDiffableDataSource<PDFPageSection, PDFPageItem>(collectionView: collectionView) {
            (collectionView: NSCollectionView, indexPath: IndexPath, identifier: PDFPageItem) -> NSCollectionViewItem? in
            let item = collectionView.makeItem(withIdentifier: PageItem.reuseIdentifier, for: indexPath)
            guard let pageItem = item as? PageItem else { return nil }
            pageItem.indexPath = indexPath
            // pageItem.pageIndex = identifier.index
            pageItem.imageView?.image = identifier.thumbnail
            pageItem.textField?.stringValue = identifier.name
            pageItem.trimLabel?.stringValue = "\(identifier.trim.left)"
            pageItem.guidePageButton?.state = self.prax.widthGuidePage == identifier ? .on : .off
            return pageItem
        }
        dataSource.supplementaryViewProvider = { [weak self]
            (collectionView: NSCollectionView, kind: String, indexPath: IndexPath) -> (NSView & NSCollectionViewElement)? in
            guard let self else { return nil }
            
            // Ensure section index is valid for current model snapshot
            let sections = self.prax.pdfPageSections
            guard indexPath.section >= 0 && indexPath.section < sections.count else {
                // The layout asked for a view that doesn’t match current state; return nil safely.
                return nil
            }
            
            if kind == PagesViewController.sectionHeaderElementKind {
                guard let header = collectionView.makeSupplementaryView(
                    ofKind: kind,
                    withIdentifier: PagesSectionHeader.reuseIdentifier,
                    for: indexPath) as? PagesSectionHeader else { return nil }
                
                header.label.stringValue = self.prax.pdfPageSections[indexPath.section].title
                header.isSelected = self.selectedSections.contains(indexPath.section)
                
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
            else if kind == PagesViewController.sectionFooterElementKind {
                if let footer = collectionView.makeSupplementaryView(
                    ofKind: kind,
                    withIdentifier: PagesSectionFooter.reuseIdentifier,
                    for: indexPath) as? PagesSectionFooter {
                    
                    footer.configure(for: indexPath)
                    
                    let w = self.prax.pdfPageSections[indexPath.section].mergedWidthPts
                    var text: String
                    if w > 0 {
                        let h = self.prax.pdfPageSections[indexPath.section].mergedHeightPts
                        let wIn = w / 72.0
                        let hIn = h / 72.0
                        text = String(format: "Merged size: %.0f × %.0f pts (%.2f × %.2f in)", w, h, wIn, hIn)
                    } else {
                        text = "Merged size: —"
                    }
                    
                    footer.label.stringValue = text
                    return footer
                }
            }
            fatalError("Cannot create new supplementary view of kind: \(kind)")
        }
    }
    
     func updateUI(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<PDFPageSection, PDFPageItem>()
        let secs = prax.pdfPageSections
        secs.forEach {
            snapshot.appendSections([$0])
            snapshot.appendItems($0.pdfPageItems)
        }
        dataSource.apply(snapshot, animatingDifferences: animated)
        
        print("PagesViewController pdateUI indexPaths ", collectionView.selectionIndexPaths, " prax: ", prax.selectionIndexPaths )
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.collectionView.selectionIndexPaths.isEmpty,
               let firstSection = secs.first,
               !firstSection.pdfPageItems.isEmpty {
                let firstIndexPath = IndexPath(item: 0, section: 0)
                self.collectionView.selectionIndexPaths = [firstIndexPath]
                self.collectionView.scrollToItems(at: [firstIndexPath], scrollPosition: .top)
                self.prax.selectionIndexPaths = self.collectionView.selectionIndexPaths
            }
            print("DispatchQueue PagesViewController pdateUI indexPaths ", collectionView.selectionIndexPaths, " prax: ", prax.selectionIndexPaths )
        }
        
        
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>){
        print("PagesViewController didSelectItemsAt indexPaths ", indexPaths)
        
        prax.selectionIndexPaths = collectionView.selectionIndexPaths
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>){
        print("PagesViewController didDeselectItemsAt indexPaths ", indexPaths)
        prax.selectionIndexPaths = collectionView.selectionIndexPaths
    }
    
    
    
}

