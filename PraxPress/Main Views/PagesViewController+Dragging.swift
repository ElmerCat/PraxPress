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
        provider.pdfDocument = document!.mergedPDFDocument
        provider.fileName = "PraxPress-Page.pdf"
        provider.fileType = typeIdentifier!.identifier
        provider.delegate = provider
        // Send out the indexPath and photo's url dictionary.
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: indexPath, requiringSecureCoding: false)
            provider.userInfo = [FilePromiseProvider.UserInfoKeys.urlKey: document!.mergedPDFURL as Any,
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
        else if draggingTypes.contains(.pdfFileType) {
            dropInternalSections(collectionView, draggingInfo: draggingInfo, indexPath: indexPath)
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
        let pasteboard = draggingInfo.draggingPasteboard
        let receivers = pasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self], options: nil) as? [NSFilePromiseReceiver] ?? []
        if !receivers.isEmpty {
            receivePromisedPDFs(from: receivers, at: indexPath)
            return
        }

        
        
        var pdfURLs: [URL] = []
        
        // 1) Prefer file URLs if available
        if let items = pasteboard.pasteboardItems {
 
            for item in items {
                
                // Try public.file-url first
                if let urlString = item.string(forType: .fileURL),
                   let url = URL(string: urlString) {
                    print("fileURL  ", url)
                    pdfURLs.append(url)
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
                            pdfURLs.append(tempURL)
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
        if pdfURLs.isEmpty, let propertyList = pasteboard.propertyList(forType: .fileURL) {
            // propertyList can be a String or array of Strings (file URL strings)
            func parseURLStrings(_ value: Any) -> [URL] {
                var urls: [URL] = []
                if let s = value as? String, let u = URL(string: s) { urls.append(u) }
                else if let arr = value as? [String] {
                    urls.append(contentsOf: arr.compactMap { URL(string: $0) })
                }
                return urls
            }
            pdfURLs = parseURLStrings(propertyList)
        }
        
        for url in pdfURLs {
            print ("\n\(url)")
        }
        

        // 3) Filter for PDFs (by path extension or UTI check)
        let urls = pdfURLs.filter { $0.pathExtension.lowercased() == "pdf" }
        
        Task {
            do {
                try await document!.insertPDFPageSectionsFromDocumentURLS(urls, at: indexPath)
            } catch let error {
                print("Julie d Prax", urls, "Error: ", error)
                
            }
        }
        
        
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
            
            Task {
                do {
                    try await self.document!.insertPDFPageSectionsFromDocumentURLS(urls, at: indexPath)
                } catch let error {
                    print("Julie d Prax", urls, "Error: ", error)
                    
                }
            }
            
        }
    }
    
    
    // MARK: - Insert helper

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
                    self.document!.movePDFPageItems(draggedItems, to: indexPath)
                    self.updateUI()
                }
            })
    }
    
    
    
    
}

extension NSPasteboard.PasteboardType {
    static let pdfPageDragType = NSPasteboard.PasteboardType("com.praxpress.pdf-page-item")
    static let pdfPageSectionType = NSPasteboard.PasteboardType("com.praxpress.pdf-page-section")
    static let pdfFileType = NSPasteboard.PasteboardType("com.praxpress.pdf-file-item")
}

extension UTType {
    static let pdfPageDragType = UTType(exportedAs: "com.praxpress.pdf-page-item")
    static let pdfPageSectionType = UTType(exportedAs: "com.praxpress.pdf-page-section")
    static let pdfFileType = UTType(exportedAs: "com.praxpress.pdf-file-item")
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
        types.append(.pdfPageDragType) // Add our own internal drag type (row drag and drop reordering).
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

