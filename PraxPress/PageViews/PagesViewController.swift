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



final class DualCollectionViewController: NSViewController, NSCollectionViewDelegate {
    @IBOutlet weak var leftCollectionView: NSCollectionView!
    @IBOutlet weak var rightCollectionView: NSCollectionView!

    private var leftDataSource: NSCollectionViewDiffableDataSource<PDFPageSectionModel, PDFPageItemModel>!
    private var rightDataSource: NSCollectionViewDiffableDataSource<PDFPageSectionModel, PDFPageItemModel>!

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
    
     
    override func viewDidLoad() {
        super.viewDidLoad()
        configure(leftCollectionView, into: &leftDataSource, kind: .pageItem)
        configure(rightCollectionView, into: &rightDataSource, kind: .pageEdit)
        applySnapshotToBoth(animated: false)
        observeModelChanges()
    }

    private func configure(_ collectionView: NSCollectionView,
                           into dataSource: inout NSCollectionViewDiffableDataSource<PDFPageSectionModel, PDFPageItemModel>!,
                           kind: CollectionElementKindCase) {
        // 1) register items/supplementaries
        collectionView.register(CollectionViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier("Cell"))
        collectionView.register(CollectionSupplementaryView.self,
                                forSupplementaryViewOfKind: CollectionViewItem.sectionHeaderElementKind,
                                withIdentifier: NSUserInterfaceItemIdentifier("Header"))
        collectionView.register(CollectionSupplementaryView.self,
                                forSupplementaryViewOfKind: CollectionViewItem.sectionFooterElementKind,
                                withIdentifier: NSUserInterfaceItemIdentifier("Footer"))
        // 2) layout
        collectionView.collectionViewLayout = makeLayout(for: kind)
        // 3) data source
        dataSource = NSCollectionViewDiffableDataSource(collectionView: collectionView) { cv, indexPath, item in
            guard let cell = cv.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("Cell"), for: indexPath) as? CollectionViewItem else { return nil }
            switch kind {
            case .pageItem: cell.configure(kind: .thumbnail(item: item), isSelected: cv.selectionIndexPaths.contains(indexPath))
            case .pageEdit: cell.configure(kind: .page(item: item), isSelected: cv.selectionIndexPaths.contains(indexPath))
            }
            return cell
        }

        dataSource.supplementaryViewProvider = { [weak self] cv, kindString, indexPath in
            guard let self else { return nil }
            if kindString == CollectionViewItem.sectionHeaderElementKind {
                let v = cv.makeSupplementaryView(ofKind: kindString,
                                                 withIdentifier: NSUserInterfaceItemIdentifier("Header"),
                                                 for: indexPath) as! CollectionSupplementaryView
                v.configure(kind: .header(item: self.document.pageSections[indexPath.section]),
                            isSelected: self.prax.selectedSections.contains(indexPath.section))
                return v
            } else if kindString == CollectionViewItem.sectionFooterElementKind {
                let v = cv.makeSupplementaryView(ofKind: kindString,
                                                 withIdentifier: NSUserInterfaceItemIdentifier("Footer"),
                                                 for: indexPath) as! CollectionSupplementaryView
                v.configure(kind: .footer(item: self.document.pageSections[indexPath.section]),
                            isSelected: self.prax.selectedSections.contains(indexPath.section))
                return v
            }
            return nil
        }

        collectionView.delegate = self
    }

    private func applySnapshotToBoth(animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<PDFPageSectionModel, PDFPageItemModel>()
        document.pageSections.forEach {
            snapshot.appendSections([$0])
            snapshot.appendItems($0.pageItems)
        }
        leftDataSource.apply(snapshot, animatingDifferences: animated)
        rightDataSource.apply(snapshot, animatingDifferences: animated)
    }

    // Keep selection in sync by writing to prax, then reflecting
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        prax.selectedPageItems = collectionView.selectionIndexPaths
        syncSelectionAcrossCollections(source: collectionView)
    }
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        prax.selectedPageItems = collectionView.selectionIndexPaths
        syncSelectionAcrossCollections(source: collectionView)
    }

    private func syncSelectionAcrossCollections(source: NSCollectionView) {
        let target = (source === leftCollectionView) ? rightCollectionView! : leftCollectionView!
        target.selectionIndexPaths = prax.selectedPageItems
    }

    private func observeModelChanges() {
        // observe document changes -> applySnapshotToBoth(animated: true)
        // observe prax.selectedPageItems -> update both collectionView.selectionIndexPaths
    }

    private enum CollectionElementKindCase { case pageItem, pageEdit }
    private func makeLayout(for kind: CollectionElementKindCase) -> NSCollectionViewLayout {
        switch (kind) {
        case .pageItem:
            return createPageItemLayout()
        case .pageEdit:
            return createPageEditLayout()
            
        }
    }
    
    
    private func createPageItemLayout() -> NSCollectionViewLayout {
        
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
            
 
            let sectionBackground = NSCollectionLayoutDecorationItem.background(elementKind: CollectionViewItem.sectionBackgroundElementKind)
            
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(0.5))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            
      //      group.contentInsets = NSDirectionalEdgeInsets(top: 30, leading: 30, bottom: 30, trailing: 30)
            
            let section = NSCollectionLayoutSection(group: group)
     //       section.interGroupSpacing = 5
     //       section.contentInsets = NSDirectionalEdgeInsets(top: 40, leading: 40, bottom: 40, trailing: 40)
     //       section.supplementariesFollowContentInsets = false
            
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                    heightDimension: .absolute(50))
            
            let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),                                                        heightDimension: .absolute(50))
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: CollectionViewItem.sectionHeaderElementKind,
                alignment: .top,)
           sectionHeader.extendsBoundary = true
           let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: footerSize,
                elementKind: CollectionViewItem.sectionFooterElementKind,
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
       
        layout.register(CollectionSupplementaryView.self, forDecorationViewOfKind: CollectionViewItem.sectionBackgroundElementKind)
        
        return layout
        
    }
    
    private func createPageEditLayout() -> NSCollectionViewLayout {
        
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
            
 
            let sectionBackground = NSCollectionLayoutDecorationItem.background(elementKind: CollectionViewItem.sectionBackgroundElementKind)
            
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(0.5))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            
      //      group.contentInsets = NSDirectionalEdgeInsets(top: 30, leading: 30, bottom: 30, trailing: 30)
            
            let section = NSCollectionLayoutSection(group: group)
     //       section.interGroupSpacing = 5
     //       section.contentInsets = NSDirectionalEdgeInsets(top: 40, leading: 40, bottom: 40, trailing: 40)
     //       section.supplementariesFollowContentInsets = false
            
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                    heightDimension: .absolute(50))
            
            let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),                                                        heightDimension: .absolute(50))
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: CollectionViewItem.sectionHeaderElementKind,
                alignment: .top,)
           sectionHeader.extendsBoundary = true
           let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: footerSize,
                elementKind: CollectionViewItem.sectionFooterElementKind,
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
       
        layout.register(CollectionSupplementaryView.self, forDecorationViewOfKind: CollectionViewItem.sectionBackgroundElementKind)
        
        return layout
        
    }

    
}


class PagesViewController: NSViewController, NSCollectionViewDelegate {
    let document: MergedPDFDocument
    let prax: PraxModel
    
    init(_ document: MergedPDFDocument, _ praxModel: PraxModel) {
        self.document = document
        self.prax = praxModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBOutlet weak var collectionView: NSCollectionView!
    
    private var dataSource: NSCollectionViewDiffableDataSource<PDFPageSectionModel, PDFPageItemModel>! = nil
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
        
/*        observeDocumentChange = Task {
            for await _ in Observations({ self.document.pageSections }) {
                print("PagesViewController observeDocumentChange  ") //, document.pageSections)
                updateUI()
            }
        }
 */
        observeCurrentIndexChange = Task {
            
            for await _ in Observations({ self.prax.selectedPageItems }) {
                print("PagesViewController observeCurrentIndexChange  ", self.prax.selectedPageItems)
                await MainActor.run {
                    self.safelyScrollTo(self.prax.selectedPageItems, animated: true)
                }
            }
            
  /*          for await _ in Observations({ self.document.selectedPageItems }) {
                print("PagesViewController observeCurrentIndexChange  ", self.document.selectedPageItems)
 
                await NSAnimationContext.runAnimationGroup { context in
                    // Optional: set duration or timing function
                    context.duration = 0.8
                    context.allowsImplicitAnimation = true
                    
                    // Call through the animator() proxy
                    collectionView.animator().scrollToItems(at: self.document.selectedPageItems, scrollPosition: .top)
                }
                
                
              *  if let firstIndexPath = PraxModel.shared.selectedPageItems.first {
                    if PraxModel.shared.editingPDFDocument.pageCount > firstIndexPath.item {
                        PraxModel.shared.editingPDFView.go(to: PraxModel.shared.editingPDFDocument.page(at: (firstIndexPath.item))!)
                        
                    }
                } */
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
        collectionView.register(CollectionViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier("PageItem"))
        collectionView.register(CollectionSupplementaryView.self, forSupplementaryViewOfKind: CollectionViewItem.sectionHeaderElementKind, withIdentifier: NSUserInterfaceItemIdentifier("SectionHeader"))
        collectionView.register(CollectionSupplementaryView.self, forSupplementaryViewOfKind: CollectionViewItem.sectionFooterElementKind, withIdentifier: NSUserInterfaceItemIdentifier("SectionFooter"))
         
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
        dataSource = NSCollectionViewDiffableDataSource<PDFPageSectionModel, PDFPageItemModel>(collectionView: collectionView) {
            (collectionView: NSCollectionView, indexPath: IndexPath, pdfPageItem: PDFPageItemModel) -> NSCollectionViewItem? in
            guard let collectionViewItem = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("PageItem"), for: indexPath) as? CollectionViewItem else { return nil }
            collectionViewItem.configure(kind: .page(item: pdfPageItem), isSelected: collectionView.selectionIndexPaths.contains(indexPath))
            
            return collectionViewItem
        }
        dataSource.supplementaryViewProvider = { [weak self]
            (collectionView: NSCollectionView, kind: String, indexPath: IndexPath) -> (NSView & NSCollectionViewElement)? in
            guard let self else { return nil }
            
            // Ensure section index is valid for current model snapshot
            let pageSections = document.pageSections
            guard indexPath.section >= 0 && indexPath.section < pageSections.count else {
                // The layout asked for a view that doesn’t match current state; return nil safely.
                return nil
            }
            
            if kind == CollectionViewItem.sectionHeaderElementKind {
                guard let supplementaryView = collectionView.makeSupplementaryView(
                    ofKind: kind,
                    withIdentifier: NSUserInterfaceItemIdentifier("SectionHeader"),
                    for: indexPath) as? CollectionSupplementaryView else { return nil }
                
                //               header.label.stringValue = document.sections[indexPath.section].title
                supplementaryView.configure(kind: .header(item: document.pageSections[indexPath.section]), isSelected: prax.selectedSections.contains(indexPath.section))
                
                supplementaryView.onToggleSelection = { [weak self] in
                    guard let self else { return }
                    if prax.selectedSections.contains(indexPath.section) {
                        prax.selectedSections.remove(indexPath.section)
                    } else {
                        prax.selectedSections.insert(indexPath.section)
                    }
                    // Refresh just this section’s header to reflect the new state.
                    self.collectionView.reloadSections(IndexSet(integer: indexPath.section))
                }
                
                return supplementaryView
                
            }
            else if kind == CollectionViewItem.sectionFooterElementKind {
                if let supplementaryView = collectionView.makeSupplementaryView(
                    ofKind: kind,
                    withIdentifier: NSUserInterfaceItemIdentifier("SectionFooter"),
                    for: indexPath) as? CollectionSupplementaryView {
                    
                    supplementaryView.configure(kind: .footer(item: document.pageSections[indexPath.section]), isSelected: prax.selectedSections.contains(indexPath.section))
                    
                    return supplementaryView
                }
            }
            fatalError("Cannot create new supplementary view of kind: \(kind)")
        }
    }
    
     func updateUI(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<PDFPageSectionModel, PDFPageItemModel>()
         let pdfPageSections = document.pageSections
         pdfPageSections.forEach {
            snapshot.appendSections([$0])
            snapshot.appendItems($0.pageItems)
        }
        dataSource.apply(snapshot, animatingDifferences: animated)
        
         print("PagesViewController pdateUI indexPaths ", collectionView.selectionIndexPaths, " prax: ", prax.selectedPageItems )
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.collectionView.selectionIndexPaths.isEmpty,
               let firstSection = pdfPageSections.first,
               !firstSection.pageItems.isEmpty {
                let firstIndexPath = IndexPath(item: 0, section: 0)
                self.collectionView.selectionIndexPaths = [firstIndexPath]
                self.safelyScrollTo([firstIndexPath], animated: false)
                prax.selectedPageItems = self.collectionView.selectionIndexPaths
            }
            print("DispatchQueue PagesViewController pdateUI indexPaths ", collectionView.selectionIndexPaths, " prax: ", prax.selectedPageItems )
        }
        
        
    }
    
    func safelyScrollTo(_ indexPaths: Set<IndexPath>, animated: Bool) {
        guard isViewLoaded,
              view.window != nil,
              collectionView.superview != nil,
              collectionView.enclosingScrollView != nil,
              collectionView.enclosingScrollView?.contentView != nil,
              !indexPaths.isEmpty
        else {
            print("PagesViewController safelyScrollTo failed isViewLoaded, etc.")
            return }
        
        collectionView.layoutSubtreeIfNeeded()
        
        guard collectionView.bounds.size.width > 0 && collectionView.bounds.size.height > 0 else {
            print("PagesViewController safelyScrollTo failed collectionView.bounds.size")
            return
        }
        
        for indexPath in indexPaths {
            if collectionView.layoutAttributesForItem(at: indexPath) == nil {
                print("PagesViewController safelyScrollTo failed layoutAttributesForItem(at: ", indexPath)
                    // The layout doesn’t currently know this item (e.g., snapshot not applied yet)
                return
            }
        }

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.8
                context.allowsImplicitAnimation = true
                collectionView.animator().scrollToItems(at: indexPaths, scrollPosition: .top)
            }
        } else {
            collectionView.scrollToItems(at: indexPaths, scrollPosition: .top)
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>){
        print("PagesViewController didSelectItemsAt indexPaths ", indexPaths)
        
        prax.selectedPageItems = collectionView.selectionIndexPaths
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>){
        print("PagesViewController didDeselectItemsAt indexPaths ", indexPaths)
        prax.selectedPageItems = collectionView.selectionIndexPaths
    }
    
    
    
}

#Preview {
 
//    PagesViewController()
    
}

