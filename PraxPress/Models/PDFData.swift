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



/*@Observable @MainActor
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
            prax.document.refreshMergedDocument()
        }
    }
    private var _merge: MergeMode = .mergeDown
    var merge: MergeMode {
        get { _merge }
        set {
            if _merge == newValue { return }
            _merge = newValue
            print("PraxModel.mergeModedidSet")
            prax.document.refreshMergedDocument()
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
*/

