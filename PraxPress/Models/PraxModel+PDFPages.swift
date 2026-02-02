//
//  PraxModel+PDFPages.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/24/26.
//

import CoreGraphics
import PDFKit
import SwiftUI


extension Notification.Name {
    static let praxWidthGuideChanged = Notification.Name("PraxWidthGuideChanged")
    //  static let praxFileSelectionChanged = Notification.Name("PraxFileSelectionChanged")
}




extension PraxModel {

    func zoomInEditingPDFView() {
        editingPDFView?.zoomIn(self)
        editingPDFAutoScales = false
    }
    func zoomOutEditingPDFView() {
        editingPDFView?.zoomOut(self)
        editingPDFAutoScales = false
    }
    func zoomInMergedPDFView() {
        mergedPDFView?.zoomIn(self)
    }
    func zoomOutMergedPDFView() {
        mergedPDFView?.zoomOut(self)
    }

    func movePDFPageItems(_ items: [IndexPath], to destination: IndexPath) {
        guard !items.isEmpty else { return }
        // Ensure destination section exists
        guard pdfPageSections.indices.contains(destination.section) else { return }
        
        // 1) Normalize and sort source indices so we can safely remove
        //    from the back to the front (avoid index shifting issues)
        let uniqueItems = Array(Set(items)).sorted { (a, b) -> Bool in
            if a.section == b.section { return a.item > b.item } // higher item index first
            return a.section > b.section                         // higher section index first
        }
        
        // 2) Extract the items being moved, preserving their original order
        //    We collect them in reverse-removal order and then reverse to original order.
        var movedItemsReversed: [PDFPageItem] = []
        for source in uniqueItems {
            guard pdfPageSections.indices.contains(source.section) else { continue }
            var section = pdfPageSections[source.section]
            guard section.pdfPageItems.indices.contains(source.item) else { continue }
            let removed = section.pdfPageItems.remove(at: source.item)
            pdfPageSections[source.section] = section
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
        var destSection = pdfPageSections[destination.section]
        let insertIndex = min(max(0, adjustedDestinationItem), destSection.pdfPageItems.count)
        destSection.pdfPageItems.insert(contentsOf: movedItems, at: insertIndex)
        pdfPageSections[destination.section] = destSection
        
        
        // 4) Update selection to the new positions of the moved items
        //    We map the moved items to their new indices in the destination section.
        var newSelection: Set<IndexPath> = selectedPageItems
        // Remove the old selection indices for moved items
        for source in uniqueItems {
            newSelection.remove(source)
        }
        // Add new selection indices for the inserted range
        for offset in 0..<movedItems.count {
            newSelection.insert(IndexPath(item: insertIndex + offset, section: destination.section))
        }
        selectedPageItems = newSelection
        
        DispatchQueue.main.async {
            print ("Dispatch self.setEditingPDFDocumentFromPDFPageSections()")
            self.setEditingPDFDocumentFromPDFPageSections()
        }
        
    }
    
    func addPDFPageSection(for document: PDFDocument, at insertIndex: Int, into mergedDoc: inout PDFDocument) -> Int {
        
        var insertIndex = insertIndex
        
        var section = PDFPageSection(title: document.documentURL?.lastPathComponent ?? "Prax")
        
        for i in 0..<document.pageCount {
            //        print("Sharon - page: ", i)
            if let docPage = document.page(at: i) {
                section.pdfPageItems.append(
                    PDFPageItem(
                        //                               pageIndex: i,
                        name: "Page \(i + 1)",
                        pdfPage: docPage,
                        thumbnail: docPage.thumbnail(of: CGSize(width: 120, height: 160), for: .cropBox)
                    )
                )
                mergedDoc.insert(docPage, at: insertIndex)
                insertIndex += 1
            }
        }
        pdfPageSections.append(section)
        return insertIndex
    }

    
    func pdfPageIndexPath(for pdfPage: PDFPage) -> IndexPath? {
        for piSection in pdfPageSections.indices {
            let section = pdfPageSections[piSection]
            for piItem in section.pdfPageItems.indices {
                let item = section.pdfPageItems[piItem]
                if item.pdfPage.hashValue == pdfPage.hashValue {
                    return IndexPath(item: piItem, section: piSection)
                }
            }
        }
        return nil
        
        
    }
    
    func pdfPageItem(id: UUID) -> PDFPageItem? {
        for piSection in pdfPageSections.indices {
            let section = pdfPageSections[piSection]
            for piItem in section.pdfPageItems.indices {
                let item = section.pdfPageItems[piItem]
                if item.id == id {
                    return item
                }
            }
        }
        return nil
    }
    
    func pdfPageItem(for pdfPage: PDFPage) -> PDFPageItem? {
        for piSection in pdfPageSections.indices {
            let section = pdfPageSections[piSection]
            for piItem in section.pdfPageItems.indices {
                let item = section.pdfPageItems[piItem]
                if item.pdfPage.hashValue == pdfPage.hashValue {
                    return item
                }
            }
        }
        return nil
    }
    
    func pdfPageItem(indexPath: IndexPath) -> PDFPageItem? {
        let piSection = indexPath.section
        let piItem = indexPath.item
        if pdfPageSections.count > piSection {
            let section = pdfPageSections[piSection]
            if section.pdfPageItems.count > piItem {
                return section.pdfPageItems[piItem]
            }
        }
        return nil
    }
    
    func pages(in section: PDFPageSection) -> [PDFPageItem] {
        return section.pdfPageItems
    }
    
    func widthGuidePage() -> PDFPageItem? {
        if widthGuidePageID == nil { return nil }
        return pdfPageItem(id: widthGuidePageID!)
    }
    
    /// Compute and store the width guide X positions (in page space of the guide page)
    func setWidthGuide(fromPage pdfPageItem: PDFPageItem) {
        if pdfPageItem.id == widthGuidePageID { clearWidthGuide() }
        let media = pdfPageItem.pdfPage.bounds(for: .cropBox)
        let per = pdfPageItem.trim
        let vis = PDFGeometry.visibleRect(media: media, trims: per, seamTop: 0, seamBottom: 0)
        widthGuidePageID = pdfPageItem.id
        widthGuideLeftX = vis.minX
        widthGuideRightX = vis.maxX
        if isLoadingPDF { return }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .praxWidthGuideChanged, object: self.mergedPDFView)
        }
    }
    
    /// Remove any active width guide
    func clearWidthGuide() {
        widthGuidePageID = nil
        widthGuideLeftX = nil
        widthGuideRightX = nil
        if isLoadingPDF { return }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .praxWidthGuideChanged, object: self.mergedPDFView)
        }
    }
}
