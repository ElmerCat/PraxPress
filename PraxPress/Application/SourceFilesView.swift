//
//  SourceFilesView.swift
//  PraxPress - Prax=0104-1
//
//  Created by Elmer Cat on 12/21/25.
//
import SwiftUI
import SwiftData

import PDFKit
import UniformTypeIdentifiers

private let DEBUG_LOGS = true

struct SourceFilesView: View {
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    //@Environment(\.modelContext) private var modelContext
    @Environment(PraxModel.self) private var prax
    
    /*   @Query(sort: \SourceFileGroup.name) private var sourceFileGroups: [SourceFileGroup]
     /   @Query() private var sourceFiles: [SourceFile]
     //   @State var selectedFiles = Set<SourceFile.ID>(){
     didSet {
     print("selectedFiles didSet: \(selectedFiles)")
     if let id = prax.selectedSourceFiles.first {
     if let sourceFile = sourceFiles.first(where: { $0.id == id }) {
     if sourceFile != prax.selectedSourceFile {
     prax.selectedSourceFile = sourceFile }
     }
     }
     }
     */
    
    
    var body: some View {
        @Bindable var prax = prax
        
        VStack {
            Text("Library").padding(.top, 5)
            Divider()
            GroupBox {
            //    if !prax.sourceFiles.isEmpty {
                    
                    VSplitView {
                        GroupBox {
                            SourceFilesList("Main File Group")
                            Text("\(prax.selectedSourceFiles.count) Files Selected") // of \(prax.sourceFiles.count) Files Selected")
                                .font(.subheadline)
                        }.frame(minHeight: 200)
                        
                        GroupBox {
                            SourceFilesList("Locked File Group")
                            Text("\(prax.selectedSourceFiles.count) Files Selected") //of \(prax.sourceFiles.count) Files Selected")
                                .font(.subheadline)
                        }.frame(minHeight: 200)
                    }
                //}
                
//                else {
//                    
//                    Button (action: { prax.showFileImporter = true  }, label: {
//                        HStack{ Image(systemName: "plus.rectangle.on.folder")
//                            Text("Click to Select Files") }.fontWeight(.bold).fontWidth(.expanded) })
//                    .buttonStyle(.borderedProminent)
//                    .buttonSizing(.flexible)
//                    //  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .init(horizontal: .center, vertical: .top))
//                }
                
            }

        }
        
        
        .onDrop(of: [.fileURL], delegate: PraxDropDelegate(prax))

        .navigationTitle("Source Files")
        .toolbar(removing: .sidebarToggle)
        .toolbarBackground(PraxGradient(4))
        .toolbar(content: {
            if prax.columnVisibility != .detailOnly {
            ToolbarItemGroup(placement: .automatic) {
                    Button { prax.showFileImporter = true} label: { Label("Add Files", systemImage: "folder.badge.plus") }
                    .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 638, width: nil, height: nil))
                        .onHover { hovering in prax.hoveredButton = hovering ? 638: nil }
                        .padding(.leading, 10)
                    
                    Button(role: .destructive) { prax.deleteSelectedFilesFromDatabase() } label: { Label("Remove Files", systemImage: "folder.badge.minus") }
                        .buttonStyle(PraxButtonStyle( isHovering: prax.hoveredButton == 637))
                        .onHover { hovering in prax.hoveredButton = hovering ? 637: nil }
                    
                        .disabled(prax.selectedSourceFiles.isEmpty)
                Divider()
                    
                Button {prax.showFileViewer.toggle()}  label: { Image(systemName: "eye")}.disabled(prax.selectedSourceFile == nil)
                    .buttonStyle(PraxButtonStyle( isHovering: prax.hoveredButton == 636, isOn: prax.showFileViewer))
                    .onHover { hovering in prax.hoveredButton = hovering ? 636: nil }
                    .padding(.horizontal, 10)
                    .disabled(prax.selectedSourceFiles.isEmpty)
                }
            }
        })
        
        .onKeyPress(phases: .down) { keyPress in  switch keyPress.key {
        
        case .space: prax.showFileViewer.toggle()
            return .handled
            default: print(keyPress.key); return .ignored } }
        //        .sheet(isPresented: $prax.showPreview, onDismiss: {print("Preview dismissed")}) { PreviewView() }
        //     .popover(isPresented: $prax.showPreview, arrowEdge: .leading, content: { PreviewView() })
        //     .interactiveDismissDisabled(true)
        //        .presentationSizing(.fitted)
        //        .presentationDetents([.medium, .large])
        //     .presentationBackgroundInteraction(.enabled)
        //     .presentationDragIndicator(.visible)
        
        .task { DispatchQueue.main.async {
            prax.loadModelItems()
            print ("Fortunareed - prax.sourceFilesView .task") } }
        
        .onAppear() {  print ("Sharon Eldon - prax.sourceFilesView .onAppear")
        //    prax.persistence?.loadModelItems()
        }
        
        //    .onChange(of: prax.sourceFiles) { prax.praxprax.sourceFiles = prax.sourceFiles }
        //    .onChange(of: sourceFileGroups) { prax.sourceFileGroups = sourceFileGroups }
        
        .onDisappear() { print ("Marsha Nolan - prax.sourceFilesView .onDisappear") }
    }
}







struct SourceFilesList: View {
    @Environment(PraxModel.self) private var prax
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SourceFileGroup.name) private var sourceFileGroups: [SourceFileGroup]
    @Query(sort: \SourceFile.addedDate) private var sourceFiles: [SourceFile]

    let fileGroupName: String
    init(_ fileGroupName: String) { self.fileGroupName = fileGroupName }
    
    var body: some View {
        if sourceFileGroups.filter({$0.name == fileGroupName}).first != nil {
            let sourceFiles = sourceFiles.filter({$0.fileGroup.name == fileGroupName})
            
            @Bindable var prax = prax
            let fixedCategoryOrder: [SourceFileType] = [ .pdf, .image, .text, .other ]
            GroupBox {
                if prax.praxPressMode != .data {
                    ZStack {
                        Color.contentViewBackground.ignoresSafeArea()
                        List(selection: $prax.selectedSourceFiles) {
                            let categories = Dictionary(grouping: sourceFiles, by: { $0.fileType})
                            ForEach(fixedCategoryOrder, id: \.self) { category in
                                if !(categories[category]?.isEmpty ?? true) {
                                    Section(header: Text(category.rawValue)) {
                                        ForEach(categories[category] ?? []) { sourceFile in
                                            SourceFilesListRow(sourceFile)
                                                .focusable(true)
                                        }
                                    }
                                }
                            }
                            .scrollContentBackground(.hidden)
                        }
                    }
                }
                
                
                else {
                    ZStack {
                        Color.pink.ignoresSafeArea()
                        
                        let fieldNames = SourceFile.defaultFieldNames
                        
                        // Define grid columns: fixed first two columns + one for each dynamic field
                        let columns: [GridItem] = [
                            GridItem(.flexible(minimum: 120), alignment: .leading), // File
                            GridItem(.fixed(60), alignment: .trailing)              // Pages
                        ] + fieldNames.map { _ in GridItem(.flexible(minimum: 80), alignment: .leading) }
                        
                        ScrollView {
                            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                                // Header row
                                Group {
                                    Text("File").font(.headline)
                                    Text("Pages").font(.headline)
                                    ForEach(fieldNames, id: \.self) { name in
                                        Text(name).font(.headline)
                                            .id("header|\(name)")
                                    }
                                }
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.15))
                                //.gridCellColumns(columns.count) // optional: comment this if you want headers in the same row cells
                                // If you prefer headers in the same row cells, remove .gridCellColumns and place them as individual cells:
                                // Just remove the .gridCellColumns line.
                                
                                // Data rows
                                ForEach(sourceFiles, id: \.id) { sourceFile in
                                    // File name
                                    Text(sourceFile.fileName)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    
                                    // Pages
                                    Text(String(sourceFile.pageCount))
                                    // .frame(maxWidth: .infinity, alignment: .trailing)
                                    
                                    // Dynamic fields — ensure unique IDs per cell
                                    ForEach(fieldNames, id: \.self) { fieldName in
                                        Text(sourceFile.displayValue(for: fieldName))
                                        //  .frame(maxWidth: .infinity, alignment: .leading)
                                            .id("\(sourceFile.id.hashValue)|\(fieldName)")
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                }
                            }
                            .padding(8)
                        }
                    }
                    
                }
            }
            
        }
        
    }
}







struct SourceFileContextMenu: View {
    @Environment(PraxModel.self) private var prax
    @Environment(\.openWindow) private var openWindow
    let sourceFile: SourceFile
    var body: some View {
        @Bindable var prax = prax
        let sourceFileString = ("\(sourceFile.url.deletingLastPathComponent().formatted(Prax.filenameStyle).split(separator: ".").first ?? "")").suffix(40)
        
        let labelString = (sourceFile.pageCount < 2 ? "One Page" : "\(sourceFile.pageCount) Pages") // + "  -  \(sourceFile.fileSize / 1000) KB"
        
        GroupBox {
            
            Divider()
            
            Section("Source File") {
                Button(action: {
                    if prax.selectedSourceFileID != sourceFile.id { prax.selectedSourceFileID = sourceFile.id }
                    prax.showFileViewer = true
                    }) {
                        Label(sourceFile.fileName, image: .pdfMenuIcon)
                        Text(labelString)
                    }
                    .labelStyle(.titleAndIcon).disabled(sourceFile.status == .bad)
                
                Spacer()
                
                Button(action: {
                    prax.selectedSourceFileID = sourceFile.id
                    prax.showFileViewer = true}){
                        Label("Show Preview", //prax.showPreview && sourceFile == prax.selectedSourceFile ? "Close Preview" : "Show Preview",
                              systemImage: "eye")}
                    .labelStyle(.titleAndIcon)
                    .disabled(sourceFile.status == .bad)
            }
            
            
            
            Section("PraxPress Editor") {
                
                Button(action: { prax.document.addPagesFromSourceFile(sourceFile) }) {
                    Label("Open as Merged Page", systemImage: "inset.filled.trailinghalf.arrow.trailing.rectangle")
                    Text("")
                }
                .labelStyle(.titleAndIcon)
                .disabled(sourceFile.status == .bad)
                
                Spacer()
            }
            
            
            
            Section("File") {
                
                Button(action: { /* prax.deleteSouurceFileFromDatabase(sourceFile) */ }) {
                    Label("Delete from PraxPress Library", systemImage: "trash")}
                .labelStyle(.titleAndIcon)
                .disabled(sourceFile.isLibraryFile)
                
                Divider()
                /*
                 Button(action: { withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {  sourceFile.isLibraryFile.toggle() }}) {
                 Label(sourceFile.isLibraryFile ? "Unlock File" : "Lock File", systemImage: sourceFile.isLibraryFile ? "lock" : "lock.open")}
                 .labelStyle(.titleAndIcon)
                 .disabled(sourceFile.status == .bad)
                 */
                
                
                Button(action: {  NSWorkspace.shared.selectFile(sourceFile.url.path, inFileViewerRootedAtPath: "") }) {
                    Label("Show in Finder", systemImage: "finder")
                    Text(sourceFileString)
                }
                .labelStyle(.titleAndIcon)
                .disabled(sourceFile.status == .bad)
                
            }
            
            //           Spacer()
            //           Text("          PraxPress").font(Font.custom("BrushScriptMT", size: 20)).foregroundStyle(Color.blue).italic(true).bold(true)
            
            
        }
        
        
        
    }
    
}


