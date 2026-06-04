//  PageItemCollectionView.swift
//  PraxPress - Prax=0104-1
//
//


import SwiftUI
import PDFKit
import AppKit
//import Combine
import UniformTypeIdentifiers




struct PageItemCollectionView: NSViewRepresentable {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    
    
    func makeCoordinator() -> PageItemCollectionViewCoordinator {
        let svd = SplitViewDelegate(prax: prax)
        return PageItemCollectionViewCoordinator(document: document, prax: prax, splitViewDelegate: svd)
    }

//    func makeNSView(context: Context) -> NSSplitView {
    func makeNSView(context: Context) -> NSScrollView {
        
 //       let splitView = NSSplitView()
//        splitView.isVertical = true
//        splitView.dividerStyle = .paneSplitter
//        splitView.autosaveName = NSSplitView.AutosaveName("DocumentEditingSplitView")
//        splitView.delegate = context.coordinator.splitViewDelegate
//        context.coordinator.splitViewDelegate.splitView = splitView
        let scrollView = NSScrollView()
    //    pageItemScrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false

        prax.pageItemCollectionView.translatesAutoresizingMaskIntoConstraints = false
        prax.pageItemCollectionView.backgroundColors = [.clear]
        prax.pageItemCollectionView.isSelectable = true
        prax.pageItemCollectionView.allowsEmptySelection = true
        prax.pageItemCollectionView.allowsMultipleSelection = true
        prax.pageItemCollectionView.delegate = context.coordinator
        scrollView.documentView = prax.pageItemCollectionView
        
 //       let mergedDoumentView = MergedPDFDocumentNSView(prax: prax)
//        let editingDoumentView = EditingPDFDocumentNSView(prax: prax)
 //
 //       splitView.arrangesAllSubviews = true
 //       splitView.addArrangedSubview(scrollView)
 //       splitView.addArrangedSubview(editingDoumentView)
 //       splitView.addArrangedSubview(mergedDoumentView)
  //      splitView.setHoldingPriority(.defaultHigh, forSubviewAt: 0)
  //      splitView.setHoldingPriority(.defaultLow, forSubviewAt: 1)
  //      splitView.setHoldingPriority(.defaultHigh, forSubviewAt: 2)
        
        // Configure collection views: layout, registration, data sources
        context.coordinator.configure(collectionView: prax.pageItemCollectionView, kind: .pageItem)
 
        // Apply initial snapshot to both
        context.coordinator.applySnapshot(animated: false)

        // Initial divider position
/*        DispatchQueue.main.async {
            
//            let pageItemWidth = 120.0
 //           let pageEditWidth = 100.0
            
//            let positionOne = pageEditWidth + pageItemWidth
//            var remainingWidth = splitView.frame.width - positionOne
//            remainingWidth = remainingWidth * 0.25
            
//            let positionTwo = splitView.frame.width - remainingWidth

 //           print("PageItemCollectionView - plitView.setPositions 1: \(String(describing: positionOne)),  -  2: \(String(describing: positionTwo)) <-- ")
            splitView.setPosition(200, ofDividerAt: 0)
            splitView.setPosition(600, ofDividerAt: 1)
   //         splitView.setPosition(positionTwo, ofDividerAt: 2)
        }
*/
        
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        scrollView.isHidden = document.mergedPages.isEmpty
        //     splitView.setPosition(200, ofDividerAt: 0)
    //    splitView.setPosition(600, ofDividerAt: 1)
        print("PageItemCollectionView - uupdateNSView(_ scrollView: NSScrollView, context: Context)- ", prax.selectedPageItem?.mergedPage.title ?? "No selectedPageItem")
        context.coordinator.applySnapshot(animated: true)
        
                
            
    }

    
    
    
    
    final class PageItemCollectionViewCoordinator: NSObject, NSSplitViewDelegate, NSCollectionViewDelegate {
        // Shared model
        private let document: MergedPDFDocument
        private let prax: PraxModel
        let splitViewDelegate: SplitViewDelegate
        
        // Views
//        weak var splitView: NSSplitView?
 //       weak var pageItemScrollView: NSScrollView?

        // Data sources
        private var leftDataSource: NSCollectionViewDiffableDataSource<MergedPage, PageItem>!

        init(document: MergedPDFDocument, prax: PraxModel, splitViewDelegate: SplitViewDelegate) {
            self.document = document
            self.prax = prax
            self.splitViewDelegate = splitViewDelegate
        }
        

        private func selectFirstPageItemIfNeeded() {
            if prax.selectedPageItems.isEmpty {
                prax.selectedPageItems = [IndexPath(item: 0, section: 0)]
            }
        }
  
        
        enum CollectionKind { case pageItem } //, mergedPage }

        // Configure one collection view (layout, registration, data source)
        func configure(collectionView: NSCollectionView, kind: CollectionKind) {
            // Layout
            collectionView.collectionViewLayout = makeLayout(for: kind)

            // Register unified item/supplementaries
            collectionView.register(
                CollectionViewItem.self,
                forItemWithIdentifier: NSUserInterfaceItemIdentifier("Cell")
            )
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

            // Optional background
            collectionView.backgroundView = CollectionViewBackground()

            // Drag & drop (optional)
            collectionView.registerForDraggedTypes([
                .fileURL,
                .pdfPageDragType,
                .mergedPageType,
                .sourceFileType
            ])

            // Data source
            let dataSource = NSCollectionViewDiffableDataSource<MergedPage, PageItem>(
                collectionView: collectionView
            ) {cv, indexPath, item in
                guard let cell = cv.makeItem(
                    withIdentifier: NSUserInterfaceItemIdentifier("Cell"),
                    for: indexPath
                ) as? CollectionViewItem else { return nil }
                cell.representedObject = item
                let isSelected = cv.selectionIndexPaths.contains(indexPath)
                switch kind {
                case .pageItem:
                    cell.configure(kind: .pageItem(item: item), isSelected: isSelected)
                }
                return cell
            }

            dataSource.supplementaryViewProvider = { [weak self] cv, kindString, indexPath in
                guard let self = self else { return nil }
                let sections = self.document.mergedPages
                guard indexPath.section >= 0, indexPath.section < sections.count else { return nil }

                
                if kindString == CollectionViewItem.sectionHeaderElementKind {
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
             //  self.centerDataSource = dataSource
            }
        }
        
        struct LayoutSettings {
            var itemWidth: NSCollectionLayoutDimension = .fractionalWidth(1.0)
            var itemHeight: NSCollectionLayoutDimension = .fractionalWidth(1.0)
            var itemSpacing: NSCollectionLayoutEdgeSpacing = NSCollectionLayoutEdgeSpacing(leading: .fixed(0), top: nil, trailing: .fixed(0), bottom: .fixed(0))
            var itemInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            var groupWidth: NSCollectionLayoutDimension = .fractionalWidth(1.0)
            var groupHeight: NSCollectionLayoutDimension = .fractionalWidth(1.0)
            var groupSpacing: NSCollectionLayoutEdgeSpacing = NSCollectionLayoutEdgeSpacing(leading: .fixed(0), top: nil, trailing: .fixed(0), bottom: .fixed(0))
            var groupInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            var sectionInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            var sectionSpacing: CGFloat = 0
            var headerKind: String?
            var footerKind: String?
            var backgroundKind: String?
            var headerWidth: NSCollectionLayoutDimension = .fractionalWidth(1.0)
            var headerHeight: NSCollectionLayoutDimension = .absolute(20)
            var headerInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            var footerWidth: NSCollectionLayoutDimension = .fractionalWidth(1.0)
            var footerHeight: NSCollectionLayoutDimension = .absolute(30)
            var footerInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            
            
        }
        // Build appropriate compositional layout per side
        private func makeLayout(for kind: CollectionKind) -> NSCollectionViewLayout {
            var layoutSettings = LayoutSettings()
            switch kind {
            case .pageItem:
                layoutSettings.itemHeight = .fractionalWidth(0.5)
                layoutSettings.itemWidth = .fractionalWidth(0.75)
                layoutSettings.groupHeight = .fractionalWidth(0.5)
             
      //          layoutSettings.itemSpacing = NSCollectionLayoutEdgeSpacing(leading: .fixed(0), top: .fixed(0), trailing: .fixed(0), bottom: .fixed(0))
                layoutSettings.groupSpacing = NSCollectionLayoutEdgeSpacing(leading: .fixed(0), top: .fixed(0), trailing: .fixed(0), bottom: .fixed(0))
                layoutSettings.sectionSpacing = 5
                
                //   layoutSettings.sectionInsets = NSDirectionalEdgeInsets(top: 100, leading: 30, bottom: 100, trailing: 30)
                layoutSettings.itemInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                layoutSettings.groupInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                layoutSettings.sectionInsets = NSDirectionalEdgeInsets(top: 35, leading: 5, bottom: 10, trailing: 5)
                
                layoutSettings.headerKind = CollectionViewItem.sectionHeaderElementKind
         //       layoutSettings.headerHeight = .absolute(20)
         //       layoutSettings.footerHeight = .absolute(30)
                
                layoutSettings.footerKind = CollectionViewItem.sectionFooterElementKind
                layoutSettings.backgroundKind = CollectionViewItem.pageItemSectionBackgroundElementKind
                layoutSettings.headerInsets = NSDirectionalEdgeInsets(top: 33, leading: 0, bottom: 0, trailing: 0)
                layoutSettings.footerInsets = NSDirectionalEdgeInsets(top: -25, leading: 0, bottom: 0, trailing: 0)
                
             
/*
            case .pageEdit:
                layoutSettings.itemHeight = .fractionalWidth(2.0)
                
                layoutSettings.groupHeight = .fractionalWidth(2.0)
                
                layoutSettings.sectionInsets = NSDirectionalEdgeInsets(top: 60, leading: 5, bottom: 50, trailing: 5)
                layoutSettings.sectionSpacing = 15
                layoutSettings.headerKind = CollectionViewItem.sectionHeaderElementKind
                layoutSettings.footerKind = CollectionViewItem.sectionFooterElementKind
                layoutSettings.backgroundKind = CollectionViewItem.pageItemSectionBackgroundElementKind
                layoutSettings.headerInsets = NSDirectionalEdgeInsets(top: 33, leading: 0, bottom: 0, trailing: 0)
                layoutSettings.footerInsets = NSDirectionalEdgeInsets(top: -50, leading: 0, bottom: 0, trailing: 0)
 */

            }
            return createLayout(layoutSettings)
        }

        func createLayout(_ layoutSettings: LayoutSettings) -> NSCollectionViewLayout {
            let layout = NSCollectionViewCompositionalLayout {
                (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection in
                
                let itemSize = NSCollectionLayoutSize(widthDimension: layoutSettings.itemWidth, heightDimension: layoutSettings.itemHeight)
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                item.edgeSpacing = layoutSettings.itemSpacing
                item.contentInsets = layoutSettings.itemInsets

                let groupSize = NSCollectionLayoutSize(widthDimension: layoutSettings.groupWidth, heightDimension: layoutSettings.groupHeight)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                group.edgeSpacing = layoutSettings.groupSpacing
                group.contentInsets = layoutSettings.groupInsets
                let section = NSCollectionLayoutSection(group: group)
                
                
                section.interGroupSpacing = layoutSettings.sectionSpacing
                section.contentInsets = layoutSettings.sectionInsets
           //     section.supplementariesFollowContentInsets = true
                
                
                var boundarySupplementaryItems: [NSCollectionLayoutBoundarySupplementaryItem] = []
                if layoutSettings.headerKind != nil {
                    let headerSize = NSCollectionLayoutSize(widthDimension: layoutSettings.headerWidth, heightDimension: layoutSettings.headerHeight)
                    let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: headerSize,
                        elementKind: layoutSettings.headerKind!,
                        alignment: .top,)
                    sectionHeader.contentInsets = layoutSettings.headerInsets
                    sectionHeader.extendsBoundary = true
                    sectionHeader.pinToVisibleBounds = true
//sectionHeader.zIndex = 2
                    boundarySupplementaryItems.append(sectionHeader)
                }
                if layoutSettings.footerKind != nil {
                    let footerSize = NSCollectionLayoutSize(widthDimension: layoutSettings.footerWidth, heightDimension: layoutSettings.footerHeight)
                    let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(
                         layoutSize: footerSize,
                         elementKind: layoutSettings.footerKind!,
                         alignment: .bottom)
                    sectionFooter.contentInsets = layoutSettings.footerInsets
                //    sectionFooter.extendsBoundary = true
                    sectionFooter.pinToVisibleBounds = true
                 //   sectionFooter.zIndex = 2
                    boundarySupplementaryItems.append(sectionFooter)
                }
                if !boundarySupplementaryItems.isEmpty {
                    section.boundarySupplementaryItems = boundarySupplementaryItems
                }
                
                if layoutSettings.backgroundKind != nil {
                    let sectionBackground = NSCollectionLayoutDecorationItem.background(elementKind: layoutSettings.backgroundKind!)
                    section.decorationItems = [sectionBackground]
                }
                
        /*        section.visibleItemsInvalidationHandler = { visibleItems, scrollOffset, layoutEnvironment in
                    // Perform animations on the visible items.
                    print("\nsection.visibleItemsInvalidationHandler\n", layoutEnvironment.container.contentSize, "\nScroll Offset: ", scrollOffset)
                }
       */
                return section
            }
            if layoutSettings.backgroundKind != nil {
                layout.register(CollectionSupplementaryView.self, forDecorationViewOfKind: layoutSettings.backgroundKind!)
            }
            return layout
        }
        
 

        func applySnapshot(animated: Bool) {
            var pageItemSnapshot = NSDiffableDataSourceSnapshot<MergedPage, PageItem>()
 //           var editPageSnapshot = NSDiffableDataSourceSnapshot<MergedPage, PageItem>()
            for mergedPage in document.mergedPages {
                
                pageItemSnapshot.appendSections([mergedPage])
                pageItemSnapshot.appendItems(mergedPage.pageItems)
                
      /*          if mergedPage.mergeModePages > 0 {
                    editPageSnapshot.appendSections([mergedPage])
                    
                    editPageSnapshot.appendItems([mergedPage.mergedPageItem()])
                    
                   // for pageItem in mergedPage.pageItems {
                   //     if !pageItem.skipped {
                     //       editPageSnapshot.appendItems([pageItem])
                   //     }
                 //   }

                }
*/
            }
            leftDataSource?.apply(pageItemSnapshot, animatingDifferences: animated)
     //       centerDataSource?.apply(editPageSnapshot, animatingDifferences: animated)
            
     //      DispatchQueue.main.async {
       //         self.selectFirstPageItemIfNeeded()
     //       }
            
            
        }

        func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
            if collectionView == prax.pageItemCollectionView {
                print("pageItemCollectionView - didSelectItemsAt - ", indexPaths)

                prax.selectedPageItems = collectionView.selectionIndexPaths
                
                var selectedSections: Set<Int> = []
                for item in prax.selectedPageItems {
                    let section = item.section
                    selectedSections.insert(section)
                }
                prax.selectedSections = selectedSections
 
            }
 /*           else if collectionView == prax.pageEditCollectionView {
                print("pageEditCollectionView - didSelectItemsAt - ", indexPaths)
                
                prax.selectedEditPages = collectionView.selectionIndexPaths
                
            }
 */
            else {
                assertionFailure("Unexpected collection view")
            }
          //  mirrorSelection(from: collectionView)
        }

        func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
            if collectionView == prax.pageItemCollectionView {
                
                print("pageItemCollectionView - didDeSelectItemsAt - ", indexPaths, " - ", collectionView.selectionIndexPaths)
                prax.selectedPageItems = collectionView.selectionIndexPaths
                
                var selectedSections: Set<Int> = []
                for item in prax.selectedPageItems {
                    let section = item.section
                    selectedSections.insert(section)
                }
                prax.selectedSections = selectedSections
                
            }
            
/*            else if collectionView == prax.pageEditCollectionView {
                print("pageEditCollectionView - did DE SelectItemsAt - ", indexPaths)
                prax.selectedEditPages = collectionView.selectionIndexPaths
            }
*/
            else {
                assertionFailure("Unexpected collection view")
            }
        //    mirrorSelection(from: collectionView)
        }

      /*  private func mirrorSelection(from source: NSCollectionView) {
            guard let left = pageItemCollectionView, let right = pageEditCollectionView else { return }
            let target = (source === left) ? right : left
            target.selectionIndexPaths = prax.selectedPageItems
        }
        */
        
        func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent
        ) -> Bool {
            print("collectionView canDragItemsAt  ", indexPaths, " event ", event)
            return true
        }
        
        func collectionView(_ collectionView: NSCollectionView,
                            pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
            
            print("collectionView pasteboardWriterForItemAt  ", indexPath)

            
            //       guard let pageItem = dataSource.itemIdentifier(for: IndexPath(item: indexPath.item, section: 0)) else { return provider }
            
            let typeIdentifier = UTType(filenameExtension: "pdf")
            
            let provider = FilePromiseProvider()
            provider.pdfDocument = document.mergedPDFDocument
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
    
        private var validatedDropOperation: NSDragOperation = []
        
        func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: any NSDraggingInfo,
                            proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>,
                            dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation> ) -> NSDragOperation {
            
            guard let draggingTypes = draggingInfo.draggingPasteboard.types else { return [] }
            let propsedIndexPath = proposedDropIndexPath.pointee
            let dropOperation = proposedDropOperation.pointee
            
            if draggingTypes.contains(.pdfPageDragType) {
 //               print("collectionView validateDrop .pdfPageDragType - proposedIndexPath: ", propsedIndexPath, " - dropOperation: ", dropOperation.rawValue)
                validatedDropOperation = prax.optionKeyPressed ? [.copy] : [.move] }
            
            else if draggingTypes.contains(.mergedPageType) {
//                print("collectionView validateDrop .mergedPageType - proposedIndexPath: ", propsedIndexPath, " - dropOperation: ", dropOperation.rawValue)
                validatedDropOperation = prax.optionKeyPressed ? [.copy] : [.move] }
            
            else if draggingTypes.contains(.sourceFileType) {
 //               print("collectionView validateDrop .sourceFileType - proposedIndexPath: ", propsedIndexPath, " - dropOperation: ", dropOperation.rawValue)
                validatedDropOperation = [.copy]  }

            else if draggingTypes.contains(.fileURL) {
  //              print("collectionView validateDrop .fileURL - proposedIndexPath: ", propsedIndexPath, " - dropOperation: ", dropOperation.rawValue)
                validatedDropOperation = [.copy]  }

            else {
                print("collectionView validateDrop -- Some Other Type: ", draggingTypes, "\n - proposedIndexPath: ", propsedIndexPath, " - dropOperation: ", dropOperation.rawValue)
                validatedDropOperation = []  }

            return validatedDropOperation
        }
                 
        func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {

            guard let draggingTypes = draggingInfo.draggingPasteboard.types else { return false }

            if draggingTypes.contains(.pdfPageDragType) {
                print("collectionView acceptDrop .pdfPageDragType")
                dropInternalPages(collectionView, draggingInfo: draggingInfo, indexPath: indexPath, copy: validatedDropOperation == [.copy])  }
  
            else if draggingTypes.contains(.mergedPageType) {
                print("collectionView acceptDrop .mergedPageType")
                dropInternalSections(collectionView, draggingInfo: draggingInfo, indexPath: indexPath)
            }
            else if draggingTypes.contains(.sourceFileType) {
                print("collectionView acceptDrop .sourceFileType")
                dropSourceFiles(collectionView, draggingInfo: draggingInfo, indexPath: indexPath)
            }

            else if draggingTypes.contains(.fileURL) {
                print("collectionView acceptDrop .fileURL")
                dropSourceFiles(collectionView, draggingInfo: draggingInfo, indexPath: indexPath)
                return dropExternalPages(draggingInfo: draggingInfo, indexPath: indexPath)
            }

            else { print("collectionView acceptDrop -- Some Other Type \n ", draggingTypes);  return false }
            
            return true
        }
        
        func dropExternalPages(draggingInfo: NSDraggingInfo, indexPath: IndexPath) -> Bool {
            let pasteboard = draggingInfo.draggingPasteboard
            let receivers = pasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self], options: nil) as? [NSFilePromiseReceiver] ?? []
            if !receivers.isEmpty {
                let praxError = PraxError.generic(
                    title: "Drag Source Not Supported",
                    message: "PraxPress works best with files already on your Mac. Please download or copy the PDF to your Documents folder, then drag it in."
                )
                prax.presentError(praxError)
                return false
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
//                prax.receiveDroppedURL(url, at: indexPath)
            }
      
/*            Task {
                do {
                   try await prax.importURLs(droppedURLs)
                } catch {
                    let praxError = PraxError.persistenceFailed(
                        operation: "Import dropped PDFs",
                        underlyingError: error
                    )
                    self.prax.presentError(praxError)
                }
            }
*/
            return true
          }
        
        func dropSourceFiles(_ collectionView: NSCollectionView, draggingInfo: NSDraggingInfo, indexPath: IndexPath) {
            print("dropSourceFiles to: ", indexPath)
            var sourceFilePayloads: [SourceFilePayload] = []
            draggingInfo.enumerateDraggingItems(
                options: NSDraggingItemEnumerationOptions.concurrent,
                for: collectionView,
                classes: [NSPasteboardItem.self],
                searchOptions: [:],
                using: {(draggingItem, idx, stop) in
                    if let pasteboardItem = draggingItem.item as? NSPasteboardItem {
                        do { if let data = pasteboardItem.data(forType: .sourceFileType) {
                            let sourceFilePayload = try JSONDecoder().decode(SourceFilePayload.self, from: data)
                            sourceFilePayloads.append(sourceFilePayload)
                            print ("dropSourceFile: ", sourceFilePayload.fileURL.lastPathComponent, " idx-", idx, " to indexPath: ", indexPath)  }  }
                        catch { print(" -- Failed to unarchive indexPath for dropped item.") }
                    } else { print( " -- No NSPasteboardItem")} })
            for sourceFilePayload in sourceFilePayloads {
                document.addPagesFromPDFURL(sourceFilePayload.fileURL, bookmark: sourceFilePayload.bookmarkData, at: indexPath)
            }
        }
            

            
        func dropInternalSections(_ collectionView: NSCollectionView, draggingInfo: NSDraggingInfo, indexPath: IndexPath) {
            print("dropInternalSections to: ", indexPath)
            
        }
            
        func dropInternalPages(_ collectionView: NSCollectionView, draggingInfo: NSDraggingInfo, indexPath: IndexPath, copy: Bool) {
            print("dropInternalPages to: ", indexPath, " - copy: ", copy)
            
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
                        
                        if copy {
                            print ("document.copyPDFPageItems(draggedItems: ", draggedItems, " to indexPath: ", indexPath)
                            self.document.copyPDFPageItems(draggedItems, to: indexPath)

                        }
                        else {
                            print ("document.movePDFPageItems(draggedItems: ", draggedItems, " to indexPath: ", indexPath)
                            self.document.movePDFPageItems(draggedItems, to: indexPath)

                        }
                       
               //         self.updateUI()
                    }
                })
        }
        
    }

}



struct DocumentEditingLeadingEdge: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    @State private var hoveredButton: Int? = nil
    @State private var viewWidth: CGFloat = 20
    @State private var auxilliaryOpacity: CGFloat = 0.0
    
    @State private var hoverLocation: CGPoint = .zero
    @State private var isHovering = false
    @State private var paddingTop = 20.0
    @State private var imageAngle = 0.0
    
    var body: some View {
        @Bindable var prax = praxModel
        
        GeometryReader { geometry in
           
            
            ZStack {
                
                
                VStack {
                    
                    
                GroupBox {
                    
                    
                    Image(systemName: prax.columnVisibility == .detailOnly ?  "building.columns" : "building.columns.fill")
                    
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .padding(0)
                        .padding(.top, 5)
                        .padding(.leading, 5)
                        .frame(width: viewWidth, height: viewWidth)
                        .symbolEffect(.bounce.up.byLayer, options: .nonRepeating)
                        .foregroundColor(prax.columnVisibility == .detailOnly ? .blue : .white)
                    Spacer()
                    
                    Image("PraxPress").resizable().aspectRatio(contentMode: .fit)
                        .rotationEffect(Angle(degrees: imageAngle))
                        .padding(.leading, 5)
                     //   .padding(.top, hoverOffset)
                        //.zIndex(997)
                        .frame(width: viewWidth, height: viewWidth)
                    }
                    
                    
                    Spacer()
                    
                }
                Rectangle().background(Color.blue).opacity(auxilliaryOpacity)
                    .onTapGesture {
                        withAnimation {
                            prax.columnVisibility = prax.columnVisibility == .detailOnly ? .all : .detailOnly
                        }
                    }.zIndex(998)
            }
            .frame(minWidth: viewWidth, maxWidth: viewWidth, maxHeight: .infinity)
            

            .onHover { hovering in
                 withAnimation {
                     viewWidth = hovering ? 30 : 20
                     
                     imageAngle = hovering ? -3000 : 0
                     paddingTop = hovering ? geometry.size.width / 2 : 20
                     
                     auxilliaryOpacity = hovering ? 0.01 : 0.0
                     
                 }
             }
     
 /*           .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hoverLocation = location
                    
                    isHovering = true
                case .ended:
                    isHovering = false
                }
            }
            .overlay {
                Rectangle()
                    .frame(width: 50, height: 50)
                    .foregroundColor(isHovering ? .green : .blue)
                    .offset(x: hoverLocation.x, y: hoverLocation.y)
            }

*/
            
        }
        


        
        
    }
}

/*struct DocumentEditingTrailingEdge: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    let praxTheme = PraxTheme()
    
    @State private var hoveredButton: Int? = nil
    @State private var viewWidth: CGFloat = 50
    @State private var spacerWidth: CGFloat = 50
    @State private var auxilliaryOpacity: CGFloat = 0
    @State private var imageAlignment: Alignment = .center
    
    
    @State private var hoverLocation: CGPoint = .zero
    @State private var isHovering = false
   
    var body: some View {
        @Bindable var prax = praxModel
        VStack {
            Spacer(minLength: spacerWidth)
            GroupBox {
                Image(systemName: "building.columns").resizable().aspectRatio(contentMode: .fit)
            }
            Spacer()
        }
        
        .frame(minWidth: viewWidth, maxWidth: viewWidth, maxHeight: .infinity, alignment: imageAlignment)
        .background(PraxGradient()).opacity(auxilliaryOpacity)
        .onTapGesture {
            withAnimation {
                prax.columnVisibility = prax.columnVisibility == .detailOnly ? .all : .detailOnly
            }
        }

 /*
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                hoverLocation = location
                isHovering = true
            case .ended:
                isHovering = false
            }
        }
        .overlay {
            Rectangle()
                .frame(width: 50, height: 50)
                .foregroundColor(isHovering ? .green : .blue)
                .offset(x: hoverLocation.x, y: hoverLocation.y)
        }
*/
       .onHover { hovering in
            withAnimation {
                viewWidth = hovering ? 50 : 30
                spacerWidth = hovering ? 100 : 50
                auxilliaryOpacity = hovering ? 1 : 0.1
                imageAlignment = hovering ? .top : .center
            }
        }

        
        
    }
}
*/

#Preview {
    
    DocumentEditingToolbar()
    PageItemCollectionView()
    DocumentEditingFooter()
}

