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
    
    
    init() {
        @Environment(\.modelContext) var _modelContext
        modelContext = _modelContext
    }
    let modelContext: ModelContext
    
    static let shared = PraxModel()
    
    enum PraxPressMode: String, CaseIterable {
        case data = "Data Mode"
        case merge = "Merge Mode"
        
        var color: Color {
            switch self {
            case .merge:
                return .pink
            case .data:
                return .blue
            }
        }
        
        // And an icon, because why not?
        var icon: String {
            switch self {
            case .merge:
                return "apple.logo"
            case .data:
                return "swift"
             }
        }
    }
    var praxPressMode: PraxPressMode = .merge
    
    var dropTargeted = false
    var optionKeyPressed = false
    
    // Width Guide support
    var widthGuidePageID: UUID? = nil
    var widthGuideLeftX: CGFloat? = nil
    var widthGuideRightX: CGFloat? = nil
    
    var pdfPageSections: [PDFPageSection] = [] {
        didSet {
            print("pdfPageSections didSet:  ", pdfPageSections.count)
         //   refreshEditingDocument()
            
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
    
    var saveError: String?
    var isLoadingPDF = false {
        didSet {
            print ("\n isLoadingPDF: \(isLoadingPDF)\n")
        }
    }
    var isOn = false
    var isLarge: Bool = false
    var showFilesPanel = true
    var showingFileImportOptions: Bool = false
    var showingFileExportOptions: Bool = false
    var showingMergedDocumentInspector = false
    var showingPDFPageItemInspector = false
    var showingImporter: Bool = false
    var showingFileImporter: Bool = false
    var showingExportFolderSelector: Bool = false
    var isShowingInspector: Bool = false
    var showSavePanel: Bool = false
    var columnVisibility: NavigationSplitViewVisibility = .all
    
//    var lastListOfFiles: [PDFEntry] = []
/*    var listOfFiles: [PDFEntry] = [] {
        willSet {
            print ("PraxModel listOfFiles willSet ") //, listOfFiles.description)
            lastListOfFiles = listOfFiles
        }
        didSet {
            print ("PraxModel listOfFiles didSet ") //, listOfFiles.description)
        }
    }
*/

    func refreshMergedDocument() {
        if !refreshingMergedDocument {
            refreshingMergedDocument = true
            recomputeMergedMetrics()
            mergedPDFDocument = PraxModel.shared.mergeDocumentPagesForSections()
            refreshingMergedDocument = false
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
        
  /* func refreshEditingDocument() {
        if !refreshingEditingDocument {
            refreshingEditingDocument = true
            if pdfPageSections.isEmpty {
                editingPDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)!
                mergedPDFDocument = editingPDFDocument
            }
            else {
                editingPDFDocument = pdfDocumentFromPDFPageSections(sections: pdfPageSections)
                refreshMergedDocument()
            }
            refreshingEditingDocument = false
        }
    } */

/*    var refreshingEditingDocument: Bool = false {
        didSet {
            if refreshingEditingDocument {
                print ("Refreshing Editing Document") }
            else {
                print ("Editing Document Refreshed") }
        }
    } */

    
    
    var pdfFiles: [PDFFile] = [] {
        didSet {
            print ("PraxModel pdfFiles didSet: ", pdfFiles.count)
        }
    }
    
    
    var selectedFiles = Set<PDFFile.ID>() {
        didSet {
            print ("PraxModel selectedFiles didSet: ", selectedFiles.count) //, selectedFiles.description)
            isLoadingPDF = true
            selectedPageItems = []
            clearWidthGuide()

            
            DispatchQueue.main.async {
                print ("Dispatch setEditingPDFDocumentFromSelectedFiles()")
                self.setPageSectionsFromSelectedFiles()
         //       self.refreshMergedDocument()
            }
        }
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
    
//    var editingPDFURL: URL = {
//        FileManager.default.temporaryDirectory.appendingPathComponent("praxpress-editing").appendingPathExtension("pdf")
//    }()
  
 /*   var editingPDFDocument: PDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)! {
        didSet {
            print ("editingPDFDocument didSet ")
            
            if isLoadingPDF {
                print ("isLoadingPDF - editingPDFDocument didSet ")
                 
  //              recomputeMergedMetrics()
            }
            
            editingPDFView.document = editingPDFDocument
            
            DispatchQueue.main.async {
                print ("self.mergedPDFDocument = self.mergeDocumentPagesForSections()")
 //               self.mergedPDFDocument = self.mergeDocumentPagesForSections()
            }
        }
    }
 */
    
/*    var editingPDFView: PDFView = PDFView() { didSet {
        editingPDFView.document = editingPDFDocument
        editingPDFView.displaysPageBreaks = editingPDFDisplayPageBreaks
        editingPDFView.displayMode = editingPDFDisplayMode
        editingPDFView.displaysAsBook = editingPDFDisplaysAsBook
        editingPDFView.autoScales = editingPDFAutoScales
        editingPDFView.backgroundColor = editingPDFBackgroundColor
    }}
    
    var editingPDFDisplayMode: PDFDisplayMode = .singlePageContinuous { didSet {
        editingPDFView.displayMode = editingPDFDisplayMode
        editingPDFView.scaleFactor = editingPDFView.scaleFactorForSizeToFit
    }}
    var editingPDFAutoScales: Bool = true
    var editingPDFDisplayPageBreaks: Bool = true
    var editingPDFDisplaysAsBook: Bool = false {
        didSet{ editingPDFView.displaysAsBook = editingPDFDisplaysAsBook }
    }
    var editingPDFBackgroundColor: NSColor = .red { didSet {
        editingPDFView.backgroundColor = editingPDFBackgroundColor }
    }
 */
 
    var mergedPDFURL: URL = {
        FileManager.default.temporaryDirectory.appendingPathComponent("praxpress-merged").appendingPathExtension("pdf")
    }()
    var mergedPDFDocument: PDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)! {
        didSet {
            print ("mergedPDFDocument didSet ")
            mergedPDFView.document = mergedPDFDocument
            self.isLoadingPDF = false
        }
    }
    var mergedPDFView: PDFView = PDFView() { didSet {
        print ("mergedPDFView didSet ")
        mergedPDFView.document = mergedPDFDocument
        mergedPDFView.displaysPageBreaks = mergedPDFDisplayPageBreaks
        mergedPDFView.displayMode = mergedPDFDisplayMode
        mergedPDFView.displaysAsBook = mergedPDFDisplaysAsBook
        mergedPDFView.autoScales = mergedPDFAutoScales
        mergedPDFView.backgroundColor = mergedPDFBackgroundColor
    }}
    var mergedPDFDisplayMode: PDFDisplayMode = .singlePage { didSet {
        mergedPDFView.displayMode = mergedPDFDisplayMode
        mergedPDFView.scaleFactor = mergedPDFView.scaleFactorForSizeToFit
    }}
    var mergedPDFAutoScales: Bool = true
    var mergedPDFDisplayPageBreaks: Bool = true
    var mergedPDFDisplaysAsBook: Bool = false {
        didSet{ mergedPDFView.displaysAsBook = mergedPDFDisplaysAsBook }
    }
    var mergedPDFBackgroundColor: NSColor = .yellow { didSet {
        mergedPDFView.backgroundColor = mergedPDFBackgroundColor }
    }
    
}

