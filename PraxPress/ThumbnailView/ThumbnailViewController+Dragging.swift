//
//  ThumbnailViewController + Dragging.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/22/26.
//

import Cocoa
import PDFKit
import AppKit
import SwiftUI
import Observation
import UniformTypeIdentifiers

extension ThumbnailViewController {
    
         
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
                    self.updateUI()
                }
            })
    }
    
    
   
    
    
    
}

extension NSImage {
    func resize(to newSize: NSSize) -> NSImage? {
        guard let tiffData = self.tiffRepresentation,
              let bitmapImageRep = NSBitmapImageRep(data: tiffData) else { return nil }
        
        let newRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(newSize.width),
            pixelsHigh: Int(newSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: newRep!)
        bitmapImageRep.draw(in: NSRect(origin: .zero, size: newSize))
        NSGraphicsContext.restoreGraphicsState()
        
        let resizedImage = NSImage(size: newSize)
        resizedImage.addRepresentation(newRep!)
        return resizedImage
    }
}
