//  DocumentEditingView.swift
//  PraxPress - Prax=0104-1
//
//


import SwiftUI
import PDFKit
import AppKit
//import Combine
import UniformTypeIdentifiers


struct DocumentEditingView: NSViewRepresentable {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    
    func makeCoordinator() -> DocumentEditingViewCoordinator {
        let svd = SplitViewDelegate(prax: praxModel)
        return DocumentEditingViewCoordinator(document: document, prax: praxModel, splitViewDelegate: svd)
    }

    func makeNSView(context: Context) -> NSSplitView {
        
        // Split view
        let splitView = NSSplitView()
        praxModel.splitView = splitView
        context.coordinator.splitViewDelegate.splitView = splitView
        splitView.delegate = context.coordinator.splitViewDelegate
        context.coordinator.splitView = splitView
        splitView.isVertical = true
        splitView.dividerStyle = .paneSplitter
        splitView.translatesAutoresizingMaskIntoConstraints = false

        // Left: Scroll + Collection
        let pageItemScrollView = NSScrollView()
        pageItemScrollView.translatesAutoresizingMaskIntoConstraints = false
        pageItemScrollView.hasVerticalScroller = true
        pageItemScrollView.hasHorizontalScroller = false

        let pageItemCollectionView = NSCollectionView()
        pageItemCollectionView.translatesAutoresizingMaskIntoConstraints = false
        pageItemCollectionView.backgroundColors = [.clear]
        pageItemCollectionView.isSelectable = true
        pageItemCollectionView.allowsEmptySelection = true
        pageItemCollectionView.allowsMultipleSelection = true
        pageItemCollectionView.delegate = context.coordinator
        pageItemScrollView.documentView = pageItemCollectionView
        
        // Left: Scroll + Collection
        let pageEditScrollView = NSScrollView()
        pageEditScrollView.translatesAutoresizingMaskIntoConstraints = false
        pageEditScrollView.hasVerticalScroller = true
        pageEditScrollView.hasHorizontalScroller = false

        let pageEditCollectionView = NSCollectionView()
        pageEditCollectionView.translatesAutoresizingMaskIntoConstraints = false
        pageEditCollectionView.backgroundColors = [.clear]
        pageEditCollectionView.isSelectable = true
        pageEditCollectionView.allowsEmptySelection = true
        pageEditCollectionView.allowsMultipleSelection = true
        pageEditCollectionView.delegate = context.coordinator
        pageEditScrollView.documentView = pageEditCollectionView

        // Right: Scroll + Collection
        let mergedPageScrollView = NSScrollView()
        mergedPageScrollView.translatesAutoresizingMaskIntoConstraints = false
        mergedPageScrollView.hasVerticalScroller = true
        mergedPageScrollView.hasHorizontalScroller = false

        let mergedPageCollectionView = NSCollectionView()
        mergedPageCollectionView.translatesAutoresizingMaskIntoConstraints = false
        mergedPageCollectionView.backgroundColors = [.clear]
        mergedPageCollectionView.isSelectable = true
        mergedPageCollectionView.allowsEmptySelection = true
        mergedPageCollectionView.allowsMultipleSelection = true
        mergedPageCollectionView.delegate = context.coordinator
        mergedPageScrollView.documentView = mergedPageCollectionView

        // Attach both scroll views to split view
        splitView.arrangesAllSubviews = true
        splitView.addArrangedSubview(pageItemScrollView)
        splitView.addArrangedSubview(pageEditScrollView)
        splitView.addArrangedSubview(mergedPageScrollView)
  //      splitView.setHoldingPriority(.defaultHigh, forSubviewAt: 0)
  //      splitView.setHoldingPriority(.defaultLow, forSubviewAt: 1)
  //      splitView.setHoldingPriority(.defaultHigh, forSubviewAt: 2)
        
        // Store references on the coordinator
        context.coordinator.pageItemCollectionView = pageItemCollectionView
        context.coordinator.pageItemScrollView = pageItemScrollView
        context.coordinator.pageEditCollectionView = pageEditCollectionView
        context.coordinator.pageEditScrollView = pageEditScrollView
        context.coordinator.mergedPageCollectionView = mergedPageCollectionView
        context.coordinator.mergedPageScrollView = mergedPageScrollView

        // Configure collection views: layout, registration, data sources
        context.coordinator.configure(collectionView: pageItemCollectionView, kind: .pageItem)
        context.coordinator.configure(collectionView: pageEditCollectionView, kind: .pageEdit)
        context.coordinator.configure(collectionView: mergedPageCollectionView, kind: .mergedPage)

        // Apply initial snapshot to both
        context.coordinator.applySnapshot(animated: false)

        // Initial divider position
        DispatchQueue.main.async {
            print("DocumentEditingView - plitView.setPosition(150, ofDividerAt: 0)")
            splitView.setPosition(150, ofDividerAt: 0)
            splitView.setPosition(250, ofDividerAt: 1)
        }

        return splitView
    }

    func updateNSView(_ splitView: NSSplitView, context: Context) {
        print("DocumentEditingView - updateNSView - context.coordinator.applySnapshot(animated: true)")
        context.coordinator.applySnapshot(animated: true)
    }

    final class DocumentEditingViewCoordinator: NSObject, NSSplitViewDelegate, NSCollectionViewDelegate {
        // Shared model
        private let document: MergedPDFDocument
        private let prax: PraxModel
        let splitViewDelegate: SplitViewDelegate
        
        // Views
        weak var splitView: NSSplitView?
        weak var pageItemCollectionView: NSCollectionView?
        weak var pageEditCollectionView: NSCollectionView?
        weak var mergedPageCollectionView: NSCollectionView?
        weak var pageItemScrollView: NSScrollView?
        weak var pageEditScrollView: NSScrollView?
        weak var mergedPageScrollView: NSScrollView?

        // Data sources
        private var leftDataSource: NSCollectionViewDiffableDataSource<MergedPage, PageItem>!
        private var centerDataSource: NSCollectionViewDiffableDataSource<MergedPage, PageItem>!
        private var rightDataSource: NSCollectionViewDiffableDataSource<MergedPage, PageItem>!

        init(document: MergedPDFDocument, prax: PraxModel, splitViewDelegate: SplitViewDelegate) {
            self.document = document
            self.prax = prax
            self.splitViewDelegate = splitViewDelegate
        }
        
        enum CollectionKind { case pageItem, pageEdit, mergedPage }

        // Configure one collection view (layout, registration, data source)
        func configure(collectionView: NSCollectionView, kind: CollectionKind) {
            // Layout
            collectionView.collectionViewLayout = makeLayout(for: kind)

            // Register unified item/supplementaries
            collectionView.register(
                CollectionViewItem.self,
                forItemWithIdentifier: NSUserInterfaceItemIdentifier("Cell")
            )
            if kind == .mergedPage {
                collectionView.register(
                    CollectionSupplementaryView.self,
                    forSupplementaryViewOfKind: CollectionViewItem.mergedPageHeaderElementKind,
                    withIdentifier: NSUserInterfaceItemIdentifier("Merged-Header")
                )
                collectionView.register(
                    CollectionSupplementaryView.self,
                    forSupplementaryViewOfKind: CollectionViewItem.mergedPageFooterElementKind,
                    withIdentifier: NSUserInterfaceItemIdentifier("Merged-Footer")
                )
            }
            else {
                collectionView.register(
                    CollectionSupplementaryView.self,
                    forSupplementaryViewOfKind: CollectionViewItem.sectionHeaderElementKind,
                    withIdentifier: NSUserInterfaceItemIdentifier("Header")
                )
                collectionView.register(
                    CollectionSupplementaryView.self,
                    forSupplementaryViewOfKind: CollectionViewItem.sectionFooterElementKind,
                    withIdentifier: NSUserInterfaceItemIdentifier("Footer")
                )
            }
            



            // Optional background
            collectionView.backgroundView = CollectionViewBackground()

            // Drag & drop (optional)
            collectionView.registerForDraggedTypes([
                .fileURL,
                .pdfPageDragType,
                .mergedPageType,
                .pdfFileType
            ])

            // Data source
            let dataSource = NSCollectionViewDiffableDataSource<MergedPage, PageItem>(
                collectionView: collectionView
            ) {cv, indexPath, item in
                guard let cell = cv.makeItem(
                    withIdentifier: NSUserInterfaceItemIdentifier("Cell"),
                    for: indexPath
                ) as? CollectionViewItem else { return nil }

                let isSelected = cv.selectionIndexPaths.contains(indexPath)
                switch kind {
                case .pageItem:
                    cell.configure(kind: .thumbnail(item: item), isSelected: isSelected)
                case .pageEdit:
                    cell.configure(kind: .page(item: item), isSelected: isSelected)
                case .mergedPage:
                    cell.configure(kind: .mergedPage(item: item), isSelected: isSelected)
                }
                return cell
            }

            dataSource.supplementaryViewProvider = { [weak self] cv, kindString, indexPath in
                guard let self = self else { return nil }
                let sections = self.document.pageSections
                guard indexPath.section >= 0, indexPath.section < sections.count else { return nil }

                
                if kindString == CollectionViewItem.mergedPageHeaderElementKind {
                    let v = cv.makeSupplementaryView(
                        ofKind: kindString,
                        withIdentifier: NSUserInterfaceItemIdentifier("Merged-Header"),
                        for: indexPath
                    ) as! CollectionSupplementaryView
                    v.configure(
                        kind: .mergedPageHeader(item: sections[indexPath.section]),
                        isSelected: self.prax.selectedSections.contains(indexPath.section)
                    )
                    return v
                }
                else if kindString == CollectionViewItem.sectionHeaderElementKind {
                    let v = cv.makeSupplementaryView(
                        ofKind: kindString,
                        withIdentifier: NSUserInterfaceItemIdentifier("Header"),
                        for: indexPath
                    ) as! CollectionSupplementaryView
                    v.configure(
                        kind: .header(item: sections[indexPath.section]),
                        isSelected: self.prax.selectedSections.contains(indexPath.section)
                    )
                    return v
                }
                else if kindString == CollectionViewItem.mergedPageFooterElementKind {
                    let v = cv.makeSupplementaryView(
                        ofKind: kindString,
                        withIdentifier: NSUserInterfaceItemIdentifier("Merged-Footer"),
                        for: indexPath
                    ) as! CollectionSupplementaryView
                    v.configure(
                        kind: .mergedPageFooter(item: sections[indexPath.section]),
                        isSelected: self.prax.selectedSections.contains(indexPath.section)
                    )
                    return v
                }
                else if kindString == CollectionViewItem.sectionFooterElementKind {
                    let v = cv.makeSupplementaryView(
                        ofKind: kindString,
                        withIdentifier: NSUserInterfaceItemIdentifier("Footer"),
                        for: indexPath
                    ) as! CollectionSupplementaryView
                    v.configure(
                        kind: .footer(item: sections[indexPath.section]),
                        isSelected: self.prax.selectedSections.contains(indexPath.section)
                    )
                    return v
                }
                return nil
            }

            switch kind {
            case .pageItem:
                self.leftDataSource = dataSource
            case .pageEdit:
                self.centerDataSource = dataSource
            case .mergedPage:
                self.rightDataSource = dataSource
            }
        }
        
        struct LayoutSettings {
            var itemWidth: NSCollectionLayoutDimension = .fractionalWidth(1.0)
            var itemHeight: NSCollectionLayoutDimension = .fractionalWidth(1.0)
            var groupWidth: NSCollectionLayoutDimension = .fractionalWidth(1.0)
            var groupHeight: NSCollectionLayoutDimension = .fractionalWidth(1.0)
            var headerKind: String?
            var footerKind: String?
            var backgroundKind: String?
            var headerWidth: NSCollectionLayoutDimension = .fractionalWidth(1.0)
            var headerHeight: NSCollectionLayoutDimension = .absolute(20)
            var footerWidth: NSCollectionLayoutDimension = .fractionalWidth(1.0)
            var footerHeight: NSCollectionLayoutDimension = .absolute(20)
            var itemContentInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            var itemEdgeSpacing: NSCollectionLayoutEdgeSpacing = NSCollectionLayoutEdgeSpacing(leading: nil, top: nil, trailing: nil, bottom: nil)
            
        }
        // Build appropriate compositional layout per side
        private func makeLayout(for kind: CollectionKind) -> NSCollectionViewLayout {
            var layoutSettings = LayoutSettings()
            switch kind {
            case .pageItem:
                layoutSettings.itemHeight = .fractionalWidth(1.0)
                layoutSettings.groupHeight = .fractionalWidth(1.0)
                layoutSettings.headerKind = CollectionViewItem.sectionHeaderElementKind
                layoutSettings.footerKind = CollectionViewItem.sectionFooterElementKind
                layoutSettings.backgroundKind = CollectionViewItem.sectionBackgroundElementKind
            case .pageEdit:
                layoutSettings.itemHeight = .fractionalWidth(1.0)
                layoutSettings.groupHeight = .fractionalWidth(1.0)
                layoutSettings.headerKind = CollectionViewItem.sectionHeaderElementKind
                layoutSettings.footerKind = CollectionViewItem.sectionFooterElementKind
                layoutSettings.backgroundKind = CollectionViewItem.sectionBackgroundElementKind
            case .mergedPage:
                layoutSettings.itemHeight = .estimated(200)
                layoutSettings.groupHeight = .estimated(200)
                layoutSettings.headerKind = CollectionViewItem.mergedPageHeaderElementKind
                layoutSettings.footerKind = CollectionViewItem.mergedPageFooterElementKind
                layoutSettings.backgroundKind = CollectionViewItem.sectionBackgroundElementKind
            }
            return createLayout(layoutSettings)
        }

        func createLayout(_ layoutSettings: LayoutSettings) -> NSCollectionViewLayout {
            let layout = NSCollectionViewCompositionalLayout {
                (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection in
                
                let itemSize = NSCollectionLayoutSize(widthDimension: layoutSettings.itemWidth, heightDimension: layoutSettings.itemHeight)
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                item.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: .fixed(0), top: nil, trailing: .fixed(0), bottom: .fixed(0))
                
                let groupSize = NSCollectionLayoutSize(widthDimension: layoutSettings.groupWidth, heightDimension: layoutSettings.groupHeight)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                let section = NSCollectionLayoutSection(group: group)
                
                
                section.interGroupSpacing = 20
                section.contentInsets = NSDirectionalEdgeInsets(top: 40, leading: 0, bottom: 0, trailing: 0)
                section.supplementariesFollowContentInsets = true
                
                
                var boundarySupplementaryItems: [NSCollectionLayoutBoundarySupplementaryItem] = []
                if layoutSettings.headerKind != nil {
                    let headerSize = NSCollectionLayoutSize(widthDimension: layoutSettings.headerWidth, heightDimension: layoutSettings.headerHeight)
                    let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: headerSize,
                        elementKind: layoutSettings.headerKind!,
                        alignment: .top,)
                    sectionHeader.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0)
                    sectionHeader.extendsBoundary = false
                    sectionHeader.pinToVisibleBounds = true
                    sectionHeader.zIndex = 2
                    boundarySupplementaryItems.append(sectionHeader)
                }
                if layoutSettings.footerKind != nil {
                    let footerSize = NSCollectionLayoutSize(widthDimension: layoutSettings.footerWidth, heightDimension: layoutSettings.footerHeight)
                    let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(
                         layoutSize: footerSize,
                         elementKind: layoutSettings.footerKind!,
                         alignment: .bottom)
                    sectionFooter.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 40, trailing: 40)
                    sectionFooter.extendsBoundary = true
                    sectionFooter.pinToVisibleBounds = true
                    sectionFooter.zIndex = 2
                    boundarySupplementaryItems.append(sectionFooter)
                }
                if !boundarySupplementaryItems.isEmpty {
                    section.boundarySupplementaryItems = boundarySupplementaryItems
                }
                
                if layoutSettings.backgroundKind != nil {
                    let sectionBackground = NSCollectionLayoutDecorationItem.background(elementKind: CollectionViewItem.sectionBackgroundElementKind)
                    section.decorationItems = [sectionBackground]
                }
                 
         //       section.visibleItemsInvalidationHandler = { visibleItems, scrollOffset, layoutEnvironment in
                    // Perform animations on the visible items.
         //           print("section.visibleItemsInvalidationHandler")
       
                return section
            }
            if layoutSettings.backgroundKind != nil {
                layout.register(CollectionSupplementaryView.self, forDecorationViewOfKind: CollectionViewItem.sectionBackgroundElementKind)
            }
            return layout
        }
        
        
/*
        private func createPageItemLayout() -> NSCollectionViewLayout {
            
            let layout = NSCollectionViewCompositionalLayout {
                (sectionIndex: Int,
                 layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection in
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .fractionalWidth(0.5))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
/*
                item.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 2, bottom: 20, trailing: 2)
                item.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: .fixed(0), top: .fixed(0), trailing: .fixed(0), bottom: .fixed(0))
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 0)
                item.edgeSpacing = NSCollectionLayoutEdgeSpacing(
                    leading: nil,
                    top: nil,
                    trailing: .fixed(0),
                    bottom: nil
                )
 */
                let sectionBackground = NSCollectionLayoutDecorationItem.background(elementKind: CollectionViewItem.sectionBackgroundElementKind)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(0.5))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
//                group.contentInsets = NSDirectionalEdgeInsets(top: 30, leading: 30, bottom: 30, trailing: 30)
                
                let section = NSCollectionLayoutSection(group: group)
/*
                section.interGroupSpacing = 5
                section.contentInsets = NSDirectionalEdgeInsets(top: 40, leading: 40, bottom: 40, trailing: 40)
                section.supplementariesFollowContentInsets = false
*/
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
                let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
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
/*
               section.visibleItemsInvalidationHandler = { visibleItems, scrollOffset, layoutEnvironment in
                    // Perform animations on the visible items.
                    print("section.visibleItemsInvalidationHandler")
                }
*/
                sectionHeader.pinToVisibleBounds = true
                sectionHeader.zIndex = 2
                sectionFooter.pinToVisibleBounds = true
                sectionFooter.zIndex = 2
           
                return section
            }
            layout.register(CollectionSupplementaryView.self, forDecorationViewOfKind: CollectionViewItem.sectionBackgroundElementKind)
            return layout
        }
        
        private func createPageEditLayout() -> NSCollectionViewLayout {
            
            let layout = NSCollectionViewCompositionalLayout {
                (sectionIndex: Int,
                 layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection in
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(200))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                item.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 2, bottom: 20, trailing: 2)
                item.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: .fixed(0), top: .fixed(0), trailing: .fixed(0), bottom: .fixed(0))
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 0)
/*
                item.edgeSpacing = NSCollectionLayoutEdgeSpacing(
                    leading: nil,
                    top: nil,
                    trailing: .fixed(0),
                    bottom: nil
                )
 */
                let sectionBackground = NSCollectionLayoutDecorationItem.background(elementKind: CollectionViewItem.sectionBackgroundElementKind)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(200))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
//                group.contentInsets = NSDirectionalEdgeInsets(top: 30, leading: 30, bottom: 30, trailing: 30)
                
                let section = NSCollectionLayoutSection(group: group)
/*
                section.interGroupSpacing = 5
                section.contentInsets = NSDirectionalEdgeInsets(top: 40, leading: 40, bottom: 40, trailing: 40)
                section.supplementariesFollowContentInsets = false
*/
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
                let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
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
                sectionFooter.pinToVisibleBounds = true
                sectionFooter.zIndex = 2
           
                return section
            }
            layout.register(CollectionSupplementaryView.self, forDecorationViewOfKind: CollectionViewItem.sectionBackgroundElementKind)
            return layout
        }

        private func createMergedPageLayout() -> NSCollectionViewLayout {
            
            let layout = NSCollectionViewCompositionalLayout {
                (sectionIndex: Int,
                 layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection in
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(200))
               let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                
                                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                item.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: .fixed(0), top: .fixed(0), trailing: .fixed(0), bottom: .fixed(0))
                                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                                item.edgeSpacing = NSCollectionLayoutEdgeSpacing(
                                    leading: nil,
                                    top: nil,
                                    trailing: .fixed(0),
                                    bottom: nil
                                )
                 
                
               let sectionBackground = NSCollectionLayoutDecorationItem.background(elementKind: CollectionViewItem.sectionBackgroundElementKind)
                
               let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(200))
               let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
               let section = NSCollectionLayoutSection(group: group)
                
                /*
                                section.interGroupSpacing = 5
                                section.contentInsets = NSDirectionalEdgeInsets(top: 40, leading: 40, bottom: 40, trailing: 40)
                                section.supplementariesFollowContentInsets = false
                */
                
               let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(20))
                let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(20))
    
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: CollectionViewItem.mergedPageHeaderElementKind,
                    alignment: .top,)
               sectionHeader.extendsBoundary = true
                
                let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(
                     layoutSize: footerSize,
                     elementKind: CollectionViewItem.mergedPageFooterElementKind,
                     alignment: .bottom)
                 section.boundarySupplementaryItems = [sectionHeader, sectionFooter]
                 section.decorationItems = [sectionBackground]

                
                section.boundarySupplementaryItems = [sectionHeader, sectionFooter]
                
                section.decorationItems = [sectionBackground]
                
         //       section.visibleItemsInvalidationHandler = { visibleItems, scrollOffset, layoutEnvironment in
                    // Perform animations on the visible items.
         //           print("section.visibleItemsInvalidationHandler")
         //       }
        
                sectionHeader.pinToVisibleBounds = true
                sectionHeader.zIndex = 2
                sectionFooter.pinToVisibleBounds = true
                sectionFooter.zIndex = 2
           
                return section
            }
           
            layout.register(CollectionSupplementaryView.self, forDecorationViewOfKind: CollectionViewItem.sectionBackgroundElementKind)
            
            return layout
            
        }
*/
        // Apply the same snapshot to both data sources
        func applySnapshot(animated: Bool) {
            var pageItemSnapshot = NSDiffableDataSourceSnapshot<MergedPage, PageItem>()
            var editPageSnapshot = NSDiffableDataSourceSnapshot<MergedPage, PageItem>()
            var mergedPageSnapshot = NSDiffableDataSourceSnapshot<MergedPage, PageItem>()
            for mergedPage in document.pageSections {
                
                pageItemSnapshot.appendSections([mergedPage])
                pageItemSnapshot.appendItems(mergedPage.pageItems)
                
                editPageSnapshot.appendSections([mergedPage])
                editPageSnapshot.appendItems(mergedPage.pageItems)
                
                
                /*for pageItem in mergedPage.pageItems {
                    if pageItem.merge != .mergeSkip {
                        editPageSnapshot.appendItems([pageItem])
                    }
                }
                */
                
   /*             if mergedPage.mergeModePages > 0 {
                    mergedPageSnapshot.appendSections([mergedPage])
                    mergedPageSnapshot.appendItems([mergedPage.mergedPageItem()])
                }*/
            }
            leftDataSource?.apply(pageItemSnapshot, animatingDifferences: animated)
            centerDataSource?.apply(editPageSnapshot, animatingDifferences: animated)
            rightDataSource?.apply(mergedPageSnapshot, animatingDifferences: animated)
        }

        // MARK: Selection mirroring

        func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
            prax.selectedPageItems = collectionView.selectionIndexPaths
            mirrorSelection(from: collectionView)
        }

        func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
            prax.selectedPageItems = collectionView.selectionIndexPaths
            mirrorSelection(from: collectionView)
        }

        private func mirrorSelection(from source: NSCollectionView) {
            guard let left = pageItemCollectionView, let right = pageEditCollectionView else { return }
            let target = (source === left) ? right : left
            target.selectionIndexPaths = prax.selectedPageItems
        }
        
        func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent
        ) -> Bool {
            print("ThumbnailViewController canDragItemsAt  ", indexPaths, " event ", event)
            return true
        }
        
        func collectionView(_ collectionView: NSCollectionView,
                            pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
            
            print("ThumbnailViewController pasteboardWriterForItemAt  ", indexPath)

            
            //       guard let pageItem = dataSource.itemIdentifier(for: IndexPath(item: indexPath.item, section: 0)) else { return provider }
            
            let typeIdentifier = UTType(filenameExtension: "pdf")
            
            let provider = FilePromiseProvider()
            provider.pdfDocument = document.mergedPDFDocument()
            provider.fileName = "PraxPress-Page.pdf"
            provider.fileType = typeIdentifier!.identifier
            provider.delegate = provider
            // Send out the indexPath and photo's url dictionary.
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: indexPath, requiringSecureCoding: false)
                provider.userInfo = [FilePromiseProvider.UserInfoKeys.urlKey: document.mergedPDFURL as Any,
                                      FilePromiseProvider.UserInfoKeys.indexPathKey: data]
            } catch {
                fatalError("failed to archive indexPath to pasteboard")
            }
            return provider
        }
    
        func collectionView(
            _ collectionView: NSCollectionView, validateDrop draggingInfo: any NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>
        ) -> NSDragOperation {
            
                 let indexPath = proposedDropIndexPath.pointee
             
            if prax.optionKeyPressed {
                print("ThumbnailViewController validateDrop [.copy]  ", indexPath)
               return [.copy]

            }
            else {
                print("ThumbnailViewController validateDrop [.move]  ", indexPath)
                return [.move]

            }
        }
                 
        func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
            print("ThumbnailViewController acceptDrop  ", indexPath.item)
            
            guard let draggingTypes = draggingInfo.draggingPasteboard.types else { return false }
            
            if draggingTypes.contains(.pdfPageDragType) {
                dropInternalPages(collectionView, draggingInfo: draggingInfo, indexPath: indexPath)
            }
            else if draggingTypes.contains(.mergedPageType) {
                dropInternalSections(collectionView, draggingInfo: draggingInfo, indexPath: indexPath)
            }
            else if draggingTypes.contains(.pdfFileType) {
                dropPDFFiles(collectionView, draggingInfo: draggingInfo, indexPath: indexPath)
            }

            else {
                // The drop source is from another app (Finder, Mail, Safari, etc.) and there may be more than one file.
                // Drop each dragged image file to their new place.
                dropExternalPages(draggingInfo: draggingInfo, indexPath: indexPath)
            }
            return true
        }
        
        func dropExternalPages(draggingInfo: NSDraggingInfo, indexPath: IndexPath) {
            let pasteboard = draggingInfo.draggingPasteboard
            let receivers = pasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self], options: nil) as? [NSFilePromiseReceiver] ?? []
            if !receivers.isEmpty {
                receivePromisedPDFs(from: receivers, at: indexPath)
                return
            }

            var droppedURLs: [URL] = []
            
            // 1) Prefer file URLs if available
            if let items = pasteboard.pasteboardItems {
     
                for item in items {
                    
                    // Try public.file-url first
                    if let urlString = item.string(forType: .fileURL),
                       let url = URL(string: urlString) {
                        print("fileURL  ", url)
                        droppedURLs.append(url)
                        continue
                        
                    }

                    for type in item.types {
                        print("\npasteboard item type:  \(type)  \nString:  ", item.string(forType: type) ?? "nil")
                        
                        if let data = item.data(forType: type) {
                            print("data:  ", data.debugDescription)
                            // Create a temporary file to hold this PDF data
                            let tempURL = FileManager.default.temporaryDirectory
                                .appendingPathComponent(UUID().uuidString)
                                .appendingPathExtension("\(type)")
                            do {
                                try data.write(to: tempURL, options: .atomic)
                                droppedURLs.append(tempURL)
                            } catch {
                                Swift.debugPrint("Failed to write dropped PDFPage data to temp file: \(tempURL) - Error: \(error)")
                            }
                        }
                        
                        if let propertyList = item.propertyList(forType: type) {
                            
                            print("propertyList:  ", propertyList)
                            
                            if let string = propertyList as? String {
                                print ("propertyList as String: \(string)")
                            }
                            else if let array = propertyList as? [String] {
                                print ("propertyList as String array: \(array)")
                            }
                            else {
                                print ("propertyList as something else: \(propertyList)")
                            }
                        }
                        
                    }

                }
            }
            
       //     print (pdfURLs)

            
            // 2) Fallback: read URLs from the general property list if present
            if droppedURLs.isEmpty, let propertyList = pasteboard.propertyList(forType: .fileURL) {
                // propertyList can be a String or array of Strings (file URL strings)
                func parseURLStrings(_ value: Any) -> [URL] {
                    var urls: [URL] = []
                    if let s = value as? String, let u = URL(string: s) { urls.append(u) }
                    else if let arr = value as? [String] {
                        urls.append(contentsOf: arr.compactMap { URL(string: $0) })
                    }
                    return urls
                }
                droppedURLs = parseURLStrings(propertyList)
            }
            
            for url in droppedURLs {
                print ("\n\(url)")
            }
      
            fatalError()
    /*
            // 3) Filter for PDFs (by path extension or UTI check)
            let pdfURLs = droppedURLs.filter { $0.pathExtension.lowercased() == "pdf" }
            self.insertPDFPageItemsFromDocumentURLS(pdfURLs, at: indexPath)
            
            let imageFileExtensions = ["png", "jpeg", "jpg", "gif", "heic"]
            let imageURLs = droppedURLs.filter { imageFileExtensions.contains( $0.pathExtension.lowercased()) }
            if prax.optionKeyPressed {
                self.insertPDFPageSectionsFromImageURLS(imageURLs, at: indexPath)

            }
            else {
                self.insertPDFPageItemsFromImageURLS(imageURLs, at: indexPath)

            }
            
    */
            
            /*
     
            guard candidateURLs.isNotEmpty else {
                Swift.debugPrint("No PDF URLs found in external drop.")
                return
            }
            
            // 4) Build PDFDocuments and insert pages at the drop position
            var insertionIndex = indexPath.item
            for url in candidateURLs {
                guard let document = PDFDocument(url: url) else {
                    Swift.debugPrint("Failed to open PDF at url: \(url)")
                    continue
                }
                
                // Insert each page from the external document into the model
                let pageCount = document.pageCount
                var pagesToInsert: [PDFPage] = []
                pagesToInsert.reserveCapacity(pageCount)
                
                for i in 0..<pageCount {
                    if let page = document.page(at: i) {
                        pagesToInsert.append(page)
                    }
                }
                
                // If PraxModel has an API for inserting pages, call it here.
                // Example approach A: If there’s a method to insert PDFPages directly:
                // PraxModel.shared.insertPDFPages(pagesToInsert, at: insertionIndex)
                
                // Example approach B: If PraxModel works with a single PDFDocument, we can merge:
                if let targetDoc = PraxModel.shared.editingPDFDocument {
                    // Insert each page into the current working document
                    for page in pagesToInsert {
                        // PDFKit allows inserting a page into a document at an index
                        targetDoc.insert(page, at: insertionIndex)
                        insertionIndex += 1
                    }
                } else {
                    // If no working document exists, you might set it to the first dropped doc
                    PraxModel.shared.editingPDFDocument = PDFDocument()
                    if let targetDoc = PraxModel.shared.editingPDFDocument {
                        for page in pagesToInsert {
                            targetDoc.insert(page, at: insertionIndex)
                            insertionIndex += 1
                        }
                    }
                }

        */
            
            
            
            
        }
        
        // MARK: - File promise handling
        
        private func receivePromisedPDFs(from receivers: [NSFilePromiseReceiver], at indexPath: IndexPath) {
            // Create a temp directory for the incoming promised files
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("PraxDrop-\(UUID().uuidString)")
            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Swift.debugPrint("Failed to create temp directory for promised files: \(error)")
                return
            }
            
            var receivedURLs: [URL] = []
            let group = DispatchGroup()
            
            for receiver in receivers {
                group.enter()
                // You can use the promised file type to pick an extension; Acrobat advertises com.adobe.pdf
                receiver.receivePromisedFiles(atDestination: tempDir, options: [:], operationQueue: .main) { fileURL, error in
                    if let error {
                        Swift.debugPrint("Failed to receive promised file: \(error)")
                    } else {
                        print("Received promised file: \(fileURL)")
                        receivedURLs.append(fileURL)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                let urls = receivedURLs.filter { $0.pathExtension.lowercased() == "pdf" }
                guard !urls.isEmpty else {
                    Swift.debugPrint("No promised PDF files received.")
                    return
                }
                
                print (urls)
      fatalError()
    //           self.insertPDFPageItemsFromDocumentURLS(urls, at: indexPath)
                
      //          self.insertPDFs(at: pdfs, dropIndex: indexPath.item)
    //            self.updateUI()
            }
        }

        // MARK: - Insert helper
            
        /*    func insertPDFPageSectionsFromImageURLS(_ urls: [URL], at indexPath: IndexPath) {
                
                for url in urls {
                    guard var image = NSImage(contentsOf: url) else { fatalError("Failed to open Image at \(url)") }
                    image = image.resize(to: NSSize(width: 50, height: 70))!
                    
                    let sourceFileName = url.deletingPathExtension().lastPathComponent
                    guard let docPage = PDFPage(image: image) else { fatalError("Failed to create PDFPage from Image at \(url)")}
                    let pdfPageItem = PDFPageItem(
                        document: document,
                        name: "Image - \(sourceFileName)",
                        pdfPage: docPage
                    )
                    document.sections.append(PDFPageSection(document: document, title: "Image - \(sourceFileName)", pdfPageItems: [pdfPageItem]))
                }
               
            }
            func insertPDFPageItemsFromImageURLS(_ urls: [URL], at indexPath: IndexPath) {
                var pages: [PDFPageItem] = []
                for url in urls {
                    guard var image = NSImage(contentsOf: url) else { fatalError("Failed to open Image at \(url)") }
                    image = image.resize(to: NSSize(width: 50, height: 70))!
                    
                    let sourceFileName = url.deletingPathExtension().lastPathComponent
                    guard let docPage = PDFPage(image: image) else { fatalError("Failed to create PDFPage from Image at \(url)")}
                    pages.append(PDFPageItem(
                        document: document,
                        name: "Image - \(sourceFileName)",
                        pdfPage: docPage
                    ))
                }
                document.sections[indexPath.section].pdfPageItems.append(contentsOf: pages)
            }
        */
            
         
        func dropPDFFiles(_ collectionView: NSCollectionView, draggingInfo: NSDraggingInfo, indexPath: IndexPath) {
            print("dropPDFFiles to: ", indexPath)
            
            var urls: [URL] = []
            
            struct Payload: Codable {
                let fileName: String
                let bookmarkData: Data
            }
            
            draggingInfo.enumerateDraggingItems(
                options: NSDraggingItemEnumerationOptions.concurrent,
                for: collectionView,
                classes: [NSPasteboardItem.self],
                searchOptions: [:],
                using: {(draggingItem, idx, stop) in
                    if let pasteboardItem = draggingItem.item as? NSPasteboardItem {
                        do {
                            if let data = pasteboardItem.data(forType: .pdfFileType) {
                                
                                let payload = try JSONDecoder().decode(Payload.self, from: data)
                                // Resolve the URL from the bookmark to rebuild a PDFFile
                                var isStale = false
                                let url = try URL(resolvingBookmarkData: payload.bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
                                
                                urls.append(url)
                                
                                
                            }
                        } catch { Swift.debugPrint("failed to unarchive indexPath for dropped item.") }
                        
                        print ("dropPDFFiles(urls: ", urls, " to indexPath: ", indexPath)
    fatalError()
                        //                    self.insertPDFPageItemsFromDocumentURLS(urls, at: indexPath)
                 //       self.updateUI()
                    }
                })
        }
            

            
        func dropInternalSections(_ collectionView: NSCollectionView, draggingInfo: NSDraggingInfo, indexPath: IndexPath) {
            print("dropInternalSections to: ", indexPath)
            
        }
            
        func dropInternalPages(_ collectionView: NSCollectionView, draggingInfo: NSDraggingInfo, indexPath: IndexPath) {
            print("dropInternalPages to: ", indexPath)
            
            var draggedItems: [IndexPath] = []
            
            draggingInfo.enumerateDraggingItems(
                options: NSDraggingItemEnumerationOptions.concurrent,
                for: collectionView,
                classes: [NSPasteboardItem.self],
                searchOptions: [:],
                using: {(draggingItem, idx, stop) in
                    if let pasteboardItem = draggingItem.item as? NSPasteboardItem {
                        do {
                            if let data = pasteboardItem.data(forType: .pdfPageDragType) {
                                let nsIndexPath = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSIndexPath.self, from: data)
                                if let nsIndexPath {
                                    let pageIndexPath = nsIndexPath as IndexPath
                                    draggedItems.append(pageIndexPath)
                                }
                            }
                        } catch { Swift.debugPrint("failed to unarchive indexPath for dropped item.") }
                        
                        print ("self.prax.movePDFPageItems(draggedItems: ", draggedItems, " to indexPath: ", indexPath)
                        self.document.movePDFPageItems(draggedItems, to: indexPath)
                       
               //         self.updateUI()
                    }
                })
        }
        
    }
    
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
        
        return proposedMinimumPosition
    }

    
    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        print ("splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: ", proposedMaximumPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)
        
        return proposedMaximumPosition
    }

    
    func splitView(_ splitView: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        print ("splitView: NSSplitView, constrainSplitPosition proposedPosition: ", proposedPosition, "  ofSubviewAt dividerIndex:   ", dividerIndex)
        
        return proposedPosition
    }

    
    func splitView(_ splitView: NSSplitView, resizeSubviewsWithOldSize oldSize: NSSize) {
        print ("splitView: NSSplitView, resizeSubviewsWithOldSize oldSize:  ", oldSize)

    }

    
    func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
        print ("splitView: NSSplitView, shouldAdjustSizeOfSubview view: : ")
        
        return false
    }

    
    func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
        print ("splitView: NSSplitView, shouldHideDividerAt dividerIndex:   ", dividerIndex)
        
        return false
    }

    
    func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
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
}



struct DocumentEditingToolbar: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    private func title(for mode: PDFDisplayMode) -> String {
        switch mode {
        case .singlePage: return "Single"
        case .singlePageContinuous: return "Continuous"
        case .twoUp: return "Two Up"
        case .twoUpContinuous: return "Two Up Cont."
        @unknown default: return "Unknown"
        }
    }
    
    let filenameStyle = URL.FormatStyle(scheme: .never,
                                        user: .never,
                                        password: .never,
                                        host: .always,
                                        port: .never,
                                        path: .always,
                                        query: .never,
                                        fragment: .never)
 
    var body: some View {
        @Bindable var prax = praxModel
        @Bindable var document = document
        GroupBox {
            
            //    Text("Prax")
            let pageCount = "Pages: " + String(document.totalPDFPageItems())
            HStack {
                Text(pageCount)
                Button("Clear All", systemImage: "document.on.trash", action: {
                    print (pageCount)
                    
                })
                Button {
                    prax.showingFileImporter = true }
                label: {
                    Text("Import Files") //.frame(minWidth: 100, maxWidth: 200, alignment: .center)
                }
                
                //       .background(dropTargeted ? Color.green : Color.blue)
                .fileImporter(
                    isPresented: $prax.showingFileImporter,
                    allowedContentTypes: [.pdf, .image, .text, .video],
                    allowsMultipleSelection: true
                ) { result in
                    switch result {
                    case .success(let urls):
                        print (urls)
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
                Button("Export…", systemImage: "arrow.down.document") {
                    prax.showSavePanel.toggle()
                }
                Spacer()
                ZStack {
                    TextField("Prefix", text: $document.exportFilenamePrefix)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                        .overlay(alignment: .trailing) {
                            if !document.exportFilenamePrefix.isEmpty {
                                Button {
                                    document.exportFilenamePrefix = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                        .padding(.trailing, 6) // adjust for your field style
                                }
                                .buttonStyle(.plain)
                                .help("Clear")
                            }
                        }
                }
                
                TextField("Filename", text: Binding<String>(
                    get: { document.exportFilenameBody },
                    set: { newValue in
                        var newName = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        // Ensure we don't accidentally include a dot/extension typed by the user
                        if let dotRange = newName.range(of: ".") {
                            newName = String(newName[..<dotRange.lowerBound])}
                        document.exportFilenameBody = newName
                    })
                          
                )
                //   .frame(minWidth: 10, idealWidth: 20, alignment: .init(horizontal: .trailing, vertical: .center))
                //.frame(maxWidth: 100, alignment: .init(horizontal: .trailing, vertical: .center))
                .textFieldStyle(RoundedBorderTextFieldStyle())
               // .disabled(document.exportFolderURL == nil)
                
                
                Text(".pdf")
                Button("Drag", systemImage: "arrow.right.doc.on.clipboard") {
                    
                
                }.draggable {
                    if let data = document.mergedPDFDocument().dataRepresentation() {
                        return MergedPDFTransfer(data: data, filename: (document.exportFilename))
                        
                    } else {
                        return nil
                    }
                }
               
                Spacer(minLength: 15)


            }
            .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
            .padding(8)
            
        }
        
        
        .onDrop(of: [.fileURL], delegate: PraxDropDelegate(document, prax))
        
        .fileDialogDefaultDirectory(document.sourceFolderURL)
        .fileDialogMessage("Add Files to PraxPress")
        .fileDialogConfirmationLabel(Text("Add to PraxPress"))
        
        .background(prax.dropTargeted ? Color(red: 0.4, green: 0.4, blue: 0.8, opacity: 0.3) : Color.orange)
        .foregroundStyle(Color.white)
        
    }
    
    private var dragPreviewView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor, lineWidth: 2)
                )
                .frame(width: 180, height: 80)
            
            VStack(spacing: 6) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.blue)
                Text("\(document.exportFilename).pdf")
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
            }
        }
        
    }
    

}

struct DocumentEditingFooter: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    let filenameStyle = URL.FormatStyle(scheme: .never,
                                        user: .never,
                                        password: .never,
                                        host: .always,
                                        port: .never,
                                        path: .always,
                                        query: .never,
                                        fragment: .never)
    var body: some View {
        @Bindable var prax = praxModel
        HStack {
            switch (prax.selectedFiles.count) {
            case 0:
                Text("No files selected")
            case 1:
                Text("Source file: \(document.firstSelectedFileURL?.formatted(filenameStyle) ?? "")")
            default:
                Text("\(prax.selectedFiles.count) Source files selected")
            }
            Spacer()
            Text(String(format: "frame width: \(prax.splitViewFrameWidth) divZero:  \(prax.dividerZeroPos) divOne:   \(prax.dividerOnePos)"))
        }
        .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
        .padding(8)
    }
}



#Preview {
    
    DocumentEditingToolbar()
    DocumentEditingView()
    DocumentEditingFooter()
}

