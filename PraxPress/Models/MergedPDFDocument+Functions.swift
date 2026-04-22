//
//  MergedPDFDocument+Functions.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/22/26.
//

import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers

extension MergedPDFDocument {
    
    var totalPageItems: Int {
        get {
            var total = 0
            for section in pageSections {
                total += section.pageItems.count
            }
            return total
        }
    }
    
    
/*    func pdfPageIndexPath(for pdfPage: PDFPage) -> IndexPath? {
        for piSection in pageSections.indices {
            let section = pageSections[piSection]
            for piItem in section.pageItems.indices {
                let item = section.pageItems[piItem]
                if item.pdfPage.hashValue == pdfPage.hashValue {
                    return IndexPath(item: piItem, section: piSection)
                }
            }
        }
        return nil
    }
  */
    
    func pageItem(id: UUID) -> PageItem? {
        for piSection in pageSections.indices {
            let section = pageSections[piSection]
            for piItem in section.pageItems.indices {
                let item = section.pageItems[piItem]
                if item.id == id {
                    return item
                }
            }
        }
        return nil
    }
    
    
    
    func pageItem(for pdfPage: PDFPage) -> PageItem? {
        for piSection in pageSections.indices {
            let section = pageSections[piSection]
            for piItem in section.pageItems.indices {
                let item = section.pageItems[piItem]
                if item.pdfPage.hashValue == pdfPage.hashValue {
                    return item
                }
            }
        }
      //  fatalError("No Such Number")
        return nil
    }
    
    func indexPath(for pageItem: PageItem) -> IndexPath? {
        var section = 0
        for aSection in self.pageSections {
            var item = 0
            for anItem in aSection.pageItems {
                if anItem == pageItem {
                    return IndexPath(item: item, section: section)
                }
                item += 1
            }
            section += 1
        }
        return nil
    }
    
    func pageItem(indexPath: IndexPath) -> PageItem? {
        let piSection = indexPath.section
        let piItem = indexPath.item
        if pageSections.count > piSection {
            let section = pageSections[piSection]
            if section.pageItems.count > piItem {
                return section.pageItems[piItem]
            }
        }
        return nil
    }
    
    func pages(in section: MergedPage) -> [PageItem] {
        return section.pageItems
    }
    
    
    func copyPDFPageItems(_ items: [IndexPath], to destination: IndexPath) {
        guard !items.isEmpty else { return }
        // Ensure destination section exists
        guard pageSections.indices.contains(destination.section) else { return }
        let mergedPage = pageSections[destination.section]
        let insertIndex = destination.item
        var pageItems: [PageItem] = []
        for item in items {
            if let pageItem = pageItem(indexPath: item) {
                guard let pageData = pageItem.pdfPage.dataRepresentation else {continue}
                let pdfDocument = PDFDocument(data: pageData)
                guard let pdfPage = pdfDocument?.page(at: 0) else {continue}
                let copiedPageItem = PageItem(
                    mergedPage: mergedPage,
                    name: pageItem.name + "-copy",
                    sourceBookmark: pageItem.sourceBookmark,
                    sourceURL: URL(string: pageItem.sourceURLString)!,
                    sourcePageIndex: pageItem.sourcePageIndex,
                    pdfPage: pdfPage
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
        guard pageSections.indices.contains(destination.section) else { return }
        
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
            guard pageSections.indices.contains(source.section) else { continue }
            let section = pageSections[source.section]
            guard section.pageItems.indices.contains(source.item) else { continue }
            let removed = section.pageItems.remove(at: source.item)
            pageSections[source.section] = section
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
        let destSection = pageSections[destination.section]
        let insertIndex = min(max(0, adjustedDestinationItem), destSection.pageItems.count)
        destSection.pageItems.insert(contentsOf: movedItems, at: insertIndex)
        pageSections[destination.section] = destSection
        
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
    
    
    
    
    func acceptDrop(_ providers: [NSItemProvider]) -> Bool {
        
        
        var urls: [URL] = []
        for provider in providers {
            
            provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { (data, error) in
                if let data = data, let path = String(data: data, encoding: .utf8), let url = URL(string: path) {
                    urls.append(url)
                    print("Julie Belanger URL: ", url)
                    
                }
            }
            if urls.isEmpty {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { (url, error) in
                    if let url = url {
                        urls.append(url)
                        print("Julie Belanger URL: ", url)
                    }
                }
            }

/*
            let pdfURLs = urls.filter { $0.pathExtension.lowercased() == "pdf" }
            if !pdfURLs.isEmpty {
                Task {
                    do {
                        
                        try await insertPDFPageItemsFromDocumentURLS(pdfURLs, at: IndexPath(item: -1, section: -1))
                        refreshMergedDocument()
                    } catch let error {
                        print("Julie d Prax", urls, "Error: ", error)
                        
                    }
                }
                
            }
            
            
            let imageFileExtensions = ["png", "jpeg", "jpg", "gif", "heic"]
            let imageURLs = urls.filter { imageFileExtensions.contains( $0.pathExtension.lowercased()) }
      
            if !imageURLs.isEmpty {
                if prax!.optionKeyPressed {
                    self.insertPDFPageSectionsFromImageURLS(imageURLs, at: IndexPath(item: -1, section: -1))
                }
                else {
                    self.insertPDFPageItemsFromImageURLS(imageURLs, at: IndexPath(item: -1, section: -1))
                }
            }
*/

        }

        print("Julie d Prax", urls)
        
        return true
        
    }
    
/*    func insertPDFPageItemsFromImageURLS(_ urls: [URL], at indexPath: IndexPath) {
        var pages: [PDFPageItem] = []
        var sourceFileName = ""
        for url in urls {
            guard var image = NSImage(contentsOf: url) else { fatalError("Failed to open Image at \(url)") }
            image = image.resize(to: NSSize(width: 50, height: 70))!
            
            sourceFileName = url.deletingPathExtension().lastPathComponent
            guard let docPage = PDFPage(image: image) else { fatalError("Failed to create PDFPage from Image at \(url)")}
            let pageItem = PDFPageItem(
                document: self,
                name: "Image - \(sourceFileName)",
                pdfPage: docPage
            )
            pages.append(pageItem)
        }
        if indexPath.section >= 0 {
            if indexPath.item < 0 || indexPath.item >= pageSections[indexPath.section].pageItems.count {
                pageSections[indexPath.section].pageItems.append(contentsOf: pages)
            }
            else {
                pageSections[indexPath.section].pageItems.insert(contentsOf: pages, at: indexPath.item)
            }
        }
        else {
            pageSections.append(PDFPageSection(document: self, title: "Image - \(sourceFileName)", pageItems: pages))
        }
        
    }

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

    func insertPDFPageSectionsFromDocumentURLS(_ urls: [URL], at indexPath: IndexPath)  async throws {
        
        var pageItems: [PDFPageItem] = []
        for url in urls {
            guard let doc = PDFDocument(url: url) else { throw (NSException(name: .internalInconsistencyException, reason: "Could not load PDF document at \(url)", userInfo: nil) as! any Error) }
            let sourceFileName = url.deletingPathExtension().lastPathComponent
            for i in 0..<doc.pageCount {
                guard let docPage = doc.page(at: i)  else { throw (NSException(name: .internalInconsistencyException, reason: "Could not load document page at \(url)", userInfo: nil) as! any Error) }
                pageItems.append(PDFPageItem(
                    document: self,
                    name: "\(sourceFileName) - Page \(i + 1)",
                    pdfPage: docPage
                ))
            }
            pageSections.append(PDFPageSection(document: self, title: "PDF - \(sourceFileName)", pageItems: pageItems))
        }
        
    }
    
    
    func insertPDFPageItemsFromDocumentURLS(_ urls: [URL], at indexPath: IndexPath) async throws {
        
        
        var pages: [PDFPageItem] = []
        var sourceFileName = ""
        for url in urls {
            guard let doc = PDFDocument(url: url) else { throw (NSException(name: .internalInconsistencyException, reason: "Could not load PDF document at \(url)", userInfo: nil) as! any Error) }
            sourceFileName = url.deletingPathExtension().lastPathComponent
            for i in 0..<doc.pageCount {
                guard let docPage = doc.page(at: i)  else { throw (NSException(name: .internalInconsistencyException, reason: "Could not load document page at \(url)", userInfo: nil) as! any Error) }
                pages.append(PDFPageItem(
                    document: self,
                    name: "\(sourceFileName) - Page \(i + 1)",
                    pdfPage: docPage
                ))
            }
        }
        
        if indexPath.section >= 0 {
            if indexPath.item < 0 || indexPath.item >= pageSections[indexPath.section].pageItems.count {
                pageSections[indexPath.section].pageItems.append(contentsOf: pages)
            }
            else {
                pageSections[indexPath.section].pageItems.insert(contentsOf: pages, at: indexPath.item)
            }
        }
        else {
            pageSections.append(PDFPageSection(document: self, title: sourceFileName, pageItems: pages))
        }

    }
 */
    
    
/*
    
    
    func pdfDocumentFromPDFPageSections(pageSections: [MergedPage]) -> PDFDocument {
        isLoadingPDF = true
        var insertIndex = 0
        let pdfDocument = PDFDocument()
        pageSections.forEach {
            section in
            section.pageItems.forEach {
                page in
                if page.merge != .mergeSkip {
                    pdfDocument.insert(page.pdfPage, at: insertIndex)
                    insertIndex += 1
                }
            }
        }
        return pdfDocument
    }
    
    
    
    func recomputeMergedMetrics() {
        let count = totalPDFPageItems()
        guard count > 0 else { fatalError("No pages in PDF!")}
        
        var pageIndex = 0
        let sectionCount = pageSections.count
        for sectionIndex in 0..<sectionCount {
            var maxVisibleWidth: CGFloat = 0
            var totalVisibleHeight: CGFloat = 0
            
            pageSections[sectionIndex].pageItems.forEach {
                pageItem in
                if pageItem.merge != .mergeSkip {
                    let media = pageItem.pdfPage.bounds(for: .cropBox)
                    let per = pageItem.trims
                    let seamTop: CGFloat = (pageIndex == 0) ? 0 : 0
                    let seamBottom: CGFloat = (pageIndex == count - 1) ? 0 : 0
                    let vis = PDFGeometry.visibleRect(media: media, trims: per, seamTop: seamTop, seamBottom: seamBottom)
                    maxVisibleWidth = max(maxVisibleWidth, vis.width)
                    totalVisibleHeight += vis.height
                    pageIndex += 1
                }
            }
            pageSections[sectionIndex].mergedWidthPts = maxVisibleWidth
            pageSections[sectionIndex].mergedHeightPts = totalVisibleHeight
        }
    }

    
    func mergeDocumentPagesForSections() -> PDFDocument {
        
        let mergedDocument = PDFDocument()
        
        var pageItems: [PageItem] = []
        for sectionIndex in 0..<pageSections.count {
            for pageIndex in 0..<pageSections[sectionIndex].pageItems.count{
                if pageSections[sectionIndex].pageItems[pageIndex].merge != .mergeSkip {
                    pageItems.append(pageSections[sectionIndex].pageItems[pageIndex])
                }
            }
            //  var removedPerPage: [[PDFAnnotation]] = Array(repeating: [], count: pageItems.count)
            var pageRects: [CGRect] = []
            pageRects.reserveCapacity(pageItems.count)
            
            for pageIndex in 0..<pageItems.count{
                let page = pageItems[pageIndex].pdfPage
                let rect = page.bounds(for: .cropBox)
                pageRects.append(rect)
                //      removedPerPage[pageIndex] = page.annotations
                //      for annotation in page.annotations {
                //    page.removeAnnotation(annotation)
                //     }
            }
            
            var mediaBox = CGRect(x: 0, y: 0, width: pageSections[sectionIndex].mergedWidthPts, height: pageSections[sectionIndex].mergedHeightPts)
            let tmpOut = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf")
            guard let consumer = CGDataConsumer(url: tmpOut as CFURL) else { fatalError("CGDataConsumer failed") }
            guard let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { fatalError("CGContext failed") }
            
            ctx.beginPDFPage([kCGPDFContextMediaBox as String: mediaBox] as CFDictionary)
            // Stack pages from top to bottom. Track the Y origin of each placed slice for annotation mapping.
            var currentTop = pageSections[sectionIndex].mergedHeightPts
            var placedOriginsY: [CGFloat] = Array(repeating: 0, count: pageItems.count)
            
            for pageIndex in 0..<pageItems.count {
                let page = pageItems[pageIndex].pdfPage
                let rect = pageRects[pageIndex]
                let per = pageItems[pageIndex].trims
                //    let seamTop: CGFloat = 0
                //    let seamBottom: CGFloat = 0
                
                let vis = rect.trimmed(per) //: per, seamTop: seamTop, seamBottom: seamBottom)
                
                //   let vis = PDFGeometry.visibleRect(media: rect, trims: per, seamTop: seamTop, seamBottom: seamBottom)
                //       print("merge draw page \(i) rect:", rect.debugDescription, "trims:", per, "vis:", vis.debugDescription)
                let visibleWidth = vis.width
                let visibleHeight = vis.height
                guard visibleWidth > 0, visibleHeight > 0 else {
                    currentTop -= (max(0, visibleHeight)) // + interPageGap)
                    continue
                }
                
                // Place the slice at the LEFT edge (x = 0) and directly under the running top
                let destX: CGFloat = 0
                let destY: CGFloat = currentTop - visibleHeight
                placedOriginsY[pageIndex] = destY
                
                ctx.saveGState()
                // Translate so that (vis.minX, vis.minY) in page space lands at (destX, destY) in canvas space
                ctx.translateBy(x: destX - vis.minX, y: destY - vis.minY)
                // Clip in the CURRENT (translated) coordinate system using a rect defined in PAGE space coordinates
                // Because we translated by (-vis.minX, -vis.minY), the clip rect is simply:
                ctx.clip(to: vis)
                
                if let cgPage = page.pageRef {
                    ctx.drawPDFPage(cgPage)
                } else {
                    page.draw(with: .cropBox, to: ctx)
                }
                ctx.restoreGState()
                
                currentTop -= visibleHeight // (visibleHeight + interPageGap)
                
            }
            ctx.endPDFPage()
            ctx.closePDF()
            
            
            
            // Restore annotations to source pages
            //     for pageIndex in 0..<pageItems.count {
            //         let p = pageItems[pageIndex].pdfPage
            //          for a in removedPerPage[pageIndex] { p.addAnnotation(a) }
            //     }
            
            // Second pass: reopen merged and re-add cloned annotations with the SAME translation used above
            
            guard let tempDoc = PDFDocument(url: tmpOut) else { fatalError("PDFDocument(url: tmpOut) failed") }
            guard let mergedPage = tempDoc.page(at: 0) else { fatalError("mergedDoc.page(at: 0) failed") }
            
            for pageIndex in 0..<pageItems.count {
                let srcPage = pageItems[pageIndex].pdfPage
                let pageRect = pageRects[pageIndex]
                let trims = pageItems[pageIndex].trims
                //   let seamTop: CGFloat = 0
                //   let seamBottom: CGFloat = 0
                
                let trimmedPageRect = pageRect.trimmed(trims)
                
                let dx = 0 - trimmedPageRect.minX
                let dy = placedOriginsY[pageIndex] - trimmedPageRect.minY
                //   print("merge annot page \(i) rect:", rect.debugDescription, "trims:", per, "vis:", vis.debugDescription, "dx:", dx, "dy:", dy)
                
                for annotation in srcPage.annotations {
                    // Only handle form fields; skip others as before
                    guard annotation.fieldName != nil else { continue }
                    guard let copiedAnnotation = annotation.copy() as? PDFAnnotation else { continue }
                    
                    // Translate annotation bounds from source page space into merged page space
                    let translatedBounds = annotation.bounds.offsetBy(dx: dx, dy: dy)
                    
   /*                 // Destination rect for this slice in merged page coordinates
                    let destSliceRect = CGRect(x: 0,
                                               y: placedOriginsY[pageIndex],
                                               width: trimmedPageRect.width,
                                               height: trimmedPageRect.height)
                    
                    // Fit while preserving center as much as possible
                    let minSize: CGFloat = 2.0
                    
                    // Start from original center
                    let centerX = translatedBounds.midX
                    let centerY = translatedBounds.midY
                    
                    // Compute the max size that fits within the slice while centered at (centerX, centerY)
                    var targetWidth = translatedBounds.width
                    var targetHeight = translatedBounds.height
                    
                    // Limit size to slice dimensions
                    targetWidth = min(targetWidth, destSliceRect.width)
                    targetHeight = min(targetHeight, destSliceRect.height)
                    
                    // Ensure minimum size
                    targetWidth = max(targetWidth, minSize)
                    targetHeight = max(targetHeight, minSize)
                    
                    // Build a rect of the target size centered at original center
                    var fitted = CGRect(x: centerX - targetWidth / 2.0,
                                        y: centerY - targetHeight / 2.0,
                                        width: targetWidth,
                                        height: targetHeight)
                    
                    // If this centered rect spills outside the slice, clamp position while keeping size
                    if fitted.minX < destSliceRect.minX {
                        fitted.origin.x = destSliceRect.minX
                    }
                    if fitted.maxX > destSliceRect.maxX {
                        fitted.origin.x = destSliceRect.maxX - fitted.width
                    }
                    if fitted.minY < destSliceRect.minY {
                        fitted.origin.y = destSliceRect.minY
                    }
                    if fitted.maxY > destSliceRect.maxY {
                        fitted.origin.y = destSliceRect.maxY - fitted.height
                    }
                    
                    // Final safety: ensure we still overlap the slice (in case slice is extremely small)
                    guard fitted.intersects(destSliceRect) else { continue }
                    
                    copiedAnnotation.bounds = fitted
   */
                    copiedAnnotation.bounds = translatedBounds
               
                    mergedPage.addAnnotation(copiedAnnotation)
                    
                    // Preserve text values for text widgets
                    
                    if copiedAnnotation.widgetFieldType == .text {
                        if let v = copiedAnnotation.widgetStringValue, !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            copiedAnnotation.widgetStringValue = v
                        }
                    }
                }
            }
            
            
       //     pageSections[sectionIndex].pdfPage = mergedPage
            mergedDocument.insert(mergedPage, at: sectionIndex)
            
            do { try FileManager.default.removeItem(at: tmpOut) }
            catch {  print("FileManager.default.removeItem(at: tmpOut) failed", error.localizedDescription) }
        }
        
        mergedDocument.write(to: mergedPDFURL)
        return mergedDocument
    }
    
    
*/
    
    
    
    func clickedDeletePageButton(_ pageItem: PageItem) {
        
        print("PageItem - clickedDeletePageButton pageItem: \(pageItem.name)")
        for section in pageSections {
            if section.pageItems.contains(pageItem) {
                section.pageItems.removeAll(where: {$0 == pageItem})
                if section.pageItems.isEmpty {
                    pageSections.removeAll(where: {$0 == section})
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
        for pageSection in self.pageSections {
            for pageItem in pageSection.pageItems {
                    if !pageItem.skipped {
                        pageItem.skipped = true
                    }
            }
        }
    }
    
    func includeAllPages() {
        for pageSection in self.pageSections {
            for pageItem in pageSection.pageItems {
                    if pageItem.skipped {
                        pageItem.skipped = false
                    }
            }
        }
    }
    
    func includeAllExcept(exceptPageItem: PageItem) {
        for pageSection in self.pageSections {
            for pageItem in pageSection.pageItems {
                if pageItem == exceptPageItem {
                    if !pageItem.skipped {
                        pageItem.skipped = true
                    }
                }
                else {
                    if pageItem.skipped {
                        pageItem.skipped = false
                    }
                }
            }
        }
    }
    
    func skipAllExcept(exceptPageItem: PageItem) {
        for pageSection in self.pageSections {
            for pageItem in pageSection.pageItems {
                if pageItem == exceptPageItem {
                    if pageItem.skipped {
                        pageItem.skipped = false
                    }
                }
                else {
                    if pageItem.skipped != true {
                        pageItem.skipped = true
                    }
                }
            }
        }
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
        for pageSection in self.pageSections {
            for pageItem in pageSection.pageItems {
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
