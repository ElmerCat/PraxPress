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
    
    func addPagesFromURLBookmark(title: String? = nil, url: URL?, bookmarkData: Data?, to pageSection: MergedPage?, at location: Int? = 0) {
 //       guard let ctx = windowModelContext else { return }
        
        // Determine normalized section insertion index
        let sectionIndex = normalizedInsertionIndex(count: pageSections.count, location: location)
        
        // Determine target section
        let mergedPage: MergedPage = {
            if let givenSection = pageSection {
                ensureSectionInOrder(givenSection, at: sectionIndex)
                return givenSection
            } else {

                let newMergedPage = MergedPage(document: self, title: (title ?? (url?.deletingPathExtension().lastPathComponent)) ?? "New Page Section")
                
       //         let newSection = PDFPageSectionModel(title: (title ?? (url?.deletingPathExtension().lastPathComponent)) ?? "New Page Section", orderIndex: sectionIndex)
       //         windowModelContext.insert(newSection)
                pageSections.insert(newMergedPage, at: sectionIndex)
                return newMergedPage
            }
        }()
        
        // If neither URL nor bookmark provided, just save new empty section
        guard url != nil || bookmarkData != nil else {
            do { try windowModelContext.save() } catch { print("Save failed: \(error)") }
            refreshMergedDocument()
            return
        }
        
        // Resolve bookmark or direct url
        let fileURL: URL
        let baseBookmark: Data
        if let data = bookmarkData {
            var isStale = false
            guard let resolved = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) else {
                print("addPagesFromURLBookmark - Error resolvingBookmarkData for URL: ", url ?? "No URL")
        //        do { try windowModelContext.save() } catch { print("Save failed: \(error)") }
                refreshMergedDocument()
                return
            }
            fileURL = resolved
            baseBookmark = data
        } else if let direct = url {
            fileURL = direct
            baseBookmark = (try? direct.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)) ?? Data()
        } else {
            print("addPagesFromURLBookmark - no valid bookmark or url")
      //      do { try windowModelContext.save() } catch { print("Save failed: \(error)") }
            refreshMergedDocument()
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
                        sourceBookmark: baseBookmark,
                        sourceURL: fileURL,
                        pageIndex: index,
                        pdfPage: doc.page(at: index)!

                    )
                mergedPage.pageItems.insert(item, at: pageInsertIndex)
              //  windowModelContext.insert(item)
                pageInsertIndex += 1
                
            }
            
        }
        
        // Normalize page insertion index relative to pageItems count in section
        
        do { try windowModelContext.save() } catch { print("Save failed: \(error)") }
        refreshMergedDocument()
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
    
    func indexOfSection(_ section: PDFPageSectionModel) -> Int? {
        pageSections.firstIndex { $0 === section }
    }
    
    func indexOfPageItem(_ item: PDFPageItemModel, in section: PDFPageSectionModel) -> Int? {
        section.pageItems.firstIndex { $0 === item }
    }
    
    
    
    
    // MARK: - Cross-section move/copy

        func performDropOrAction(for item: PDFPageItemModel,
                                 to destinationSection: PDFPageSectionModel,
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
        func moveItem(_ item: PDFPageItemModel,
                      to destinationSection: PDFPageSectionModel,
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

            do { try windowModelContext.save() } catch { print("Move save failed: \(error)") }
            refreshMergedDocument()
        }

        /// Copy an item to a destination section at a specific logical location.
        /// Creates a new PDFPageItemModel that shares the same source/bookmark and pageIndex.
        func copyItem(_ item: PDFPageItemModel,
                      to destinationSection: PDFPageSectionModel,
                      at location: Int? = nil) {
//guard let windowModelContext = windowModelContext else { return }

            let resolvedURL = item.resolveSourceURL() ?? URL(fileURLWithPath: item.sourceURLString)

            let clone = PDFPageItemModel(
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

            windowModelContext.insert(clone)
            do { try windowModelContext.save() } catch { print("Copy save failed: \(error)") }
            refreshMergedDocument()
        }
    
    
}

