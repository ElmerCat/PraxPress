//
//  ContentView.swift
//  PraxPress - Prax=0104-1
//
//  Created by Elmer Cat on 12/21/25.
//

import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers

struct ContentView: View {
 //   @Environment(PersistenceController.self) private var persistence

    @Environment(\.modelContext) private var modelContext           // Global context (from app)
//    //  @Environment(MergedPDFDocument.self) var document
    @Environment(PraxModel.self) private var praxModel
    @Environment(\.undoManager) var undoManager
    @State private var importError: String?
    
    var body: some View {
        @Bindable var prax = praxModel
 //      let _ = Self._printChanges()

        GeometryReader { proxy in
            HStack(spacing: 0) {
                if prax.praxPressMode == .data { SourceFilesView() }
                else {
                    NavigationSplitView(columnVisibility: $prax.columnVisibility) {
                        SourceFilesView() }
                    detail: {
                        HStack {
                            DocumentEditingLeadingEdge().frame(minWidth: 20, maxWidth: 30)
                            VStack {
                                ContentHeader()
                                HStack {
                                        HSplitView {
                                            MergedPagesView()
                                                .frame(minWidth: 100, idealWidth: 120, maxWidth: 300).layoutPriority(1)
                                             
                                            EditingDocumentView()
                                            .frame(minWidth: 300, idealWidth: 500, maxWidth: 1200).layoutPriority(2)
                                            .overlay(Rectangle().fill(Color.blue).frame(width: 2),alignment: .leading)
                                            
                                            MergedPDFDocumentView()
                                            .frame(minWidth: 300, idealWidth: 500, maxWidth: 1200).layoutPriority(2)
                                            .overlay(Rectangle().fill(Color.blue).frame(width: 2),alignment: .leading)
                                            
                                          /*InspectorView()
                                            .frame(minWidth: prax.showInspector ? 200 : 0, idealWidth: prax.showInspector ? 500 : 0, maxWidth: prax.showInspector ? 1200 : 0, maxHeight: .infinity)
                                            .overlay(Rectangle().fill(Color.blue).frame(width: 2),alignment: .leading)
                                            .animation(.easeIn(duration: 0.25), value: prax.showInspector)
                                          */
                                        }
                                        .overlay(content: {
                                            if prax.document.mergedPages.isEmpty {
                                                ZStack {
                                                    Image("PraxPress").resizable().aspectRatio(contentMode: .fit).frame(width: prax.dropTargeted ? 500 : 200)
                                                        .rotationEffect(Angle(degrees: prax.dropTargeted ? 800 : 0))
                                                        .padding(.leading, 30)
                                                    Text(prax.dropTargeted ? "Drop Files Here" : "Drag files into PraxPress")
                                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                        .font(Font.custom("BrushScriptMT", size: prax.dropTargeted ? 100 : 30))
                                                        .onDrop(of: [.fileURL, .sourceFileType, .mergedPageType, .pageItemType], delegate: PraxDropDelegate(prax))
                                                }
                                                .animation(.easeIn(duration: 0.25), value: prax.dropTargeted)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .background(PraxGradient().opacity(0.85))
                                                .onDrop(of: [.fileURL, .sourceFileType, .mergedPageType, .pageItemType], delegate: PraxDropDelegate(prax))
                                            } })
                                }
                                ContentFooter()
                            }
                        }
                    }
                }
            }
        }
        .onGeometryChange(for: CGSize.self) {  viewGeometry in return viewGeometry.size }
        action: {oldValue, newValue in prax.windowSize = newValue }

        .alert( prax.presentedError?.title ?? "Error",
                isPresented: Binding( get: { prax.presentedError != nil }, set: { if !$0 { prax.dismissError() } } ),
                presenting: prax.presentedError) { error in Button("OK") {prax.dismissError() } }
        message: { error in VStack(alignment: .leading, spacing: 12) {
            Text(error.userMessage).font(.body)
            if !error.recoverySuggestions.isEmpty { Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Try:").font(.caption).fontWeight(.bold)
                    ForEach(error.recoverySuggestions, id: \.self) { suggestion in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•").font(.caption)
                            Text(suggestion).font(.caption)
                        } } }.padding(.top, 8) } } }


        .fileImporter(
            isPresented: $prax.showFileImporter,
            allowedContentTypes: [.pdf, .folder],
            allowsMultipleSelection: true ) { result in
                
                switch result {
                case .success(let urls):
                    Task { do { try await prax.persistence.importURLs(urls) }
                        catch { print("Failed to importURLs(urls)", urls) } }
          
                case .failure(let error):
                    PraxLogger.shared.logError("File Import Error", error: error, category: .import)
                    let praxError = PraxError.fileImportFailed( fileName: "No Files", underlyingError: error )
                    prax.presentError(praxError)
                    importError = error.localizedDescription }
          
            }
        
        .fileDialogDefaultDirectory(prax.document.sourceFolderURL)
        .fileDialogMessage("Add Files to the PraxPress Library")
        .fileDialogConfirmationLabel(Text("Add to Library"))
        .fileDialogCustomizationID("AddToLibraryFileDialog")


        .fileExporter(isPresented: $prax.showFileExporter, item: MergedPDFTransfer(data: prax.document.mergedPDFDocument.dataRepresentation() ?? Data(), filename: prax.document.exportFilename), contentTypes: [.pdf]) { result in
            switch result {
            case .success(let url):
                print ("Writing mergedPDFView to: ", url)
                prax.document.mergedPDFDocument.write(to: url)
            case .failure(let error):
                print (error.localizedDescription)
                prax.saveError = error.localizedDescription } }
        .fileDialogDefaultDirectory(prax.document.exportFolderURL)
        .fileDialogMessage("Save the PraxPress Merged PDF")
        .fileExporterFilenameLabel("Save Merged PDF as:")
        .fileDialogConfirmationLabel(Text("Save Merged PDF"))
               
        .onAppear {
            print("ContentView .onAppear")
            prax.undoManager = undoManager!

        }
      //  .background(PraxGradient())
 
        .navigationTitle("PraxPress PDF Processor")
    }
}

