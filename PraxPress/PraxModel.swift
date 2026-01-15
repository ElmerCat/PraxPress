//  PraxModel.swift
//  PraxPress - Prax=0104-1
//

import Foundation
import CoreGraphics
import PDFKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

internal import Combine

extension Notification.Name {
    static let praxWidthGuideChanged = Notification.Name("PraxWidthGuideChanged")
    static let praxFileSelectionChanged = Notification.Name("PraxFileSelectionChanged")
}

struct EdgeTrims: Codable, Hashable {
    var left: CGFloat
    var right: CGFloat
    var top: CGFloat
    var bottom: CGFloat
    
    static let zero = EdgeTrims(left: 0, right: 0, top: 0, bottom: 0)
}

struct PDFPageSection: Hashable {
    let title: String
    let id = UUID()
}

struct PDFPageItem: Hashable {
    let index: Int
    let name: String
    let id = UUID()
}

//@Model
@Observable
final class PraxModel: Sendable {
    init() { }
    static let shared = PraxModel()
    
    var mergedPDFView: PDFView?
    
    var editingPDFView: PDFView?
    
    func zoomToFitEditingPDFView() {
        if let editingPDFView {
            editingPDFView.scaleFactor = editingPDFView.scaleFactorForSizeToFit
            pdfAutoScales = true
        }
    }
    func zoomInEditingPDFView() {
        if let editingPDFView {
            editingPDFView.zoomIn(self)
            pdfAutoScales = false
        }
    }
    func zoomOutEditingPDFView() {
        if let editingPDFView {
            editingPDFView.zoomOut(self)
            pdfAutoScales = false
        }
    }
    
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
    
    let noFileURL = Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!
    var selectedFiles = Set<PDFEntry.ID>() {
        didSet {
            print ("PraxModel selectedFiles didSet ") //, selectedFiles.description)

            if selectedFiles.isEmpty {
                editingPDFDocument = PDFDocument(url: noFileURL)!
                mergedPDFDocument = editingPDFDocument
            }
            else {
                
                editingPDFDocument = createMergedDocumentFromSelectedFiles()!
                currentIndex = 0   //  }
                trims = [:]
                clearWidthGuide()
                
                DispatchQueue.main.async {
                    self.recomputeMergedMetrics()
                    self.mergedPDFDocument = self.editingPDFDocument
                    NotificationCenter.default.post(name: .praxFileSelectionChanged, object: nil)
                }
            }
        }
    }
    
    
    var fileURL: URL?
    var lastPreviewURL: URL? = nil
    var lastCombinedSourceURL: URL? = nil
    
    var pdfDisplayMode: PDFDisplayMode = .singlePageContinuous
    var pdfAutoScales: Bool = true
    var pdfDisplayPageBreaks: Bool = true
    var pdfDisplaysAsBook: Bool = false
    
    var pdfBackgroundColor: NSColor = .clear
    var saveError: String?
    
    var pdfSections: [PDFPageSection] = []
    var pdfPages: [PDFPageItem] = [] {
        didSet {
            print ("pdfPages didSet ") //, pdfPages.description)
        }
    }
    
    var mergedPDFURL: URL = {
        FileManager.default.temporaryDirectory.appendingPathComponent("praxpress-merged-\(UUID().uuidString)").appendingPathExtension("pdf")
    }()
    
    var mergedPDFDocument: PDFDocument? {
        didSet {
            print ("mergedPDFDocument didSet ")
            DispatchQueue.main.async {
                
                self.mergeDocumentPages()
                
                let pv = PDFDocument(url: self.mergedPDFURL)!
                self.mergedPDFView?.document = pv
                
                self.mergedPDFView?.layoutDocumentView()
                print ("Prax Model - mergedPDFDocument layoutDocumentView ")
            }
            
        }
    }
    
  
    
    
    
    var editingPDFDocument: PDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)! {
        didSet {
            print ("editingPDFDocument didSet ")
            pdfSections.removeAll()
            pdfPages.removeAll()
          //  if let editingPDFDocument {
                pdfSections.append(PDFPageSection(title: "Julie d'Prax"))
                for idx in 0..<editingPDFDocument.pageCount {
                    pdfPages.append(PDFPageItem(index: idx, name:"Page \(idx + 1)"))
                }
          //  }
        }
    }
    
    func updateCurrentIndex(indexPaths: Set<IndexPath>) -> Void {
        if let first = indexPaths.first {
            currentIndex = first.item
        }
        
    }
    
    func pages(in section: PDFPageSection) -> [PDFPageItem] {
        return pdfPages
    }
    
    var currentIndex: Int = -1
    
    var trims: [Int: EdgeTrims] = [:]
    func trims(for index: Int) -> EdgeTrims { trims[index] ?? .zero }
    func setTrims(_ value: EdgeTrims, for index: Int) { trims[index] = value }
    
    var mergedWidthPts: CGFloat = 0
    var mergedHeightPts: CGFloat = 0
    
    var pageCount: Int? = nil
    var totalHeightPoints: CGFloat? = nil
    var maxWidthPoints: CGFloat? = nil
    
    var mergeTopMargin: Double = 0
    var mergeBottomMargin: Double = 0
    var mergeInterPageGap: Double = 0
    
    // Width Guide support
    var widthGuidePageIndex: Int? = nil
    var widthGuideLeftX: CGFloat? = nil
    var widthGuideRightX: CGFloat? = nil
    
   
}

