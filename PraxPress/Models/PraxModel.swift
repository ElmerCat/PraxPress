//  PraxModel.swift
//  PraxPress - Prax=0104-1
//

import Foundation
import CoreGraphics
import PDFKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

import Combine

//@Model
@Observable
final class PraxModel: Sendable {
    init() { }
    static let shared = PraxModel()
    
    
    
    var editingPDFView: PDFView? { didSet {
        editingPDFView!.document = editingPDFDocument
        editingPDFView!.displaysPageBreaks = editingPDFDisplayPageBreaks
        editingPDFView!.displayMode = editingPDFDisplayMode
        editingPDFView!.displaysAsBook = editingPDFDisplaysAsBook
        editingPDFView!.autoScales = editingPDFAutoScales
        editingPDFView!.backgroundColor = editingPDFBackgroundColor
    }}
    
    var editingPDFDisplayMode: PDFDisplayMode = .singlePageContinuous { didSet {
        editingPDFView?.displayMode = editingPDFDisplayMode
        editingPDFView?.scaleFactor = editingPDFView?.scaleFactorForSizeToFit ?? 0
        
    }}
    
    var editingPDFAutoScales: Bool = true
    var editingPDFDisplayPageBreaks: Bool = true
    
    var editingPDFDisplaysAsBook: Bool = false {
        didSet{ editingPDFView?.displaysAsBook = editingPDFDisplaysAsBook }
    }
    
    var editingPDFBackgroundColor: NSColor = .red { didSet {
        editingPDFView?.backgroundColor = editingPDFBackgroundColor }
    }
    
    
    func zoomInEditingPDFView() {
        editingPDFView?.zoomIn(self)
        editingPDFAutoScales = false
    }
    func zoomOutEditingPDFView() {
        editingPDFView?.zoomOut(self)
        editingPDFAutoScales = false
    }
    
    var mergedPDFView: PDFView? { didSet {
        mergedPDFView!.document = mergedPDFDocument
        mergedPDFView!.displaysPageBreaks = mergedPDFDisplayPageBreaks
        mergedPDFView!.displayMode = mergedPDFDisplayMode
        mergedPDFView!.displaysAsBook = mergedPDFDisplaysAsBook
        mergedPDFView!.autoScales = mergedPDFAutoScales
        mergedPDFView!.backgroundColor = mergedPDFBackgroundColor
    }}
    var mergedPDFDisplayMode: PDFDisplayMode = .singlePage { didSet {
        mergedPDFView?.displayMode = mergedPDFDisplayMode
        mergedPDFView?.scaleFactor = mergedPDFView?.scaleFactorForSizeToFit ?? 0
    }}
    
    var mergedPDFAutoScales: Bool = true
    var mergedPDFDisplayPageBreaks: Bool = true
    
    var mergedPDFDisplaysAsBook: Bool = false {
        didSet{ mergedPDFView?.displaysAsBook = mergedPDFDisplaysAsBook }
    }
    var mergedPDFBackgroundColor: NSColor = .yellow { didSet {
        mergedPDFView?.backgroundColor = mergedPDFBackgroundColor }
    }
    
    func zoomInMergedPDFView() {
        mergedPDFView?.zoomIn(self)
    }
    func zoomOutMergedPDFView() {
        mergedPDFView?.zoomOut(self)
    }
    
    var isLoadingPDF = false
    var isOn = false
    var isLarge: Bool = false
    var showingImporter: Bool = false
    var isShowingInspector: Bool = false
    var showSavePanel: Bool = false
    var columnVisibility: NavigationSplitViewVisibility = .all
    
    var listOfFiles: [PDFEntry] = [] {
        didSet {
            print ("PraxModel listOfFiles didSet ") //, listOfFiles.description)
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
    
    var selectedFiles = Set<PDFEntry.ID>() {
        didSet {
            print ("PraxModel selectedFiles didSet ") //, selectedFiles.description)
            isLoadingPDF = true
            
            DispatchQueue.main.async {
                print ("Dispatch setEditingPDFDocumentFromSelectedFiles()")
                self.setEditingPDFDocumentFromSelectedFiles()
            }
        }
    }
    
    var editingPDFDocument: PDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)! {
        didSet {
            print ("editingPDFDocument didSet ")
            
            if isLoadingPDF {
                print ("isLoadingPDF - editingPDFDocument didSet ")
                selectionIndexPaths = []
                clearWidthGuide()

                recomputeMergedMetrics()
            }
            
            editingPDFView?.document = editingPDFDocument
            
            DispatchQueue.main.async {
                print ("self.mergedPDFDocument = self.mergeDocumentPagesForSections()")
                self.mergedPDFDocument = self.mergeDocumentPagesForSections()
            }
        }
    }
    
    
    var editingPDFURL: URL = {
        FileManager.default.temporaryDirectory.appendingPathComponent("praxpress-editing").appendingPathExtension("pdf")
    }()
    
    var fileURL: URL?
    var lastPreviewURL: URL? = nil
    var lastCombinedSourceURL: URL? = nil
    
    
    // Width Guide support
    var widthGuidePage: PDFPageItem? = nil
    var widthGuideLeftX: CGFloat? = nil
    var widthGuideRightX: CGFloat? = nil

    
    var saveError: String?
    
    var pdfPageSections: [PDFPageSection] = []
    
    
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
        var newSelection: Set<IndexPath> = selectionIndexPaths
        // Remove the old selection indices for moved items
        for source in uniqueItems {
            newSelection.remove(source)
        }
        // Add new selection indices for the inserted range
        for offset in 0..<movedItems.count {
            newSelection.insert(IndexPath(item: insertIndex + offset, section: destination.section))
        }
        selectionIndexPaths = newSelection
        
        DispatchQueue.main.async {
            print ("Dispatch self.setEditingPDFDocumentFromPDFPageSections()")
            self.setEditingPDFDocumentFromPDFPageSections()
        }
        
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
  
    var mergedPDFURL: URL = {
        FileManager.default.temporaryDirectory.appendingPathComponent("praxpress-merged").appendingPathExtension("pdf")
    }()
    
    var mergedPDFDocument: PDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)! {
        didSet {
            print ("mergedPDFDocument didSet ")
            mergedPDFView?.document = mergedPDFDocument
            self.isLoadingPDF = false
        }
    }
    
    var selectionIndexPaths: Set<IndexPath> = [] {
        didSet {
            print("selectionIndexPaths didSet:  ", selectionIndexPaths)
            selectionIndexPaths.forEach {
                print("\($0)")
            }
            
        }
    }
    
    
    
}

