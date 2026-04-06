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
 //   let windowModelContext: ModelContext
    unowned let prax: PraxModel
    unowned let persistence: FilesPersistenceController

    init(prax: PraxModel, persistence: FilesPersistenceController) {
 //       self.windowModelContext = windowModelContext
        self.prax = prax
        self.persistence = persistence
    }
    var widthGuidePageID: UUID? = nil
    var widthGuideLeftX: CGFloat? = nil
    var widthGuideRightX: CGFloat? = nil

/*    var isLoadingPDF = false {
        didSet {
            print ("\n isLoadingPDF: \(isLoadingPDF)\n")
        }
    }
*/

    
    var pageSections: [MergedPage] = [] {
        didSet {
            print("pageSections didSet:  ", pageSections.count)
        }
    }

    
    var mergedPDFView: PDFView = {
        let pdfView = PDFView()
        pdfView.displaysPageBreaks = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displaysAsBook = false
        pdfView.document = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)!
        pdfView.autoScales = true
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .green

        return pdfView
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
    
    var documentVersion = UUID()
    
    func refreshMergedDocument() {
        if refreshingMergedDocument { return }
        
        print("refreshMergedDocument")
        refreshingMergedDocument = true
        
        let jean = Task {
            
            try? await Task.sleep(for:.milliseconds(100))

            print("refreshMergedDocument — started")

            var insertIndex = 0
            let pdfDocument = PDFDocument()
            pageSections.forEach {
                section in
                if let pdfPage = section.pdfPage {
                    pdfDocument.insert(pdfPage, at: insertIndex)
                    insertIndex += 1
                }
            }
            mergedPDFDocument = pdfDocument
            documentVersion = UUID()
            self.refreshingMergedDocument = false
            print("refreshMergedDocument — done")
        }
        print("refreshMergedDocument — Task starting")
  
    }

    var mergedPDFURL: URL = {
        FileManager.default.temporaryDirectory.appendingPathComponent("praxpress-merged").appendingPathExtension("pdf")
    }()
    
    var mergedPDFDocument: PDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)! {
        didSet {
            print ("mergedPDFDocument didSet ")
            mergedPDFView.document = mergedPDFDocument
   //         refreshingMergedDocument = false
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
    var exportFilenameBody: String = "PraxPress"
 
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


