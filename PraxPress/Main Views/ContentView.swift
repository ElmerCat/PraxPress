//
//  ContentView.swift
//  PraxPress - Prax=0104-1
//
//  Created by Elmer Cat on 12/21/25.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import Combine



enum MergeMode: String, Codable { case mergeDown, mergeRight, mergeSkip }

struct PDFPageItem: Hashable, Codable, Equatable {
    // Keep id stable after creation, but allow init/decoding to assign it
    private(set) var id: UUID
    
    let name: String
    let pdfPage: PDFPage
    let thumbnail: NSImage
    
    var trim: EdgeTrims = .zero {
        didSet {
            print("PraxModel.trims didSet")
            if PraxModel.shared.isLoadingPDF { return }
            
            DispatchQueue.main.async {
                PraxModel.shared.recomputeMergedMetrics()
                PraxModel.shared.mergedPDFDocument = PraxModel.shared.mergeDocumentPagesForSections()
                print("DispatchQueue PraxModel.trims didSet")
            }
        }
    }
    var merge: MergeMode = .mergeDown
    
    // Single concrete initializer that initializes all stored properties
    init(
        id: UUID = UUID(),
        name: String,
        pdfPage: PDFPage,
        thumbnail: NSImage,
        trim: EdgeTrims = .zero,
        merge: MergeMode = .mergeDown
    ) {
        self.id = id
        self.name = name
        self.pdfPage = pdfPage
        self.thumbnail = thumbnail
        self.trim = trim
        self.merge = merge
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case trim
        case merge
        // Exclude: pdfPage, thumbnail
    }
    
    // Single decoding initializer: decode codable fields and supply placeholders
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedID = try container.decode(UUID.self, forKey: .id)
        let decodedName = try container.decode(String.self, forKey: .name)
        let decodedTrim = try container.decode(EdgeTrims.self, forKey: .trim)
        let decodedMerge = try container.decode(MergeMode.self, forKey: .merge)
        
        self = PDFPageItem(
            id: decodedID,
            name: decodedName,
            pdfPage: PDFPage(),   // placeholder; replace with real page later in app logic
            thumbnail: NSImage(), // placeholder; replace with real image later
            trim: decodedTrim,
            merge: decodedMerge
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(trim, forKey: .trim)
        try container.encode(merge, forKey: .merge)
    }
    
    mutating func setTrim(_ trim: EdgeTrims) {
        self.trim = trim
    }
    
    static func == (lhs: PDFPageItem, rhs: PDFPageItem) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct PDFPageSection: Hashable, Codable, Transferable {
    var title: String
    private(set) var id: UUID = UUID()
    var pdfPage: PDFPage? = nil
    
    var mergedWidthPts: CGFloat = 0
    var mergedHeightPts: CGFloat = 0
    
    var pdfPageItems: [PDFPageItem] = [] {
        didSet {
            print("\n pdfPageItems didSet: \(self.pdfPageItems.count)\n\n")
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case title
        case id
        case mergedWidthPts
        case mergedHeightPts
        case pdfPageItems
    }
    
    init(
        title: String,
        pdfPage: PDFPage? = nil,
        mergedWidthPts: CGFloat = 0,
        mergedHeightPts: CGFloat = 0,
        pdfPageItems: [PDFPageItem] = []
    ) {
        self.title = title
        self.pdfPage = pdfPage
        self.mergedWidthPts = mergedWidthPts
        self.mergedHeightPts = mergedHeightPts
        self.pdfPageItems = pdfPageItems
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.mergedWidthPts = try container.decode(CGFloat.self, forKey: .mergedWidthPts)
        self.mergedHeightPts = try container.decode(CGFloat.self, forKey: .mergedHeightPts)
        self.pdfPageItems = try container.decode([PDFPageItem].self, forKey: .pdfPageItems)
        // Decode id if present, otherwise generate a new one
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(id, forKey: .id)
        try container.encode(mergedWidthPts, forKey: .mergedWidthPts)
        try container.encode(mergedHeightPts, forKey: .mergedHeightPts)
        try container.encode(pdfPageItems, forKey: .pdfPageItems)
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
    
}

struct MergedPDFTransfer: Transferable, Identifiable {
    let id = UUID()
    let data: Data
    
    static var transferRepresentation: some TransferRepresentation {
        // Provide PDF data so other apps (Mail, Notes, Finder) can accept the drop
        DataRepresentation(exportedContentType: .pdf) { item in
            item.data
        }
    }
}

struct PDFPageSectionsPayload: Transferable, Codable, Hashable {
    var sections: [PDFPageSection]
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}






struct ContentView: View {
    @State private var prax = PraxModel.shared
    
    var body: some View {
        
        let _ = Self._printChanges()
        
        
        
        NavigationSplitView(columnVisibility: $prax.columnVisibility
        ) {
            SourceFilesView()
                .navigationSplitViewColumnWidth(min: 50, ideal: 300, max: 1000)
        }
        
        detail:  {
            HSplitView {
                
                GroupBox {
                    DocumentEditingToolbar()
                    DocumentEditingView()
                    
                }
                .frame(maxWidth: 1000, maxHeight: .infinity)
                .background(.cyan).padding(20)
                
                GroupBox {
                    MergedDocumentToolbar()
                        .draggable {
                            if let data = prax.mergedPDFDocument.dataRepresentation() {
                                return MergedPDFTransfer(data: data)
                            } else {
                                return nil
                            }
                        }
                    GroupBox {
                        MergedDocumentView()
                        
                    }
                    .draggable {
                        if let data = prax.mergedPDFDocument.dataRepresentation() {
                            return MergedPDFTransfer(data: data)
                        } else {
                            return nil
                        }
                    }
                    
                }.background(.green).padding(20)
                    .frame(maxWidth: 1000, maxHeight: .infinity)
            }
            
            .sheet(isPresented: $prax.showSavePanel) {
                SaveAsPanel(suggestedURL: prax.mergedPDFURL) { destination in
                    prax.mergedPDFView?.document?.write(to: destination)
                }}
            
            .inspector(isPresented: $prax.isShowingInspector) {
                VStack {
                    GroupBox {
                        
                        Text("Inspector 1")
                            .frame(minWidth: 100, maxWidth: 1000, maxHeight: 100)
                            .background(.pink)
                    }
                    .padding(20)
                    //  .background(.yellow)
                    Button(prax.isLarge ? "Make Small" : "Make Large") {
                        // Toggle the state when the button is tapped
                        prax.isLarge.toggle()
                    }
                    Text("Inspector 2")
                    //           .frame(maxWidth: .infinity, maxHeight: .infinity)
                    //               .background(.purple)
                        .background(.purple)
                }
                Text("Inspector 3")
                //    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .inspectorColumnWidth(min: 50, ideal: 150, max: 500)
                    .background(.gray)
            }
        }
        
        .navigationSplitViewColumnWidth(min: 150, ideal: 200, max: 400)
        .navigationSplitViewColumnWidth(min: (prax.isOn ? 0 : 500), ideal: (prax.isOn ? 0 : 500), max: (prax.isOn ? 1: 500))
        
        .toolbar() {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
                } label: {
                    Label("Sidebar", systemImage: "sidebar.left")
                }
                Button {
                    if prax.columnVisibility == .detailOnly {
                        NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
                    }
                    prax.showingImporter = true
                } label: {
                    Label("Select Files", systemImage: "folder.badge.plus")
                }
                //              Button("Save", systemImage: "square.and.arrow.down") {
                //                prax.handleMergePagesOverwrite()
                //            handleSaveCurrentSelection()
                
                //          }
                //         .disabled(prax.selectedFiles.isEmpty)
                
                Button("Save As …", systemImage: "square.and.arrow.down.on.square") {
                    //  prax.showSavePanel = true
                    prax.showSavePanel = true
                }
                .disabled(prax.selectedFiles.isEmpty)
            }
            
            
            
            ToolbarItemGroup(placement: .secondaryAction) {
                Button {
                    prax.isLarge.toggle()
                } label: {
                    Label((prax.isLarge ? "Julie d'Prax" : "Juliette M. Belanger"), systemImage: (prax.isLarge ? "minus.magnifyingglass" : "plus.magnifyingglass"))
                }
            }
            
            ToolbarItemGroup(placement: .status) {
                Button {
                    prax.isLarge.toggle()
                } label: {
                    Label((prax.isLarge ? "Status Small" : "Status Large"), systemImage: (prax.isLarge ? "minus.magnifyingglass" : "plus.magnifyingglass"))
                }
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    prax.isShowingInspector.toggle()
                } label: {
                    Label((prax.isShowingInspector ? "Hide Inspector" : "Show Inspector"), systemImage: (prax.isShowingInspector ? "info.square.fill" : "info.square"))
                }
            }
        }
        .onAppear {
            print("ContentView  .onAppear ")
            //    prax.loadSelectedFiles()
        }
        
    }
}
#Preview {
    ContentView()
}


/*  .draggable(PDFPageSectionsPayload(sections: prax.pdfPageSections)){
 // Custom drag preview
 VStack(alignment: .leading) {
 Text("Dragging \(prax.pdfPageSections.count) section(s)")
 .font(.headline)
 Text("Drop to merge or reorder")
 .font(.caption)
 .foregroundStyle(.secondary)
 }
 .padding(8)
 .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
 }
 */
