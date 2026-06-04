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
//import Combine

private let DEBUG_LOGS = true

struct SourceFilesListRow: View {
    @Environment(PersistenceController.self) private var persistence
    
        
   
    
    let document: MergedPDFDocument
    let sourceFile: SourceFile
    func backgroundColor() -> Color {
        switch sourceFile.status {
        case .bad: .red
        case .stale: .orange
        case .okay: .blue
        }
    }

    var body: some View {
        GroupBox {
            HStack {
                Text(sourceFile.fileName).lineLimit(1).font(.system(size: 12))
                Spacer()
                Text("\(sourceFile.pageCount)")
            }
        }
        .background(backgroundColor())
        .padding(0)
        .draggable {
            return SourceFileTransfer(sourceFile: sourceFile)
        }
        

    }
}


struct SourceFilesView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    //   @State private var prax = PraxModel.shared
    @Environment(PersistenceController.self) private var persistence
    @Environment(PraxModel.self) private var praxModel
    @Query(sort: \SourceFileGroup.name) private var sourceFileGroups: [SourceFileGroup]
    @Query(sort: \SourceFile.fileName) private var sourceFiles: [SourceFile]
    
    @State private var importError: String?
    

    func praxTest() {
        print("\nJulie d'Prax")
        
        for sourceFile in sourceFiles {
            print(sourceFile.fileName, "  status: ", sourceFile.status)
        }
        
        print("\nJuliette M. Belanger")
        for sourceFileGroup in sourceFileGroups {
            print(sourceFileGroup.name)
        }
        
        // MARK: - Test Error Alert (Add this section)
        
        // Test 1: PDF Import Error
        PraxLogger.shared.logWarning("Testing PDF import error alert", category: .general)
        let testError1 = NSError(domain: "TestDomain", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "File not found or corrupted"
        ])
        let praxError1 = PraxError.fileImportFailed(
            fileName: "test-document.pdf",
            underlyingError: testError1
        )
        document.prax.presentError(praxError1)
        
        // Uncomment below to test other error types:
        
        /*
        // Test 2: Image Processing Error
        let praxError2 = PraxError.imageProcessingFailed(
            fileName: "test-image.png",
            reason: "Image format not supported or file corrupted"
        )
        document.prax.presentError(praxError2)
        
        // Test 3: File Access Error
        let praxError3 = PraxError.fileAccessDenied(
            filePath: "/Volumes/NetworkDrive/restricted-folder/file.pdf"
        )
        document.prax.presentError(praxError3)
        
        // Test 4: Bookmark Error
        let testError4 = NSError(domain: "BookmarkDomain", code: -2, userInfo: [
            NSLocalizedDescriptionKey: "Bookmark data is invalid or stale"
        ])
        let praxError4 = PraxError.bookmarkResolutionFailed(underlyingError: testError4)
        document.prax.presentError(praxError4)
        
        // Test 5: Generic Error
        let praxError5 = PraxError.generic(
            title: "Operation Failed",
            message: "Something unexpected happened. Please try again."
        )
        document.prax.presentError(praxError5)
        */
    }
    
    
    var body: some View {
        
        @Bindable var prax = praxModel
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                if !sourceFiles.isEmpty {
                    GroupBox {
                        HStack {
                            Button("PraxTest", action: praxTest)
                            Button {
                                prax.showingImporter = true
                            } label: {
                                Label("Add Files", systemImage: "folder.badge.plus")
                            }


                            if !prax.selectedFiles.isEmpty {
                                Button {
                                    deleteSelectedFilesFromDatabase()
                                } label: {
                                    Label("Remove Files", systemImage: "folder.badge.minus")
                                }
                                .disabled(prax.selectedFiles.isEmpty)
                            }
                    }
                    .background(.accent)
                        
                    }
                    VSplitView {
                        
                        GroupBox {
                            SourceFilesList()
                                .background(Color.prax)
                            
                            Text("\(prax.selectedFiles.count)  of \(sourceFiles.count) Files Selected")
                                .font(.subheadline)
                        }
                        .frame(minHeight: 200)
                        .background(.mergedPDFViewBackground)
                    }
                    
                    
                } else {
                    Button("PraxTest", action: praxTest)

                    Button (action: {
                        prax.showingImporter = true
                    }, label: {
                        HStack{
                            Image(systemName: "plus.rectangle.on.folder")
                            Text("Click to Select Files")
                        }
                        .fontWeight(.bold)
                        .fontWidth(.expanded)
                    })
                    .background(.prax)
                    .buttonStyle(.borderedProminent)
                    .buttonSizing(.flexible)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .init(horizontal: .center, vertical: .top))
                }
                
            }
        //    .background(Color.sourceFilesViewBackground.opacity(0.5))
            
        }
        
 
        .toolbar(removing: .sidebarToggle)
    
        .toolbar {
            
            ToolbarItemGroup(placement: .secondaryAction) {
                
                if (prax.columnVisibility == .all) { //} && !prax.selectedFiles.isEmpty) {
                    Button {
                       // prax.listOfFiles.removeAll()
                      //  prax.selectedFiles.removeAll()
                    } label: {
                        Label("Remove Files", systemImage: "folder.badge.minus")
                    }
                    .disabled(prax.selectedFiles.isEmpty)
                    
                    Button {
                        if prax.columnVisibility == .detailOnly {
                            NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
                        }
                        prax.showingImporter = true
                    } label: {
                        Label("Select Files", systemImage: "folder.badge.plus")
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            prax.columnVisibility = prax.columnVisibility == .detailOnly ? .all : .detailOnly
                        }
                    } label: {
                        Label("Hide Library", systemImage: "building.columns")
                    }
                    
               /*
                    Button {
                        withAnimation {
                            prax.columnVisibility = prax.columnVisibility == .detailOnly ? .all : .detailOnly
                                        }
                     //   NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
                        
                    } label: {
                        Label("Sidebar", systemImage: "sidebar.left")
                    }
                  */
                }
            }
            
            /*
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    withAnimation {
                        prax.columnVisibility = prax.columnVisibility == .detailOnly ? .all : .detailOnly
                                    }
                 //   NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
                    
                } label: {
                    Label("Sidebar", systemImage: "sidebar.left")
                }
            }
           */
        }
     //   .toolbarBackground(.blue).opacity(0.2)
      //  .toolbarColorScheme(.light)
        
 
        
        .fileImporter(
            isPresented: $prax.showingImporter,
            allowedContentTypes: [.pdf, .folder],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                Task {
                    do {
                        try await persistence.importURLs(urls)
                    }
                    catch {
                        print("Failed to importURLs(urls)", urls)
                    }
                }

            case .failure(let error):
                importError = error.localizedDescription
            }
           
        }
        .fileDialogDefaultDirectory(document.sourceFolderURL)
        .fileDialogMessage("Add Files to the PraxPress Library")
        .fileDialogConfirmationLabel(Text("Add to Library"))
        .fileDialogCustomizationID("AddToLibraryFileDialog")
        .task {
            DispatchQueue.main.async {
                print ("Fortunareed")
            }
        }
        
        .onAppear() {
            print ("Sharon Eldon")
            
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
        let filesToDelete = praxModel.selectedFiles
        Task {
            do {
                try await persistence.deleteSourceFiles(filesToDelete)
            } catch {
                // Handle or present the error appropriately
                print("Failed to delete files: \(error)")
            }
        }
        praxModel.selectedFiles.removeAll()
    }
 
 
    
}


struct SourceFilesList: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument

    @Environment(PraxModel.self) private var praxModel
    @Query(sort: \SourceFileGroup.name) private var sourceFileGroups: [SourceFileGroup]
    @Query(sort: \SourceFile.fileName) private var sourceFiles: [SourceFile]
    
    
    private func displayValue(for key: String, in entry: SourceFile) -> String {
        guard let fields = entry.dataFields else {return "No Data Fields"}
        guard let field = fields[key] else { return "No Field: " + key }

    //    print (field)
        
        if let s = field.stringValue { return s }
        if let i = field.intValue { return String(i) }
        if let d = field.doubleValue { return String(d) }
        if let b = field.boolValue { return String(b) }
        if let date = field.dateValue {
            return ISO8601DateFormatter().string(from: date)
        }
        return "No Data: " + key
    }

    var body: some View {
        @Bindable var document = document
        @Bindable var prax = praxModel
        
        GroupBox {
            if prax.praxPressMode != .data {
                ZStack {
                    Color.contentViewBackground.ignoresSafeArea()
                    List(sourceFiles, selection: $prax.selectedFiles) { sourceFile in
                        let notFound = sourceFile.bookmarkData.count == 0
                        SourceFilesListRow(document: document, sourceFile: sourceFile)
                            .listRowBackground(notFound ? Color.red : Color.clear)
                            .selectionDisabled(notFound)
                    }
                    .scrollContentBackground(.hidden)
                }
                .onChange(of: prax.selectedFiles) {
                    if document.mergedPages.isEmpty, !prax.selectedFiles.isEmpty {
                        for selectedFile in prax.selectedFiles {
                            let sourceFile = sourceFiles.first(where: { $0.id == selectedFile })!
        
                            document.addPagesFromPDFURL(sourceFile.url, bookmark: sourceFile.bookmarkData)
                        }
                    }

                    
                }
            } else {
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
                            // Data rows
                            ForEach(sourceFiles, id: \.id) { entry in
                                // File name
                                Text(entry.fileName)
                                    .lineLimit(1)
                                    .truncationMode(.tail)

                                // Pages
                                Text(String(entry.pageCount))
                                    .frame(maxWidth: .infinity, alignment: .trailing)

                                // Dynamic fields — ensure unique IDs per cell
                                ForEach(fieldNames, id: \.self) { fieldName in
                                    Text(displayValue(for: fieldName, in: entry))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .id("\(entry.id.uuidString)|\(fieldName)")
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


