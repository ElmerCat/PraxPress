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
    
    // Width Guide support
    var widthGuidePageID: UUID? = nil
    var widthGuideLeftX: CGFloat? = nil
    var widthGuideRightX: CGFloat? = nil
    
    
    var pdfPageSections: [PDFPageSection] = []
    
    var fileURL: URL?
    var lastPreviewURL: URL? = nil
    var lastCombinedSourceURL: URL? = nil
    var saveError: String?
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
    var selectionIndexPaths: Set<IndexPath> = [] {
        didSet {
            print("selectionIndexPaths didSet:  ", selectionIndexPaths)
            selectionIndexPaths.forEach {
                print("\($0)")
            }
            
        }
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
    
    
    var editingPDFURL: URL = {
        FileManager.default.temporaryDirectory.appendingPathComponent("praxpress-editing").appendingPathExtension("pdf")
    }()
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

