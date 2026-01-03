//
//  ContentView.swift
//  PraxPress - Prax=0102-0
//
//  Created by Elmer Cat on 12/21/25.
//

import SwiftUI
internal import Combine

struct ContentView: View {
    
    @Environment(ViewModel.self) private var _viewModel
    @Environment(PDFModel.self) private var _pdfModel
    
    var body: some View {
        
        let _ = Self._printChanges()
        
        @Bindable var viewModel = _viewModel
        @Bindable var pdfModel = _pdfModel
        
        NavigationSplitView(columnVisibility: $viewModel.columnVisibility) {
            SourceFilesView()
                .environment(viewModel)
                .navigationSplitViewColumnWidth(min: 50, ideal: 300, max: 400)
        }
        
        detail:  {
            HSplitView {
                
                GroupBox {
                    PageTrimView(viewModel: viewModel, pdfModel: pdfModel)
                }
                .background(.cyan).padding(20)

                GroupBox {
                    DocumentTrimStatus(pdfModel: pdfModel)
                    PDFViewContainer(viewModel: viewModel, pdfModel: pdfModel)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                }.background(.green).padding(20)

            }
            .sheet(isPresented: $viewModel.showSavePanel) {
                
                if let id = viewModel.selectedFiles.first, let entry = viewModel.listOfFiles.first(where: { $0.id == id }) {
                    SaveAsPanel(suggestedURL: entry.url.deletingPathExtension().appendingPathExtension("merged.pdf")) { destination in
                        do {
                            try pdfModel.mergeAllPagesVerticallyIntoSinglePage(
                                sourceURL: entry.url,
                                destinationURL: destination,
                                trimTop: CGFloat(pdfModel.mergeTopMargin),
                                trimBottom: CGFloat(pdfModel.mergeBottomMargin),
                                interPageGap: CGFloat(pdfModel.mergeInterPageGap),
                                perPageTrims: pdfModel.trims
                            )
                            // Update preview to show merged result if overwriting selected file
                        } catch {
                            viewModel.saveError = error.localizedDescription
                        }
                    }
                }
            }
            .inspector(isPresented: $viewModel.isShowingInspector) {
                VStack {
                    GroupBox {
                        
                        Text("Inspector 1")
                            .frame(minWidth: 100, maxWidth: .infinity, maxHeight: 100)
                            .background(.pink)
                        
                    }
                    .padding(20)
                  //  .background(.yellow)
                    Button(viewModel.isLarge ? "Make Small" : "Make Large") {
                        // Toggle the state when the button is tapped
                        viewModel.isLarge.toggle()
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
                    if viewModel.columnVisibility == .detailOnly {
                        NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
                    }
                    viewModel.showingImporter = true
                } label: {
                    Label("Select Files", systemImage: "folder.badge.plus")
                }
                Button("Save", systemImage: "square.and.arrow.down") {
                    pdfModel.handleMergePagesOverwrite(viewModel: viewModel)
                    //            handleSaveCurrentSelection()
                    
                }
                .disabled(viewModel.selectedFiles.isEmpty)
                
                Button("Save As …", systemImage: "square.and.arrow.down.on.square") {
                  //  pdfModel.showSavePanel = true
                    viewModel.showSavePanel = true
                }
                .disabled(viewModel.selectedFiles.isEmpty)

                

                
            }
            ToolbarItemGroup(placement: .secondaryAction) {
                
                Button {
                    viewModel.isLarge.toggle()
                } label: {
                    Label((viewModel.isLarge ? "Julie d'Prax" : "Juliette M. Belanger"), systemImage: (viewModel.isLarge ? "minus.magnifyingglass" : "plus.magnifyingglass"))
                }
                

            }
            
            
            ToolbarItemGroup(placement: .status) {
                
                Button {
                    viewModel.isLarge.toggle()
                } label: {
                    Label((viewModel.isLarge ? "Status Small" : "Status Large"), systemImage: (viewModel.isLarge ? "minus.magnifyingglass" : "plus.magnifyingglass"))
                }
                
            }
            
         //   ToolbarItemGroup(placement: .primaryAction) {  }
            

//            ToolbarItemGroup(placement: .principal) {  }

            ToolbarItemGroup(placement: .primaryAction) {
                
                Button {
                    viewModel.isShowingInspector.toggle()
                } label: {
                    Label((viewModel.isShowingInspector ? "Hide Inspector" : "Show Inspector"), systemImage: (viewModel.isShowingInspector ? "info.square.fill" : "info.square"))
                }
     
            }

            
        }
        .navigationSplitViewColumnWidth(min: 150, ideal: 200, max: 400)
        
    }

    
}


#Preview {
    SourceFilesView()
}
