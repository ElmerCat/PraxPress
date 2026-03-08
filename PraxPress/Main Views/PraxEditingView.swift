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
        didSet {
            print ("selectedPages didSet: ", selectedPages)
        }
    }
    @State private var selectedSections: Set<UUID> = [] {
        didSet {
            print ("selectedSections didSet: ", selectedSections)
        }
    }
    
    
    @Query(sort: \PDFPageSectionModel.orderIndex) private var pageSections: [PDFPageSectionModel]
    
    
    
    var body: some View {
        @Bindable var prax = praxModel
        
        HSplitView {
            GroupBox {
                VStack {
                    Button("Thumbnail List", action: praxTest)
                    
                    ZStack {
                        Color.contentViewBackground.ignoresSafeArea()
                        
                        // 1) Bind List selection to pages (rows)
                        List(selection: $selectedPages) {
                            ForEach(pageSections) { pageSection in
                                Section(header:
                                            HStack {
                                                Text(pageSection.title)
                                                Spacer()
                                            Button("Select",
                                                   systemImage: selectedSections.contains(pageSection.id) ? "checkmark.circle.fill" :  "checkmark.circle") {
                                                if selectedSections.contains(pageSection.id) {
                                                    selectedSections.remove(pageSection.id)
                                                } else {
                                                    selectedSections.insert(pageSection.id)
                                                }
                                            }
                                        }.contentShape(Rectangle()) ) {
 
                                    ForEach(pageSection.orderedItems) { pageItem in
                                        HStack {
                                            Text(pageItem.name)
                                            Spacer()
                                            if selectedPages.contains(pageItem.id) {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                    .onMove { indices, newOffset in
                                        var items = pageSection.orderedItems
                                        items.move(fromOffsets: indices, toOffset: newOffset)
                                        for (idx, item) in items.enumerated() { item.orderIndex = idx }
                                        do { try modelContext.save() } catch { print("Failed to save item order: \(error)") }
                                    }
                                }
                            }
                            .onMove { indices, newOffset in
                                var sections = pageSections
                                sections.move(fromOffsets: indices, toOffset: newOffset)
                                for (idx, section) in sections.enumerated() { section.orderIndex = idx }
                                do { try modelContext.save() } catch { print("Failed to save section order: \(error)") }
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
        }
    }
    
    func praxTest() {
        print("\nJulie d'Prax")
        for section in pageSections.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            for item in section.orderedItems {
                print(item.name)
            }
        }
    }
    
}


