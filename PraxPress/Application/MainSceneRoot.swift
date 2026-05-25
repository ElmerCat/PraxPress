//
//  MainSceneRoot.swift
//  PraxPress - Prax=0104-1
//
//  Created by Elmer Cat on 12/21/25.
//

import SwiftUI
import PDFKit
import SwiftData
import Foundation

struct MainSceneRoot: View {

    @Environment(FilesPersistenceController.self) private var persistence

    // We’ll build praxModel and document after we have a window-scoped context.
    @State private var prax: PraxModel? = nil
    @State private var document: MergedPDFDocument? = nil

//    @State private var windowStore: WindowEditingStore? = nil
//    @State private var windowContext: ModelContext? = nil

    var body: some View {
        Group {
            if let prax = prax, let document = document { //, let winContext = windowContext {
                ContentView()
                    .environment(prax)
                    .environment(document)
//                    .environment(\.perWindowModelContext, winContext)
            } else {
                ProgressView("Preparing window…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        
        .onModifierKeysChanged(mask: .option) { old, new in
            guard let prax = prax else { return }
            if new.isEmpty {
                prax.optionKeyPressed = false
                print("Option key released")
            }
            else if new.contains(.option) {
                prax.optionKeyPressed = true
                print("Option key pressed")
            }
        }
        .task {

            // Construct PraxModel first (only once)
            if prax == nil {
                prax = PraxModel()
            }
            guard let prax = prax else { return }
            
            
            // Construct the document with non-optional dependencies (only once)
            if document == nil {
                let document = MergedPDFDocument(
            //        windowModelContext: windowContext,
                    prax: prax,
                    persistence: persistence
                )
                // Attach the document back to PraxModel to complete the cycle
                prax.attach(document: document)
                // Publish into @State so it propagates into the environment
                self.document = document
            }
        }
    }
}

struct MainCommands: Commands {
    @Environment(\.openWindow) private var openWindow
            
        
    
    var body: some Commands {
        
/*        CommandGroup(replacing: .undoRedo) {
            Button("Undo") { appDelegate.undoManager.undo() }
                .keyboardShortcut("z")
                .disabled(!appDelegate.undoManager.canUndo)
            Button("Redo") { appDelegate.undoManager.redo() }
                .keyboardShortcut("Z", modifiers: [.command, .shift])
                .disabled(!appDelegate.undoManager.canRedo)
        }
*/
        CommandGroup(after: .textEditing) {
            Button("Select All Prax") {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
            .keyboardShortcut("a", modifiers: [.command, .option])
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

// MARK: - Per-window ModelContext environment key

/*private struct PerWindowModelContextKey: EnvironmentKey {
    static let defaultValue: ModelContext? = nil
}

extension EnvironmentValues {
    var perWindowModelContext: ModelContext? {
        get { self[PerWindowModelContextKey.self] }
        set { self[PerWindowModelContextKey.self] = newValue }
    }
}*/
