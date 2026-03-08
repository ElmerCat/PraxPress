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
    @Environment(\.perWindowModelContext) private var perWindowContext // The one-and-only editor context
    @Environment(MergedPDFDocument.self) var document
    @Environment(PraxModel.self) private var praxModel
   
    var body: some View {
        @Bindable var prax = praxModel

        let _ = Self._printChanges()

        GeometryReader { proxy in
            HStack(spacing: 0) {
                
                if prax.praxPressMode == .data {
                    // Left panel: global data (uses app-level container/context)
                    SourceFilesView()
                }
                else {
                    NavigationSplitView(columnVisibility: $prax.columnVisibility) {
                        // Left panel: global data (uses app-level container/context)
                        SourceFilesView()
                            .navigationSplitViewColumnWidth(min: proxy.size.width * 0.15, ideal: 300, max: proxy.size.width * 0.75)
                    }
                    content: {
                        // Middle panel: editor list (use per-window context)
                        if let perWindowContext {
                            ContentDetailView()
                                .modelContext(perWindowContext)
                                .navigationSplitViewColumnWidth(min: proxy.size.width * 0.25, ideal: 300, max: proxy.size.width * 0.75)
                        } else {
                            ContentDetailView()
                                .navigationSplitViewColumnWidth(min: proxy.size.width * 0.25, ideal: 300, max: proxy.size.width * 0.75)
                        }
                    }
                    detail: {
                        // Right panel: merged document UI (use per-window context)
                        let detailStack = VStack {
                            MergedDocumentToolbar()
                            MergedDocumentView()
                            MergedDocumentFooter()
                        }
                        .navigationSplitViewColumnWidth(min: proxy.size.width * 0.25, ideal: 300, max: proxy.size.width * 0.75)

                        if let perWindowContext {
                            detailStack
                                .modelContext(perWindowContext)
                        } else {
                            detailStack
                        }
                    }
                }
            }
            .background(Color.indigo.opacity(0.5))
        }
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .init(horizontal: .center, vertical: .top))
        .onGeometryChange(for: CGFloat.self) {  windowGeometry in
            print("onGeometryChange - windowGeometry.size.width: ", windowGeometry.size.width)
            return windowGeometry.size.width
        }
        action: {oldValue, newValue in
            print ("windowGeometry.size.width:  old: ", oldValue, "  new: ", newValue )
        }
        .toolbar { MainToolbar() }
        .onAppear {
            print("ContentView .onAppear")
            if let docCtx = document.windowModelContext, let perWindowContext {
                print("[Debug] editor context shared? \(docCtx === perWindowContext)")
            } else {
                print("[Debug] perWindowContext or document.windowModelContext is nil")
            }
        }
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
                
                if prax.praxPressMode == .prax {
                    PraxEditingView()
                        .inspector(isPresented: $prax.showingPDFPageItemInspector) {
                            PDFPageItemInspector()
                        }
                }
                else {
                    DocumentEditingView()
                        .inspector(isPresented: $prax.showingPDFPageItemInspector) {
                            PDFPageItemInspector()
                        }
                }
            }
            else {
                Text("Drag files into PraxPress")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .font(Font.custom("BrushScriptMT", size: 30))
            }
            DocumentEditingFooter()
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
        .padding(20)
    }
}

#Preview {
    ContentView()
}
