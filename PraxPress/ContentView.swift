//
//  ContentView.swift
//  PraxPress - Prax=0104-1
//
//  Created by Elmer Cat on 12/21/25.
//

import SwiftUI
internal import Combine

struct ContentView: View {
    @State private var prax = PraxModel.shared

     var body: some View {
        
        let _ = Self._printChanges()
        
        NavigationSplitView(columnVisibility: $prax.columnVisibility) {
            SourceFilesView()
                .navigationSplitViewColumnWidth(min: 50, ideal: 300, max: 400)
        }
        
        detail:  {
            HSplitView {
                
                GroupBox {
                    DocumentEditingToolbar()
                    DocumentEditingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            prax.loadSelectedFiles()
                        }

                }
                .background(.cyan).padding(20)

                GroupBox {
                    MergedDocumentToolbar()
                    MergedDocumentView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                }.background(.green).padding(20)

            }
            .sheet(isPresented: $prax.showSavePanel) {
                
                if let id = prax.selectedFiles.first, let entry = prax.listOfFiles.first(where: { $0.id == id }) {
                    SaveAsPanel(suggestedURL: entry.url.deletingPathExtension().appendingPathExtension("merged.pdf")) { destination in
                        do {
                            try prax.mergeAllPagesVerticallyIntoSinglePage(
                                sourceURL: entry.url,
                                destinationURL: destination,
                                trimTop: CGFloat(prax.mergeTopMargin),
                                trimBottom: CGFloat(prax.mergeBottomMargin),
                                interPageGap: CGFloat(prax.mergeInterPageGap),
                                perPageTrims: prax.trims
                            )
                            // Update preview to show merged result if overwriting selected file
                        } catch {
                            prax.saveError = error.localizedDescription
                        }
                    }
                }
            }
            .inspector(isPresented: $prax.isShowingInspector) {
                VStack {
                    GroupBox {
                        
                        Text("Inspector 1")
                            .frame(minWidth: 100, maxWidth: .infinity, maxHeight: 100)
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
        //       .navigationSplitViewColumnWidth(min: (self.isOn ? 0 : 500), ideal: (self.isOn ? 0 : 500), max: (self.isOn ? 1: 500))
        
        
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
            
         //   ToolbarItemGroup(placement: .primaryAction) {  }
            

//            ToolbarItemGroup(placement: .principal) {  }

            ToolbarItemGroup(placement: .primaryAction) {
                
                Button {
                    prax.isShowingInspector.toggle()
                } label: {
                    Label((prax.isShowingInspector ? "Hide Inspector" : "Show Inspector"), systemImage: (prax.isShowingInspector ? "info.square.fill" : "info.square"))
                }
     
            }

            
        }
        .navigationSplitViewColumnWidth(min: 150, ideal: 200, max: 400)
        
    }

    
}


#Preview {
    SourceFilesView()
}
