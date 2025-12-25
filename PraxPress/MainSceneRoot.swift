//
//  MainSceneRoot.swift
//  PraxPress
//
//  Created by Elmer Cat on 12/21/25.
//

import SwiftUI
internal import Combine

@Observable class ViewModel {
    var isOn = false
    var isLarge: Bool = false
    var showingImporter: Bool = false
    var isShowingInspector: Bool = false
    var columnVisibility: NavigationSplitViewVisibility = .all

    var listOfFiles: [PDFEntry] = []
    var selectedFiles = Set<PDFEntry.ID>() 
    var isEnabled = false
    
}

struct MainSceneRoot: View {

    @State private var viewModel = ViewModel()
    @State private var perPageTrimModel = PerPageTrimModel()

    
    
    var body: some View {
        ContentView()
            .environment(viewModel)
            .environment(perPageTrimModel)
    }
}




struct MainCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    
    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Button("Select All") {
                // Use focused values to trigger select all
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
            .keyboardShortcut("a", modifiers: [.command])
        }
        CommandGroup(after: .newItem) {
            Button("New Tab") {
                let keyWindow = NSApp.keyWindow
                WindowCoordinator.shared.requestNewTab(in: keyWindow)
                openWindow(id: "main")
            }
            .keyboardShortcut("t", modifiers: [.command])
        }
        CommandGroup(after: .sidebar) {
            Button("Show/Hide Sidebar") {
                NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("s", modifiers: [.command, .control])
        }
        
    }
}
