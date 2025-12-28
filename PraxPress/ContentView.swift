//
//  ContentView.swift
//  PraxPress
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
                    PDFViewContainer(viewModel: viewModel, pdfModel: pdfModel)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
/*                    if pdfModel.fileURL != nil {
                        PDFViewContainer(previewModel: pdfModel)
                            .background(Color(nsColor: .windowBackgroundColor))
                    } else {
                        ContentUnavailableView("No PDF available", systemImage: "doc")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }*/
                }.background(.green).padding(20)

/*                GroupBox {
                    MeshGradient(
                        width: 3,
                        height: 3,
                        points: [
                            [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                            [0.0, 0.5], [0.9, 0.3], [1.0, 0.5],
                            [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                        ],
                        colors: [
                            .black,.black,.black,
                            .blue, .blue, .blue,
                            .green, .green, .green
                        ]
                    ).overlay(alignment: .center) {
                        
                        VStack {
                            GroupBox {
                                
                                Text("NavigationSplitView 1 - Detail")
                                    .frame(minWidth: 100, maxWidth: 100, maxHeight: 100)
                                    .background(.pink)
                                
                            }
                            .background(.yellow)
                            Button(viewModel.isLarge ? "Make Small" : "Make Large") {
                                // Toggle the state when the button is tapped
                                viewModel.isLarge.toggle()
                            }
                            Text("NavigationSplitView 1 - Content")
                            //           .frame(maxWidth: .infinity, maxHeight: .infinity)
                            //               .background(.purple)
                            
                                .background(.purple)
                            
                        }
                        
                        
                        
                    }
                    
                }.background(.cyan).padding(20)
                
            */

            }
            .sheet(isPresented: $viewModel.showSavePanel) {
       //         pdfModel.saveMergedPagesAs(viewModel: viewModel)
                
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
                        
                        Text("NavigationSplitView 1 - Detail")
                            .frame(minWidth: 100, maxWidth: 100, maxHeight: 100)
                            .background(.pink)
                        
                    }
                    .background(.yellow)
                    Button(viewModel.isLarge ? "Make Small" : "Make Large") {
                        // Toggle the state when the button is tapped
                        viewModel.isLarge.toggle()
                    }
                    Text("NavigationSplitView 1 - Content")
                    //           .frame(maxWidth: .infinity, maxHeight: .infinity)
                    //               .background(.purple)
                    
                        .background(.purple)
                    
                }
                Text("Inspector View 1")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .inspectorColumnWidth(min: 50, ideal: 150, max: 500)
                    .background(.yellow)
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
                
                Button("Save As…", systemImage: "square.and.arrow.down.on.square") {
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
