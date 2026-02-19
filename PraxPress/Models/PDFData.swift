//
//  PDFData.swift
//  PraxPress - Prax=0104-1
//
//  Created by Elmer Cat on 12/22/25.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import Combine

enum MergeMode: String, Codable { case mergeDown, mergeRight, mergeSkip }


struct PDFPageSection: Hashable, Identifiable {
    var title: String
    private(set) var id: UUID = UUID()
    var pdfPage: PDFPage? = nil
    
    var mergedWidthPts: CGFloat = 0
    var mergedHeightPts: CGFloat = 0
    
    var pdfPageItems: Array<PDFPageItem> = [] {
        didSet {
            //         let prax = oldValue.count
            
            print("\n pdfPageItems didSet: \(self.pdfPageItems.count)\n\n")
        }
    }
    
}

struct MergedPDFTransfer: Transferable, Identifiable {
    let id = UUID()
    let data: Data
    let filename: String
    
    static var transferRepresentation: some TransferRepresentation {
        // Provide PDF data so other apps (Mail, Notes, Finder) can accept the drop
        DataRepresentation(exportedContentType: .pdf) { pdf in
            pdf.data
        }
        .suggestedFileName { value in
            value.filename
        }
    }
}



@Observable class PDFPageItem: Sendable, Hashable, Equatable, Identifiable {
    // Keep id stable after creation, but allow init/decoding to assign it
    private(set) var id: UUID
    
    let name: String
    let pdfPage: PDFPage
    let aspectRatio: CGFloat
    
    var thumbnail: NSImage?
    
    var trim: EdgeTrims = .zero {
        didSet {
            print(oldValue)
            if PraxModel.shared.isLoadingPDF {
                print("isLoadingPDF - PraxModel.trims didSet")
                return }
            print("PraxModel.trims didSet")
            DispatchQueue.main.async {
                PraxModel.shared.refreshMergedDocument()
                //   PraxModel.shared.mergedPDFDocument = PraxModel.shared.mergeDocumentPagesForSections()
                print("DispatchQueue PraxModel.trims didSet")
            }
        }
    }
    private var _merge: MergeMode = .mergeDown
    var merge: MergeMode {
        get { _merge }
        set {
            if _merge == newValue { return }
            
         //   if PraxModel.shared.editingPDFDocument.pageCount == 1 && newValue == .mergeSkip { return }
            _merge = newValue
            
            
            if PraxModel.shared.isLoadingPDF {
                print("isLoadingPDF - PraxModel.merge didSet")
                return }
            
            print("PraxModel.merge didSet")
            DispatchQueue.main.async {
                print ("DispatchQueue - refreshEditingDocument()")
                PraxModel.shared.refreshMergedDocument()
                
                
            }
        }
    }
    
    
    // Single concrete initializer that initializes all stored properties
    init(
        id: UUID = UUID(),
        name: String,
        pdfPage: PDFPage,
        trim: EdgeTrims = .zero,
        merge: MergeMode = .mergeDown
    ) {
        self.id = id
        self.name = name
        self.pdfPage = pdfPage
        
        self.aspectRatio = {
            let bounds = pdfPage.bounds(for: .cropBox)
            return bounds.size.width / bounds.size.height
        }()
        
        self.trim = trim
        self.merge = merge
    }
    
    static func == (lhs: PDFPageItem, rhs: PDFPageItem) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


func isPDF(_ url: URL) -> Bool {
    if let type = UTType(filenameExtension: url.pathExtension) {
        return type.conforms(to: .pdf)
    }
    return url.pathExtension.lowercased() == "pdf"
}


struct EdgeTrims: Codable, Hashable {
    var left: CGFloat
    var right: CGFloat
    var top: CGFloat
    var bottom: CGFloat
    
    static let zero = EdgeTrims(left: 0, right: 0, top: 0, bottom: 0)
}

struct PDFEntry: Identifiable, Hashable {
    let id: UUID
    let url: URL
    let bookmarkData: Data
    let pageCount: Int
    var fileName: String { url.lastPathComponent }
    let pcardHolderName: String?
    let documentNumber: String?
    let date: String?
    let amount: String?
    let vendor: String?
    let glAccount: String?
    let costObject: String?
    let description: String?
    
    init(id: UUID = UUID(), url: URL, bookmarkData: Data, pageCount: Int, pcardHolderName: String?, documentNumber: String?, date: String?, amount: String?, vendor: String?, glAccount: String?, costObject: String?, description: String?) {
        self.id = id
        self.url = url
        self.bookmarkData = bookmarkData
        self.pageCount = pageCount
        self.pcardHolderName = pcardHolderName
        self.documentNumber = documentNumber
        self.date = date
        self.amount = amount
        self.vendor = vendor
        self.glAccount = glAccount
        self.costObject = costObject
        self.description = description
    }
}

extension CGRect {
    func trimmed(_ trim: EdgeTrims, seamTop: CGFloat = 0, seamBottom: CGFloat = 0) -> CGRect {
        let minX = self.minX + trim.left
        let maxX = self.maxX - trim.right
        let minY = self.minY + trim.bottom + seamBottom
        let maxY = self.maxY - trim.top - seamTop
        let w = max(0, maxX - minX)
        let h = max(0, maxY - minY)
        return CGRect(x: minX, y: minY, width: w, height: h)
    }
}

struct PDFGeometry {
    /// Compute the visible rect in page space given media box and trims.
    static func visibleRect(media: CGRect, trims: EdgeTrims, seamTop: CGFloat, seamBottom: CGFloat) -> CGRect {
        let minX = media.minX + trims.left
        let maxX = media.maxX - trims.right
        let minY = media.minY + trims.bottom + seamBottom
        let maxY = media.maxY - trims.top - seamTop
        let w = max(0, maxX - minX)
        let h = max(0, maxY - minY)
        return CGRect(x: minX, y: minY, width: w, height: h)
    }
    
    /// Computes the final canvas size for the merged PDF using the same rules as the merge routine.
/*    static func canvasSize(for pageRects: [CGRect], pdfPages: [PDFPageItem], trimTop: CGFloat, trimBottom: CGFloat, interPageGap: CGFloat) -> CGSize {
        var maxVisibleWidth: CGFloat = 0
        var totalVisibleHeight: CGFloat = 0
        let count = pageRects.count
        for i in 0..<count {
            let per = pdfPages[i].trim
            let seamTop: CGFloat = (i == 0) ? 0 : trimTop
            let seamBottom: CGFloat = (i == count - 1) ? 0 : trimBottom
            let vis = visibleRect(media: pageRects[i], trims: per, seamTop: seamTop, seamBottom: seamBottom)
            maxVisibleWidth = max(maxVisibleWidth, vis.width)
            totalVisibleHeight += vis.height
        }
        let internalSeams = max(0, count - 1)
        let gapsTotal = interPageGap * CGFloat(internalSeams)
        return CGSize(width: maxVisibleWidth, height: totalVisibleHeight + gapsTotal)
    }*/
}

