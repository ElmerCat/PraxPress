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

    @State private var selectedPages: Set<UUID> = [] {
        didSet { print("selectedPages didSet: ", selectedPages) }
    }
    @State private var selectedSections: Set<UUID> = [] {
        didSet { print("selectedSections didSet: ", selectedSections) }
    }

    // Current drop target to drive custom insertion indicators
    @State private var dropTarget: DropTarget? = nil

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

                        List(selection: $selectedPages) {
                            // Reorderable sections (by dragging headers)
                            ForEach(pageSections) { section in
                                Section(header: sectionHeader(section)) {
                                    ForEach(section.orderedItems) { pageItem in
                                        PageItemRow(
                                            pageItem: pageItem,
                                            pageSection: section,
                                            selectedPages: $selectedPages,
                                            allSectionsProvider: { pageSections },
                                            isInsertTarget: dropTarget == DropTarget(sectionID: section.id, beforeItemID: pageItem.id),
                                            setDropTarget: { dropTarget = $0 },
                                            optionKeyPressedProvider: { praxModel.optionKeyPressed }
                                        )
                                    }
                                    
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
        VStack(spacing: 0) {
            ForEach(section.orderedItems) { pageItem in
                PageItemRow(
                    pageItem: pageItem,
                    pageSection: section,
                    selectedPages: $selectedPages,
                    allSectionsProvider: { pageSections },
                    isInsertTarget: dropTarget == DropTarget(sectionID: section.id, beforeItemID: pageItem.id),
                    setDropTarget: { dropTarget = $0 },
                    optionKeyPressedProvider: { praxModel.optionKeyPressed }
                )
            }

            // Explicit "append" drop target at end of section with visible indicator
            SectionAppendRow(
                section: section,
                isTarget: dropTarget == DropTarget(sectionID: section.id, beforeItemID: nil),
                allSectionsProvider: { pageSections },
                document: document,
                setDropTarget: { dropTarget = $0 },
                optionKeyPressedProvider: { praxModel.optionKeyPressed }
            )
        }
    }

    // MARK: - Persistence helpers

    private func reorderSections(indices: IndexSet, newOffset: Int) {
        print ("reorderSections indicies: ", indices, " newOffset: ", newOffset)
        
        return
        var sectionsCopy = pageSections
        sectionsCopy.move(fromOffsets: indices, toOffset: newOffset)
        for (idx, section) in sectionsCopy.enumerated() {
            section.orderIndex = idx
        }
        do { try modelContext.save() }
        catch { print("Failed to save section order: \(error)") }
    }

    // MARK: - Debug

    func praxTest() {
        print("\nJulie d'Prax")
        for section in pageSections.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            print("Juliette M. Belanger - ", section.title)
            for item in section.orderedItems {
                print(item.name)
            }
        }
    }
}

// MARK: - DropTarget model

private struct DropTarget: Equatable {
    let sectionID: UUID
    // If nil, means "append to end of section"
    let beforeItemID: UUID?
}

// MARK: - Row Subview

private struct PageItemRow: View {
    @Environment(MergedPDFDocument.self) private var document

    let pageItem: PDFPageItemModel
    let pageSection: PDFPageSectionModel
    @Binding var selectedPages: Set<UUID>
    let allSectionsProvider: () -> [PDFPageSectionModel]

    // For custom indicator
    let isInsertTarget: Bool

    // State setter for global drop target
    let setDropTarget: (DropTarget?) -> Void
    let optionKeyPressedProvider: () -> Bool

    var body: some View {
        @Bindable var item = pageItem
        HStack(spacing: 8) {
            TextField("Name", text: $item.name)
            Text(pageItem.name)
            Text(String(item.pageSection!.orderIndex) + " - " + String(pageItem.orderIndex))
            Spacer()
            if selectedPages.contains(item.id) {
                Image(systemName: "checkmark")
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        // Unified drag from anywhere on the row
        .onDrag {
            NSItemProvider(object: item.id.uuidString as NSString)
        }
        // Accept drops to insert BEFORE this row
        .onDrop(of: [UTType.plainText], delegate: RowDropDelegate(
            targetRowItem: item,
            targetSection: pageSection,
            allSectionsProvider: allSectionsProvider,
            document: document,
            optionKeyPressedProvider: optionKeyPressedProvider,
            setDropTarget: setDropTarget
        ))
        // Custom insertion indicator line
        .overlay(alignment: .top) {
            if isInsertTarget {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 2)
                    .padding(.horizontal, -8)
                    .allowsHitTesting(false) // <- don’t steal clicks
            }
        }
    }
}

// MARK: - Section Append Row

private struct SectionAppendRow: View {
    let section: PDFPageSectionModel
    let isTarget: Bool
    let allSectionsProvider: () -> [PDFPageSectionModel]
    let document: MergedPDFDocument
    let setDropTarget: (DropTarget?) -> Void
    let optionKeyPressedProvider: () -> Bool

    var body: some View {
        ZStack(alignment: .center) {
            if isTarget {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 2)
                    .padding(.horizontal, -8)
                    .padding(.vertical, 6)
                    .accessibilityHidden(true)
            } else {
                // Keep a minimal height so it's easy to target
                Color.clear
                    .frame(height: 8)
            }
        }
        .contentShape(Rectangle())
        .onDrop(of: [UTType.plainText], delegate: SectionAppendDropDelegate(
            section: section,
            allSectionsProvider: allSectionsProvider,
            document: document,
            optionKeyPressedProvider: optionKeyPressedProvider,
            setDropTarget: setDropTarget
        ))
    }
}

// MARK: - Drop Delegates

private struct RowDropDelegate: DropDelegate {
    let targetRowItem: PDFPageItemModel
    let targetSection: PDFPageSectionModel
    let allSectionsProvider: () -> [PDFPageSectionModel]
    let document: MergedPDFDocument
    let optionKeyPressedProvider: () -> Bool
    let setDropTarget: (DropTarget?) -> Void

    func validateDrop(info: DropInfo) -> Bool {
        !info.itemProviders(for: [UTType.plainText]).isEmpty
    }

    func dropEntered(info: DropInfo) {
        setDropTarget(DropTarget(sectionID: targetSection.id, beforeItemID: targetRowItem.id))
    }

    func dropExited(info: DropInfo) {
        setDropTarget(nil)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        setDropTarget(DropTarget(sectionID: targetSection.id, beforeItemID: targetRowItem.id))
        return DropProposal(operation: optionKeyPressedProvider() ? .copy : .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        setDropTarget(nil)
        guard let provider = info.itemProviders(for: [UTType.plainText]).first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
            guard let uuid = decodeUUID(from: item) else { return }

            let sections = allSectionsProvider()
            let allItems = sections.flatMap { $0.pageItems }
            guard let sourceItem = allItems.first(where: { $0.id == uuid }) else { return }

            // Insert before this row: find the current index of the target row
            if let currentIndex = targetSection.orderedItems.firstIndex(where: { $0.id == targetRowItem.id }) {
                let location = currentIndex + 1 // your 1-based “before N”
                DispatchQueue.main.async {
                    document.performDropOrAction(for: sourceItem, to: targetSection, at: location)
                }
            } else {
                // Fallback: append
                DispatchQueue.main.async {
                    document.performDropOrAction(for: sourceItem, to: targetSection, at: 0)
                }
            }
        }
        return true
    }
}

private struct SectionAppendDropDelegate: DropDelegate {
    let section: PDFPageSectionModel
    let allSectionsProvider: () -> [PDFPageSectionModel]
    let document: MergedPDFDocument
    let optionKeyPressedProvider: () -> Bool
    let setDropTarget: (DropTarget?) -> Void

    func validateDrop(info: DropInfo) -> Bool {
        !info.itemProviders(for: [UTType.plainText]).isEmpty
    }

    func dropEntered(info: DropInfo) {
        setDropTarget(DropTarget(sectionID: section.id, beforeItemID: nil))
    }

    func dropExited(info: DropInfo) {
        setDropTarget(nil)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        setDropTarget(DropTarget(sectionID: section.id, beforeItemID: nil))
        return DropProposal(operation: optionKeyPressedProvider() ? .copy : .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        setDropTarget(nil)
        guard let provider = info.itemProviders(for: [UTType.plainText]).first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
            guard let uuid = decodeUUID(from: item) else { return }

            let sections = allSectionsProvider()
            let allItems = sections.flatMap { $0.pageItems }
            guard let sourceItem = allItems.first(where: { $0.id == uuid }) else { return }

            // location 0 = append at end
            DispatchQueue.main.async {
                document.performDropOrAction(for: sourceItem, to: section, at: 0)
            }
        }
        return true
    }
}

// MARK: - Helpers

private func decodeUUID(from item: NSSecureCoding?) -> UUID? {
    // Item may arrive as Data or NSString
    if let data = item as? Data,
       let idString = String(data: data, encoding: .utf8),
       let uuid = UUID(uuidString: idString) {
        return uuid
    }
    if let str = item as? NSString,
       let uuid = UUID(uuidString: str as String) {
        return uuid
    }
    return nil
}
