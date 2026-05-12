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
    
    var mergedPages: [MergedPage] = [] {
        didSet {
            print("MergedPDFDocument - mergedPages: didSet ")
            if mergedPages.isEmpty {
                prax.selectedPageItems = []
            }
    } }


    var mergedDocumentVersion = UUID()
    var mergedDocumentSizeKB = 0
    
    var refreshingMergedDocument: Bool = false
    func refreshMergedDocument() {
        if refreshingMergedDocument { return }
     //   print("refreshMergedDocument")
        refreshingMergedDocument = true
        
        Task {
            
            try? await Task.sleep(for:.milliseconds(100))

            var insertIndex = 0
            let pdfDocument = PDFDocument()
            
            for mergedPage in mergedPages {
                if let pdfPage = mergedPage.pdfPage {
                    
                    pdfDocument.insert(pdfPage, at: insertIndex)
                    insertIndex += 1
                }

            }
            

            mergedPDFDocument = pdfDocument
            mergedDocumentVersion = UUID()
            
            if let pdfData = pdfDocument.dataRepresentation() {
                let sizeInBytes = pdfData.count
                mergedDocumentSizeKB = sizeInBytes / (1000)
                print("mergedDocumentSizeKB: \(mergedDocumentSizeKB) KB")
            }
            self.refreshingMergedDocument = false
            print("refreshMergedDocument — done")
        }
  
    }

    var mergedPDFURL: URL = {
        FileManager.default.temporaryDirectory.appendingPathComponent("praxpress-merged").appendingPathExtension("pdf")
    }()
    
    var mergedPDFDocument: PDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)! {
        didSet {
           prax.mergedDocumentPDFView.document = mergedPDFDocument
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


