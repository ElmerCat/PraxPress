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
    var aspectRatio: Double
    var trimLeft: Double
    var trimRight: Double
    var trimTop: Double
    var trimBottom: Double
    var mergeModeRaw: String

    var sourceBookmark: Data
    var sourceURLString: String
    var pageIndex: Int
    var cachedAspectRatio: Double?

    @Transient private var _pdfPage: PDFPage? = nil
    var mediaBounds: CGRect

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
        mergeModeRaw: String = "mergeDown"
    ) throws {
        self.id = id
        self.name = name
        self.trimLeft = trimLeft
        self.trimRight = trimRight
        self.trimTop = trimTop
        self.trimBottom = trimBottom
        self.sourceBookmark = sourceBookmark
        self.sourceURLString = sourceURL.absoluteString
        self.pageIndex = pageIndex
        self.mergeModeRaw = mergeModeRaw

        // Resolve and set pdfPage and mediaBounds, compute aspect ratio
        let resolvedURL: URL
        if !sourceBookmark.isEmpty {
            var isStale = false
            guard let url = try? URL(resolvingBookmarkData: sourceBookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) else {
                throw PDFPageItemError.unresolvedSource
            }
            resolvedURL = url
        } else {
            resolvedURL = sourceURL
        }
        let needsStop = resolvedURL.startAccessingSecurityScopedResource()
        defer { if needsStop { resolvedURL.stopAccessingSecurityScopedResource() } }
        guard let doc = PDFDocument(url: resolvedURL) else { throw PDFPageItemError.unresolvedSource }
        guard pageIndex >= 0, pageIndex < doc.pageCount else { throw PDFPageItemError.pageOutOfRange }
        guard let page = doc.page(at: pageIndex) else { throw PDFPageItemError.pageOutOfRange }
        self._pdfPage = page
        let b = page.bounds(for: .cropBox)
        self.mediaBounds = b
        let computed = Double(b.width / b.height)
        self.aspectRatio = computed
        self.cachedAspectRatio = computed
    }
}

@Model
final class PDFPageSectionModel {
    @Attribute(.unique) var id: UUID
    var title: String
    
    // One-to-many: A section owns many items; deleting a section cascades to items.
    @Relationship(deleteRule: .cascade, inverse: \PDFPageItemModel.pageSection)
    var pageItems: [PDFPageItemModel] = []
    
    init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
    }
    
//    @Transient var pdfPage: PDFPage? = nil
    
    var aspectRatio: CGFloat?
    var mergedWidthPts: CGFloat = 0
    var mergedHeightPts: CGFloat = 0
    
}

extension PDFPageItemModel {
    var pdfPage: PDFPage {
        if let page = _pdfPage { return page }
        guard let url = resolveSourceURL(),
              let doc = PDFDocument(url: url),
              pageIndex >= 0, pageIndex < doc.pageCount,
              let page = doc.page(at: pageIndex) else {
            
            print("PDFPageItemModel: Unable to resolve PDFPage at URL: \(sourceURLString)")
            return PDFPage()
//            fatalError("PDFPageItemModel: Unable to resolve PDFPage for id \(id)")
        }
        _pdfPage = page
        return page
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
            var isStale = false
            return try? URL(
                resolvingBookmarkData: sourceBookmark,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        }
        else {
           return URL(string: sourceURLString)
        }
    }

    var media: (bounds: CGRect, aspect: Double) { (mediaBounds, aspectRatio) }
}

