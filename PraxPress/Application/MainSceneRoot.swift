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
    @State private var praxModel: PraxModel? = nil
    @State private var document: MergedPDFDocument? = nil

//    @State private var windowStore: WindowEditingStore? = nil
//    @State private var windowContext: ModelContext? = nil

    var body: some View {
        Group {
            if let prax = praxModel, let doc = document { //, let winContext = windowContext {
                ContentView()
                    .environment(prax)
                    .environment(doc)
//                    .environment(\.perWindowModelContext, winContext)
            } else {
                ProgressView("Preparing window…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        
        .onModifierKeysChanged(mask: .option) { old, new in
            guard let prax = praxModel else { return }
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
            
/*            if windowContext == nil {
                if let windowStore = try? WindowEditingStore(inMemory: true) {
                    let container = windowStore.container
                    windowContext = ModelContext(container)
                }
            }
           
            guard let windowContext else { return }
*/
            // Construct PraxModel first (only once)
            if praxModel == nil {
                praxModel = PraxModel()
            }
            guard let prax = praxModel else { return }

            // Construct the document with non-optional dependencies (only once)
            if document == nil {
                let doc = MergedPDFDocument(
            //        windowModelContext: windowContext,
                    prax: prax,
                    persistence: persistence
                )
                // Attach the document back to PraxModel to complete the cycle
                prax.attach(document: doc)
                // Publish into @State so it propagates into the environment
                document = doc
            }
        }
    }
}

struct MainCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    
    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Button("Select All") {
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
