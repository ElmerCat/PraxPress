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

    @State private var praxModel = PraxModel()
    @State private var document = MergedPDFDocument()

    @State private var windowStore: WindowEditingStore? = nil
    @State private var windowContext: ModelContext? = nil

    var body: some View {
        ContentView()
            .environment(document)
            .environment(praxModel)
            // Provide the per-window ModelContext to the view tree via a custom key,
            // so ContentView can choose exactly where to apply .modelContext(...)
            .environment(\.perWindowModelContext, windowContext)
            .onModifierKeysChanged(mask: .option) { old, new in
                if new.isEmpty {
                    praxModel.optionKeyPressed = false
                    print("Option key released")
                }
                else if new.contains(.option) {
                    praxModel.optionKeyPressed = true
                    print("Option key pressed")
                }
            }
            .task {
                if windowStore == nil {
                    // If this is file-backed in your app, use your actual init. In-memory is fine for testing.
                    windowStore = try? WindowEditingStore(inMemory: true)
                }
                if windowContext == nil, let container = windowStore?.container {
                    // Create exactly one ModelContext for the per-window container
                    windowContext = ModelContext(container)
                }
                // Give the document the exact same context instance
                document.windowModelContext = windowContext

                // Wire up cross-refs
                praxModel.documment = document
                document.prax = praxModel
                document.persistence = persistence
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

private struct PerWindowModelContextKey: EnvironmentKey {
    static let defaultValue: ModelContext? = nil
}

extension EnvironmentValues {
    var perWindowModelContext: ModelContext? {
        get { self[PerWindowModelContextKey.self] }
        set { self[PerWindowModelContextKey.self] = newValue }
    }
}
