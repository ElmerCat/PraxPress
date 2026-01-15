//
//  ContentView.swift
//  PraxPress - Prax=0104-1
//
//  Created by Elmer Cat on 12/21/25.
//

import SwiftUI
import PDFKit
internal import Combine

struct ContentView: View {
    @State private var prax = PraxModel.shared
    
    var body: some View {
        
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
                .frame(maxWidth: 1000, maxHeight: .infinity)
                .background(.cyan).padding(20)
                
                GroupBox {
                    MergedDocumentToolbar()
                    MergedDocumentView()
                        
                    
                }.background(.green).padding(20)
                    .frame(maxWidth: 1000, maxHeight: .infinity)
            }
            .sheet(isPresented: $prax.showSavePanel) {
                
                if let id = prax.selectedFiles.first, let entry = prax.listOfFiles.first(where: { $0.id == id }) {
                    
                    SaveAsPanel(suggestedURL: prax.mergedPDFURL) { destination in
                        
                        prax.mergedPDFView?.document?.write(to: destination)
                        
                    //    fatalError("Julie d'Prax: This function is not currently implemented")
                    //
                        prax.mergeDocumentPages()
                        /*  do {
                         try prax.mergeDocumentPages()
                         /*      sourceURL: entry.url,
                          destinationURL: destination,
                          trimTop: CGFloat(prax.mergeTopMargin),
                          trimBottom: CGFloat(prax.mergeBottomMargin),
                          interPageGap: CGFloat(prax.mergeInterPageGap),
                          perPageTrims: prax.trims
                          )
                          */                  // Update preview to show merged result if overwriting selected file
                         } catch {
                         prax.saveError = error.localizedDescription
                         }*/
                    }
                }
            }
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
        
        .toolbar() {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
                } label: {
                    Label("Sidebar", systemImage: "sidebar.left")
                }
                Button {
                    if prax.columnVisibility == .detailOnly {
                        NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
                    }
                    prax.showingImporter = true
                } label: {
                    Label("Select Files", systemImage: "folder.badge.plus")
                }
                Button("Save", systemImage: "square.and.arrow.down") {
                    prax.handleMergePagesOverwrite()
                    //            handleSaveCurrentSelection()
                    
                }
                .disabled(prax.selectedFiles.isEmpty)
                
                Button("Save As …", systemImage: "square.and.arrow.down.on.square") {
                    //  prax.showSavePanel = true
                    prax.showSavePanel = true
                }
                .disabled(prax.selectedFiles.isEmpty)
            }
            
            ToolbarItemGroup(placement: .navigation) {
                Menu {
                    Button {
                        prax.setWidthGuide(fromPage: prax.currentIndex)
                    } label: {
                        Label("Set Width Guide to This Page", systemImage: "ruler")
                    }
                    Button(role: .destructive) {
                        prax.clearWidthGuide()
                    } label: {
                        Label("Clear Width Guide", systemImage: "ruler.fill")
                    }
                } label: {
                    Label("Width Guide", systemImage: "ruler")
                }
            }
            
            ToolbarItemGroup(placement: .secondaryAction) {
                Button {
                    prax.isLarge.toggle()
                } label: {
                    Label((prax.isLarge ? "Julie d'Prax" : "Juliette M. Belanger"), systemImage: (prax.isLarge ? "minus.magnifyingglass" : "plus.magnifyingglass"))
                }
            }
            
            ToolbarItemGroup(placement: .status) {
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
