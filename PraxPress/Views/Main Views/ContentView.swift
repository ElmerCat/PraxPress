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
    
    @Environment(\.modelContext) private var modelContext           // Global context (from app)
 //   @Environment(\.perWindowModelContext) private var perWindowContext // The one-and-only editor context
    @Environment(MergedPDFDocument.self) var document
    @Environment(PraxModel.self) private var praxModel
    @Environment(\.undoManager) var undoManager
    
    var body: some View {
        @Bindable var prax = praxModel

  //      let _ = Self._printChanges()

        GeometryReader { proxy in
            HStack(spacing: 0) {
                
                if prax.praxPressMode == .data {
                    SourceFilesView()
                }
                else {
                    NavigationSplitView(columnVisibility: $prax.columnVisibility) {
                        SourceFilesView()
                            .navigationSplitViewColumnWidth(min: 300, ideal: 300, max: .infinity)
                    }
                    detail: {
                        HStack(spacing: 0) {
                            DocumentEditingLeadingEdge().frame(minWidth: 20, maxWidth: 30)
                            ContentDetailView().frame(minWidth: 500, maxWidth: .infinity)
                   
                        }
                        
                        .navigationSplitViewColumnWidth(min: 500, ideal: 1500, max: .infinity)
                    }
                }
            }
  //          .background(PraxGradient(2))
//            .background(Color.indigo.opacity(0.5))
            
        }
       // .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .init(horizontal: .center, vertical: .top))
        .onGeometryChange(for: CGSize.self) {  windowGeometry in
      //      print("onGeometryChange - windowGeometry.size.width: ", windowGeometry.size.width)
            return windowGeometry.size
        }
        action: {oldValue, newValue in
   //         print ("windowGeometry.size.width:  old: ", oldValue.width, "  new: ", newValue.width )
   //         print ("windowGeometry.size.height:  old: ", oldValue.height, "  new: ", newValue.height )
            prax.windowSize = newValue

        }
        
        .alert(
            prax.presentedError?.title ?? "Error",
            isPresented: Binding(
                get: { prax.presentedError != nil },
                set: { if !$0 { prax.dismissError() } }
            ),
            presenting: prax.presentedError
        ) { error in
            Button("OK") {
                prax.dismissError()
            }
        } message: { error in
            VStack(alignment: .leading, spacing: 12) {
                // Main error message
                Text(error.userMessage)
                    .font(.body)
                
                // Recovery suggestions (if any)
                if !error.recoverySuggestions.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Try:")
                            .font(.caption)
                            .fontWeight(.bold)
                        
                        ForEach(error.recoverySuggestions, id: \.self) { suggestion in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                    .font(.caption)
                                Text(suggestion)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        
 
        .fileExporter(isPresented: $prax.showSavePanel, item: MergedPDFTransfer(data: document.mergedPDFDocument.dataRepresentation()!, filename: document.exportFilename), contentTypes: [.pdf]) { result in
            switch result {
            case .success(let url):
                print ("Writing mergedPDFView to: ", url)
                document.mergedPDFDocument.write(to: url)
            case .failure(let error):
                print (error.localizedDescription)
                prax.saveError = error.localizedDescription
            }
        }
        .fileDialogDefaultDirectory(document.exportFolderURL)
        .fileDialogMessage("Save the PraxPress Merged PDF")
        .fileExporterFilenameLabel("Save Merged PDF as:")
        .fileDialogConfirmationLabel(Text("Save Merged PDF"))
               
        
        .inspector(isPresented: $prax.showingPDFPageItemInspector) {
                PDFPageItemInspector()
        }
        
        
        .inspectorPanel(prax, isPresented: $prax.showDataFields) { DataFieldsEditor() }
        
        .inspectorPanel(prax, isPresented: $prax.showingImportEditor, contentRect: CGRect(x: 0, y: 0, width: 650, height: 1000)) { ImageImportEditor() }
        
        
        .inspectorPanel(prax, isPresented: $prax.showingPDFPageItemInspector) {
            VStack {
                Text("Julie D'Prax")
                VisualEffectView(material: .sidebar, blendingMode: .behindWindow, state: .followsWindowActiveState, emphasized: true)
                }
            //                 Example()
        }
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .toolbar(removing: .sidebarToggle)
   //     .offset(x: 0, y: -20)
        
       .toolbar { MainToolbar()  }
        
  //     .toolbarBackground(PraxGradient())
       .ignoresSafeArea(.container, edges: .top)
        .onAppear {
            print("ContentView .onAppear")
            prax.undoManager = undoManager!

        }
        .background(PraxGradient())
        
        
    }
}

struct ContentDetailView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    var body: some View {
        @Bindable var prax = praxModel
        
        VStack(spacing: 0) {
//            DocumentEditingToolbar()
            
            if document.mergedPages.count >= 0 {
                if prax.praxPressMode == .prax {
                    Text("Julie d'Prax")
                        .inspector(isPresented: $prax.showingPDFPageItemInspector) {
                            PDFPageItemInspector()
                        }
                }
                else {
                    HSplitView {
                     
                        GroupBox {
                            VStack {
                                PageItemToolbar()
                                PageItemCollectionView()
                                
                            }
                        }
                        .frame(minWidth: 100, idealWidth: 150, maxWidth: 300)
                        
                        GroupBox {
                            VStack {
                          //      let toolbarHeight = prax.selectedPageItem != nil ? 100 : 20.0
                                EditingDocumentToolbar()
                         //           .frame(maxWidth: .infinity, minHeight: toolbarHeight, maxHeight: toolbarHeight, alignment: .center)
                         //           .animation(.snappy(duration: 0.25), value: toolbarHeight)
                       //            .zIndex(258)
                                EditingPDFDocumentView()
                                
                            }
                        }
                        .frame(minWidth: 300, idealWidth: 350, maxWidth: 1200)
                        
                        GroupBox {
                            VStack {
                               // EditingDocumentToolbar()
                                DocumentEditingToolbar()
                                MergedPDFDocumentView()
                                
                            }
                        }
                        .frame(minWidth: 300, idealWidth: 350, maxWidth: 1200)
                        
                    }
                    .onDrop(of: [.fileURL, .sourceFileType, .mergedPageType, .pdfPageDragType], delegate: PraxDropDelegate(prax.document, prax))
                    .overlay(content: {
                       
                        if document.mergedPages.isEmpty {
                            GroupBox {
                                Text(prax.dropTargeted ? "Drop Files Here" : "Drag files into PraxPress")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .font(Font.custom("BrushScriptMT", size: prax.dropTargeted ? 100 : 30))
                                    .onDrop(of: [.fileURL, .sourceFileType, .mergedPageType, .pdfPageDragType], delegate: PraxDropDelegate(document, prax))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(PraxGradient())
                            
                        }
                    })
                }
                
            }
            else {
                Text(prax.dropTargeted ? "Drop Files Here" : "Drag files into PraxPress")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .font(Font.custom("BrushScriptMT", size: prax.dropTargeted ? 100 : 30))
                    .onDrop(of: [.fileURL, .sourceFileType, .mergedPageType, .pdfPageDragType], delegate: PraxDropDelegate(document, prax))
            }
            
            DocumentEditingFooter()
        }
        
        
        
/*        .inspectorPanel(isPresented: $prax.showingPDFPageItemInspector) {
            VStack {
                Text("Julie D'Prax")
                VisualEffectView(material: .sidebar, blendingMode: .behindWindow, state: .followsWindowActiveState, emphasized: true)
                }
            //                 Example()
        }
*/
//        .inspectorPanel(isPresented: $prax.showDataFields) { DataFieldsEditor().environment(prax) }

        .padding(0)
    }
}


#Preview {
    ContentView()
}
