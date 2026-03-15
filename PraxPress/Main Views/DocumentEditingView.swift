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
        DocumentEditingViewCoordinator(document: document, prax: praxModel)
    }

    func makeNSView(context: Context) -> NSSplitView {
        // Split view
        let splitView = NSSplitView()
        context.coordinator.splitView = splitView
        splitView.delegate = context.coordinator
        splitView.isVertical = true
        splitView.dividerStyle = .paneSplitter
        splitView.translatesAutoresizingMaskIntoConstraints = false

        // Left: Scroll + Collection
        let leftScroll = NSScrollView()
        leftScroll.translatesAutoresizingMaskIntoConstraints = false
        leftScroll.hasVerticalScroller = true
        leftScroll.hasHorizontalScroller = false

        let leftCV = NSCollectionView()
        leftCV.translatesAutoresizingMaskIntoConstraints = false
        leftCV.backgroundColors = [.clear]
        leftCV.isSelectable = true
        leftCV.allowsEmptySelection = true
        leftCV.allowsMultipleSelection = true
        leftCV.delegate = context.coordinator
        leftScroll.documentView = leftCV

        // Right: Scroll + Collection
        let rightScroll = NSScrollView()
        rightScroll.translatesAutoresizingMaskIntoConstraints = false
        rightScroll.hasVerticalScroller = true
        rightScroll.hasHorizontalScroller = false

        let rightCV = NSCollectionView()
        rightCV.translatesAutoresizingMaskIntoConstraints = false
        rightCV.backgroundColors = [.clear]
        rightCV.isSelectable = true
        rightCV.allowsEmptySelection = true
        rightCV.allowsMultipleSelection = true
        rightCV.delegate = context.coordinator
        rightScroll.documentView = rightCV

        // Attach both scroll views to split view
        splitView.addArrangedSubview(leftScroll)
        splitView.addArrangedSubview(rightScroll)

        // Store references on the coordinator
        context.coordinator.leftCollectionView = leftCV
        context.coordinator.rightCollectionView = rightCV
        context.coordinator.leftScrollView = leftScroll
        context.coordinator.rightScrollView = rightScroll

        // Configure collection views: layout, registration, data sources
        context.coordinator.configure(collectionView: leftCV, kind: .pageItem)
        context.coordinator.configure(collectionView: rightCV, kind: .pageEdit)

        // Apply initial snapshot to both
        context.coordinator.applySnapshotToBoth(animated: false)

        // Initial divider position
        DispatchQueue.main.async {
            splitView.setPosition(250, ofDividerAt: 0)
        }

        return splitView
    }

    func updateNSView(_ splitView: NSSplitView, context: Context) {
        print("updateNSView - context.coordinator.applySnapshotToBoth(animated: true)")
        context.coordinator.applySnapshotToBoth(animated: true)
        // If your document/prax changes while the view is alive, you can reflect them here.
        // For example:
        // context.coordinator.applySnapshotToBoth(animated: true)
        // Or mirror prax.selectedPageItems to both collections.
    }

    final class DocumentEditingViewCoordinator: NSObject, NSSplitViewDelegate, NSCollectionViewDelegate {
        // Shared model
        private let document: MergedPDFDocument
        private let prax: PraxModel

        // Views
        weak var splitView: NSSplitView?
        weak var leftCollectionView: NSCollectionView?
        weak var rightCollectionView: NSCollectionView?
        weak var leftScrollView: NSScrollView?
        weak var rightScrollView: NSScrollView?

        // Data sources
        private var leftDataSource: NSCollectionViewDiffableDataSource<MergedPage, PageItem>!
        private var rightDataSource: NSCollectionViewDiffableDataSource<MergedPage, PageItem>!

        init(document: MergedPDFDocument, prax: PraxModel) {
            self.document = document
            self.prax = prax
        }

        enum CollectionKind { case pageItem, pageEdit }

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
                .pdfPageSectionType,
                .pdfFileType
            ])

            // Data source
            let ds = NSCollectionViewDiffableDataSource<MergedPage, PageItem>(
                collectionView: collectionView
            ) { [weak self] cv, indexPath, item in
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
                }
                return cell
            }

            ds.supplementaryViewProvider = { [weak self] cv, kindString, indexPath in
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
                } else if kindString == CollectionViewItem.sectionFooterElementKind {
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
                self.leftDataSource = ds
            case .pageEdit:
                self.rightDataSource = ds
            }
        }

        // Build appropriate compositional layout per side
        private func makeLayout(for kind: CollectionKind) -> NSCollectionViewLayout {
            switch kind {
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

                
         //       section.boundarySupplementaryItems = [sectionHeader, sectionFooter]
                
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

        // Apply the same snapshot to both data sources
        func applySnapshotToBoth(animated: Bool) {
            var snapshot = NSDiffableDataSourceSnapshot<MergedPage, PageItem>()
            document.pageSections.forEach {
                snapshot.appendSections([$0])
                snapshot.appendItems($0.pageItems)
            }
            leftDataSource?.apply(snapshot, animatingDifferences: animated)
            rightDataSource?.apply(snapshot, animatingDifferences: animated)
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
            guard let left = leftCollectionView, let right = rightCollectionView else { return }
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
            else if draggingTypes.contains(.pdfPageSectionType) {
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
            
         /*
            func insertPDFPageItemsFromDocumentURLS(_ urls: [URL], at indexPath: IndexPath) {
                var pages: [PDFPageItem] = []
                for url in urls {
                    let needsStop = url.startAccessingSecurityScopedResource()
                    defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
                    
                    guard let doc = PDFDocument(url: url) else { fatalError("Failed to open PDFDocument at \(url)") }
                    let sourceFileName = url.deletingPathExtension().lastPathComponent
                    for i in 0..<doc.pageCount {
                        guard let docPage = doc.page(at: i)  else { fatalError("No document.page(at: \(i)") }
                        pages.append(PDFPageItem(
                            document: document,
                            name: "\(sourceFileName) - Page \(i + 1)",
                            pdfPage: docPage
                        ))
                        print ("\(sourceFileName) - Page \(i + 1)")
                    }
                }
                document.sections[indexPath.section].pdfPageItems.append(contentsOf: pages)
                self.updateUI()
            }
        */
            

            
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
    
}










/*struct aDocumentEditingView: NSViewRepresentable {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    func makeCoordinator() -> Coordinator {
        print("Nadine Peeler- DocumentEditingView makeCoordinator")
        return Coordinator()
    }
    
    func makeNSView(context: Context) -> NSSplitView {
        print("Nadine Peeler- DocumentEditingView makeNSView")
        let splitView = NSSplitView()
        context.coordinator.splitView = splitView
        splitView.delegate = context.coordinator
        splitView.isVertical = true
        splitView.dividerStyle = .thick
        splitView.translatesAutoresizingMaskIntoConstraints = false
        
        let thumbnailViewController = ThumbnailViewController(document, praxModel)
        splitView.addArrangedSubview(thumbnailViewController.view)

        let pagesViewController = PagesViewController(document, praxModel)
        
        splitView.addArrangedSubview(pagesViewController.view)
        
        splitView.dividerStyle = .paneSplitter

        DispatchQueue.main.async {
            let target: CGFloat = 250
            splitView.setPosition(target, ofDividerAt: 0)
        }
        
      /*  NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.widthGuideChanged(_:)),
            name: .praxWidthGuideChanged,
            object: nil
        )
       */
        return splitView
    }
    
    func updateNSView(_ split: NSSplitView, context: Context) {
        print("Nadine Peeler- DocumentEditingView updateNSView")
    }
    
    final class Coordinator: NSObject, NSSplitViewDelegate, NSDraggingDestination { //PDFPageOverlayViewProvider,
       
        var splitView: NSSplitView?
        func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
            print("Coordinator - draggingEntered")
            return .copy
        }
        
        func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
            let pboard = sender.draggingPasteboard
            if let urls = pboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
                for url in urls {
                    print("Coordinator - Dropped file: \(url.path)")
                }
                return true // Drop was successful
            }
            return false // Drop rejected
        }
 
 /*       func splitView(_ splitView: NSSplitView, shouldCollapseSubview subview: NSView, forDoubleClickOnDividerAt dividerIndex: Int) -> Bool {
            print("DocumentEditingView Coordinator - shouldCollapseSubview subview: ", subview, ", forDoubleClickOnDividerAt dividerIndex:  ", dividerIndex)
             return true
        }
        func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
            print("DocumentEditingView Coordinator - canCollapseSubview subview:  ", subview)
            
            return true
        }

        func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
           print("DocumentEditingView Coordinator - constrain Min Coordinate proposedMinimumPosition: ", proposedMinimumPosition, ", ofSubviewAt dividerIndex: ", dividerIndex)
            return 100
        }
        func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            print("DocumentEditingView Coordinator - constrain Max Coordinate proposedMinimumPosition: ", proposedMaximumPosition)
            return 500
        }
        func splitView(_ splitView: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            print("DocumentEditingView Coordinator - constrainSplitPosition proposedPosition: ", proposedPosition, ", ofSubviewAt dividerIndex: ", dividerIndex)
            return 250
        }
        func splitView(_ splitView: NSSplitView, resizeSubviewsWithOldSize oldSize: NSSize) {
            print("DocumentEditingView Coordinator - resizeSubviewsWithOldSize oldSize:  ", oldSize)
        }
        func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
            print("DocumentEditingView Coordinator - shouldAdjustSizeOfSubview view:  ", view)
            return true
        }
 
        func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
            print("DocumentEditingView Coordinator - shouldHideDividerAt dividerIndex: ", dividerIndex)
            return false
        }
        func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
            print("DocumentEditingView Coordinator - proposedEffectiveRect: ", proposedEffectiveRect, ", forDrawnRect: ", drawnRect, ", ofDividerAt dividerIndex: ", dividerIndex)
            return proposedEffectiveRect
        }
        func splitView(_ splitView: NSSplitView, additionalEffectiveRectOfDividerAt dividerIndex: Int) -> NSRect {
            print("DocumentEditingView Coordinator - additionalEffectiveRectOfDividerAt dividerIndex:   ", dividerIndex)
            return NSRect(x: 0, y: 0, width: 20, height: 0)
        }
        func splitViewWillResizeSubviews(_ notification: Notification) {
            print("DocumentEditingView Coordinator - splitView Will ResizeSubviews")
       }
        
        func splitViewDidResizeSubviews(_ notification: Notification) {
            print("DocumentEditingView Coordinator - splitView Did ResizeSubviews")
        }
*/
        
/*
        @objc func pageChanged(_ note: Notification) {
            guard let pdfView = note.object as? PDFView,
                  let doc = pdfView.document,
                  let page = pdfView.currentPage else { return }
            let idx = doc.index(for: page)
            print("DocumentEditingView Coordinator - changed to page:", idx)
        }
       
        @objc func widthGuideChanged(_ note: Notification) {
            print("DocumentEditingView Coordinator - widthGuideChanged")
            
            let target: CGFloat = 250
            splitView!.setPosition(target, ofDividerAt: 0)
            
        }
        
        func pdfView(_ pdfView: PDFView, overlayViewFor pdfPage: PDFPage) -> NSView? {
            print("DocumentEditingView Coordinator - overlayViewFor page")
            @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
            
            guard let pdfPageItem = document.pdfPageItem(for: pdfPage) else { return nil }
            let view = PDFPageOverlayView()
            view.pdfView = pdfView
            
            view.onFinish = { [weak pdfPage] rectInOverlay in
                guard let pdfPage = pdfPage else { return }
                
                // Convert overlay-local rect to PDFView coordinates
                let rectInView = view.convert(rectInOverlay, to: pdfView)
                
                // Clamp to page bounds in PDFView coordinates
                let pageBoundsInView = pdfView.convert(pdfPage.bounds(for: .cropBox), from: pdfPage)
                let clamped = rectInView.intersection(pageBoundsInView)
                guard !clamped.isEmpty else { return }
                
                // Convert to page coords
                let pageRect = pdfView.convert(clamped, to: pdfPage)
                let media = pdfPage.bounds(for: .cropBox)
                
                let left = max(0, pageRect.minX - media.minX)
                let right = max(0, media.maxX - pageRect.maxX)
                let bottom = max(0, pageRect.minY - media.minY)
                let top = max(0, media.maxY - pageRect.maxY)
                
                let trim = EdgeTrims(left: left, right: right, top: top, bottom: bottom)
                print("DocumentEditingView Coordinator - trim l:", trim.left, " r:", trim.right, " b:", trim.bottom, " t:", trim.top)
                
                pdfPageItem.trim = trim
            }
            
            // Seed current rect from trims
            DispatchQueue.main.async { [weak view, weak pdfPage, weak pdfView, weak pdfPageItem] in
                guard let view = view, let pdfPage = pdfPage, let pdfView = pdfView, let pdfPageItem = pdfPageItem else { return }
                let crop = pdfPage.bounds(for: .cropBox)
                let cropInView = pdfView.convert(crop, from: pdfPage)
                let cropInOverlay = view.convert(cropInView, from: pdfView)
                view.clampRect = cropInOverlay

                // Recompute visible using current trims
                let trim = pdfPageItem.trim
                let visibleInPage = CGRect(
                    x: crop.minX + trim.left,
                    y: crop.minY + trim.bottom,
                    width: crop.width - trim.left - trim.right,
                    height: crop.height - trim.top - trim.bottom
                )
                let visibleInView = pdfView.convert(visibleInPage, from: pdfPage)
                let visibleInOverlay = view.convert(visibleInView, from: pdfView)
                view.currentRect = visibleInOverlay
                
                view.needsDisplay = true
            }
            return view
        }

*/
        
    }
}

*/




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
            }
            .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
            .padding(8)
            
        }
        .onDrop(of: [.fileURL], delegate: PraxDropDelegate(document, prax))
        
        .fileDialogDefaultDirectory(document.sourceFolderURL)
        .fileDialogMessage("Choose the Export Folder")
        .fileDialogConfirmationLabel(Text("Choose Export Folder"))
        
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

