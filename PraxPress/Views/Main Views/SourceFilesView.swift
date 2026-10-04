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
  //  @Environment(PersistenceController.self) private var persistence
    @Environment(PraxModel.self) private var prax
    @Query(sort: \SourceFileGroup.name) private var sourceFileGroups: [SourceFileGroup]
    @Query(sort: \SourceFile.fileName) private var sourceFiles: [SourceFile]
    
  
    func praxTest() {
        
        print("Prax Test -- Julie d'Prax")
        
        for sourceFile in sourceFiles { print(sourceFile.fileName, "  status: ", sourceFile.status) }
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
                    GroupBox {
                        HStack {
                            Button("PraxTest", action: praxTest)
                            Button { prax.showFileImporter = true} label: { Label("Add Files", systemImage: "folder.badge.plus") }
                            Button { deleteSelectedFilesFromDatabase() } label: { Label("Remove Files", systemImage: "folder.badge.minus") } .disabled(prax.selectedFiles.isEmpty)
                        }
                     //   .background(.accent)
                    }
                    VSplitView {
                        
                        GroupBox {
                            SourceFilesList(showLibraryFiles: false)
                       //         .background(Color.prax)
                            
                            Text("\(prax.selectedFiles.count)  of \(sourceFiles.count) Files Selected")
                                .font(.subheadline)
                        }
                        .frame(minHeight: 200)
                  //      .background(.mergedPDFViewBackground)
                        
                        GroupBox {
                            SourceFilesList(showLibraryFiles: true)
                //                .background(Color.prax)
                            
                            Text("\(prax.selectedFiles.count)  of \(sourceFiles.count) Files Selected")
                                .font(.subheadline)
                        }
                        .frame(minHeight: 200)
                  //      .background(.mergedPDFViewBackground)
                        
                    }
                    
                    
                } else {
                    Button("PraxTest", action: praxTest)
                    
                    Button (action: {
                        prax.showFileImporter = true
                    }, label: {
                        HStack{
                            Image(systemName: "plus.rectangle.on.folder")
                            Text("Click to Select Files")
                        }
                        .fontWeight(.bold)
                        .fontWidth(.expanded)
                    })
                //    .background(.prax)
                    .buttonStyle(.borderedProminent)
                    .buttonSizing(.flexible)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .init(horizontal: .center, vertical: .top))
                }
                
            }
            .toolbar(removing: .sidebarToggle)
            .toolbarBackground(PraxGradient(4))
            //    .background(Color.sourceFilesViewBackground.opacity(0.5))
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
        
        .task {
            DispatchQueue.main.async {
                print ("Fortunareed")
                
            }
        }
        
        .onAppear() {
            print ("Sharon Eldon")
            
            prax.sourceFiles = sourceFiles
            
                
            
                
            
            print("View modelContext:", ObjectIdentifier(modelContext))
            
            for sourceFile in sourceFiles {
                sourceFile.testBookmark()
                //                let isOkay = testBookmark(for: sourceFile)
                //                print ("testBookmark for: ", sourceFile.fileName, "  isOkay: ", isOkay)
            }
            
        }
        
        .onDisappear() {
            print ("Marsha Nolan")
        }
        
        
        
    }
    
    func deleteSelectedFilesFromDatabase() {
        print("deleteSelectedFilesFromDatabase()")
        let filesToDelete = prax.selectedFiles
        Task {
            do {
                try await prax.persistence.deleteSourceFiles(filesToDelete)
            } catch {
                // Handle or present the error appropriately
                print("Failed to delete files: \(error)")
            }
        }
        prax.selectedFiles.removeAll()
    }
    
    
    struct SourceFilesList: View {
        var showLibraryFiles: Bool = false
        init(showLibraryFiles: Bool) { self.showLibraryFiles = showLibraryFiles }
        
        @Environment(\.modelContext) private var modelContext
        //  @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
        
        @Environment(PraxModel.self) private var praxModel
        @Query(sort: \SourceFileGroup.name) private var sourceFileGroups: [SourceFileGroup]
        @Query(sort: \SourceFile.fileName) private var sourceFiles: [SourceFile]
        //@Query(filter: #Predicate<SourceFile> { $0.status == $0.status }, sort: \SourceFile.fileName) private var sourceFiles: [SourceFile]
        
        //    init(library: SourceFileStatus) {
        //       self.sourceFileStatus = sourceFileStatus
        //      _sourceFiles = Query(filter: #Predicate<SourceFile> { $0.status == sourceFileStatus }, sort: \SourceFile.fileName)
        //   }
        
        
        var body: some View {
         //   @Bindable var document = document
            @Bindable var prax = praxModel
            let fixedCategoryOrder: [SourceFileType] = [ .pdf, .image, .text, .other ]
            let files = sourceFiles.filter { $0.isLibraryFile == showLibraryFiles }
            GroupBox {
                if prax.praxPressMode != .data {
                    ZStack {
                        Color.contentViewBackground.ignoresSafeArea()
                        List(selection: $prax.selectedFiles) {
                            let categories = Dictionary(grouping: files, by: { $0.fileType})
                            ForEach(fixedCategoryOrder, id: \.self) { category in
                                if !(categories[category]?.isEmpty ?? true) {
                                    Section(header: Text(category.rawValue)) {
                                        ForEach(categories[category] ?? []) { sourceFile in
                                            SourceFilesListRow(document: prax.document, sourceFile: sourceFile)
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
                                ForEach(files, id: \.id) { sourceFile in
                                    // File name
                                    Text(sourceFile.fileName)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    
                                    // Pages
                                    Text(String(sourceFile.pageCount))
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                    
                                    // Dynamic fields — ensure unique IDs per cell
                                    ForEach(fieldNames, id: \.self) { fieldName in
                                        Text(sourceFile.displayValue(for: fieldName))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .id("\(sourceFile.id.uuidString)|\(fieldName)")
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
    
    

    
    
    struct SourceFilesListRow: View {
        //   @Environment(PersistenceController.self) private var persistence
        @Environment(PraxModel.self) private var prax
        @Environment(\.dismiss) private var dismiss
        
        let document: MergedPDFDocument
        let sourceFile: SourceFile
        func backgroundColor() -> Color {
            if sourceFile.isLibraryFile { return .orange }
            switch sourceFile.status {
            case .bad: return .red
            case .trashed: return .orange
            case .okay: switch sourceFile.fileType {
            case .pdf: return .blue
            case .image: return .brown
            case .text: return .green
                case .other: return .gray } }
        }
        
        
        
        
        var body: some View {
            @Bindable var prax = prax
            GroupBox {
                HStack {
                    Image(.pdfMenuIcon)
                        .foregroundColor(.gray)
                    // 1. Add the badge view inside an overlay
                        .overlay(alignment: .topTrailing) {
                            if sourceFile.pageCount < 2 {
                                EmptyView()
                            }
                            else {
                                Text(String(sourceFile.pageCount))
                                    .font(.system(size: 10, weight: .heavy)).bold() //.font(.caption2)
                                    .foregroundColor(.black)
                                    .padding(4)
                                    .background(Color.red, in: Circle())
                                // 2. Adjust offset so it sits nicely on the edge
                                    .offset(x: 5, y: -5)

                            }
                        }
                    Text(sourceFile.fileName)
                        .font(.system(size: 12, weight: .black)).layoutPriority(2)
                    Spacer()
                    
                    
                    PraxButton(action: { prax.document.addPagesFromSourceFile(sourceFile) }, symbol: "inset.filled.trailinghalf.arrow.trailing.rectangle", help: "Trim and Merge File Pages")
                      //  .frame(maxWidth: 30, alignment: .center)
                       // .padding(.horizontal, 20)
                    
                   // if sourceFile.pageCount > 1 { Text("\(sourceFile.pageCount) Pages  ") }
                    
                    
                 //   Text("\(sourceFile.fileSize/1000) KB")
                }
            }
            .lineLimit(1).font(.system(size: 12))
            .background(backgroundColor())
            .padding(0)
            .draggable {
                return SourceFileTransfer(sourceFile: sourceFile)
            }
            
            .focusable()
            
            .onTapGesture(count: 1) {sourceFile.testBookmark(); prax.selectedSourceFile = sourceFile}
            .onTapGesture(count: 2) {prax.showPreview.toggle()}
            .contextMenu {ContextMenu(sourceFile: sourceFile)}
            
      
            
        }
    }
    
    
    
    struct ContextMenu: View {
        @Environment(PraxModel.self) private var prax
        let sourceFile: SourceFile
        var body: some View {
            GroupBox {
               
                
                Button(sourceFile.fileName, image: .pdfMenuIcon, action: {}).labelStyle(.titleAndIcon)
                   

                Divider()
                
                Button(action: {
                    if prax.selectedSourceFile == sourceFile { prax.showPreview.toggle() }
                    else { prax.selectedSourceFile = sourceFile
                        prax.showPreview = true
                    }}){
                        Label(prax.showPreview && sourceFile == prax.selectedSourceFile ? "Hide Preview" : "Show Preview", systemImage: prax.showPreview && sourceFile == prax.selectedSourceFile ? "eye.fill" : "eye")
                    }.labelStyle(.titleAndIcon)
                    .disabled(prax.sourceFiles.isEmpty)
               
                    Divider()
                
                Text(sourceFile.fileName)
                    .font(.system(size: 12, weight: .black)).layoutPriority(2)
                Divider()
                
                Button(action: { sourceFile.isLibraryFile.toggle() }) {
                    Label(sourceFile.isLibraryFile ? "Make Source File" : "Make Library File", systemImage: sourceFile.isLibraryFile ? "building.classical.columns.fill" : "building.classical.columns")
                }.labelStyle(.titleAndIcon)
                    
                
                Button {
                    // Add this item to a list of favorites.
                } label: {
                    PreviewView()
                    Label("Add to Favorites", systemImage: "heart")
                }
                Button {
                    // Open Maps and center it on this item.
                } label: {
                    Label("Show in Maps", systemImage: "mappin")
                }
            }
            .background(PraxGradient())
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
