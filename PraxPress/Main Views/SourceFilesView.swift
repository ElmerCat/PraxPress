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
    let document: MergedPDFDocument
    let pdfFile: PDFFile
    var body: some View {
     GroupBox {
         HStack {
             Text(pdfFile.fileName)
             Spacer()
             Text(String(pdfFile.pageCount))
             Button("Merge", systemImage: "arrowshape.zigzag.forward", action: {
                 print ("Merge \(pdfFile.fileName)")
                 document.addPagesFromURLBookmark(url: pdfFile.url, bookmarkData: pdfFile.bookmarkData, to: nil)
             })
         }
         
        }
     
     .draggable {
         return PDFFileTransfer(pdfFile: pdfFile)
     }
     
    }
}


struct PDFFilesList: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    @Query(sort: \PDFFileGroup.name) private var pdfFileGroups: [PDFFileGroup]
    @Query(sort: \PDFFile.fileName) private var pdfFiles: [PDFFile]
    

    var body: some View {
        @Bindable var document = document
        @Bindable var prax = praxModel
        
        GroupBox {
            if prax.praxPressMode != .data {
                ZStack {
                    Color.contentViewBackground.ignoresSafeArea()
                    List(pdfFiles, selection: $document.selectedFiles) { pdfFile in
                        PDFFilesListRow(document: document, pdfFile: pdfFile)
                            .listRowBackground(Color.clear)
                    }
                    .scrollContentBackground(.hidden)
                }
            } else {
                ZStack {
                    Color.pink.ignoresSafeArea()
                    Table(pdfFiles, selection: $document.selectedFiles) {
                        TableColumn("File") { (entry: PDFFile) in
                            let value = entry.fileName
                            Text(value).background(Color.yellow)
                        }
                        TableColumn("Pages") { (entry: PDFFile) in
                            let value = entry.pageCount
                            Text(String(value))
                        }
                        TableColumn("PcardHolderName") { (entry: PDFFile) in
                            let value = entry.dataFields?.pcardHolderName ?? "—"
                            Text(value)
                        }
                        TableColumn("DocumentNumber") { (entry: PDFFile) in
                            let value = entry.dataFields?.documentNumber ?? "—"
                            Text(value)
                        }
                        TableColumn("Date") { (entry: PDFFile) in
                            let value = entry.dataFields?.date ?? "—"
                            Text(value)
                        }
                        TableColumn("Amount") { (entry: PDFFile) in
                            let value = entry.dataFields?.amount ?? "—"
                            Text(value)
                        }
                        TableColumn("Vendor") { (entry: PDFFile) in
                            let value = entry.dataFields?.vendor ?? "—"
                            Text(value)
                        }
                        TableColumn("GLAccount") { (entry: PDFFile) in
                            let value = entry.dataFields?.glAccount ?? "—"
                            Text(value)
                        }
                        TableColumn("CostObject") { (entry: PDFFile) in
                            let value = entry.dataFields?.costObject ?? "—"
                            Text(value)
                        }
                        TableColumn("Justification") { (entry: PDFFile) in
                            let value = entry.dataFields?.justification ?? "—"
                            Text(value)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
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
            print (pdfFile.fileName)
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
                            
                            if !document.selectedFiles.isEmpty {
                                Button {
                                    document.deleteSelectedFilesFromDatabase()
                                } label: {
                                    Label("Remove Files", systemImage: "folder.badge.minus")
                                }
                                .disabled(document.selectedFiles.isEmpty)
                            }
                    }
                    .background(.accent)
                        
                    }
                    VSplitView {
                        
                        GroupBox {
                            PDFFilesList()
                                .background(Color.prax)
                            
                            Text("\(document.selectedFiles.count)  of \(pdfFiles.count) Files Selected")
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
            .background(Color.sourceFilesViewBackground.opacity(0.5))
        }
        
        
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
        
        .task {
            DispatchQueue.main.async {
                print ("Fortunareed")
            }
        }
        
        .onAppear() {
            print ("Sharon Eldon")
            
            print("View modelContext:", ObjectIdentifier(modelContext))


            
        }
        
        .onDisappear() {
            print ("Marsha Nolan")
        }
        
    }
    
}

#Preview {
   
    SourceFilesView()
}

