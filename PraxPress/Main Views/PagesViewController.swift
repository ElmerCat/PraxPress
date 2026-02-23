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
var document: MergedPDFDocument?
  //  private var prax = PraxModel.shared
    var thumbnailViewer = false
    
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
            for await _ in Observations({ self.document!.sections }) {
                print("PagesViewController observeDocumentChange  ") //, document.sections)
                updateUI()
            }
        }
        observeCurrentIndexChange = Task {
            for await _ in Observations({ self.document!.selectedPageItems }) {
                print("PagesViewController observeCurrentIndexChange  ") //, PraxModel.shared.selectedPageItems)
                
              /*  if let firstIndexPath = PraxModel.shared.selectedPageItems.first {
                    if PraxModel.shared.editingPDFDocument.pageCount > firstIndexPath.item {
                        PraxModel.shared.editingPDFView.go(to: PraxModel.shared.editingPDFDocument.page(at: (firstIndexPath.item))!)
                        
                    }
                } */
            }
        }
    }
    
    private func createLayout() -> NSCollectionViewLayout {
       
        
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .fractionalWidth(1.4))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
         //   item.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 2, bottom: 20, trailing: 2)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(1.4))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
     //       section.interGroupSpacing = 5
     //       section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
            

            let layout = NSCollectionViewCompositionalLayout(section: section)
            return layout
        

    }
    
    private func configureHierarchy() {
        collectionView.register(CollectionViewPDFPageItemView.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier("PageItem"))
        collectionView.register(SectionHeader.self, forSupplementaryViewOfKind: PagesViewController.sectionHeaderElementKind, withIdentifier: NSUserInterfaceItemIdentifier("SectionHeader"))
        collectionView.register(SectionFooter.self, forSupplementaryViewOfKind: PagesViewController.sectionFooterElementKind, withIdentifier: NSUserInterfaceItemIdentifier("SectionFooter"))
         
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
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("PageItem"), for: indexPath)
            guard let pageItem = item as? CollectionViewPDFPageItemView else { return nil }
            pageItem.configure(for: self.document, at: indexPath,
                               isSelected: collectionView.selectionIndexPaths.contains(indexPath))
            return pageItem
        }
        dataSource.supplementaryViewProvider = { [weak self]
            (collectionView: NSCollectionView, kind: String, indexPath: IndexPath) -> (NSView & NSCollectionViewElement)? in
            guard let self else { return nil }
            
            // Ensure section index is valid for current model snapshot
            let sections = document!.sections
            guard indexPath.section >= 0 && indexPath.section < sections.count else {
                // The layout asked for a view that doesn’t match current state; return nil safely.
                return nil
            }
            
            if kind == PagesViewController.sectionHeaderElementKind {
                guard let header = collectionView.makeSupplementaryView(
                    ofKind: kind,
                    withIdentifier: NSUserInterfaceItemIdentifier("SectionHeader"),
                    for: indexPath) as? SectionHeader else { return nil }
                
 //               header.label.stringValue = document.sections[indexPath.section].title
                header.configure(for: document, at: indexPath,
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
            else if kind == PagesViewController.sectionFooterElementKind {
                if let footer = collectionView.makeSupplementaryView(
                    ofKind: kind,
                    withIdentifier: NSUserInterfaceItemIdentifier("SectionFooter"),
                    for: indexPath) as? SectionFooter {
                    
                    footer.configure(for: document, at: indexPath,
                                       isSelected: self.selectedSections.contains(indexPath.section))
                    return footer
                }
            }
            fatalError("Cannot create new supplementary view of kind: \(kind)")
        }
    }
    
     func updateUI(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<PDFPageSection, PDFPageItem>()
         let secs = document!.sections
        secs.forEach {
            snapshot.appendSections([$0])
            snapshot.appendItems($0.pdfPageItems)
        }
        dataSource.apply(snapshot, animatingDifferences: animated)
        
         print("PagesViewController pdateUI indexPaths ", collectionView.selectionIndexPaths, " prax: ", document!.selectedPageItems )
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.collectionView.selectionIndexPaths.isEmpty,
               let firstSection = secs.first,
               !firstSection.pdfPageItems.isEmpty {
                let firstIndexPath = IndexPath(item: 0, section: 0)
                self.collectionView.selectionIndexPaths = [firstIndexPath]
                self.collectionView.scrollToItems(at: [firstIndexPath], scrollPosition: .top)
                document!.selectedPageItems = self.collectionView.selectionIndexPaths
            }
            print("DispatchQueue PagesViewController pdateUI indexPaths ", collectionView.selectionIndexPaths, " prax: ", document!.selectedPageItems )
        }
        
        
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>){
        print("PagesViewController didSelectItemsAt indexPaths ", indexPaths)
        
        document!.selectedPageItems = collectionView.selectionIndexPaths
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>){
        print("PagesViewController didDeselectItemsAt indexPaths ", indexPaths)
        document!.selectedPageItems = collectionView.selectionIndexPaths
    }
    
    
    
}

#Preview {
 
    PagesViewController()
    
}

