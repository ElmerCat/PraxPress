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
    @Environment(PraxModel.self) private var prax
    
    
    func makeCoordinator() -> DocumentEditingViewCoordinator {
        let svd = SplitViewDelegate(prax: prax)
        return DocumentEditingViewCoordinator(document: document, prax: prax, splitViewDelegate: svd)
    }

    func makeNSView(context: Context) -> NSSplitView {
        
        let splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .paneSplitter
        
        splitView.autosaveName = NSSplitView.AutosaveName("DocumentEditingSplitView")
        let scrollView = NSScrollView()
    //    pageItemScrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false

   //     prax.pageItemCollectionView.translatesAutoresizingMaskIntoConstraints = false
        prax.pageItemCollectionView.backgroundColors = [.clear]
        prax.pageItemCollectionView.isSelectable = true
        prax.pageItemCollectionView.allowsEmptySelection = true
        prax.pageItemCollectionView.allowsMultipleSelection = true
        prax.pageItemCollectionView.delegate = context.coordinator
        scrollView.documentView = prax.pageItemCollectionView
        
        let mergedDoumentView = MergedPDFDocumentNSView(prax: prax)
        let editingDoumentView = EditingPDFDocumentNSView(prax: prax)
        
        splitView.arrangesAllSubviews = true
        splitView.addArrangedSubview(scrollView)
        splitView.addArrangedSubview(editingDoumentView)
        splitView.addArrangedSubview(mergedDoumentView)
  //      splitView.setHoldingPriority(.defaultHigh, forSubviewAt: 0)
  //      splitView.setHoldingPriority(.defaultLow, forSubviewAt: 1)
  //      splitView.setHoldingPriority(.defaultHigh, forSubviewAt: 2)
        
        // Configure collection views: layout, registration, data sources
        context.coordinator.configure(collectionView: prax.pageItemCollectionView, kind: .pageItem)
 
        // Apply initial snapshot to both
        context.coordinator.applySnapshot(animated: false)

        // Initial divider position
        DispatchQueue.main.async {
            
//            let pageItemWidth = 120.0
 //           let pageEditWidth = 100.0
            
//            let positionOne = pageEditWidth + pageItemWidth
//            var remainingWidth = splitView.frame.width - positionOne
//            remainingWidth = remainingWidth * 0.25
            
//            let positionTwo = splitView.frame.width - remainingWidth

 //           print("DocumentEditingView - plitView.setPositions 1: \(String(describing: positionOne)),  -  2: \(String(describing: positionTwo)) <-- ")
            splitView.setPosition(200, ofDividerAt: 0)
            splitView.setPosition(600, ofDividerAt: 1)
   //         splitView.setPosition(positionTwo, ofDividerAt: 2)
        }

        
        return splitView
    }

    func updateNSView(_ splitView: NSSplitView, context: Context) {
        print("DocumentEditingView - updateNSView - ", prax.selectedPageItem?.mergedPage.title ?? "No selectedPageItem")
        context.coordinator.applySnapshot(animated: true)
    }

    
    
    
    
    final class DocumentEditingViewCoordinator: NSObject, NSSplitViewDelegate, NSCollectionViewDelegate {
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
  
        
        enum CollectionKind { case pageItem, pageEdit} //, mergedPage }

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
                cell.representedObject = item
                let isSelected = cv.selectionIndexPaths.contains(indexPath)
                switch kind {
                case .pageItem:
                    cell.configure(kind: .pageItem(item: item), isSelected: isSelected)
                case .pageEdit:
                    cell.configure(kind: .editPage(item: item), isSelected: isSelected)
                }
                return cell
            }

            dataSource.supplementaryViewProvider = { [weak self] cv, kindString, indexPath in
                guard let self = self else { return nil }
                let sections = self.document.pageSections
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
            case .pageEdit:
                break
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
            for mergedPage in document.pageSections {
                
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
            print("ThumbnailViewController canDragItemsAt  ", indexPaths, " event ", event)
            return true
        }
        
        func collectionView(_ collectionView: NSCollectionView,
                            pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
            
            print("ThumbnailViewController pasteboardWriterForItemAt  ", indexPath)

            
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
        
        func collectionView(
            _ collectionView: NSCollectionView, validateDrop draggingInfo: any NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>
        ) -> NSDragOperation {
            
                 let indexPath = proposedDropIndexPath.pointee
             
            if prax.optionKeyPressed {
                print("ThumbnailViewController validateDrop [.copy]  ", indexPath)
                validatedDropOperation = [.copy]
        
            }
            else {
                print("ThumbnailViewController validateDrop [.move]  ", indexPath)
                validatedDropOperation = [.move]
        
            }
            return validatedDropOperation
        }
                 
        func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
            print("ThumbnailViewController acceptDrop  ", indexPath.item, " -  dropOperation: ", dropOperation, " - draggingInfo: ", draggingInfo)
            
            guard let draggingTypes = draggingInfo.draggingPasteboard.types else { return false }
            
            if draggingTypes.contains(.pdfPageDragType) {
                if validatedDropOperation == [.copy] {
                    dropInternalPages(collectionView, draggingInfo: draggingInfo, indexPath: indexPath, copy: true)
                }
                else {
                    dropInternalPages(collectionView, draggingInfo: draggingInfo, indexPath: indexPath, copy: false)
                }
                
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
      
            Task {
                do {
                    try await document.persistence.processImportedURLs(droppedURLs)
                }
                catch {
                    print("Failed to processImportedURLs(urls)", droppedURLs)
                }
            }
            
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



struct DocumentEditingToolbar: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    let praxTheme = PraxTheme(.erika)
    
    @State var showDataFields = false
    @State var showSettings = false
    @State var showDelete = false
    @State private var hoveredButton: Int? = nil
    @State private var showFilenamePrefixPopover = false
    
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
                
                HStack {
                
                    Button {
                        showDelete = !showDelete
                    }label: {
                        Image(systemName: document.pageSections.isEmpty ? "rectangle.dashed" : "rectangle.stack.slash")
                    }
                    .buttonStyle(PrefixButtonStyle(isHovering: hoveredButton == 40, isDisabled: document.pageSections.isEmpty))
                    .onHover { hovering in hoveredButton = hovering ? 40 : nil }
                    .disabled(document.pageSections.isEmpty)
                    
                    
                    
                    .popover(isPresented: $showDelete, arrowEdge: .leading) {
                        DeletePopover() }
                    Spacer()
                    
                    Button { showFilenamePrefixPopover = !showFilenamePrefixPopover  }
                    label: {
                        if document.exportFilenamePrefix == "" {
                            Text("prefix...").italic().foregroundStyle(.gray)
                        }
                        else {
                            Text(document.exportFilenamePrefix).bold()
                        }
                    }
                    .buttonStyle(PrefixButtonStyle(isHovering: hoveredButton == 42))
                    .onHover { hovering in hoveredButton = hovering ? 42 : nil }
                    .popover(isPresented: $showFilenamePrefixPopover, arrowEdge: .leading) {
                        FilenamePrefixPopover() }
                    
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
                    
                    .frame(width: 200)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                   // .disabled(document.exportFolderURL == nil)
                    
                    
                    Text(".pdf")
                    Button("Drag", systemImage: "arrow.right.doc.on.clipboard") {
                        
                    
                    }
                    .draggable({ () -> MergedPDFTransfer? in
                        guard let data = document.mergedPDFDocument.dataRepresentation() else { return nil }
                        return MergedPDFTransfer(data: data, filename: document.exportFilename)
                    }()!, preview: {
                        PraxDragPreview()
                    })
                    
                    if let pageItem = prax.selectedPageItem, !pageItem.dataFields.isEmpty {
                        
                        Spacer()
                        
                        Button { showDataFields = !showDataFields }label: {
                            GroupBox {
                                HStack {
                                    Image(systemName: showDataFields ? "list.bullet.rectangle.fill": "list.bullet.rectangle")
                                    Text("Data Fields")
                                }
                            }
                        }
                        
                        .buttonStyle(SwitchButtonStyle(isOn: showDataFields, isHovering: hoveredButton == 417))
                        .controlSize(.extraLarge)
                        .onHover { hovering in hoveredButton = hovering ? 417 : nil }
                        .inspectorPanel(isPresented: $showDataFields) { DataFieldsEditor(prax: prax) }
     
                        Spacer()
                        
                    }
                    
                    Spacer(minLength: 15)

                    Button("Save", systemImage: "square.and.arrow.down") {
                        var isStale = false
                        if let bookmark = document.exportFileURLBookmark, let url = try? URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) {
                            let needsStop = url.startAccessingSecurityScopedResource()
                            defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
                        
                            document.mergedPDFDocument.write(to: url)
                      //      document.mergedPDFDocument.write(to: url, withOptions: [.burnInAnnotationsOption: true])
                   
                        }
                        else {
                            prax.showSavePanel.toggle()

                        }
                        
                    }
                    Button("Save As…", systemImage: "square.and.arrow.down.on.square") {
                        prax.showSavePanel.toggle()
                    }
                    
                }
                .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
                .padding(0)
                
       
            
            

            
        }
        
        
        .onDrop(of: [.fileURL], delegate: PraxDropDelegate(document, prax))

        
  //     .background(PraxGradient(2))
  //      .background(prax.dropTargeted ? Color(red: 0.4, green: 0.4, blue: 0.8, opacity: 0.3) : Color.orange)
    //    .foregroundStyle(Color.white)
        
        
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
                Text("Source file: \(document.exportFilenameBody)")
            default:
                Text("\(prax.selectedFiles.count) Source files selected")
            }
            Spacer()
   //         Text(String(format: "Window size: \(prax.windowSize.width) x \(prax.windowSize.height) -- -- SplitView width: \(prax.splitViewFrameWidth) -  divZero@:  \(prax.dividerZeroPos) -  divOne@:   \(prax.dividerOnePos)"))
        }
        .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
        .padding(8)
    }
}


struct DocumentEditingLeadingEdge: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    let praxTheme = PraxTheme(.erika)
    
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
    let praxTheme = PraxTheme(.erika)
    
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
    DocumentEditingView()
    DocumentEditingFooter()
}

