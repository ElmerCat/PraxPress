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
    //  static let praxFileSelectionChanged = Notification.Name("PraxFileSelectionChanged")
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
    

    func zoomInEditingPDFView() {
        editingPDFView?.zoomIn(self)
        editingPDFAutoScales = false
    }
    func zoomOutEditingPDFView() {
        editingPDFView?.zoomOut(self)
        editingPDFAutoScales = false
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
    
    func zoomInMergedPDFView() {
        mergedPDFView?.zoomIn(self)
    }
    func zoomOutMergedPDFView() {
        mergedPDFView?.zoomOut(self)
    }
    
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
    
    let noFileURL = Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!
    var selectedFiles = Set<PDFEntry.ID>() {
        didSet {
            print ("PraxModel selectedFiles didSet ") //, selectedFiles.description)
            
            if selectedFiles.isEmpty {
                editingPDFDocument = PDFDocument(url: noFileURL)!
                mergedPDFDocument = editingPDFDocument
            }
            else {
                isLoadingPDF = true
                DispatchQueue.main.async {
                    print ("self.editingPDFDocument = self.createMergedDocumentFromSelectedFiles()!")
                    self.editingPDFDocument = self.createMergedDocumentFromSelectedFiles()!
                }
            }
        }
    }
    
    var editingPDFDocument: PDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)! {
        didSet {
            print ("editingPDFDocument didSet ")
            
            pdfSections.removeAll()
            pdfPages.removeAll()

            pdfSections.append(PDFPageSection(title: "Julie d'Prax"))
            for idx in 0..<editingPDFDocument.pageCount {
                pdfPages.append(PDFPageItem(index: idx, name:"Page \(idx + 1)"))
            }

            self.currentIndex = 0   //  }
            self.trims = [:]
            self.clearWidthGuide()
            self.recomputeMergedMetrics()
            DispatchQueue.main.async {
                print ("self.mergedPDFDocument = self.mergeDocumentPages()")
                self.mergedPDFDocument = self.mergeDocumentPages()
                self.isLoadingPDF = false
            }

            
            
            //  }
        }
    }

    
    var editingPDFURL: URL = {
        FileManager.default.temporaryDirectory.appendingPathComponent("praxpress-editing").appendingPathExtension("pdf")
    }()
    

    var fileURL: URL?
    var lastPreviewURL: URL? = nil
    var lastCombinedSourceURL: URL? = nil
    
    var saveError: String?
    
    var pdfSections: [PDFPageSection] = []
    var pdfPages: [PDFPageItem] = [] {
        didSet {
//            print ("pdfPages didSet ") //, pdfPages.description)
        }
    }
    
    var mergedPDFURL: URL = {
        FileManager.default.temporaryDirectory.appendingPathComponent("praxpress-merged").appendingPathExtension("pdf")
    }()
    
    var mergedPDFDocument: PDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)! {
        didSet {
            print ("mergedPDFDocument didSet ")
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
    
    var trims: [Int: EdgeTrims] = [:] {
        didSet {
 //           print("PraxModel.trims didSet")
            if isLoadingPDF { return }
            DispatchQueue.main.async {
                self.mergedPDFDocument = self.mergeDocumentPages()
                print("DispatchQueue PraxModel.trims didSet")
            }
        }
    }
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

