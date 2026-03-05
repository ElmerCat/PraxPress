import SwiftData
import Foundation
import Combine

/// A helper class to create and own a per-window SwiftData ModelContainer.
/// Each window or tab should instantiate its own `WindowEditingStore`
/// and inject the container via `.modelContainer(...)` on the window's root view.
@MainActor
final class WindowEditingStore: ObservableObject {
    let container: ModelContainer
    let context: ModelContext

    init(inMemory: Bool = true, fileURL: URL? = nil) throws {
        let schema = Schema([
            PDFPageSectionModel.self,
            PDFPageItemModel.self
        ])

        if let fileURL {
            let config = ModelConfiguration(url: fileURL)
            self.container = try ModelContainer(for: schema, configurations: config)
        } else if inMemory {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            self.container = try ModelContainer(for: schema, configurations: config)
        } else {
            self.container = try ModelContainer(for: schema)
        }

        self.context = ModelContext(container)
    }
}

