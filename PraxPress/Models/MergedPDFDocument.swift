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
    let windowModelContext: ModelContext
    unowned let prax: PraxModel
    unowned let persistence: FilesPersistenceController

    init(windowModelContext: ModelContext, prax: PraxModel, persistence: FilesPersistenceController) {
        self.windowModelContext = windowModelContext
        self.prax = prax
        self.persistence = persistence
    }
    var widthGuidePageID: UUID? = nil
    var widthGuideLeftX: CGFloat? = nil
    var widthGuideRightX: CGFloat? = nil

    var isLoadingPDF = false {
        didSet {
            print ("\n isLoadingPDF: \(isLoadingPDF)\n")
        }
    }
    
    var pageSections: [PDFPageSectionModel] = [] {
        didSet {
            print("pageSections didSet:  ", pageSections.count)
        }
    }

    
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
    
    
    func handleMergePagesOverwrite() {
        
        
        fatalError("Julie d'Prax: This function is not currently implemented")
        //guard let id = selectedFiles.first, let entry = listOfFiles.first(where: { $0.id == id }) else { return }
        //mergeDocumentPages()
        // Recompute metrics based on the new single-page doc
        //computePageMetrics(for: entry.url)
        
    }
    
   
    
}


