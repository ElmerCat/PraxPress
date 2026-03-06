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
//import Combine

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(MergedPDFDocument.self) var document
    @Environment(PraxModel.self) private var praxModel
    @Environment(\.perWindowModelContainer) private var perWindowContainer
    @State private var effectivePerWindowContainer: ModelContainer? = nil
   
    var body: some View {
        @Bindable var prax = praxModel

        
        let _ = Self._printChanges()
        
        // Determine effective per-window container once the view appears
        let _ = {
            // no-op placeholder to keep structure; actual assignment in onAppear below
        }()
        
        GeometryReader { proxy in
            HStack(spacing: 0) {
                
                if prax.praxPressMode == .data {
                    SourceFilesView()
                }
                else {
                    NavigationSplitView(columnVisibility: $prax.columnVisibility) {
                        SourceFilesView()
                            .navigationSplitViewColumnWidth(min: proxy.size.width * 0.15, ideal: 300, max: proxy.size.width * 0.75)
                    }
                    content: {
                        
                        if let container = effectivePerWindowContainer {
                            ContentDetailView()
                                .modelContainer(container)
                                .navigationSplitViewColumnWidth(min: proxy.size.width * 0.25, ideal: 300, max: proxy.size.width * 0.75)
                        } else {
                            ContentDetailView()
                                .navigationSplitViewColumnWidth(min: proxy.size.width * 0.25, ideal: 300, max: proxy.size.width * 0.75)
                        }
                        
                    }
                    detail: {
                        
                        let detailStack = VStack {
                            MergedDocumentToolbar()
                            MergedDocumentView()
                            MergedDocumentFooter()
                        }
                        .navigationSplitViewColumnWidth(min: proxy.size.width * 0.25, ideal: 300, max: proxy.size.width * 0.75)
                        
                        if let container = effectivePerWindowContainer {
                            detailStack
                                .modelContainer(container)
                        } else {
                            detailStack
                        }
                       
                    }
                }
            }
            .background(Color.indigo.opacity(0.5))
        }
        .onAppear {
            // Prefer the provided per-window container; fall back to current environment's container if available
            if effectivePerWindowContainer == nil {
                effectivePerWindowContainer = perWindowContainer ?? modelContext.container
                
                #if DEBUG
                if perWindowContainer == nil {
                    print("[ContentView] perWindowContainer was nil; using environment container: \(String(describing: modelContext.container))")
                } else {
                    print("[ContentView] Using provided per-window container: \(String(describing: perWindowContainer))")
                }
                #endif
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .init(horizontal: .center, vertical: .top))
        .onGeometryChange(for: CGFloat.self) {  windowGeometry in
            print("onGeometryChange - windowGeometry.size.width: ", windowGeometry.size.width)
            return windowGeometry.size.width
        }
        action: {oldValue, newValue in
            print ("windowGeometry.size.width:  old: ", oldValue, "  new: ", newValue )
         //   windowWidth = Double(newValue)
        }
        .toolbar { MainToolbar() }
        .onAppear { print("ContentView  .onAppear ") }
    }
}

struct ContentDetailView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    var body: some View {
        @Bindable var prax = praxModel
        
        GroupBox {
            DocumentEditingToolbar()
            if document.pageSections.count > 0 {
                DocumentEditingView()
                    .inspector(isPresented: $prax.showingPDFPageItemInspector) {
                        PDFPageItemInspector()
                    }
                
            }
            else {
                Text("Drag files into PraxPress")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .font(Font.custom("BrushScriptMT", size: 30))
            }
            DocumentEditingFooter()
            //               .inspector(isPresented: $prax.showingMergedDocumentInspector) {
            //                 MergedDocumentInspector()
            //           }
        }
        
        .fileExporter(isPresented: $prax.showSavePanel, item: MergedPDFTransfer(data: document.mergedPDFDocument.dataRepresentation()!, filename: document.exportFilename), contentTypes: [.pdf], onCompletion: {
            result in
            switch result {
            case .success(let url):
                print ("Writing mergedPDFView to: ", url)
                document.mergedPDFDocument.write(to: url)
            case .failure(let error):
                print (error.localizedDescription)
                prax.saveError = error.localizedDescription
            }
        })
        .fileDialogDefaultDirectory(document.exportFolderURL)
        .fileDialogMessage("Save the PraxPress Merged PDF")
        .fileExporterFilenameLabel("Save Merged PDF as:")
        .fileDialogConfirmationLabel(Text("Save Merged PDF"))
        .padding(20)
    }
}


#Preview {
    ContentView()
}

