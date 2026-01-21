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
            pageItem.indexPath = indexPath
           // pageItem.pageIndex = identifier.index
            pageItem.imageView?.image = identifier.thumbnail
            pageItem.textField?.stringValue = identifier.name
            pageItem.trimLabel?.stringValue = "\(identifier.trim.left)"
            pageItem.guidePageButton?.state = self.prax.widthGuidePage == identifier ? .on : .off
            return pageItem
        }
        dataSource.supplementaryViewProvider = {
            (collectionView: NSCollectionView, kind: String, indexPath: IndexPath) -> (NSView & NSCollectionViewElement)? in
            
            let pdfPageSection = self.prax.pdfPageSections[indexPath.section]
            
            if kind == PagesViewController.sectionHeaderElementKind {
                if let supplementaryView = collectionView.makeSupplementaryView(
                    ofKind: kind,
                    withIdentifier: PagesSectionHeader.reuseIdentifier,
                    for: indexPath) as? PagesSectionHeader {
                    supplementaryView.label.stringValue = self.prax.pdfPageSections[indexPath.section].title
                    return supplementaryView
                }
            }
            else if kind == PagesViewController.sectionFooterElementKind {
                if let supplementaryView = collectionView.makeSupplementaryView(
                    ofKind: kind,
                    withIdentifier: PagesSectionFooter.reuseIdentifier,
                    for: indexPath) as? PagesSectionFooter {

                    supplementaryView.configure(for: indexPath)
                    
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
                    
                    supplementaryView.label.stringValue = text
                    return supplementaryView
                }
            }
            fatalError("Cannot create new supplementary view of kind: \(kind)")
        }
    }
    
    private func updateUI(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<PDFPageSection, PDFPageItem>()
        let secs = prax.pdfPageSections
        secs.forEach {
            snapshot.appendSections([$0])
            snapshot.appendItems($0.pdfPageItems)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>){
        print("PagesViewController didSelectItemsAt indexPaths ", indexPaths)
        
        prax.selectionIndexPaths = collectionView.selectionIndexPaths
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>){
        print("PagesViewController didDeselectItemsAt indexPaths ", indexPaths)
        prax.selectionIndexPaths = collectionView.selectionIndexPaths
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
        
 //       guard let pageItem = dataSource.itemIdentifier(for: IndexPath(item: indexPath.item, section: 0)) else { return provider }
        
        let typeIdentifier = UTType(filenameExtension: "pdf")
        
        provider = FilePromiseProvider()
        provider!.fileType = typeIdentifier!.identifier
        provider!.delegate = provider as? any NSFilePromiseProviderDelegate
        // Send out the indexPath and photo's url dictionary.
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: indexPath, requiringSecureCoding: false)
            provider!.userInfo = [FilePromiseProvider.UserInfoKeys.urlKey: prax.editingPDFURL as Any,FilePromiseProvider.UserInfoKeys.indexPathKey: data]
        } catch {
            fatalError("failed to archive indexPath to pasteboard")
        }
        return provider
    }
    
    func collectionView(
        _ collectionView: NSCollectionView, validateDrop draggingInfo: any NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>
    ) -> NSDragOperation {
        
   //     let indPth = proposedDropIndexPath.pointee
   //     print("PagesViewController validateDrop  ", indPth.debugDescription)
        
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
                        if let data = pasteboardItem.data(forType: .itemDragType) {
                            let nsIndexPath = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSIndexPath.self, from: data)
                            if let nsIndexPath {
                                let pageIndexPath = nsIndexPath as IndexPath
                                draggedItems.append(pageIndexPath)
                            }
                        }
                    } catch { Swift.debugPrint("failed to unarchive indexPath for dropped item.") }
                    
                    print ("elf.prax.movePDFPageItems(draggedItems: ", draggedItems, " to indexPath: ", indexPath)
                    self.prax.movePDFPageItems(draggedItems, to: indexPath)
                    self.updateUI()
                }
            })
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

    override func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        var types = super.writableTypes(for: pasteboard)
        types.append(.itemDragType) // Add our own internal drag type (row drag and drop reordering).
        types.append(.fileURL) // Add the .fileURL drag type (to promise files to other apps).
        return types
    }
    
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
        PraxModel.shared.editingPDFDocument.write(to: url)  
        
    }
    
}

