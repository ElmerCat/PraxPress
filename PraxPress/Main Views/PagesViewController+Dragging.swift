//
//  PagesViewController + Dragging.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/22/26.
//


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

extension PagesViewController {
         
    func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent
    ) -> Bool {
        print("PagesViewController canDragItemsAt  ", indexPaths, " event ", event)
        return true
    }
    
    func collectionView(_ collectionView: NSCollectionView,
                        pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        
        print("PagesViewController pasteboardWriterForItemAt  ", indexPath)

        
        //       guard let pageItem = dataSource.itemIdentifier(for: IndexPath(item: indexPath.item, section: 0)) else { return provider }
        
        let typeIdentifier = UTType(filenameExtension: "pdf")
        
        let provider = FilePromiseProvider()
        provider.pdfDocument = PraxModel.shared.editingPDFDocument
        provider.fileName = "PraxPress-Page.pdf"
        provider.fileType = typeIdentifier!.identifier
        provider.delegate = provider
        // Send out the indexPath and photo's url dictionary.
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: indexPath, requiringSecureCoding: false)
            provider.userInfo = [FilePromiseProvider.UserInfoKeys.urlKey: PraxModel.shared.editingPDFURL as Any,
                                  FilePromiseProvider.UserInfoKeys.indexPathKey: data]
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
        
        guard let draggingTypes = draggingInfo.draggingPasteboard.types else { return false }
        
        if draggingTypes.contains(.pdfPageDragType) {
            dropInternalPages(collectionView, draggingInfo: draggingInfo, indexPath: indexPath)
        }
        else if draggingTypes.contains(.pdfPageSectionType) {
            dropInternalSections(collectionView, draggingInfo: draggingInfo, indexPath: indexPath)
        }
        
        else {
            // The drop source is from another app (Finder, Mail, Safari, etc.) and there may be more than one file.
            // Drop each dragged image file to their new place.
            dropExternalPages(collectionView, draggingInfo: draggingInfo, indexPath: indexPath)
        }
        return true
    }
    
    func dropExternalPages(_ collectionView: NSCollectionView, draggingInfo: NSDraggingInfo, indexPath: IndexPath) {
        print("dropExternalPages  ", indexPath)
        
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
                    
                    print ("elf.prax.movePDFPageItems(draggedItems: ", draggedItems, " to indexPath: ", indexPath)
                    PraxModel.shared.movePDFPageItems(draggedItems, to: indexPath)
                    self.updateUI()
                }
            })
    }
    
}

extension NSPasteboard.PasteboardType {
    static let pdfPageDragType = NSPasteboard.PasteboardType("com.praxpress.pdfPageDragType")
    static let pdfPageSectionType = NSPasteboard.PasteboardType("com.praxpress.pdfPageSectionType")
}


class FilePromiseProvider: NSFilePromiseProvider, NSFilePromiseProviderDelegate {
    
    var pdfDocument: PDFDocument?
    var fileName: String = "PraxPress-Prax.pdf"
    
    struct UserInfoKeys {
        static let indexPathKey = "indexPath"
        static let urlKey = "url"
    }
    
    override func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        var types = super.writableTypes(for: pasteboard)
        types.append(.pdfPageSectionType) // Add our own internal drag type (row drag and drop reordering).
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
        case .pdfPageSectionType:
            print ("pdfPageSectionType")
            // Incoming type is "com.mycompany.mydragdrop", return (from our userInfo) the item's indexPath.
            let indexPathData = userInfoDict[FilePromiseProvider.UserInfoKeys.indexPathKey]
            return indexPathData

        case .pdfPageDragType:
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
        return fileName
    }
    
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL) async throws {
        
        print("filePromiseProvider writePromiseTo url:  ", url)
        pdfDocument?.write(to: url)
        
    }
    
}

