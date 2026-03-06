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



@Observable @MainActor class MergedPDFDocument {
    // Window-scoped SwiftData context for PDFPageSectionModel/PDFPageItemModel
    var windowModelContext: ModelContext?
    
    var prax: PraxModel?
    var persistence: FilesPersistenceController?
    
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
    
    
    func addPagesFromURLBookmark(_ title: String = "New Page Section", url: URL?, bookmarkData: Data?, to pageSection: PDFPageSectionModel?) {
        guard let ctx = windowModelContext else { return }
        // Determine or create the target section
        let section: PDFPageSectionModel = pageSection ?? {
            let s = PDFPageSectionModel(title: title)
            ctx.insert(s)
            return s
        }()

        // If neither URL nor bookmark provided, just save the section
        guard url != nil || bookmarkData != nil else {
            do { try ctx.save() } catch { print("Save failed: \(error)") }
            refreshMergedDocument()
            return
        }

        // Prefer bookmark if provided; otherwise use direct URL
        let fileURL: URL
        let baseBookmark: Data
        if let data = bookmarkData {
            var isStale = false
            guard let resolved = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) else {
                do { try ctx.save() } catch { print("Save failed: \(error)") }
                refreshMergedDocument()
                return
            }
            fileURL = resolved
            baseBookmark = data
        } else if let direct = url {
            fileURL = direct
            baseBookmark = (try? direct.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)) ?? Data()
        } else {
            do { try ctx.save() } catch { print("Save failed: \(error)") }
            refreshMergedDocument()
            return
        }

        // Determine page count (fallback to 1 if not available)
        var pageCount = 1
        if let doc = PDFDocument(url: fileURL) { pageCount = doc.pageCount }

        // Create an item per page without opening pages here; runtime will resolve via makePDFPage()
        for index in 0..<pageCount {
            let displayName = nameForPage(url: fileURL, index: index)
            let item = PDFPageItemModel(
                name: displayName,
                aspectRatio: 0,
                trimLeft: 0,
                trimRight: 0,
                trimTop: 0,
                trimBottom: 0,
                sourceBookmark: baseBookmark,
                sourceURL: fileURL,
                pageIndex: index,
                mergeModeRaw: MergeMode.mergeDown.rawValue
            )
            section.pageItems.append(item)
            ctx.insert(item)
        }

        do { try ctx.save() } catch { print("Save failed: \(error)") }
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
    
   
    
    
    
    
    private func nameForPage(url: URL, index: Int) -> String {
        let base = url.deletingPathExtension().lastPathComponent
        return "\(base) [\(index + 1)]"
    }
    
}

