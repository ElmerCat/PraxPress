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
     
    
    @Bindable var viewModel:  ViewModel
    @Bindable var pdfModel: PDFModel
    
    init(with viewModel: ViewModel, pdfModel: PDFModel) {
        self.viewModel = viewModel
        self.pdfModel = pdfModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static let sectionHeaderElementKind = "section-header-element-kind"
    static let sectionFooterElementKind = "section-footer-element-kind"
    
    @IBOutlet weak var collectionView: NSCollectionView!
    
    private var dataSource: NSCollectionViewDiffableDataSource<PDFPageSection, PDFPageItem>! = nil
    
    weak var pdfView: PDFView? {
        didSet {
            
            print("PagesViewController pdfView didSet")
            
            //  reloadData()
        }
    }
    
    private var observeDocumentChange: Task<Void, Never>?
    private var observeCurrentIndexChange: Task<Void, Never>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureDataSource()
        updateUI(animated: false)
        
        
        observeDocumentChange = Task {
            for await _ in Observations({ self.pdfModel.pdfDocument }) {
                print("PagesViewController observeDocumentChange  ", self.pdfModel.pdfDocument ?? "None")
                
                updateUI()
            }
        }
        observeCurrentIndexChange = Task {
            for await _ in Observations({ self.pdfModel.currentIndex }) {
                print("PagesViewController observeCurrentIndexChange  ", self.pdfModel.currentIndex)
                if collectionView?.numberOfSections == 0  { return }
                if (collectionView?.numberOfItems(inSection: 0) == 0)  { return }
                collectionView.selectionIndexPaths = [IndexPath(item: self.pdfModel.currentIndex, section: 0)]
            }
        }
    }
    
 }

extension PagesViewController {
    private func createLayout() -> NSCollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalWidth(1.3))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
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
        
        let layout = NSCollectionViewCompositionalLayout(section: section)
        return layout
    }
}

extension PagesViewController {
    private func configureHierarchy() {
        let itemNib = NSNib(nibNamed: "PageItem", bundle: nil)
        collectionView.register(itemNib, forItemWithIdentifier: PageItem.reuseIdentifier)
        
        let titleSupplementaryNib = NSNib(nibNamed: "TitleSupplementaryView", bundle: nil)
        collectionView.register(titleSupplementaryNib,
                                forSupplementaryViewOfKind: PagesViewController.sectionHeaderElementKind,
                                withIdentifier: TitleSupplementaryView.reuseIdentifier)
        collectionView.register(titleSupplementaryNib,
                                forSupplementaryViewOfKind: PagesViewController.sectionFooterElementKind,
                                withIdentifier: TitleSupplementaryView.reuseIdentifier)
        
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
            if let page = self.pdfModel.pdfDocument?.page(at: indexPath.item) {
                pageItem.imageView?.image = page.thumbnail(of: CGSize(width: 120, height: 160), for: .cropBox)
            } else {
                pageItem.imageView?.image = nil
            }
            pageItem.textField?.stringValue = identifier.name
            
            pageItem.guidePageButton?.state = self.pdfModel.widthGuidePageIndex == identifier.index ? .on : .off
            
            return pageItem
        }
        dataSource.supplementaryViewProvider = {
            (collectionView: NSCollectionView, kind: String, indexPath: IndexPath) -> (NSView & NSCollectionViewElement)? in
            if let supplementaryView = collectionView.makeSupplementaryView(
                ofKind: kind,
                withIdentifier: TitleSupplementaryView.reuseIdentifier,
                for: indexPath) as? TitleSupplementaryView {
                let viewKind = kind == PagesViewController.sectionHeaderElementKind ?
                PagesViewController.sectionHeaderElementKind : PagesViewController.sectionFooterElementKind
                supplementaryView.label.stringValue = self.pdfModel.pdfSections[indexPath.section].title
                return supplementaryView
            } else {
                fatalError("Cannot create new supplementary")
            }
        }
    }
    
    private func updateUI(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<PDFPageSection, PDFPageItem>()
        pdfModel.pdfSections.forEach {
            snapshot.appendSections([$0])
            snapshot.appendItems(pdfModel.pdfPages)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>){
        print("PagesViewController didSelectItemsAt indexPaths ", indexPaths)
        pdfModel.updateCurrentIndex(indexPaths: indexPaths)
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
            provider!.userInfo = [FilePromiseProvider.UserInfoKeys.urlKey: pdfModel.fileURL as Any,FilePromiseProvider.UserInfoKeys.indexPathKey: data]
        } catch {
            fatalError("failed to archive indexPath to pasteboard")
        }
        return provider
    }
    
    func collectionView(
        _ collectionView: NSCollectionView, validateDrop draggingInfo: any NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>
    ) -> NSDragOperation {
        
        print("PagesViewController validateDrop  ", draggingInfo, " proposedIndexPath ", proposedDropIndexPath, " dropOperation ", proposedDropOperation)
        
        var dragOperation: NSDragOperation = [.move]
        
        return dragOperation
    }

    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
        
        print("PagesViewController acceptDrop  ", draggingInfo, " indexPath: ", indexPath, " dropOperation ", dropOperation)
        
        // Check where the dragged items are coming from.
        if let draggingSource = draggingInfo.draggingSource as? NSCollectionView, draggingSource == collectionView {
            // Drag source from your own collection view.
            // Move each dragged photo item to their new place.
            dropInternalPages(collectionView, draggingInfo: draggingInfo, indexPath: indexPath)
        } else {
            // The drop source is from another app (Finder, Mail, Safari, etc.) and there may be more than one file.
            // Drop each dragged image file to their new place.
            dropExternalPages(collectionView, draggingInfo: draggingInfo, indexPath: indexPath)
        }
        return true
    }
    
    
    
    func dropExternalPages(_ collectionView: NSCollectionView, draggingInfo: NSDraggingInfo, indexPath: IndexPath) {

        print("dropExternalPages  ", draggingInfo, " indexPath: ", indexPath)
        
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
    
    
    func dropInternalPages(_ collectionView: NSCollectionView, draggingInfo: NSDraggingInfo, indexPath: IndexPath) {
        
        print("dropInternalPages  ", draggingInfo, " indexPath: ", indexPath)
        
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
                                let photoIndexPath = nsIndexPath as IndexPath
                                if let photoItem = self.dataSource.itemIdentifier(for: photoIndexPath) {
                                    // Find out the proper indexPath drop point.
                                    let toIndexPath = self.dropLocation(indexPath: indexPath)
                                    
                                    let dropItemLocation = snapshot.itemIdentifiers[toIndexPath.item]
                                    
                                    print("\ndropItemLocation  ", dropItemLocation, " toIndexPath: ", toIndexPath)
                                    
                                    if toIndexPath.item == 0 {
                                        // Item is being dropped at the beginning.
                                        snapshot.moveItem(photoItem, beforeItem: dropItemLocation)
                                    } else {
                                        // Item is being dropped between items or at the very end.
                                        snapshot.moveItem(photoItem, afterItem: dropItemLocation)
                                    }
                                }
                            }
                        }
                        
                    } catch {
                        Swift.debugPrint("failed to unarchive indexPath for dropped photo item.")
                    }
                }
            })
        dataSource.apply(snapshot, animatingDifferences: true)
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
