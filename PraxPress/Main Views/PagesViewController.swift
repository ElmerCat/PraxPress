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
    
    @State private var prax = PraxModel.shared
    
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
        updateUI(animated: false)
        
        observeDocumentChange = Task {
            for await _ in Observations({ self.prax.editingPDFDocument }) {
                print("PagesViewController observeDocumentChange  ", self.prax.editingPDFDocument)
                
                updateUI()
            }
        }
        observeCurrentIndexChange = Task {
            for await _ in Observations({ self.prax.currentIndex }) {
                print("PagesViewController observeCurrentIndexChange  ", self.prax.currentIndex)
                if collectionView?.numberOfSections == 0  { return }
                if (collectionView?.numberOfItems(inSection: 0) == 0)  { return }
                collectionView.selectionIndexPaths = [IndexPath(item: self.prax.currentIndex, section: 0)]
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
            .itemDragType]) // Intra drag of row items numbers within the collection view.
        
        // Determine the kind of source drag originating from this app.
        // Note, if you want to allow your app to drag items to the Finder's trash can, add ".delete".
        collectionView.setDraggingSourceOperationMask([.copy, .delete], forLocal: false)
    }

    private func configureDataSource() {
        dataSource = NSCollectionViewDiffableDataSource<PDFPageSection, PDFPageItem>(collectionView: collectionView) {
            (collectionView: NSCollectionView, indexPath: IndexPath, identifier: PDFPageItem) -> NSCollectionViewItem? in
            let item = collectionView.makeItem(withIdentifier: PageItem.reuseIdentifier, for: indexPath)
            guard let pageItem = item as? PageItem else { return nil }
            pageItem.pageIndex = identifier.index
            if let page = self.prax.editingPDFDocument.page(at: indexPath.item) {
                pageItem.imageView?.image = page.thumbnail(of: CGSize(width: 120, height: 160), for: .cropBox)
            } else {
                pageItem.imageView?.image = nil
            }
            pageItem.textField?.stringValue = identifier.name
            
            pageItem.guidePageButton?.state = self.prax.widthGuidePageIndex == identifier.index ? .on : .off
            
            return pageItem
        }
        dataSource.supplementaryViewProvider = {
            (collectionView: NSCollectionView, kind: String, indexPath: IndexPath) -> (NSView & NSCollectionViewElement)? in
            
            
            if kind == PagesViewController.sectionHeaderElementKind {
                if let supplementaryView = collectionView.makeSupplementaryView(
                    ofKind: kind,
                    withIdentifier: PagesSectionHeader.reuseIdentifier,
                    for: indexPath) as? PagesSectionHeader {
                    supplementaryView.label.stringValue = self.prax.pdfSections[indexPath.section].title
                    return supplementaryView
                }
            }
            
            else if kind == PagesViewController.sectionFooterElementKind {
                if let supplementaryView = collectionView.makeSupplementaryView(
                    ofKind: kind,
                    withIdentifier: PagesSectionFooter.reuseIdentifier,
                    for: indexPath) as? PagesSectionFooter {
                    supplementaryView.label.stringValue = String(self.prax.editingPDFDocument.pageCount)
                    return supplementaryView
                }
            }
            
            fatalError("Cannot create new supplementary view of kind: \(kind)")
        }
    }
    
    private func updateUI(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<PDFPageSection, PDFPageItem>()
        prax.pdfSections.forEach {
            snapshot.appendSections([$0])
            snapshot.appendItems(prax.pdfPages)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>){
        print("PagesViewController didSelectItemsAt indexPaths ", indexPaths)
        prax.updateCurrentIndex(indexPaths: indexPaths)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>){
        print("PagesViewController didSelectItemsAt indexPaths ", indexPaths)
    }
    
    
    func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent
    ) -> Bool {
        print("PagesViewController canDragItemsAt  ", indexPaths, " event ", event)
        return true
    }
    
    func collectionView(_ collectionView: NSCollectionView,
                        pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        
        print("PagesViewController pasteboardWriterForItemAt  ", indexPath)
        var provider: NSFilePromiseProvider?
        
        provider = FilePromiseProvider()
        
        guard let pageItem =
                dataSource.itemIdentifier(for: IndexPath(item: indexPath.item, section: 0)) else { return provider }
        
        let typeIdentifier = UTType(filenameExtension: "pdf")
        
        provider = FilePromiseProvider()
        provider!.fileType = typeIdentifier!.identifier
        provider!.delegate = provider as? any NSFilePromiseProviderDelegate
        // Send out the indexPath and photo's url dictionary.
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: indexPath, requiringSecureCoding: false)
            provider!.userInfo = [FilePromiseProvider.UserInfoKeys.urlKey: prax.fileURL as Any,FilePromiseProvider.UserInfoKeys.indexPathKey: data]
        } catch {
            fatalError("failed to archive indexPath to pasteboard")
        }
        return provider
    }
    
    func collectionView(
        _ collectionView: NSCollectionView, validateDrop draggingInfo: any NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>
    ) -> NSDragOperation {
        
        let indPth = proposedDropIndexPath.pointee
        
        print("PagesViewController validateDrop  ", indPth.debugDescription)
        
        return [.move]
    }
    
    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
        
        print("PagesViewController acceptDrop  ", indexPath.item)
        
        // Check where the dragged items are coming from.
        if let draggingSource = draggingInfo.draggingSource as? NSCollectionView, draggingSource == collectionView {
            // Drag source from your own collection view.
            // Move each dragged item to their new place.
            dropInternalPages(collectionView, draggingInfo: draggingInfo, indexPath: indexPath)
        } else {
            // The drop source is from another app (Finder, Mail, Safari, etc.) and there may be more than one file.
            // Drop each dragged image file to their new place.
            dropExternalPages(collectionView, draggingInfo: draggingInfo, indexPath: indexPath)
        }
        return true
    }
    
    
    
    func dropExternalPages(_ collectionView: NSCollectionView, draggingInfo: NSDraggingInfo, indexPath: IndexPath) {
        
        print("dropExternalPages  ", indexPath)
        
    }
    // Find the proper drop location relative to the provided indexPath.
    func dropLocation(indexPath: IndexPath) -> IndexPath {
        var toIndexPath = indexPath
        if indexPath.item == 0 {
            toIndexPath = IndexPath(item: indexPath.item, section: indexPath.section)
        } else {
            toIndexPath = IndexPath(item: indexPath.item - 1, section: indexPath.section)
        }
        return toIndexPath
    }
    
    // Flatten the snapshot’s sections/items into a single array of page indices
    // in the exact order the PDFDocument should have them.
    private func flattenedPageOrder(from snapshot: NSDiffableDataSourceSnapshot<PDFPageSection, PDFPageItem>) -> [Int] {
        var order: [Int] = []
        for section in snapshot.sectionIdentifiers {
            let items = snapshot.itemIdentifiers(inSection: section)
            order.append(contentsOf: items.map { $0.index })
        }
        return order
    }

    // Reorder the existing document in-place using PDFKit’s exchangePage(at:withPageAt:)
    private func reorderDocumentPagesInPlaceUsingExchange(to newOrder: [Int]) {
        let pageCount = prax.editingPDFDocument.pageCount
        guard pageCount == newOrder.count else { return }

        // currentOrder[i] = logical page index currently at position i
        var currentOrder = Array(0..<pageCount)

        for i in 0..<pageCount {
            if currentOrder[i] == newOrder[i] { continue }
            guard let j = currentOrder.firstIndex(of: newOrder[i]) else { continue }

            prax.editingPDFDocument.exchangePage(at: i, withPageAt: j)
            currentOrder.swapAt(i, j)
        }

        // After the document order changes, rebuild pages and keep trims aligned
        prax.rebuildPagesFromDocument()
        updateUI(animated: true)
    }

    // Update selection to the new position of a logical page index after reordering
    private func updateSelectionForMovedPage(originalLogicalIndex: Int, newOrder: [Int]) {
        if let newPos = newOrder.firstIndex(of: originalLogicalIndex) {
            prax.currentIndex = newPos
        }
    }
    
    func dropInternalPages(_ collectionView: NSCollectionView, draggingInfo: NSDraggingInfo, indexPath: IndexPath) {
        
        print("dropInternalPages  ", indexPath)
        
        var snapshot = self.dataSource.snapshot()
        
        draggingInfo.enumerateDraggingItems(
            options: NSDraggingItemEnumerationOptions.concurrent,
            for: collectionView,
            classes: [NSPasteboardItem.self],
            searchOptions: [:],
            using: {(draggingItem, idx, stop) in
                if let pasteboardItem = draggingItem.item as? NSPasteboardItem {
                    do {
                        if let data = pasteboardItem.data(forType: .itemDragType) {
                            let nsIndexPath = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSIndexPath.self, from: data)
                            if let nsIndexPath {
                                let pageIndexPath = nsIndexPath as IndexPath
                                if let pageItem = self.dataSource.itemIdentifier(for: pageIndexPath) {
                                    // Find out the proper indexPath drop point.
                                    let toIndexPath = self.dropLocation(indexPath: indexPath)
                                    
                                    let dropItemLocation = snapshot.itemIdentifiers[toIndexPath.item]
                                    
                                    print("\ndropItemLocation  ", dropItemLocation, " toIndexPath: ", toIndexPath)
                                    
                                    if toIndexPath.item == 0 {
                                        // Item is being dropped at the beginning.
                                        snapshot.moveItem(pageItem, beforeItem: dropItemLocation)
                                    } else {
                                        // Item is being dropped between items or at the very end.
                                        snapshot.moveItem(pageItem, afterItem: dropItemLocation)
                                    }
                                }
                            }
                        }
                        
                    } catch {
                        Swift.debugPrint("failed to unarchive indexPath for dropped item.")
                    }
                }
            })
        dataSource.apply(snapshot, animatingDifferences: true)

        // Compute the new flattened document order (section 0 items, then section 1 items, ...)
        let newOrder = flattenedPageOrder(from: snapshot)
        prax.remapTrims(using: newOrder)
        
        // If we can determine the originally dragged page logical index, preserve selection
        var originalDraggedLogicalIndex: Int? = nil
        draggingInfo.enumerateDraggingItems(options: [], for: collectionView, classes: [NSPasteboardItem.self], searchOptions: [:]) { draggingItem, _, _ in
            if let pasteboardItem = draggingItem.item as? NSPasteboardItem,
               let data = pasteboardItem.data(forType: .itemDragType),
               let nsIndexPath = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSIndexPath.self, from: data) {
                let sourceIndexPath = nsIndexPath as IndexPath
                if let pageItem = self.dataSource.itemIdentifier(for: sourceIndexPath) {
                    originalDraggedLogicalIndex = pageItem.index
                }
            }
        }

        // Reorder the PDF document in place using exchanges
        reorderDocumentPagesInPlaceUsingExchange(to: newOrder)

        // Update selection to the new location of the dragged page, if available
        if let original = originalDraggedLogicalIndex {
            updateSelectionForMovedPage(originalLogicalIndex: original, newOrder: newOrder)
        }
    }
    
}

extension NSPasteboard.PasteboardType {
    static let itemDragType = NSPasteboard.PasteboardType("com.praxpress.pdfPageDragType")
}


class FilePromiseProvider: NSFilePromiseProvider, NSFilePromiseProviderDelegate {
    
    struct UserInfoKeys {
        static let indexPathKey = "indexPath"
        static let urlKey = "url"
    }
    
    
    /** Required:
     Return an array of UTI strings of data types the receiver can write to the pasteboard.
     By default, data for the first returned type is put onto the pasteboard immediately, with the remaining types being promised.
     To change the default behavior, implement -writingOptionsForType:pasteboard: and return
     NSPasteboardWritingPromised to lazily provided data for types, return no option to provide the data for that type immediately.
     
     Use the pasteboard argument to provide different types based on the pasteboard name, if desired.
     Do not perform other pasteboard operations in the function implementation.
     */
    override func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        var types = super.writableTypes(for: pasteboard)
        types.append(.itemDragType) // Add our own internal drag type (row drag and drop reordering).
        types.append(.fileURL) // Add the .fileURL drag type (to promise files to other apps).
        return types
    }
    
    /** Required:
     Return the appropriate property list object for the provided type.
     This will commonly be the NSData for that data type.  However, if this function returns either a string, or any other property-list type,
     the pasteboard will automatically convert these items to the correct NSData format required for the pasteboard.
     */
    override func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        guard let userInfoDict = userInfo as? [String: Any] else { return nil }
        switch type {
        case .fileURL:
            // Incoming type is "public.file-url", return (from our userInfo) the item's URL.
            if let url = userInfoDict[FilePromiseProvider.UserInfoKeys.urlKey] as? NSURL {
                return url.pasteboardPropertyList(forType: type)
            }
        case .itemDragType:
            // Incoming type is "com.mycompany.mydragdrop", return (from our userInfo) the item's indexPath.
            let indexPathData = userInfoDict[FilePromiseProvider.UserInfoKeys.indexPathKey]
            return indexPathData
        default:
            break
        }
        return super.pasteboardPropertyList(forType: type)
    }
    
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        
        print("filePromiseProvider fileNameForType: ", fileType)
        return "Prax.pdf"
    }
    
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL) async throws {
        
        print("filePromiseProvider writePromiseTo url:  ", url)
        
    }
    
}

