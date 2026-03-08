//
//  PagesModel.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/26/26.
//

// Model objects: PDFPageItemModel & PDFPageSectionModel
//   and
// PagesPersistenceController




import Foundation
import SwiftData
import PDFKit

enum PDFPageItemError: Error {
    case unresolvedSource
    case pageOutOfRange
}

@Model
final class PDFPageItemModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var trimLeft: Double
    var trimRight: Double
    var trimTop: Double
    var trimBottom: Double
    var mergeModeRaw: String
    var sourceBookmark: Data
    var sourceURLString: String
    var pageIndex: Int
    var orderIndex: Int

    @Transient private var _pdfPage: PDFPage? = nil
    @Transient private var _mediaBounds: CGRect? = nil
    @Transient private var _aspectRatio: Double? = nil

    var pageSection: PDFPageSectionModel?

    init(
        id: UUID = UUID(),
        name: String,
        aspectRatio: Double,
        trimLeft: Double = 0,
        trimRight: Double = 0,
        trimTop: Double = 0,
        trimBottom: Double = 0,
        sourceBookmark: Data = Data(),
        sourceURL: URL,
        pageIndex: Int = 0,
        orderIndex: Int = 0,
        mergeModeRaw: String = "mergeDown"
    ) {
        self.id = id
        self.name = name
        self.trimLeft = trimLeft
        self.trimRight = trimRight
        self.trimTop = trimTop
        self.trimBottom = trimBottom
        self.sourceBookmark = sourceBookmark
        self.sourceURLString = sourceURL.absoluteString
        self.pageIndex = pageIndex
        self.orderIndex = orderIndex
        self.mergeModeRaw = mergeModeRaw
    }
}

@Model
final class PDFPageSectionModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var orderIndex: Int
    
    // One-to-many: A section owns many items; deleting a section cascades to items.
    @Relationship(deleteRule: .cascade, inverse: \PDFPageItemModel.pageSection)
    var pageItems: [PDFPageItemModel] = []
    
    init(id: UUID = UUID(), title: String, orderIndex: Int = 0) {
        self.id = id
        self.title = title
        self.orderIndex = orderIndex
    }
    
//    @Transient var pdfPage: PDFPage? = nil
    
    var aspectRatio: CGFloat?
    var mergedWidthPts: CGFloat = 0
    var mergedHeightPts: CGFloat = 0
    
}

extension PDFPageItemModel {
    var pdfPage: PDFPage {
        if let page = _pdfPage { return page }
        return loadPageAndCache()
    }

    private func loadPageAndCache() -> PDFPage {
        if let url = resolveSourceURL() {
            
            let needsStop = url.startAccessingSecurityScopedResource()
            defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
            
            if let doc = PDFDocument(url: url) {
                if pageIndex >= 0, pageIndex < doc.pageCount {
                    if let page = doc.page(at: pageIndex) {
                        _pdfPage = page
                    }
                }
            }
        }
        else {
            print("PDFPageItemModel: Unable to resolve PDFPage at URL: \(sourceURLString)")
            _pdfPage = PDFPage()
        }
        _mediaBounds = _pdfPage!.bounds(for: .cropBox)
        _aspectRatio = Double(_mediaBounds!.width / _mediaBounds!.height)
        return _pdfPage!
    }

    var mediaBounds: CGRect {
        if let b = _mediaBounds { return b }
        _ = pdfPage
        return _mediaBounds ?? .zero
    }
    
    var aspectRatio: Double {
        if let a = _aspectRatio { return a }
        _ = pdfPage
        return _aspectRatio ?? 0
    }

    var mergeMode: MergeMode {
        get { MergeMode(rawValue: mergeModeRaw) ?? .mergeDown }
        set { mergeModeRaw = newValue.rawValue }
    }

    var trims: EdgeTrims {
        get {
            EdgeTrims(
                left: CGFloat(trimLeft),
                right: CGFloat(trimRight),
                top: CGFloat(trimTop),
                bottom: CGFloat(trimBottom)
            )
        }
        set {
            trimLeft = Double(newValue.left)
            trimRight = Double(newValue.right)
            trimTop = Double(newValue.top)
            trimBottom = Double(newValue.bottom)
        }
    }

    func resolveSourceURL() -> URL? {
        if !sourceBookmark.isEmpty {
            print("PDFPageItemModel: Trying sourceBookmark")
            var isStale = false
            return try? URL(
                resolvingBookmarkData: sourceBookmark,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        }
        else {
            print("PDFPageItemModel: Failed sourceBookmark - returning URL: \(sourceURLString)")
           return URL(string: sourceURLString)
        }
    }

    var media: (bounds: CGRect, aspect: Double) { (mediaBounds, aspectRatio) }
}

extension PDFPageSectionModel {
    /// Reindex all items in this section sequentially from 0 based on the current array order
    func normalizeItemOrder() {
        for (idx, item) in pageItems.enumerated() {
            item.orderIndex = idx
        }
    }
}

extension Array where Element == PDFPageSectionModel {
    /// Normalize section orderIndex values sequentially from 0 based on array order
    mutating func normalizeSectionOrder() {
        for (idx, section) in self.enumerated() {
            section.orderIndex = idx
        }
    }
}

extension PDFPageSectionModel {
    var orderedItems: [PDFPageItemModel] {
        pageItems.sorted { $0.orderIndex < $1.orderIndex }
    }
}
