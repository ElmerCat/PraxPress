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

struct PDFFileTransfer: Transferable, Identifiable, @unchecked Sendable {
    let id = UUID()
    let pdfFile: PDFFile

    struct Payload: Codable {
        let fileName: String
        let bookmarkData: Data
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .pdfFileType) { item in
            // Encode a small payload containing the file's name and bookmark data
            let payload = Payload(fileName: item.pdfFile.fileName, bookmarkData: item.pdfFile.bookmarkData)
            return try JSONEncoder().encode(payload)
        } importing: { data in
            // Decode the payload and reconstruct a minimal PDFFile via its bookmark
            let payload = try JSONDecoder().decode(Payload.self, from: data)
            // Resolve the URL from the bookmark to rebuild a PDFFile
            var isStale = false
            let url = try URL(resolvingBookmarkData: payload.bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            // Create a placeholder PDFFile; callers can insert into model context as needed
            let fileGroup = PDFFileGroup(name: "Imported")
            let pdfFile = PDFFile(fileGroup: fileGroup, url: url, bookmarkData: payload.bookmarkData, pageCount: 0)
            return PDFFileTransfer(pdfFile: pdfFile)
        }
    }
}


struct PDFFilesListRow: View {
    @Environment(FilesPersistenceController.self) private var persistence

    let document: MergedPDFDocument
    let pdfFile: PDFFile
    var body: some View {
     GroupBox {
         HStack {
             Text(pdfFile.fileName).lineLimit(1).font(.system(size: 12))
             Spacer()
     //        Text(String(pdfFile.pageCount)).lineLimit(1)
             if pdfFile.bookmarkData.count > 0 {
                 
                 Button {
                     let isOkay = testBookmark(for: pdfFile)
                     print ("Merge - testBookmark for: ", pdfFile.fileName, "  isOkay: ", isOkay)
                     if isOkay {
                         document.addPagesFromURLBookmark(url: pdfFile.url, bookmarkData: pdfFile.bookmarkData, to: nil)
                     }
                 } label: {
                     HStack {
                         Spacer(minLength: 0)
                         Text("\(pdfFile.pageCount)")
                         Image(systemName: "arrow.trianglehead.merge").rotationEffect(Angle(degrees: 90))
                         Text("Merge").font(.system(size: 8))
                     }
                    
                 }
                 .frame(minWidth: 84, maxWidth: 84, maxHeight: .infinity)
                 
          /*       Button("\(pdfFile.pageCount) Pages", systemImage: "arrowshape.zigzag.forward", action: {
                     let isOkay = testBookmark(for: pdfFile)
                     print ("Merge - testBookmark for: ", pdfFile.fileName, "  isOkay: ", isOkay)
                     if isOkay {
                         document.addPagesFromURLBookmark(url: pdfFile.url, bookmarkData: pdfFile.bookmarkData, to: nil)
                     }
                 }).controlSize(ControlSize.mini) */
             }
             else {
                 Label("Not Found", systemImage: "nosign")
                 Button("Remove", systemImage: "trash", action: {
                     print ("Merge \(pdfFile.fileName)")
                     
                     Task {
                         do {
                             try await persistence.deletePDFFiles([pdfFile.id])
                         } catch {
                             // Handle or present the error appropriately
                             print("Failed to delete files: \(error)")
                         }
                     }
                    
                 })

                 
             }
         }
         
        }
     .padding(0)
     
     .draggable {
         return PDFFileTransfer(pdfFile: pdfFile)
     }
     
    }
}


struct SourceFilesView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    //   @State private var prax = PraxModel.shared
    @Environment(FilesPersistenceController.self) private var persistence
    @Environment(PraxModel.self) private var praxModel
    @Query(sort: \PDFFileGroup.name) private var pdfFileGroups: [PDFFileGroup]
    @Query(sort: \PDFFile.fileName) private var pdfFiles: [PDFFile]
    
    @State private var importError: String?
    

    
    func praxTest() {

        print ("\nJulie d'Prax")
        
        for pdfFile in pdfFiles {
            let isOkay = testBookmark(for: pdfFile)
            print (pdfFile.fileName, "  isOkay: ", isOkay)
        }
        print ("\nJuliette M. Belanger")
        for pdfFileGroup in pdfFileGroups {
            print (pdfFileGroup.name)
        }
    }
    
    var body: some View {
        
        @Bindable var prax = praxModel
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                if !pdfFiles.isEmpty {
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
                            PDFFilesList()
                                .background(Color.prax)
                            
                            Text("\(prax.selectedFiles.count)  of \(pdfFiles.count) Files Selected")
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
                        try await persistence.processImportedURLs(urls)
                    }
                    catch {
                        print("Failed to processImportedURLs(urls)", urls)
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
            
            for pdfFile in pdfFiles {
                let isOkay = testBookmark(for: pdfFile)
                print ("testBookmark for: ", pdfFile.fileName, "  isOkay: ", isOkay)
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
                try await persistence.deletePDFFiles(filesToDelete)
            } catch {
                // Handle or present the error appropriately
                print("Failed to delete files: \(error)")
            }
        }
        praxModel.selectedFiles.removeAll()
    }
 
 
    
}


struct PDFFilesList: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument

    @Environment(PraxModel.self) private var praxModel
    @Query(sort: \PDFFileGroup.name) private var pdfFileGroups: [PDFFileGroup]
    @Query(sort: \PDFFile.fileName) private var pdfFiles: [PDFFile]
    
    
    private func displayValue(for key: String, in entry: PDFFile) -> String {
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
                    List(pdfFiles, selection: $prax.selectedFiles) { pdfFile in
                        let notFound = pdfFile.bookmarkData.count == 0
                        PDFFilesListRow(document: document, pdfFile: pdfFile)
                            .listRowBackground(notFound ? Color.red : Color.clear)
                            .selectionDisabled(notFound)
                    }
                    .scrollContentBackground(.hidden)
                }
            } else {
                ZStack {
                    Color.pink.ignoresSafeArea()

                    let fieldNames = PDFFile.defaultFieldNames

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
                            ForEach(pdfFiles, id: \.id) { entry in
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


