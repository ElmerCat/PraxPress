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
    
    
    var pageSections: [PDFPageSectionModel] = [] {
        didSet {
            print("pageSections didSet:  ", pageSections.count)
            
        }
    }
    
 //   var sections: [PDFPageSection] = [] {
 //       didSet {
 //           print("sections didSet:  ", sections.count)
 //       }
 //   }
    
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
    
    
    func addPagesFromURLBookmark(title: String? = nil, url: URL?, bookmarkData: Data?, to pageSection: PDFPageSectionModel?, at location: Int? = 0) {
        guard let ctx = windowModelContext else { return }
        
        // Determine normalized section insertion index
        let sectionIndex = normalizedInsertionIndex(count: pageSections.count, location: location)
        
        // Determine target section
        let section: PDFPageSectionModel = {
            if let givenSection = pageSection {
                ensureSectionInOrder(givenSection, at: sectionIndex)
                return givenSection
            } else {
                let newSection = PDFPageSectionModel(title: (title ?? (url?.deletingPathExtension().lastPathComponent)) ?? "New Page Section")
                ctx.insert(newSection)
                pageSections.insert(newSection, at: sectionIndex)
                return newSection
            }
        }()
        
        // If neither URL nor bookmark provided, just save and refresh
        guard url != nil || bookmarkData != nil else {
            do { try ctx.save() } catch { print("Save failed: \(error)") }
            refreshMergedDocument()
            return
        }
        
        // Resolve bookmark or direct url
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
        
        let needsStop = fileURL.startAccessingSecurityScopedResource()
        defer { if needsStop { fileURL.stopAccessingSecurityScopedResource() } }
        
        // Determine page count fallback to 1
        var pageCount = 1
        if let doc = PDFDocument(url: fileURL) { pageCount = doc.pageCount }
        
        // Normalize page insertion index relative to pageItems count in section
        var pageInsertIndex = normalizedInsertionIndex(count: section.pageItems.count, location: location)
        
        // Insert pages one by one at the computed index, preserving order
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
                section.pageItems.insert(item, at: pageInsertIndex)
                ctx.insert(item)
                pageInsertIndex += 1
                
            
            

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
    
    private func normalizedInsertionIndex(count: Int, location: Int?) -> Int {
        guard let loc = location else { return count }
        if loc == 0 {
            return count
        } else if loc > 0 {
            return min(loc - 1, count)
        } else {
            // loc < 0: count backward from end, clamp to 0
            let pos = count + loc
            return pos < 0 ? 0 : pos
        }
    }
    
    private func ensureSectionInOrder(_ section: PDFPageSectionModel, at index: Int) {
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
    
}

