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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PraxModel.self) private var prax
    
    @Query(sort: \SourceFileGroup.name) private var sourceFileGroups: [SourceFileGroup]
    @Query() private var sourceFiles: [SourceFile]
    
    func praxTest() {
        print("Prax Test -- Julie d'Prax")
        for sourceFileGroup in sourceFileGroups {
            print("------ ", sourceFileGroup.name)
            for sourceFile in sourceFileGroup.sourceFiles { print(sourceFile.fileName, "  status: ", sourceFile.status) }
        }
        
        print("\nJuliette M. Belanger")
        for sourceFileGroup in sourceFileGroups { print(sourceFileGroup.name) }
        PraxLogger.shared.logWarning("Testing PDF import error alert", category: .general)
        let error = NSError(domain: "TestDomain", code: -1, userInfo: [ NSLocalizedDescriptionKey: "File not found or corrupted" ])
        let praxError = PraxError.fileImportFailed( fileName: "test-document.pdf", underlyingError: error )
        prax.presentError(praxError)
        
    }
    
    
    var body: some View {
        @Bindable var prax = prax
        
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                if !sourceFiles.isEmpty {
                    HStack { Button("PraxTest", action: praxTest)
                        Button { prax.showFileImporter = true} label: { Label("Add Files", systemImage: "folder.badge.plus") }
                        Button { deleteSelectedFilesFromDatabase() } label: { Label("Remove Files", systemImage: "folder.badge.minus") } .disabled(prax.selectedFiles.isEmpty) }
                    
                    VSplitView {
                        GroupBox {
                            SourceFilesTable("Exported File Group")
                            Text("\(prax.selectedFiles.count)  of \(sourceFiles.count) Files Selected")
                                .font(.subheadline)
                        }.frame(minHeight: 200)
                        
                        GroupBox {
                            SourceFilesList("Locked File Group")
                            Text("\(prax.selectedFiles.count)  of \(sourceFiles.count) Files Selected")
                                .font(.subheadline)
                        }.frame(minHeight: 200)
                    } }
                
                else {
                    Button("PraxTest", action: praxTest)
                    
                    Button (action: { prax.showFileImporter = true  }, label: {
                        HStack{ Image(systemName: "plus.rectangle.on.folder")
                            Text("Click to Select Files") }.fontWeight(.bold).fontWidth(.expanded) })
                    .buttonStyle(.borderedProminent)
                    .buttonSizing(.flexible)
                  //  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .init(horizontal: .center, vertical: .top))
                }
                
            }
            .toolbar(removing: .sidebarToggle)
            .toolbarBackground(PraxGradient(4))
            .onDrop(of: [.fileURL], delegate: PraxDropDelegate(prax))
        }
        
        .onKeyPress(phases: .down) { keyPress in  switch keyPress.key {
        case .space: prax.showPreview.toggle(); return .handled
            default: print(keyPress.key); return .ignored } }
        //        .sheet(isPresented: $prax.showPreview, onDismiss: {print("Preview dismissed")}) { PreviewView() }
        .popover(isPresented: $prax.showPreview, arrowEdge: .leading, content: { PreviewView() })
        .interactiveDismissDisabled(true)
        //        .presentationSizing(.fitted)
        //        .presentationDetents([.medium, .large])
        .presentationBackgroundInteraction(.enabled)
        .presentationDragIndicator(.visible)
        
        .task { DispatchQueue.main.async { print ("Fortunareed - SourceFilesView .task") } }
        
        .onAppear() {  print ("Sharon Eldon - SourceFilesView .onAppear")
            prax.sourceFiles = sourceFiles
        }
        
        .onChange(of: sourceFiles) {
            prax.sourceFiles = sourceFiles
        }
        
        .onDisappear() { print ("Marsha Nolan - SourceFilesView .onDisappear") }
    }
    
    func deleteSelectedFilesFromDatabase() {
        print("deleteSelectedFilesFromDatabase()")
        let filesToDelete = prax.selectedFiles
        Task {
            do {
                try await prax.persistence?.deleteSourceFiles(filesToDelete)
            } catch {
                // Handle or present the error appropriately
                print("Failed to delete files: \(error)")
            }
        }
        prax.selectedFiles.removeAll()
    }
}




struct SourceFilesList: View {
    @Environment(PraxModel.self) private var praxModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SourceFileGroup.name) private var sourceFileGroups: [SourceFileGroup]
    
    let fileGroupName: String
    init(_ fileGroupName: String) { self.fileGroupName = fileGroupName }
    
    var body: some View {
        let sourceFileGroup = sourceFileGroups.filter({$0.name == fileGroupName}).first
        if let sourceFiles = sourceFileGroup?.sourceFiles {
            
            @Bindable var prax = praxModel
            let fixedCategoryOrder: [SourceFileType] = [ .pdf, .image, .text, .other ]
            GroupBox {
                if prax.praxPressMode != .data {
                    ZStack {
                        Color.contentViewBackground.ignoresSafeArea()
                        List(selection: $prax.selectedFiles) {
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
    let sourceFile: SourceFile
    var body: some View {
        
        let sourceFileString = ("\(sourceFile.url.deletingLastPathComponent().formatted(Prax.filenameStyle).split(separator: ".").first ?? "")").suffix(40)
        
        let labelString = (sourceFile.pageCount < 2 ? "One Page" : "\(sourceFile.pageCount) Pages") // + "  -  \(sourceFile.fileSize / 1000) KB"
        
        GroupBox {
            
            Divider()
            
            Section("Source File") {
                Button(action: {
                    if prax.selectedSourceFile != sourceFile { prax.selectedSourceFile = sourceFile;  prax.showPreview = true }
                    else { prax.showPreview.toggle() } }) {
                        Label(sourceFile.fileName, image: .pdfMenuIcon)
                        Text(labelString)
                    }
                    .labelStyle(.titleAndIcon).disabled(sourceFile.status == .bad)
                
                Spacer()
                
                Button(action: {
                    if prax.selectedSourceFile == sourceFile { prax.showPreview.toggle() }
                    else { prax.selectedSourceFile = sourceFile; prax.showPreview = true }}){
                        Label(prax.showPreview && sourceFile == prax.selectedSourceFile ? "Close Preview" : "Show Preview", systemImage: "eye")}
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
                
                Button(action: {prax.deleteSouurceFileFromDatabase(sourceFile)}) {
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







/*
 struct eSourceFilesList: View {
 let sourceFileStatus = SourceFileStatus.okay
 @Environment(\.modelContext) private var modelContext
 //  @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
 
 @Environment(PraxModel.self) private var praxModel
 @Query(sort: \SourceFileGroup.name) private var sourceFileGroups: [SourceFileGroup]
 @Query(filter: #Predicate<SourceFile> { $0.status == sourceFileStatus }, sort: \SourceFile.fileName) private var sourceFiles: [SourceFile]
 
 
 }*/
