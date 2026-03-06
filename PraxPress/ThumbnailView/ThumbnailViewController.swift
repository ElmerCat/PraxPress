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
    let document: MergedPDFDocument
    let prax: PraxModel
    
    init(_ document: MergedPDFDocument, _ prax: PraxModel) {
   
        self.document = document
        self.prax = prax
        super.init(nibName: nil, bundle: nil)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    static let sectionHeaderElementKind = "section-header-element-kind"
    static let sectionFooterElementKind = "section-footer-element-kind"
    static let sectionBackgroundElementKind = "section-background-element-kind"
    
    static let sectionHeaderHeight: CGFloat = 50
    static let sectionFooterHeight: CGFloat = 50

    @IBOutlet weak var collectionView: NSCollectionView!
    
    private var dataSource: NSCollectionViewDiffableDataSource<PDFPageSectionModel, PDFPageItemModel>! = nil
    private var observeDocumentChange: Task<Void, Never>?
    private var observeCurrentIndexChange: Task<Void, Never>?
    private var pendingSelectionUpdate: DispatchWorkItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureHierarchy()
        configureDataSource()
        
        collectionView.isSelectable = true
        collectionView.allowsEmptySelection = true
        collectionView.allowsMultipleSelection = true
        collectionView.setDraggingSourceOperationMask([.copy], forLocal: false)
        collectionView.backgroundView = CollectionViewBackground()
        
        updateUI(animated: false)
        
/*        observeDocumentChange = Task {
            for await _ in Observations({ self.document.pageSections }) {
                print("ThumbnailViewController observeDocumentChange  ") //, document.sections)
                updateUI()
            }
        }
 */
        
        observeCurrentIndexChange = Task {
            for await _ in Observations({ self.document.selectedPageItems }) {
                print("ThumbnailViewController observeCurrentIndexChange  ") //, PraxModel.shared.selectedPageItems)
                
              /*  if let firstIndexPath = PraxModel.shared.selectedPageItems.first {
                    if PraxModel.shared.editingPDFDocument.pageCount > firstIndexPath.item {
                        PraxModel.shared.editingPDFView.go(to: PraxModel.shared.editingPDFDocument.page(at: (firstIndexPath.item))!)
                        
                    }
                } */
            }
        }
    }
    
    
    
    private func createLayout() -> NSCollectionViewLayout {
        
        let layout = NSCollectionViewCompositionalLayout {
            (sectionIndex: Int,
             layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection in
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .fractionalWidth(0.5))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
   //         item.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 2, bottom: 20, trailing: 2)
     //       item.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: .fixed(0), top: .fixed(0), trailing: .fixed(0), bottom: .fixed(0))
            
 //           item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 0)
            
//            item.edgeSpacing = NSCollectionLayoutEdgeSpacing(
//                leading: nil,
//                top: nil,
//                trailing: .fixed(0),
//                bottom: nil
//            )
            
 
            let sectionBackground = NSCollectionLayoutDecorationItem.background(elementKind: ThumbnailViewController.sectionBackgroundElementKind)
            
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(0.5))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            
      //      group.contentInsets = NSDirectionalEdgeInsets(top: 30, leading: 30, bottom: 30, trailing: 30)
            
            let section = NSCollectionLayoutSection(group: group)
     //       section.interGroupSpacing = 5
     //       section.contentInsets = NSDirectionalEdgeInsets(top: 40, leading: 40, bottom: 40, trailing: 40)
     //       section.supplementariesFollowContentInsets = false
            
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                    heightDimension: .absolute(ThumbnailViewController.sectionHeaderHeight))
            
            let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),                                                        heightDimension: .absolute(ThumbnailViewController.sectionFooterHeight))
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: ThumbnailViewController.sectionHeaderElementKind,
                alignment: .top,)
           sectionHeader.extendsBoundary = true
           let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: footerSize,
                elementKind: ThumbnailViewController.sectionFooterElementKind,
                alignment: .bottom)

            
            section.boundarySupplementaryItems = [sectionHeader, sectionFooter]
            
            section.decorationItems = [sectionBackground]
            
     //       section.visibleItemsInvalidationHandler = { visibleItems, scrollOffset, layoutEnvironment in
                // Perform animations on the visible items.
     //           print("section.visibleItemsInvalidationHandler")
     //       }
    
            sectionHeader.pinToVisibleBounds = true
            sectionHeader.zIndex = 2
 //           sectionFooter.pinToVisibleBounds = true
 //           sectionFooter.zIndex = 2
       
            return section
        }
       
        layout.register(SectionBackground.self, forDecorationViewOfKind: ThumbnailViewController.sectionBackgroundElementKind)
        
        return layout
        
    }
    
    private func configureHierarchy() {
        collectionView.register(PDFPageThumbnail.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier("PageThumbnail"))
  
        collectionView.register(SectionHeader.self, forSupplementaryViewOfKind: ThumbnailViewController.sectionHeaderElementKind, withIdentifier: NSUserInterfaceItemIdentifier("SectionHeader"))
        
        collectionView.register(SectionFooter.self, forSupplementaryViewOfKind: ThumbnailViewController.sectionFooterElementKind, withIdentifier: NSUserInterfaceItemIdentifier("SectionFooter"))
        
        collectionView.collectionViewLayout = createLayout()
        
        collectionView.registerForDraggedTypes(
            NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        
        collectionView.registerForDraggedTypes([
            .fileURL, // Accept dragging of image file URLs from other apps.
            .pdfPageDragType,
            .pdfPageSectionType,
            .pdfFileType]) // Intra drag of row items numbers within the collection view.
        
        collectionView.setDraggingSourceOperationMask([.copy, .delete], forLocal: false)
    }
    
    private func configureDataSource() {
        dataSource = NSCollectionViewDiffableDataSource<PDFPageSectionModel, PDFPageItemModel>(collectionView: collectionView) {
            (collectionView: NSCollectionView, indexPath: IndexPath, identifier: PDFPageItemModel) -> NSCollectionViewItem? in
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("PageThumbnail"), for: indexPath)
            guard let pageItem = item as? PDFPageThumbnail else { return nil }
            pageItem.configure(for: self.document, at: indexPath,
                               isSelected: collectionView.selectionIndexPaths.contains(indexPath))
            return pageItem
        }
        dataSource.supplementaryViewProvider = { [weak self]
            (collectionView: NSCollectionView, kind: String, indexPath: IndexPath) -> (NSView & NSCollectionViewElement)? in
            guard let self else { return nil }
            
            // Ensure section index is valid for current model snapshot
            let sections = document.pageSections
            guard indexPath.section >= 0 && indexPath.section < sections.count else {
                // The layout asked for a view that doesn’t match current state; return nil safely.
                return nil
            }
            
            if kind == ThumbnailViewController.sectionHeaderElementKind {
                guard let header = collectionView.makeSupplementaryView(
                    ofKind: kind,
                    withIdentifier: NSUserInterfaceItemIdentifier("SectionHeader"),
                    for: indexPath) as? SectionHeader else { return nil }
                
                //               header.label.stringValue = document.sections[indexPath.section].title
                header.configure(for: document, at: indexPath,
                                 isSelected: document.selectedSections.contains(indexPath.section))
                
                header.onToggleSelection = { [weak self] in
             //       guard let self else { return }
             //       if document!.selectedSections.contains(indexPath.section) {
             //           document.selectedSections.remove(indexPath.section)
             //       } else {
             //           document.selectedSections.insert(indexPath.section)
             //       }
                    // Refresh just this section’s header to reflect the new state.
                    self!.collectionView.reloadSections(IndexSet(integer: indexPath.section))
                }
                
                return header
                
            }
            else if kind == ThumbnailViewController.sectionFooterElementKind {
                if let footer = collectionView.makeSupplementaryView(
                    ofKind: kind,
                    withIdentifier: NSUserInterfaceItemIdentifier("SectionFooter"),
                    for: indexPath) as? SectionFooter {
                    
                    footer.configure(for: document, at: indexPath,
                                     isSelected: document.selectedSections.contains(indexPath.section))
                    return footer
                }
            }
            fatalError("Cannot create new supplementary view of kind: \(kind)")
        }
   
        
    }
    
    func updateUI(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<PDFPageSectionModel, PDFPageItemModel>()
        let secs = document.pageSections
        secs.forEach {
            snapshot.appendSections([$0])
            snapshot.appendItems($0.pageItems)
        }
        dataSource.apply(snapshot, animatingDifferences: animated)
        
        print("ThumbnailViewController pdateUI indexPaths ", collectionView.selectionIndexPaths, " prax: ", document.selectedPageItems )
        
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
  
        scheduleDebouncedSelectionUpdate()
        
//        document.selectedPageItems = collectionView.selectionIndexPaths
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>){
        print("ThumbnailViewController didDeselectItemsAt indexPaths ", indexPaths)
        
        scheduleDebouncedSelectionUpdate()
        
//        document.selectedPageItems = collectionView.selectionIndexPaths
    }
    
    private func scheduleDebouncedSelectionUpdate(delay: TimeInterval = 0.05) {
        // Cancel any in-flight update
        pendingSelectionUpdate?.cancel()
        
        // Create a new work item that applies the final selection
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            // Snapshot the final selection after deselect/select pair completes
            let finalSelection = self.collectionView.selectionIndexPaths
            self.document.selectedPageItems = finalSelection
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .praxSelectedPageItemsChanged, object: finalSelection, userInfo: ["praxLady": "Juliette M. Belanger"])
            }

        }
        
        pendingSelectionUpdate = work
        
        // Schedule on main queue with a short delay to coalesce deselect/select
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
    
}



#Preview {
    
  //  ThumbnailViewController(coder: <#NSCoder#>)
    
}

