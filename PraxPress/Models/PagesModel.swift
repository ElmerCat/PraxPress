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

    var pageSection: PDFPageSectionModel?

    init(
        id: UUID = UUID(),
        name: String,
        aspectRatio: Double,
        trimLeft: Double = 0,
        trimRight: Double = 0,
        trimTop: Double = 0,
        trimBottom: Double = 0,
        mergeModeRaw: String = "mergeDown"
    ) {
        self.id = id
        self.name = name
        self.aspectRatio = aspectRatio
        self.trimLeft = trimLeft
        self.trimRight = trimRight
        self.trimTop = trimTop
        self.trimBottom = trimBottom
        self.mergeModeRaw = mergeModeRaw
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
