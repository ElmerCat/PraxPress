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
       // .toolbar(removing: .sidebarToggle)
        
       .toolbar {
           MainToolbar()
        }
        
  //     .toolbarBackground(PraxGradient())
        
        .onAppear {
            print("ContentView .onAppear")
            prax.undoManager = undoManager!

        }
    }
}

struct ContentDetailView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    var body: some View {
        @Bindable var prax = praxModel
        
        VStack(spacing: 0) {
            DocumentEditingToolbar()
            
            if document.mergedPages.count > 0 {
                if prax.praxPressMode == .prax {
                    Text("Julie d'Prax")
                        .inspector(isPresented: $prax.showingPDFPageItemInspector) {
                            PDFPageItemInspector()
                        }
                }
                else {
                    HSplitView {
                      //  AnyOldView()
                        
                        
                        DocumentEditingView()
                            .frame(minWidth: 100, idealWidth: 150, maxWidth: 200)
                        
                        EditingPDFDocumentView()
                            .frame(minWidth: 250, idealWidth: 400, maxWidth: 1000)
                        
                        MergedPDFDocumentView()
                            .frame(minWidth: 150, idealWidth: 300, maxWidth: 1000)

                        //   AnyOldView()
                        
                    }
                }
            }
            else {
                Text(prax.dropTargeted ? "Drop Files Here" : "Drag files into PraxPress")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .font(Font.custom("BrushScriptMT", size: prax.dropTargeted ? 100 : 30))
                    .onDrop(of: [.fileURL, .pdfFileType, .mergedPageType, .pdfPageDragType], delegate: PraxDropDelegate(document, prax))
            }
            
            DocumentEditingFooter()
        }
        
        .inspector(isPresented: $prax.showingPDFPageItemInspector) {
                PDFPageItemInspector()
        }
        
        .inspectorPanel(isPresented: $prax.showingPDFPageItemInspector) {
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow, state: .followsWindowActiveState, emphasized: true)
            //                 Example()
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
        .padding(0)
    }
}


#Preview {
    ContentView()
}
