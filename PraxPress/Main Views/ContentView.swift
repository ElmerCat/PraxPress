//
//  ContentView.swift
//  PraxPress - Prax=0104-1
//
//  Created by Elmer Cat on 12/21/25.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import Combine




struct ContentView: View {
    //    @State private var praxContext = PraxContext()
    
    //    @State private var prax = PraxModel.shared
    @Environment(PraxContext.self) private var praxContext
    @Environment(PraxModel.self) private var prax
    
    
    
    var body: some View {
        @Bindable var prax = prax
        @Bindable var praxContext = praxContext
        
        let _ = Self._printChanges()
        
        
        
        NavigationSplitView(columnVisibility: $prax.columnVisibility
        ) {
            SourceFilesView()
                .navigationSplitViewColumnWidth(min: 50, ideal: 300, max: 1000)
        }
        
        detail:  {
            HSplitView {
                
                GroupBox {
                    DocumentEditingToolbar()
                    DocumentEditingView()
                    
                }
                
                /*
                 
                 nonisolated public func fileExporter<T>(isPresented: Binding<Bool>, item: T?, contentTypes: [UTType] = [], defaultFilename: String? = nil, onCompletion: @escaping (Result<URL, any Error>) -> Void, onCancellation: @escaping () -> Void = { }) -> some View where T : Transferable
                 */
                
                .fileExporter(isPresented: $prax.showSavePanel, item: MergedPDFTransfer(data: prax.mergedPDFDocument.dataRepresentation()!, filename: prax.exportFilename), contentTypes: [.pdf], onCompletion: {
                    result in
                    switch result {
                    case .success(let url):
                        print ("Writing mergedPDFView to: ", url)
                        prax.mergedPDFView?.document?.write(to: url)
                    case .failure(let error):
                        print (error.localizedDescription)
                        prax.saveError = error.localizedDescription
                    }
                })
                .fileDialogDefaultDirectory(prax.exportFolderURL)
                .fileDialogMessage("Save the PraxPress Merged PDF")
                .fileExporterFilenameLabel("Save Merged PDF as:")
                .fileDialogConfirmationLabel(Text("Save Merged PDF"))
                
                
                .frame(maxWidth: 1000, maxHeight: .infinity)
                .padding(20)
                .background(praxContext.optionKeyPressed ? .red : .cyan)
                
                GroupBox {
                    MergedDocumentHeader()
                        .draggable {
                            if let data = prax.mergedPDFDocument.dataRepresentation() {
                                return MergedPDFTransfer(data: data, filename: (prax.exportFilename))
                                
                            } else {
                                return nil
                            }
                        }
                    GroupBox {
                        MergedDocumentView()
                        
                    }
                    .draggable {
                        if let data = prax.mergedPDFDocument.dataRepresentation() {
                            return MergedPDFTransfer(data: data, filename: "Nora Prax")
                        } else {
                            return nil
                        }
                    }
                    
                    MergedDocumentFooter()
                    
                }
                .background(Color(red: 0.0, green: 0.0, blue: 0.8, opacity: 0.3))

                .padding(20)
                    .frame(maxWidth: 1000, maxHeight: .infinity)
            }
            
     /*       .sheet(isPresented: $prax.showSavePanel) {
                SaveAsPanel(suggestedURL: (prax.exportFileURL ?? URL(filePath: "/PraxPress.pdf"))!) { destination in
                    prax.mergedPDFView?.document?.write(to: destination)
                }}
       */
            .inspector(isPresented: $prax.isShowingInspector) {
                VStack {
                    GroupBox {
                        
                        Text("Inspector 1")
                            .frame(minWidth: 100, maxWidth: 1000, maxHeight: 100)
                            .background(.pink)
                    }
                    .padding(20)
                    //  .background(.yellow)
                    Button(prax.isLarge ? "Make Small" : "Make Large") {
                        // Toggle the state when the button is tapped
                        prax.isLarge.toggle()
                    }
                    Text("Inspector 2")
                    //           .frame(maxWidth: .infinity, maxHeight: .infinity)
                    //               .background(.purple)
                        .background(.purple)
                }
                Text("Inspector 3")
                //    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .inspectorColumnWidth(min: 50, ideal: 150, max: 500)
                    .background(.gray)
            }
        }
        
        .navigationSplitViewColumnWidth(min: 150, ideal: 200, max: 400)
        .navigationSplitViewColumnWidth(min: (prax.isOn ? 0 : 500), ideal: (prax.isOn ? 0 : 500), max: (prax.isOn ? 1: 500))
        .navigationTitle(prax.exportFilename)
        
        .toolbar() {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
                } label: {
                    Label("Files", systemImage: "sidebar.left")
                }
                Button {
                    if prax.columnVisibility == .detailOnly {
                        NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
                    }
                    prax.showingImporter = true
                } label: {
                    Label("Select Files", systemImage: "folder.badge.plus")
                }
                
 /*               Button("Save As …", systemImage: "square.and.arrow.down.on.square") {
                    //  prax.showSavePanel = true
                    prax.showSavePanel = true
                }
                .disabled(prax.selectedFiles.isEmpty)
                
                Button {
                    prax.showingExportFolderSelector = true
                } label: {
                    Label("Select Export Folder", systemImage: "arrow.forward.folder")
                }
                
                RenameButton()
                    .renameAction {
                        print ("Jule d'Prax")
                    }
                
                PasteButton(payloadType: String.self) { strings in
                    prax.exportFilenamePrefix = strings[0]
                }
   */
                Spacer()
            }
            
           
            
            ToolbarItemGroup(placement: .primaryAction) {
                Spacer()
                
                /*               Button("Save", systemImage: "square.and.arrow.down") {
                    
                    prax.mergedPDFView?.document?.write(to: prax.firstSelectedFileURL!)
                    //            handleSaveCurrentSelection()
                    
                }
                .disabled(prax.selectedFiles.isEmpty)
                
                
               Button {
                    prax.showingExportFolderSelector = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.forward.folder")
                        Text(prax.exportFolderURL?.lastPathComponent ?? "Choose Export Folder")
                    }}
   */
                

                
                HStack {
                    Spacer(minLength: 5)
                    Text("Drag as...   ")
                    Spacer(minLength: 5)
                    Text(prax.exportFilenamePrefix)
                //    Spacer(minLength: 5)
                    TextField("Filename", text: Binding<String>(
                        get: { prax.exportFilenameBody },
                        set: { newValue in
                            var newName = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            // Ensure we don't accidentally include a dot/extension typed by the user
                            if let dotRange = newName.range(of: ".") {
                                newName = String(newName[..<dotRange.lowerBound])}
                            prax.exportFilenameBody = newName
                        })
                              
                    )
                    .frame(minWidth: 20, idealWidth: 100, alignment: .init(horizontal: .trailing, vertical: .center))
                    //.frame(maxWidth: 100, alignment: .init(horizontal: .trailing, vertical: .center))
                    .textFieldStyle(SquareBorderTextFieldStyle())
                    .disabled(prax.exportFolderURL == nil)
                    .foregroundStyle(.cyan)
                    .backgroundStyle(.yellow)
                    
                   // Spacer(minLength: 5)
                    Text(prax.exportFilenameSuffix)
                    Spacer(minLength: 5)
                    
                    Image(systemName: "arrow.right.doc.on.clipboard")
                    Spacer(minLength: 5)
                    Text(".\(prax.exportFilenameExtension)")
                    Spacer(minLength: 15)
                    
                }
                .draggable {
                    if let data = prax.mergedPDFDocument.dataRepresentation() {
                        return MergedPDFTransfer(data: data, filename: (prax.exportFilename))
                        
                    } else {
                        return nil
                    }
                }
                
                Spacer()

            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                
                
                Button("Save As …", systemImage: "arrow.down.document") {
                    prax.showSavePanel.toggle()
                }
                
                Button {
                    prax.isLarge.toggle()
                } label: {
                    Label((prax.isLarge ? "Status Small" : "Status Large"), systemImage: (prax.isLarge ? "minus.magnifyingglass" : "plus.magnifyingglass"))
                }
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    prax.isShowingInspector.toggle()
                } label: {
                    Label((prax.isShowingInspector ? "Hide Inspector" : "Show Inspector"), systemImage: (prax.isShowingInspector ? "info.square.fill" : "info.square"))
                }
            }
        }
        .onAppear {
            print("ContentView  .onAppear ")
            //    prax.loadSelectedFiles()
        }
        
    }
}
#Preview {
    ContentView()
}


/*  .draggable(PDFPageSectionsPayload(sections: prax.pdfPageSections)){
 // Custom drag preview
 VStack(alignment: .leading) {
 Text("Dragging \(prax.pdfPageSections.count) section(s)")
 .font(.headline)
 Text("Drop to merge or reorder")
 .font(.caption)
 .foregroundStyle(.secondary)
 }
 .padding(8)
 .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
 }
 */

