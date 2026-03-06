//
//  PDFData.swift
//  PraxPress - Prax=0104-1
//
//  Created by Elmer Cat on 12/22/25.
//
import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers



@Observable @MainActor
final class PDFPageItem: Identifiable, Equatable, Hashable {
    nonisolated static func == (lhs: PDFPageItem, rhs: PDFPageItem) -> Bool { lhs.id == rhs.id }
    nonisolated func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: UUID
    let document: MergedPDFDocument
    var name: String
    let pdfPage: PDFPage
    let aspectRatio: CGFloat
    
    init(
        id: UUID = UUID(),
        document: MergedPDFDocument,
        name: String,
        pdfPage: PDFPage,
    ) {
        self.id = id
        self.document = document
        self.name = name
        self.pdfPage = pdfPage
        self.aspectRatio = {
            let bounds = pdfPage.bounds(for: .cropBox)
            return bounds.size.width / bounds.size.height
        }()
    }
    
    var thumbnail: NSImage?
    var trim: EdgeTrims = .zero {
        didSet {
            print(oldValue)
            print("PraxModel.trims didSet")
            document.refreshMergedDocument()
        }
    }
    private var _merge: MergeMode = .mergeDown
    var merge: MergeMode {
        get { _merge }
        set {
            if _merge == newValue { return }
            _merge = newValue
            print("PraxModel.mergeModedidSet")
            document.refreshMergedDocument()
        }
    }
}

@Observable @MainActor
final class PDFPageSection: Identifiable, Equatable, Hashable {
    nonisolated static func == (lhs: PDFPageSection, rhs: PDFPageSection) -> Bool { lhs.id == rhs.id }
    nonisolated func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: UUID
    let document: MergedPDFDocument
    var title: String
    init(
        id: UUID = UUID(),
        document: MergedPDFDocument,
        title: String,
        pdfPageItems: [PDFPageItem]?
    ) {
        self.id = id
        self.document = document
        self.title = title
        self.pdfPageItems = pdfPageItems ?? []
    }

    var pdfPage: PDFPage? = nil
    var aspectRatio: CGFloat?
    var mergedWidthPts: CGFloat = 0
    var mergedHeightPts: CGFloat = 0
    var pdfPageItems: [PDFPageItem] = [] {
        didSet { print("\n pdfPageItems didSet: \(self.pdfPageItems.count)\n\n") }
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

enum MergeMode: String, Codable { case mergeDown, mergeRight, mergeSkip }

struct EdgeTrims: Codable, Hashable {
    var left: CGFloat
    var right: CGFloat
    var top: CGFloat
    var bottom: CGFloat
    
    nonisolated static let zero = EdgeTrims(left: 0, right: 0, top: 0, bottom: 0)
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
    
}
