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
    ) {
        self.id = id
        self.name = name
        // Temporarily assign provided values; we'll overwrite aspectRatio below if we can resolve the page
        self.aspectRatio = aspectRatio
        self.trimLeft = trimLeft
        self.trimRight = trimRight
        self.trimTop = trimTop
        self.trimBottom = trimBottom
        self.sourceBookmark = sourceBookmark
        self.sourceURLString = sourceURL.absoluteString
        self.pageIndex = pageIndex
        self.mergeModeRaw = mergeModeRaw

        // Compute aspect ratio once from the actual page if possible
        if !sourceBookmark.isEmpty {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: sourceBookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) {
                let needsStop = url.startAccessingSecurityScopedResource()
                defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
                if let doc = PDFDocument(url: url), pageIndex >= 0, pageIndex < doc.pageCount, let page = doc.page(at: pageIndex) {
                    let b = page.bounds(for: .cropBox)
                    let computed = Double(b.width / b.height)
                    self.aspectRatio = computed
                }
            }
        }
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
}

extension PDFPageItemModel {
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

    func makePDFPage() -> PDFPage? {
        guard let url = resolveSourceURL() else { return nil }
        let needsStop = url.startAccessingSecurityScopedResource()
        defer {
            if needsStop {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let doc = PDFDocument(url: url),
              pageIndex >= 0,
              pageIndex < doc.pageCount
        else { return nil }

        return doc.page(at: pageIndex)
    }

}

