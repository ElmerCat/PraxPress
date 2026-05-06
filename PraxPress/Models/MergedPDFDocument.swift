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
import OSLog


@Observable @MainActor class MergedPDFDocument {
    unowned let prax: PraxModel
    unowned let persistence: FilesPersistenceController
    
    init(prax: PraxModel, persistence: FilesPersistenceController) {
        self.prax = prax
        self.persistence = persistence
    }
    var widthGuidePageID: UUID? = nil
    var widthGuideLeftX: CGFloat? = nil
    var widthGuideRightX: CGFloat? = nil
    
    var pageSections: [MergedPage] = [] {
        didSet {
            print("MergedPDFDocument - pageSections: didSet ")
            
            if pageSections.isEmpty {
  //              prax.selectedEditPages = []
                prax.selectedPageItems = []
       //         prax.selectedPageItem = nil
            }
       
  //          refreshMergedDocument()
            
          /*  else if prax.selectedPageItem == nil {
                if let mergedPage = pageSections.first {
                    if mergedPage.mergeModePages > 0 {
                        prax.currentEditingMergedPage = mergedPage } }
            }
        */
    } }

    var mergedDocumentVersion = UUID()
    var mergedDocumentSize = 0.0
    
    func refreshMergedDocument() {
        if refreshingMergedDocument { return }
     //   print("refreshMergedDocument")
        refreshingMergedDocument = true
        
        Task {
            
            try? await Task.sleep(for:.milliseconds(100))

    //        print("refreshMergedDocument — started")

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
            mergedDocumentVersion = UUID()
            
            if let pdfData = pdfDocument.dataRepresentation() {
                let sizeInBytes = pdfData.count
                mergedDocumentSize = Double(sizeInBytes) / (1024)
                print("mergedDocumentSize: \(mergedDocumentSize) KB")
            }
            self.refreshingMergedDocument = false
            print("refreshMergedDocument — done")
        }
 //       print("refreshMergedDocument — Task starting")
  
    }

    var mergedPDFURL: URL = {
        FileManager.default.temporaryDirectory.appendingPathComponent("praxpress-merged").appendingPathExtension("pdf")
    }()
    
    var mergedPDFDocument: PDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)! {
        didSet {
//            print ("mergedPDFDocument didSet ")
           prax.mergedDocumentPDFView.document = mergedPDFDocument
        }
    }
    var aeditingPDFDocument: PDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)! {
        didSet {
//            print ("editingPDFDocument didSet ")
 //           editingPDFView.document = editingPDFDocument
        }
    }

    var refreshingEditingDocument: Bool = false  {
       didSet {
           if refreshingEditingDocument {
  //             print ("Refreshing Editing Document")
           }
           else {
 //              print ("Editing Document Refreshed")
           }
       }
   }
   
    var refreshingMergedDocument: Bool = false  {
       didSet {
           if refreshingMergedDocument {
 //              print ("Refreshing Merged Document")
           }
           else {
  //             print ("Merged Document Refreshed")
           }
       }
   }
   

    var sourceFolderURL: URL?
    var exportFolderURL: URL?
    //  var exportFolderURLBookmark: Data?
    var exportFileURLBookmark: Data?
    var exportFilenamePrefix: String = ""
    var exportFilenameBody: String = ""
    var exportFilenameSuffix: String = ""
    var exportFilenameExtension: String = "pdf"
    var exportFilename: String { exportFilenamePrefix + exportFilenameBody + exportFilenameSuffix }
    
    var exportFileURL: URL? {
        if exportFolderURL == nil { exportFolderURL = sourceFolderURL }
        guard let folder = exportFolderURL else { return nil }
        return folder.appending(component: exportFilename).appendingPathExtension(exportFilenameExtension) }
    
    func setExportURL(from pageItem: PageItem) {
        if let url = URL(string: pageItem.sourceURLString) {
            sourceFolderURL = url.deletingLastPathComponent()
            exportFilenameBody = url.deletingPathExtension().lastPathComponent
            if exportFolderURL == nil { exportFolderURL = sourceFolderURL } }
    }   
}


