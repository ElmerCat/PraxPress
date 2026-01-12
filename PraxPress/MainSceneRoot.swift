//
//  MainSceneRoot.swift
//  PraxPress - Prax=0104-1
//
//  Created by Elmer Cat on 12/21/25.
//

import SwiftUI
internal import Combine
import PDFKit


struct MainSceneRoot: View {

    @State private var prax = PraxModel.shared
    
    var body: some View {
        ContentView()
            .environment(prax)
            .overlay(TempCleanupLifecycleHook(onCleanup: { prax.cleanupTemporaryArtifacts() }))
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

