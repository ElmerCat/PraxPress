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
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(PraxModel.self) private var prax
    @Environment(\.undoManager) var undoManager
    

    
    var body: some View {
        @Bindable var prax = prax
        //      let _ = Self._printChanges()
        
        GeometryReader { proxy in
            HStack(spacing: 0) {
                if prax.praxPressMode == .data { SourceFilesView() }
                else {
                    NavigationSplitView(columnVisibility: $prax.columnVisibility) {
                        SourceFilesView()
                            
                        
                    }
                    detail: {
                        HStack {
                            DocumentEditingLeadingEdge().frame(minWidth: 20, maxWidth: 30)
                            VStack {
                           //     ContentHeader()
                                ContentBody()
                                
                                
                                
                                
                                
                                ContentFooter()
                            }
                        }
                    }
                }
            }
        }
        
        
        .onGeometryChange(for: CGRect.self) {  viewGeometry in return viewGeometry.frame(in: .named("MainWindow")) }
        action: {oldValue, newValue in prax.windowFrame = newValue }
        
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
        
        
        .inspector(isPresented: $prax.showInspector, content: {
            InspectorView()
                .inspectorColumnWidth(min: 250, ideal: 300, max: 1000)
        })
        
        .fileImporter(
            isPresented: $prax.showFileImporter,
            allowedContentTypes: [.pdf, .folder],
            allowsMultipleSelection: true ) { result in
                
                switch result {
                case .success(let urls):
                    Task { do { try await prax.importURLs(urls) }
                        catch { print("Failed to importURLs(urls)", urls) } }
                    
                case .failure(let error):
                    PraxLogger.shared.logError("File Import Error", error: error, category: .import)
                    let praxError = PraxError.fileImportFailed( fileName: "No Files", underlyingError: error )
                    prax.presentError(praxError)
                    prax.errorString = error.localizedDescription }
                
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
                    prax.errorString = error.localizedDescription } }
            .fileDialogDefaultDirectory(prax.document.exportFolderURL)
            .fileDialogMessage("Save the PraxPress Merged PDF")
            .fileExporterFilenameLabel("Save Merged PDF as:")
            .fileDialogConfirmationLabel(Text("Save Merged PDF"))
        
            .task {
                
                print ("Moo Bells - ContentView .task")
                prax.initializeFileGroups()
                DispatchQueue.main.async {
                     dismissWindow(id: "preview")
                     dismissWindow(id: "trims-editor")
                }
            }
            .onChange(of: prax.showTrimsEditor, { if prax.showTrimsEditor {
                openWindow(id: "trims-editor") } else {
                    dismissWindow(id: "trims-editor") } })
        
            .onChange(of: prax.showFileViewer, { if prax.showFileViewer {
                openWindow(id: "preview") } else {
                    dismissWindow(id: "preview") } })
        
        
            .onAppear {
                print("ContentView .onAppear")
                prax.undoManager = undoManager!
   
            }
        
            .onDisappear {
                print("ContentView .onDisappear")
            }
        
        
            .toolbar(content: {
                MainToolbar()
            })
        
        //  .background(PraxGradient())
        
            .navigationTitle("PraxPress PDF Processor")
    }
    
    struct ContentBody: View {
        @Environment(PraxModel.self) private var prax
        var body: some View {
            @Bindable var prax = prax
            
            HSplitView {
                @Bindable var prax = prax
                MergedPagesView()
                    .frame(minWidth: 80, idealWidth: 140, maxWidth: 300).layoutPriority(3)
                //                                                .frame(minWidth: prax.showExportedFiles ? 80 : 100, idealWidth: prax.showExportedFiles ? 200 : 300, maxWidth: prax.showExportedFiles ? 500 : 600).layoutPriority(1)
                
                EditingDocumentView()
                    .frame(minWidth: 200, idealWidth: 500, maxWidth: 1200).layoutPriority(4)
                //                                              .frame(minWidth: prax.showExportedFiles ? 200 : 300, idealWidth: prax.showExportedFiles ? 400 : 500, maxWidth: prax.showExportedFiles ? 1000 : 1200).layoutPriority(1)
                    .overlay(Rectangle().fill(Color.blue).frame(width: 2),alignment: .leading)
                    
                
                MergedPDFDocumentView()
                    .frame(minWidth: 200, idealWidth: 500, maxWidth: 1200).layoutPriority(4)
                    .overlay(Rectangle().fill(Color.blue).frame(width: 2),alignment: .leading)
            }
            .overlay(content: {
                if prax.document.mergedPages.isEmpty { //} && true == false {
                    ZStack {
                        Image("PraxPress").resizable().aspectRatio(contentMode: .fit).frame(width: prax.dropTargeted ? 500 : 200)
                            .rotationEffect(Angle(degrees: prax.dropTargeted ? 800 : 0))
                            .padding(.leading, 30)
                        Text(prax.dropTargeted ? "Drop Files Here" : "Drag files into PraxPress")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .font(Font.custom("BrushScriptMT", size: prax.dropTargeted ? 100 : 30))
                            .onDrop(of: [.sourceFileType, .mergedPageType, .pageItemType], delegate: PraxDropDelegate(prax))
                    }
                    .animation(.easeIn(duration: 0.25), value: prax.dropTargeted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(PraxGradient().opacity(0.85))
//                    .onDrop(of: [.fileURL, .sourceFileType, .mergedPageType, .pageItemType], delegate: PraxDropDelegate(prax))
                } })
        }
    }
}
