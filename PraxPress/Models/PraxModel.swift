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
        
    }
    static let shared = PraxModel()
    
    // Width Guide support
    var widthGuidePageID: UUID? = nil
    var widthGuideLeftX: CGFloat? = nil
    var widthGuideRightX: CGFloat? = nil
    
    var pdfPageSections: [PDFPageSection] = []
    var selectedSections: Set<Int> = [] { didSet {
        print("selectedSections didSet:  ", selectedSections)
        selectedSections.forEach {
            print("\($0)") }}}
    
    var selectedPageItems: Set<IndexPath> = [] { didSet {
        print("selectedPageItems didSet:  ", selectedPageItems)
        selectedPageItems.forEach {
            print("\($0)") }}}
    
    var saveError: String?
    var isLoadingPDF = false
    var isOn = false
    var isLarge: Bool = false
    var showingImporter: Bool = false
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

    var pdfFiles: [PDFFile] = [] {
        didSet {
            print ("PraxModel pdfFiles didSet: ", pdfFiles.count)
        }
    }
    
    
    var selectedFiles = Set<PDFFile.ID>() {
        didSet {
            print ("PraxModel selectedFiles didSet: ", selectedFiles.count) //, selectedFiles.description)
            isLoadingPDF = true
            
            DispatchQueue.main.async {
                print ("Dispatch setEditingPDFDocumentFromSelectedFiles()")
                self.setEditingPDFDocumentFromSelectedFiles()
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
    
    var editingPDFURL: URL = {
        FileManager.default.temporaryDirectory.appendingPathComponent("praxpress-editing").appendingPathExtension("pdf")
    }()
    var editingPDFDocument: PDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)! {
        didSet {
            print ("editingPDFDocument didSet ")
            
            if isLoadingPDF {
                print ("isLoadingPDF - editingPDFDocument didSet ")
                selectedPageItems = []
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
    
}

