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

    // Many-to-one: Each item belongs to a single section
 //   @Relationship(deleteRule: .nullify, inverse: \PDFPageSectionModel.pageItems)
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
