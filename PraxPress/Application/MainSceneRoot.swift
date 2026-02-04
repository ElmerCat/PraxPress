//
//  MainSceneRoot.swift
//  PraxPress - Prax=0104-1
//
//  Created by Elmer Cat on 12/21/25.
//

import SwiftUI
import SwiftData
import Combine
import PDFKit


struct MainSceneRoot: View {

    @State private var praxModel = PraxModel.shared
    @State private var praxContext = PraxContext()
    @Query() var pdfFiles: [PDFFile]
    var body: some View {
        ContentView()
            .environment(praxModel)
            .environment(praxContext)
            .onModifierKeysChanged(mask: .option) { old, new in
                if new.isEmpty {
                    praxContext.optionKeyPressed = false
                    // Option key released
                    print("Option key released")
                } else {
                    praxContext.optionKeyPressed = true
                    // Option key pressed
                    print("Option key pressed")
                }
            }
            .task {
                praxModel.pdfFiles = pdfFiles
            }
            .onChange(of: pdfFiles) {
                praxModel.pdfFiles = pdfFiles
            }
        
          //  .overlay(TempCleanupLifecycleHook(onCleanup: { praxModel.cleanupTemporaryArtifacts() }))
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

