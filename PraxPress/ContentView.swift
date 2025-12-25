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
    @Environment(PerPageTrimModel.self) private var _perPageTrimModel
    
    //    @State private var isOn: Bool = false
    //    @State private var isLarge: Bool = false
    //    @State private var isShowingInspector: Bool = false
    //    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    
    var body: some View {
        
        let _ = Self._printChanges()
        
        @Bindable var viewModel = _viewModel
        @Bindable var perPageTrimModel = _perPageTrimModel
        NavigationSplitView(columnVisibility: $viewModel.columnVisibility) {
            SourceFilesView()
                .environment(viewModel)
                .navigationSplitViewColumnWidth(min: 50, ideal: 300, max: 400)
        }
        
        
        detail:  {
            HSplitView {
                
                GroupBox {
                    PageTrimView(viewModel: viewModel, model: perPageTrimModel)
                }.background(.cyan).padding(20)
                
                
                GroupBox {
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
        
        
        .toolbar {
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
                
                Button {
                    viewModel.isLarge.toggle()
                } label: {
                    Label((viewModel.isLarge ? "Make Small" : "Make Large"), systemImage: (viewModel.isLarge ? "minus.magnifyingglass" : "plus.magnifyingglass"))
                }
                Button {
                    viewModel.isShowingInspector.toggle()
                } label: {
                    Label((viewModel.isShowingInspector ? "Hide Inspector" : "Show Inspector"), systemImage: (viewModel.isShowingInspector ? "info.square.fill" : "info.square"))
                }
                Button {
                    viewModel.columnVisibility = .detailOnly
                } label: {
                    if viewModel.columnVisibility == .all {
                        Label("All", systemImage: "rectangle.split.3x1")
                    }
                    else if viewModel.columnVisibility == .doubleColumn {
                        Label("Double Column", systemImage: "rectangle.split.2x1")
                    }
                    else {
                        Label("Detail Only", systemImage: "rectangle")
                        
                    }
                }
                Button {
                    viewModel.columnVisibility = .doubleColumn
                } label: {
                    if viewModel.columnVisibility == .all {
                        Label("All", systemImage: "rectangle.split.3x1")
                    }
                    else if viewModel.columnVisibility == .doubleColumn {
                        Label("Double Column", systemImage: "rectangle.split.2x1")
                    }
                    else {
                        Label("Detail Only", systemImage: "rectangle")
                        
                    }
                }
                Button {
                    viewModel.isOn.toggle()
                    
                } label: {
                    if viewModel.isOn {
                        Label("All", systemImage: "rectangle.split.3x1")
                    }
                    else {
                        Label("Detail Only", systemImage: "rectangle")
                        
                    }
                }
                Button {
                    //                    listOfFiles.removeAll()
                    //                  selection = nil
                } label: {
                    Label("Clear List", systemImage: "trash")
                }
                //            .disabled(listOfFiles.isEmpty)
            }
        }
        .navigationSplitViewColumnWidth(min: 150, ideal: 200, max: 400)
        
    }
    
}

#Preview {
    SourceFilesView()
}
