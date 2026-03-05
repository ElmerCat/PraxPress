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


enum MergeMode: String, Codable { case mergeDown, mergeRight, mergeSkip }

@Observable @MainActor class MergedPDFDocument {
    // Window-scoped SwiftData context for PDFPageSectionModel/PDFPageItemModel
    var windowModelContext: ModelContext?
    
    var prax: PraxModel?
    var persistence: PersistenceController?
    
    var mergedPDFView: PDFView = {
        let v = PDFView()
        v.displaysPageBreaks = true
        v.displayMode = .singlePageContinuous
        v.displaysAsBook = false
        v.autoScales = true
        return v
    }()
    
    var displayMode: PDFDisplayMode = .singlePageContinuous {
        didSet {
            mergedPDFView.displayMode = displayMode
        }
    }
    var autoScales = true {
        didSet {
            mergedPDFView.autoScales = autoScales
        }
    }
    
    
    var sections: [PDFPageSection] = [] {
        didSet {
            print("sections didSet:  ", sections.count)
            //   refreshEditingDocument()
            
        }
    }
    
    var pdfFileGroups: [PDFFileGroup] = [] {
        didSet {
            print ("MergedPDFDocument pdfFileGroups didSet: ", pdfFiles.count)
        }

    }
    
    var pdfFiles: [PDFFile] = [] {
        didSet {
            print ("MergedPDFDocument pdfFiles didSet: ", pdfFiles.count)
        }
    }
    
 //   @Query(sort: \PDFFileGroup.name) private var pdfFileGroups: [PDFFileGroup]
    
    var selectedFiles = Set<PDFFile.ID>() {
        didSet {
            print ("MergedPDFDocument selectedFiles didSet: ", selectedFiles.count) //, selectedFiles.description)
            //         isLoadingPDF = true
            //            selectedPageItems = []
            //           clearWidthGuide()
            
            
/*            DispatchQueue.main.async {
                print ("Dispatch setEditingPDFDocumentFromSelectedFiles()")
                       self.setPageSectionsFromSelectedFiles()
                       self.refreshMergedDocument()
            }
    */    }
    }
    
  
    
    
    var isLoadingPDF = false {
        didSet {
            print ("\n isLoadingPDF: \(isLoadingPDF)\n")
        }
    }
    
    var selectedSections: Set<Int> = [] { didSet {
        print("selectedSections didSet:  ", selectedSections)
        selectedSections.forEach {
            print("\($0)") }}}
    
    var selectedPageItems: Set<IndexPath> = [] { didSet {
        print("selectedPageItems didSet:  ", selectedPageItems)
        selectedPageItems.forEach {
            print("\($0)") }}}
    
    var selectedPages: Set<IndexPath> = [] { didSet {
        print("selectedPages didSet:  ", selectedPages)
        selectedPages.forEach {
            print("\($0)") }}}
    
    var mergedPDFURL: URL = {
        FileManager.default.temporaryDirectory.appendingPathComponent("praxpress-merged").appendingPathExtension("pdf")
    }()
    var mergedPDFDocument: PDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)! {
        didSet {
            print ("mergedPDFDocument didSet ")
            mergedPDFView.document = mergedPDFDocument
            isLoadingPDF = false
        }
    }
   
    

    var refreshingMergedDocument: Bool = false  {
        didSet {
            if refreshingMergedDocument {
                print ("Refreshing Merged Document") }
            else {
                print ("Merged Document Refreshed") }
        }
    }
    
    // MARK: - Window-scoped SwiftData helpers
    /// Example: Add a page item to a section in the per-window SwiftData store.
    func addPageItem(to pageSection: PDFPageSectionModel,
                     name: String,
                     aspectRatio: CGFloat,
                     trims: EdgeTrims,
                     merge: MergeMode) {
        guard let ctx = windowModelContext else { return }
        let pageItem = PDFPageItemModel(
            name: name,
            aspectRatio: Double(aspectRatio),
            trimLeft: Double(trims.left),
            trimRight: Double(trims.right),
            trimTop: Double(trims.top),
            trimBottom: Double(trims.bottom),
            mergeModeRaw: merge.rawValue
        )
        pageItem.pageSection = pageSection
        ctx.insert(pageItem)
        do { try ctx.save() } catch { print("Window context save failed: \(error)") }
        // Keep your existing pipeline
        refreshMergedDocument()
    }
    

    
    func handleMergePagesOverwrite() {
        
        
        fatalError("Julie d'Prax: This function is not currently implemented")
        //guard let id = selectedFiles.first, let entry = listOfFiles.first(where: { $0.id == id }) else { return }
        //mergeDocumentPages()
        // Recompute metrics based on the new single-page doc
        //computePageMetrics(for: entry.url)
        
    }
    
 
    
    var replaceSourceFiles: Bool = true
    var multipleFilesSelected: Bool = false
    var sourceFolderURL: URL?
    var exportFolderURL: URL?
    //  var exportFolderURLBookmark: Data?
    var exportFilenamePrefix: String = ""
    
    var exportFilename: String {
        exportFilenamePrefix + exportFilenameBody + exportFilenameSuffix
    }
    
    var exportFilenameSuffix: String = ""
    var exportFilenameExtension: String = "pdf"
    
    var firstSelectedFileURL: URL?  {
        didSet {
            if firstSelectedFileURL != nil {
                sourceFolderURL = firstSelectedFileURL!.deletingLastPathComponent()
                exportFilenameBody = firstSelectedFileURL!.deletingPathExtension().lastPathComponent
                if exportFolderURL == nil { exportFolderURL = sourceFolderURL }
            }
            else {
                exportFilenameBody = ""
            }
        }
    }
    var exportFilenameBody: String = ""
    
    var exportFileURL: URL? {
        
        if exportFolderURL == nil { exportFolderURL = sourceFolderURL }
        guard let folder = exportFolderURL else { return nil }
        return folder.appending(component: exportFilename).appendingPathExtension(exportFilenameExtension)
    }
    

    
   
    var widthGuidePageID: UUID? = nil
    var widthGuideLeftX: CGFloat? = nil
    var widthGuideRightX: CGFloat? = nil
    
   
    
    
    
    
}

