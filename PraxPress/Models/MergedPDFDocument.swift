//
//  MergedPDFDocument.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/22/26.
//

import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers
import Foundation
import OSLog


@Observable @MainActor class MergedPDFDocument {
    unowned let prax: PraxModel
    unowned let persistence: PersistenceController
    
    init(prax: PraxModel, persistence: PersistenceController) {
        self.prax = prax
        self.persistence = persistence
    }
    var widthGuidePageID: UUID? = nil
    var widthGuideLeftX: CGFloat? = nil
    var widthGuideRightX: CGFloat? = nil
    

    private var _mergedPages: [MergedPage] = []
    var mergedPages: [MergedPage] {
        get { _mergedPages }
        set {
            guard newValue != _mergedPages else { return }
            print("MergedPDFDocument - mergedPages: didSet ")
            
            let oldValue = _mergedPages
            prax.undoManager.registerUndo(withTarget: self, handler: {
                $0.mergedPages = oldValue
            })
            prax.undoManager.setActionName(oldValue.count < newValue.count ? "Add Merged Pages" : "Delete Merged Pages")
            if newValue.isEmpty {

                clearMergedDocument()
            }
            _mergedPages = newValue
         }
    }


    var mergedDocumentVersion = UUID()
    var mergedDocumentSizeKB = 0
    
    var refreshingMergedDocument: Bool = false
    func refreshMergedDocument() {
        if refreshingMergedDocument { return }
     //   print("refreshMergedDocument")
        refreshingMergedDocument = true
        
        Task {
            
            try? await Task.sleep(for:.milliseconds(100))

            var insertIndex = 0
            let pdfDocument = PDFDocument()
            
            for mergedPage in mergedPages {
                if let pdfPage = mergedPage.pdfPage {
                    
                    pdfDocument.insert(pdfPage, at: insertIndex)
                    insertIndex += 1
                }

            }
            

            mergedPDFDocument = pdfDocument
            mergedDocumentVersion = UUID()
            
            if let pdfData = pdfDocument.dataRepresentation() {
                let sizeInBytes = pdfData.count
                mergedDocumentSizeKB = sizeInBytes / (1000)
                print("mergedDocumentSizeKB: \(mergedDocumentSizeKB) KB")
            }
            self.refreshingMergedDocument = false
            print("refreshMergedDocument — done")
        }
  
    }

    var mergedPDFURL: URL = {
        FileManager.default.temporaryDirectory.appendingPathComponent("praxpress-merged").appendingPathExtension("pdf")
    }()
    
    var mergedPDFDocument: PDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)! {
        didSet {
           prax.mergedDocumentPDFView.document = mergedPDFDocument
        }
    }


    var sourceFolderURL: URL?
    var exportFolderURL: URL?
    //  var exportFolderURLBookmark: Data?
    var exportFileURLBookmark: Data?
    var exportFilenamePrefix: String = ""
    var exportFilenameBody: String = ""
    var exportFilenameSuffix: String = ""
    var exportFilenameExtension: String = "pdf"
    var exportFilename: String { exportFilenamePrefix + exportFilenameBody + exportFilenameSuffix }
    
    var exportFileURL: URL? {
        if exportFolderURL == nil { exportFolderURL = sourceFolderURL }
        guard let folder = exportFolderURL else { return nil }
        return folder.appending(component: exportFilename).appendingPathExtension(exportFilenameExtension) }
    
    func setExportURL(from pageItem: PageItem) {
        if let url = URL(string: pageItem.sourceURLString) {
            sourceFolderURL = url.deletingLastPathComponent()
            exportFilenameBody = url.deletingPathExtension().lastPathComponent
            if exportFolderURL == nil { exportFolderURL = sourceFolderURL } }
    }
    
    
    func mergedPagefrom(_ url: URL, at indexPath: IndexPath? = nil, title: String? = nil) -> MergedPage  {
        if indexPath == nil || indexPath?.section ?? -1 < 0 {
            let mergedPage = MergedPage(prax: prax, title: (title ?? (url.deletingPathExtension().lastPathComponent)))
            mergedPages.append(mergedPage)
            return mergedPage
        }
        else {
            let index = max(indexPath!.section, mergedPages.count - 1)
            return mergedPages[index]
        }
    }
    
    
    func addPagesFromPDFURL(_ url: URL, bookmarkData: Data? = nil, at indexPath: IndexPath? = nil, title: String? = nil) {
        var url = url
        if let bookmarkData {
            var isStale = false
            guard let fileURL = try? URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            else {  print("addPagesFromPDFURL - Error resolvingBookmarkData for URL: ", url) ; return  }
            url = fileURL
        }
        let needsStop = url.startAccessingSecurityScopedResource()
        defer { if needsStop { url.stopAccessingSecurityScopedResource() } }

        let mergedPage = mergedPagefrom(url, at: indexPath)
        let location = (indexPath?.item ?? 0) + 1
        
        if let pdfDocument = PDFDocument(url: url) {
            var pageInsertIndex = normalizedInsertionIndex(count: mergedPage.pageItems.count, location: location)
            for index in 0..<pdfDocument.pageCount {
                let displayName = nameForPage(url: url, index: index)
                let item = PageItem(
                        prax: prax,
                        mergedPage: mergedPage,
                        name: displayName,
                        sourceBookmark: Data(),
                        sourceURL: url,
                        sourcePageIndex: index,
                        pdfPage: pdfDocument.page(at: index)!,
                        dataFields: PDFFile.dataFieldsFromPDFDocument(pdfDocument)
                    )
                mergedPage.pageItems.insert(item, at: pageInsertIndex)
                pageInsertIndex += 1
            }
        }
        else {  print("No PDFDocument from url: ", url)  }
    }

    
    private func nameForPage(url: URL, index: Int) -> String {
        let base = url.deletingPathExtension().lastPathComponent
        return "\(base) [\(index + 1)]"
    }
    
    func normalizedInsertionIndex(count: Int, location: Int?) -> Int {
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
        if let currentIndex = mergedPages.firstIndex(where: { $0 === section }) {
            if currentIndex != index {
                mergedPages.remove(at: currentIndex)
                if index > mergedPages.count {
                    mergedPages.append(section)
                } else {
                    mergedPages.insert(section, at: index)
                }
            }
        } else {
            if index > mergedPages.count {
                mergedPages.append(section)
            } else {
                mergedPages.insert(section, at: index)
            }
        }
    }
    
    func indexOfSection(_ section: MergedPage) -> Int? {
        mergedPages.firstIndex { $0 === section }
    }
    
    func indexOfPageItem(_ item: PageItem, in section: MergedPage) -> Int? {
        section.pageItems.firstIndex { $0 === item }
    }
    
    var totalPageItems: Int {
        get {
            var total = 0
            for section in mergedPages {
                total += section.pageItems.count }
            return total
        }
    }
    
    func pageItem(id: UUID) -> PageItem? {
        for piSection in mergedPages.indices {
            let section = mergedPages[piSection]
            for piItem in section.pageItems.indices {
                let item = section.pageItems[piItem]
                if item.id == id {  // match found - return
                    return item } }
        }
        return nil
    }
    
    
    
    func pageItem(for pdfPage: PDFPage) -> PageItem? {
        for piSection in mergedPages.indices {
            let section = mergedPages[piSection]
            for piItem in section.pageItems.indices {
                let item = section.pageItems[piItem]
                if item.pdfPage.hashValue == pdfPage.hashValue {  // match found - return
                    return item } }
        }
        return nil
    }
    
    func indexPath(for pageItem: PageItem) -> IndexPath? {
        var section = 0
        for aSection in self.mergedPages {
            var item = 0
            for anItem in aSection.pageItems {
                if anItem == pageItem {  // match found - return
                    return IndexPath(item: item, section: section) }
                item += 1 }
            section += 1
        }
        return nil
    }
    
    func pageItem(indexPath: IndexPath) -> PageItem? {
        if mergedPages.count > indexPath.section {
            let mergedPage = mergedPages[indexPath.section]
            if mergedPage.pageItems.count > indexPath.item {  // match found - return
                return mergedPage.pageItems[indexPath.item] }
        }
        return nil
    }

    func copyPDFPageItems(_ items: [IndexPath], to destination: IndexPath) {
        guard !items.isEmpty else { return }
        // Ensure destination section exists
        guard mergedPages.indices.contains(destination.section) else { return }
        let mergedPage = mergedPages[destination.section]
        let insertIndex = destination.item
        var pageItems: [PageItem] = []
        for item in items {
            if let pageItem = pageItem(indexPath: item) {
                guard let pageData = pageItem.pdfPage.dataRepresentation else {continue}
                let pdfDocument = PDFDocument(data: pageData)
                guard let pdfPage = pdfDocument?.page(at: 0) else {continue}
                let copiedPageItem = PageItem(
                    prax: prax,
                    mergedPage: mergedPage,
                    name: pageItem.name + "-copy",
                    sourceBookmark: pageItem.sourceBookmark,
                    sourceURL: URL(string: pageItem.sourceURLString)!,
                    sourcePageIndex: pageItem.sourcePageIndex,
                    pdfPage: pdfPage,
                    dataFields: pageItem.dataFields
                )
                copiedPageItem.trims = pageItem.trims
                copiedPageItem.merge = pageItem.merge
                copiedPageItem.skipped = pageItem.skipped
                pageItems.append(copiedPageItem)
            }
            
        }
        mergedPage.pageItems.insert(contentsOf: pageItems, at: insertIndex)
 
    }
    
    
    
    func movePDFPageItems(_ items: [IndexPath], to destination: IndexPath) {
        guard !items.isEmpty else { return }
        // Ensure destination section exists
        guard mergedPages.indices.contains(destination.section) else { return }
        
        // 1) Normalize and sort source indices so we can safely remove
        //    from the back to the front (avoid index shifting issues)
        let uniqueItems = Array(Set(items)).sorted { (a, b) -> Bool in
            if a.section == b.section { return a.item > b.item } // higher item index first
            return a.section > b.section                         // higher section index first
        }
        
        // 2) Extract the items being moved, preserving their original order
        //    We collect them in reverse-removal order and then reverse to original order.
        var movedItemsReversed: [PageItem] = []
        for source in uniqueItems {
            guard mergedPages.indices.contains(source.section) else { continue }
            let section = mergedPages[source.section]
            guard section.pageItems.indices.contains(source.item) else { continue }
            let removed = section.pageItems.remove(at: source.item)
            mergedPages[source.section] = section
            movedItemsReversed.append(removed)
        }
        let movedItems = movedItemsReversed.reversed()
        
        // Adjust destination index when moving within the same section and the destination is after removed items
        var adjustedDestinationItem = destination.item
        // Count how many removals in the same section were before the destination's original index
        let removalsBeforeDestination = uniqueItems.filter {
            $0.section == destination.section && $0.item < destination.item
        }.count
        adjustedDestinationItem -= removalsBeforeDestination
        
        // 3) Insert into the destination section at the specified index
        let destSection = mergedPages[destination.section]
        let insertIndex = min(max(0, adjustedDestinationItem), destSection.pageItems.count)
        destSection.pageItems.insert(contentsOf: movedItems, at: insertIndex)
        mergedPages[destination.section] = destSection
        
        for pageItem in movedItems {
            pageItem.mergedPage  = destSection
        }
        
        // 4) Update selection to the new positions of the moved items
        //    We map the moved items to their new indices in the destination section.
        var newSelection: Set<IndexPath> = prax.selectedPageItems
        // Remove the old selection indices for moved items
        for source in uniqueItems {
            newSelection.remove(source)
        }
        // Add new selection indices for the inserted range
        for offset in 0..<movedItems.count {
            newSelection.insert(IndexPath(item: insertIndex + offset, section: destination.section))
        }
        prax.selectedPageItems = newSelection
    }
    
    func beginMergedDocument() {
        print("Clear Merged Document")

    }
    
    func clearMergedDocument() {
        if !mergedPages.isEmpty {
            
            print("Clear Merged Document")
            
            prax.selectedPageItems.removeAll()

        }
        
    }
    
    func clickedDeletePageButton(_ pageItem: PageItem) {
        
        print("PageItem - clickedDeletePageButton pageItem: \(pageItem.name)")
        for mergedPage in mergedPages {
            if mergedPage.pageItems.contains(pageItem) {
                mergedPage.pageItems.removeAll(where: {$0 == pageItem})
                if mergedPage.pageItems.isEmpty {
                    mergedPages.removeAll(where: {$0 == mergedPage})
                }
            }
        }
    }
    
    func clickedSkipPageButton(_ pageItem: PageItem) {
       
            print("pageItem.skipped \(pageItem.skipped) OptionKey \(prax.optionKeyPressed ) - clickedSkipPageButtonpageItem: \(pageItem.name)")
            if prax.optionKeyPressed {
                if pageItem.skipped {
                    includeAllExcept(exceptPageItem: pageItem)
                }
                else {
                    skipAllExcept(exceptPageItem: pageItem)
                }
            }
            else {
                pageItem.skipped = !pageItem.skipped
            }
       

    }

    func skipAllPages() {
        for mergedPage in self.mergedPages {
            for pageItem in mergedPage.pageItems {
                    if !pageItem.skipped {
                        pageItem.skipped = true } } }
    }
    
    func includeAllPages() {
        for mergedPage in self.mergedPages {
            for pageItem in mergedPage.pageItems {
                    if pageItem.skipped {
                        pageItem.skipped = false } } }
    }
    
    func includeAllExcept(exceptPageItem: PageItem) {
        for mergedPage in self.mergedPages {
            for pageItem in mergedPage.pageItems {
                if pageItem == exceptPageItem {
                    if !pageItem.skipped {
                        pageItem.skipped = true } }
                else {
                    if pageItem.skipped {
                        pageItem.skipped = false} } } }
    }
    
    func skipAllExcept(exceptPageItem: PageItem) {
        for mergedPage in self.mergedPages {
            for pageItem in mergedPage.pageItems {
                if pageItem == exceptPageItem {
                    if pageItem.skipped {
                        pageItem.skipped = false } }
                else {
                    if pageItem.skipped != true {
                        pageItem.skipped = true } } } }
    }
    
    func clickedMergeModeButton(_ pageItem: PageItem) {
        if prax.optionKeyPressed {
            switch(pageItem.merge) {
            case .mergeSkip:
                print("case .mergeSkip: OptionKey - PageItem - clickedMergeModeButton pageItem: \(pageItem.name)")
               // pageItem.merge = .mergeRight
                
            case .mergeDown:
                print("case .mergeDown: OptionKey - PageItem - clickedMergeModeButton pageItem: \(pageItem.name)")
                mergeAllExcept(exceptPageItem: pageItem, mergeAllMode: .mergeSkip, mergeExceptMode: .mergeDown)
 //               pageItem.merge = .mergeSkip

            case .mergeRight:
                print("case .mergeRight: OptionKey - PageItem - clickedMergeModeButton pageItem: \(pageItem.name)")
               // pageItem.merge = .mergeDown
            }
            
        }
        else {
            print("PageItem - clickedMergeModeButton pageItem: \(pageItem.name)")

            switch(pageItem.merge) {
            case .mergeSkip:
                pageItem.merge = .mergeRight
            case .mergeDown:
                pageItem.merge = .mergeSkip
            case .mergeRight:
                pageItem.merge = .mergeDown
            }
        }
    }

    
    func clickedIncludePageButton(_ pageItem: PageItem) {
        print("PageItem - clickedIncludePageButton pageItem: \(pageItem.name)")
        
        if pageItem.merge == .mergeSkip {
            if prax.optionKeyPressed {
               mergeAllExcept(exceptPageItem: pageItem, mergeAllMode: .mergeSkip, mergeExceptMode: .mergeDown)
            }
            else {
                pageItem.merge = .mergeDown
            }
        }
        else {
            if prax.optionKeyPressed {
                mergeAllExcept(exceptPageItem: pageItem, mergeAllMode: .mergeSkip, mergeExceptMode: .mergeDown)
             }
            else {
                pageItem.merge = .mergeSkip
            }
        }
    }

    func mergeAllExcept(exceptPageItem: PageItem, mergeAllMode: MergeMode, mergeExceptMode: MergeMode) {
        for mergedPage in self.mergedPages {
            for pageItem in mergedPage.pageItems {
                if pageItem == exceptPageItem {
                    if pageItem.merge != mergeExceptMode {
                        pageItem.merge = mergeExceptMode
                    }
                }
                else {
                    if pageItem.merge != mergeAllMode {
                        pageItem.merge = mergeAllMode
                    }
                }
            }
        }
    }
    
    
    func clickedGuidePageButton(_ clickedPageItem: PageItem) {
        
        print("PageItem - clickedGuidePageButton pageItem: \(clickedPageItem.name) PageEditView")
        
        if widthGuidePageID == clickedPageItem.id {
            clearWidthGuide()
        } else {
            if prax.optionKeyPressed {
                if widthGuidePageID == nil { return }
                guard let guidePage = pageItem(id: widthGuidePageID!) else { return }
                
                var trims = clickedPageItem.trims
                print ("old trims: ", clickedPageItem.trims )
                print (guidePage.trims)
                print (trims)
                
                
                trims.left = guidePage.trims.left
                trims.right = guidePage.trims.right
                clickedPageItem.trims = trims
            //    pageItem.overlayView.needsDisplay = true
            //    pageItem.overlayView.display()
                print("PageItem - clickedGuidePageButton copied guide page trims to current page")
                print ("new trims: ", clickedPageItem.trims )
                
            }
            else {
                setWidthGuide(fromPage: clickedPageItem)
                
            }
            
        }
    }
    
    
    func widthGuidePage() -> PageItem? {
        if widthGuidePageID == nil { return nil }
        return pageItem(id: widthGuidePageID!)
    }

    /// Compute and store the width guide X positions (in page space of the guide page)
    func setWidthGuide(fromPage pageItem: PageItem) {
  //      if pageItem.id == widthGuidePageID { clearWidthGuide() }
        let media = pageItem.pdfPage.bounds(for: .cropBox)
        let per = pageItem.trims
        let vis = PDFGeometry.visibleRect(media: media, trims: per, seamTop: 0, seamBottom: 0)
        widthGuidePageID = pageItem.id
        widthGuideLeftX = vis.minX
        widthGuideRightX = vis.maxX
//        if isLoadingPDF { return }
//        DispatchQueue.main.async {
//            NotificationCenter.default.post(name: .praxWidthGuideChanged, object: self)
//        }
        
    }
    
    /// Remove any active width guide
    func clearWidthGuide() {
        widthGuidePageID = nil
        widthGuideLeftX = nil
        widthGuideRightX = nil
//        if isLoadingPDF { return }
//        DispatchQueue.main.async {
//            NotificationCenter.default.post(name: .praxWidthGuideChanged, object: self)
 //       }
    }
    
    
   
    
    
}


