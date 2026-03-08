//
//  PraxEditingView.swift
//  PraxPress
//
//  Created by Elmer Cat on 3/6/26.
//
import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers

struct PraxEditingView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(MergedPDFDocument.self) var document
    @Environment(PraxModel.self) private var praxModel
    @Environment(\.perWindowModelContainer) private var modelContainer

    @State private var effectivePerWindowContainer: ModelContainer? = nil
    @State private var selectedPages: Set<UUID> = [] {
        didSet { print("selectedPages didSet: ", selectedPages) }
    }
    @State private var selectedSections: Set<UUID> = [] {
        didSet { print("selectedSections didSet: ", selectedSections) }
    }

    // Persisted order for sections
    @Query(sort: \PDFPageSectionModel.orderIndex) private var pageSections: [PDFPageSectionModel]

    var body: some View {
        @Bindable var prax = praxModel

        HSplitView {
            GroupBox {
                VStack {
                    Button("Thumbnail List", action: praxTest)

                    ZStack {
                        Color.contentViewBackground.ignoresSafeArea()

                        // Native row (page) selection
                        List(selection: $selectedPages) {
                            // Reorderable sections
                            ForEach(pageSections) { section in
                                Section(header: sectionHeader(section)) {
                                    sectionContent(for: section)
                                }
                                // Section-level drop to append at end when dropping in empty space
                                .onDrop(of: [.text], isTargeted: nil) { providers in
                                    handleSectionAppendDrop(providers: providers, into: section)
                                }
                            }
                            .onMove { indices, newOffset in
                                reorderSections(indices: indices, newOffset: newOffset)
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .navigationTitle("PDF Sections")
                    }
                }
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ section: PDFPageSectionModel) -> some View {
        HStack {
            Text(section.title)
            Spacer()
            Button {
                if selectedSections.contains(section.id) {
                    selectedSections.remove(section.id)
                } else {
                    selectedSections.insert(section.id)
                }
            } label: {
                Image(systemName: selectedSections.contains(section.id) ? "checkmark.circle.fill" : "checkmark.circle")
            }
            .buttonStyle(.plain)
            .help("Select Section")
        }
    }

    // MARK: - Section Content

    private func sectionContent(for section: PDFPageSectionModel) -> some View {
        // Render by identity to avoid stale snapshot/index drift
        ForEach(section.orderedItems) { pageItem in
            PageItemRow(
                pageItem: pageItem,
                pageSection: section,
                selectedPages: $selectedPages,
                allSectionsProvider: { pageSections }
            )
        }
        // In-section reorder (persist relationship + orderIndex)
        .onMove { indices, newOffset in
            reorderItems(in: section, indices: indices, newOffset: newOffset)
        }
    }

    // MARK: - Persistence helpers

    private func reorderItems(in section: PDFPageSectionModel, indices: IndexSet, newOffset: Int) {
        // Start from the current ordered list
        var ordered = section.orderedItems
        ordered.move(fromOffsets: indices, toOffset: newOffset)

        // 1) Update orderIndex to match new order
        for (idx, item) in ordered.enumerated() {
            item.orderIndex = idx
        }

        // 2) Replace the relationship array to match the new order
        section.pageItems = ordered

        do { try modelContext.save() }
        catch { print("Failed to save item order: \(error)") }
    }

    private func reorderSections(indices: IndexSet, newOffset: Int) {
        var sectionsCopy = pageSections
        sectionsCopy.move(fromOffsets: indices, toOffset: newOffset)
        for (idx, section) in sectionsCopy.enumerated() {
            section.orderIndex = idx
        }
        do { try modelContext.save() }
        catch { print("Failed to save section order: \(error)") }
    }

    // MARK: - Drops

    // Append at end when dropping in empty area of a section
    private func handleSectionAppendDrop(providers: [NSItemProvider], into section: PDFPageSectionModel) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            guard
                let data = item as? Data,
                let idString = String(data: data, encoding: .utf8),
                let uuid = UUID(uuidString: idString)
            else { return }

            // Resolve source item across all sections
            let allItems = pageSections.flatMap { $0.pageItems }
            guard let sourceItem = allItems.first(where: { $0.id == uuid }) else { return }

            DispatchQueue.main.async {
                // location 0 = append at end (your semantics)
                document.performDropOrAction(for: sourceItem, to: section, at: 0)
            }
        }
        return true
    }

    // MARK: - Debug

    func praxTest() {
        print("\nJulie d'Prax")
        for section in pageSections.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            for item in section.orderedItems {
                print(item.name)
            }
        }
    }
}

// MARK: - Row Subview

private struct PageItemRow: View {
    @Environment(MergedPDFDocument.self) private var document

    let pageItem: PDFPageItemModel
    let pageSection: PDFPageSectionModel
    @Binding var selectedPages: Set<UUID>
    let allSectionsProvider: () -> [PDFPageSectionModel]

    var body: some View {
        HStack {
            Text(pageItem.name)
            Spacer()
            if selectedPages.contains(pageItem.id) {
                Image(systemName: "checkmark")
            }
        }
        .onDrag {
            NSItemProvider(object: pageItem.id.uuidString as NSString)
        }
        .onDrop(of: [.text], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
                guard
                    let data = item as? Data,
                    let idString = String(data: data, encoding: .utf8),
                    let uuid = UUID(uuidString: idString)
                else { return }

                // Resolve source item across all sections
                let sections = allSectionsProvider()
                let allItems = sections.flatMap { $0.pageItems }
                guard let sourceItem = allItems.first(where: { $0.id == uuid }) else { return }

                DispatchQueue.main.async {
                    // Compute current index precisely at drop time
                    if let currentIndex = pageSection.orderedItems.firstIndex(where: { $0.id == pageItem.id }) {
                        // Insert before this row (1-based “before N”)
                        document.performDropOrAction(for: sourceItem, to: pageSection, at: currentIndex + 1)
                    } else {
                        // Fallback: append
                        document.performDropOrAction(for: sourceItem, to: pageSection, at: 0)
                    }
                }
            }
            return true
        }
    }
}
