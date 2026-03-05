import Foundation
import SwiftData

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
