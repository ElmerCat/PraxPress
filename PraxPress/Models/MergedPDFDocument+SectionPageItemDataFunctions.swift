//
//  MergedPDFDocument+SectionPageItemDataFunctions.swift
//  PraxPress
//
//  Created by Elmer Cat on 3/2/26.
//

private let DEBUG_LOGS = true

import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers

extension MergedPDFDocument {
    
    func mergedPagefrom(_ url: URL, at indexPath: IndexPath? = nil, title: String? = nil) -> MergedPage  {
        if indexPath == nil || indexPath?.section ?? -1 < 0 {
            let mergedPage = MergedPage(document: self, title: (title ?? (url.deletingPathExtension().lastPathComponent)))
            pageSections.append(mergedPage)
            return mergedPage
        }
        else {
            let index = max(indexPath!.section, pageSections.count - 1)
            return pageSections[index]
        }
    }
    
    
    func addPagesFromPDFURL(_ url: URL, at indexPath: IndexPath? = nil, title: String? = nil) {
        let mergedPage = mergedPagefrom(url, at: indexPath)
        var location = 1
        if let indexPath {
            location = indexPath.item + 1
        }
    
        if let doc = PDFDocument(url: url) {
//            pageCount = doc.pageCount
            var pageInsertIndex = normalizedInsertionIndex(count: mergedPage.pageItems.count, location: location)
            for index in 0..<doc.pageCount {
                let displayName = nameForPage(url: url, index: index)
                let item = PageItem(
                        mergedPage: mergedPage,
                        name: displayName,
                        sourceBookmark: Data(),
                        sourceURL: url,
                        sourcePageIndex: index,
                        pdfPage: doc.page(at: index)!,
                        dataFields: [:]
                    )
                mergedPage.pageItems.insert(item, at: pageInsertIndex)
                pageInsertIndex += 1
            }
        }
        else {
            print("No PDFDocument from url: ", url)
        }
    }

    
    func addPageFromImageURL(_ url: URL,  at indexPath: IndexPath? = nil, title: String? = nil) {
        @AppStorage("import-width") var importWidth: Int = 0
        @AppStorage("import-height") var importHeight: Int = 0
        
        let mergedPage = mergedPagefrom(url, at: indexPath)
        var location = 1
        if let indexPath {
            location = indexPath.item + 1
        }
        var pageInsertIndex = normalizedInsertionIndex(count: mergedPage.pageItems.count, location: location)
        guard var image = NSImage(contentsOf: url) else { fatalError("Failed to open Image at \(url)") }
        var imageSize = image.size
        if image.size.height > CGFloat(importHeight) || image.size.width > CGFloat(importWidth){
            let aspectRatio = imageSize.height / imageSize.width
            if aspectRatio > 1 {
                imageSize.height =  CGFloat(importHeight)
                imageSize.width =  CGFloat(importHeight) / aspectRatio
            }
            else {
                imageSize.height =  CGFloat(importWidth) * aspectRatio
                imageSize.width =  CGFloat(importWidth) / aspectRatio

            }
        }
        
        print (image.size)
        print (imageSize)
        
        image = image.resize(to: imageSize)!
        print (image.size)

        guard let pdfPage = PDFPage(image: image) else { fatalError("Failed to create PDFPage from Image at \(url)")}
        let pageItem = PageItem(mergedPage: mergedPage,
                                name: url.deletingPathExtension().lastPathComponent,
                                sourceURL: url, pdfPage: pdfPage, dataFields: [:])
            
        mergedPage.pageItems.insert(pageItem, at: pageInsertIndex)
          
      }

  
    
    func addPagesFrom(pdfFile: PDFFile, to pageSection: MergedPage?, at location: Int? = 0, title: String? = nil) {

 //   func addPagesFromURLBookmark(, url: URL?, bookmarkData: Data?, to pageSection: MergedPage?, at location: Int? = 0) {
 //       guard let ctx = windowModelContext else { return }
        
        // Determine normalized section insertion index
        let sectionIndex = normalizedInsertionIndex(count: pageSections.count, location: location)
        
        // Determine target section
        let mergedPage: MergedPage = {
            if let givenSection = pageSection {
                ensureSectionInOrder(givenSection, at: sectionIndex)
                return givenSection
            } else {

                let newMergedPage = MergedPage(document: self, title: (title ?? (pdfFile.url.deletingPathExtension().lastPathComponent)))
  
                pageSections.insert(newMergedPage, at: sectionIndex)
                return newMergedPage
            }
        }()
        
/*        // If neither URL nor bookmark provided, just save new empty section
        guard url != nil || pdfFile.bookmarkData != nil else {
         //   do { try windowModelContext.save() } catch { print("Save failed: \(error)") }
        //    refreshMergedDocument()
            return
        }
*/
        
        // Resolve bookmark or direct url
/*        let fileURL: URL
        let baseBookmark: Data
        if let data = pdfFile.bookmarkData {
            var isStale = false
            guard let resolved = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) else {
                print("addPagesFromURLBookmark - Error resolvingBookmarkData for URL: ", url ?? "No URL")
        //        do { try windowModelContext.save() } catch { print("Save failed: \(error)") }
         //       refreshMergedDocument()
                return
            }
            fileURL = resolved
            baseBookmark = data
        } else if let direct = pdfFile.url {
            fileURL = direct
            baseBookmark = (try? direct.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)) ?? Data()
        } else {
            print("addPagesFromURLBookmark - no valid bookmark or url")
      //      do { try windowModelContext.save() } catch { print("Save failed: \(error)") }
      //      refreshMergedDocument()
            return
        }
        
*/
        var isStale = false
        guard let fileURL = try? URL(resolvingBookmarkData: pdfFile.bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            else {
            print("addPagesFromURLBookmark - Error resolvingBookmarkData for URL: ", pdfFile.url)
    //        do { try windowModelContext.save() } catch { print("Save failed: \(error)") }
     //       refreshMergedDocument()
            return
        }
        
        let needsStop = fileURL.startAccessingSecurityScopedResource()
        defer { if needsStop { fileURL.stopAccessingSecurityScopedResource() } }
        
        // Determine page count fallback to 1
        var pageCount = 1
        if let doc = PDFDocument(url: fileURL) {
            pageCount = doc.pageCount
            var pageInsertIndex = normalizedInsertionIndex(count: mergedPage.pageItems.count, location: location)
            
            // Insert pages one by one at the computed index, preserving order
            for index in 0..<pageCount {
                let displayName = nameForPage(url: fileURL, index: index)
                
                let item = PageItem(
                        mergedPage: mergedPage,
                        name: displayName,
                        sourceBookmark: pdfFile.bookmarkData,
                        sourceURL: fileURL,
                        sourcePageIndex: index,
                        pdfPage: doc.page(at: index)!,
                        dataFields: pdfFile.dataFields ?? [:]
                    )
                
                mergedPage.pageItems.insert(item, at: pageInsertIndex)
              //  windowModelContext.insert(item)
                pageInsertIndex += 1
                
            }
            
        }
        
        // Normalize page insertion index relative to pageItems count in section
        
    //    do { try windowModelContext.save() } catch { print("Save failed: \(error)") }
    //    refreshMergedDocument()
    }
    

    
    private func nameForPage(url: URL, index: Int) -> String {
        let base = url.deletingPathExtension().lastPathComponent
        return "\(base) [\(index + 1)]"
    }
    
    private func normalizedInsertionIndex(count: Int, location: Int?) -> Int {
        // If location is nil or 0, insert at end
        // If location is 1, insert at beginning
        // If greater than 1, insert at that page, but not beyond count
        // If less than -1, count backwards from end, but not before beginning
        guard let loc = location else { return count }
        if loc == 0 {
            return count
        } else if loc > 0 {
            return min(loc - 1, count)
        } else {
            let pos = count + loc
            return pos < 0 ? 0 : pos
        }
    }
    
    private func ensureSectionInOrder(_ section: MergedPage, at index: Int) {
        if let currentIndex = pageSections.firstIndex(where: { $0 === section }) {
            if currentIndex != index {
                pageSections.remove(at: currentIndex)
                if index > pageSections.count {
                    pageSections.append(section)
                } else {
                    pageSections.insert(section, at: index)
                }
            }
        } else {
            if index > pageSections.count {
                pageSections.append(section)
            } else {
                pageSections.insert(section, at: index)
            }
        }
    }
    
    func indexOfSection(_ section: MergedPage) -> Int? {
        pageSections.firstIndex { $0 === section }
    }
    
    func indexOfPageItem(_ item: PageItem, in section: MergedPage) -> Int? {
        section.pageItems.firstIndex { $0 === item }
    }
    
    
    
/*
 
 
 
 func insertPDFPageSectionsFromImageURLS(_ urls: [URL], at indexPath: IndexPath) {
     
     for url in urls {
         guard var image = NSImage(contentsOf: url) else { fatalError("Failed to open Image at \(url)") }
         image = image.resize(to: NSSize(width: 50, height: 70))!
         
         let sourceFileName = url.deletingPathExtension().lastPathComponent
         guard let docPage = PDFPage(image: image) else { fatalError("Failed to create PDFPage from Image at \(url)")}
         let pageItem = PDFPageItem(
             document: self,
             name: "Image - \(sourceFileName)",
             pdfPage: docPage
         )
         pageSections.append(PDFPageSection(document: self, title: "Image - \(sourceFileName)", pageItems: [pageItem]))
     }
     
 }


 
 
 
 
    // MARK: - Cross-section move/copy

        func performDropOrAction(for item: PageItem,
                                 to destinationSection: MergedPage,
                                 at location: Int? = nil) {
            // One path for both same-section and cross-section:
            if prax.optionKeyPressed == true {
                copyItem(item, to: destinationSection, at: location)
            } else {
                moveItem(item, to: destinationSection, at: location)
            }
        }

        /// Move an existing item to a destination section at a specific logical location.
        /// - Parameter location: Insertion semantics:
        ///   - nil or 0: append at end
        ///   - > 0: insert before that 1-based position (1 means at beginning)
        ///   - < 0: count backward from end (e.g., -1 means before last, clamp to 0)
        func moveItem(_ item: PageItem,
                      to destinationSection: MergedPage,
                      at location: Int? = nil) {
         //   guard let ctx = windowModelContext else { return }

            // Capture same-section context and source index BEFORE mutation
            let movingWithinSameSection = (item.pageSection === destinationSection)
            let sourceIndex = item.pageSection?.pageItems.firstIndex(where: { $0.id == item.id })

            // Compute destination index based on the current (pre-removal) count
            let preRemovalCount = destinationSection.pageItems.count
            var destIndex = normalizedInsertionIndex(count: preRemovalCount, location: location)

            // If moving within the same section and the source index is before the destination,
            // the removal will shift indices left by 1, so adjust the destination index.
            if movingWithinSameSection, let s = sourceIndex, s < destIndex {
                destIndex = max(0, destIndex - 1)
            }

            // Remove from source section if any (same-section moves supported)
            if let src = item.pageSection,
               let idx = src.pageItems.firstIndex(where: { $0.id == item.id }) {
                src.pageItems.remove(at: idx)
                for (i, it) in src.pageItems.enumerated() { it.orderIndex = i }
                src.pageItems = src.pageItems
            }

            // Insert into destination relationship at computed index
            item.pageSection = destinationSection
            let clamped = max(0, min(destIndex, destinationSection.pageItems.count))
            destinationSection.pageItems.insert(item, at: clamped)

            // Normalize destination by position and assign back
            for (i, it) in destinationSection.pageItems.enumerated() { it.orderIndex = i }
            destinationSection.pageItems = destinationSection.pageItems

 //           do { try windowModelContext.save() } catch { print("Move save failed: \(error)") }
            refreshMergedDocument()
        }

        /// Copy an item to a destination section at a specific logical location.
        /// Creates a new PageItem that shares the same source/bookmark and pageIndex.
        func copyItem(_ item: PageItem,
                      to destinationSection: MergedPage,
                      at location: Int? = nil) {
//guard let windowModelContext = windowModelContext else { return }

            let resolvedURL = item.resolveSourceURL() ?? URL(fileURLWithPath: item.sourceURLString)

            let clone = PageItem(
                name: item.name,
                aspectRatio: item.aspectRatio,
                trimLeft: item.trimLeft,
                trimRight: item.trimRight,
                trimTop: item.trimTop,
                trimBottom: item.trimBottom,
                sourceBookmark: item.sourceBookmark,
                sourceURL: resolvedURL,
                pageIndex: item.pageIndex,
                orderIndex: 0,
                mergeModeRaw: item.mergeModeRaw
            )
            clone.pageSection = destinationSection

            // Destination index (1-based insert-before, 0 or nil = append)
            let destIndex = normalizedInsertionIndex(count: destinationSection.pageItems.count, location: location)

            destinationSection.pageItems.insert(clone, at: max(0, min(destIndex, destinationSection.pageItems.count)))

            for (i, it) in destinationSection.pageItems.enumerated() { it.orderIndex = i }
            destinationSection.pageItems = destinationSection.pageItems

 //           windowModelContext.insert(clone)
  //          do { try windowModelContext.save() } catch { print("Copy save failed: \(error)") }
            refreshMergedDocument()
        }
 */
    
}

