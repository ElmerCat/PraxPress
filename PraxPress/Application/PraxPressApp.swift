//
//  PraxPressApp.swift
//  PraxPress - Prax=0104-1
//
//  Created by Elmer Cat on 12/21/25.
//

import SwiftUI
import AppKit
import SwiftData
import TipKit
import Carbon.HIToolbox
import OSLog



@main
struct PraxPressApp: App {
  //  private let persistence: PersistenceController
    
    init() { //self.persistence = PersistenceController(modelContainer: modelContainer)
        do { try Tips.configure([Tips.ConfigurationOption.displayFrequency(.daily)])
            //           try Tips.resetDatastore()
            Tips.showAllTipsForTesting() }
        catch { print("Error configuring Tips: \(error)") }
    }
    
    
    let modelContainer: ModelContainer = {
        let schema = Schema([SourceFile.self, SourceFileGroup.self])
        let config = ModelConfiguration() // customize if needed
        let container = try! ModelContainer(for: schema, configurations: [config])
        container.mainContext.undoManager = UndoManager()
        return container
    }()
    
    
    
    var body: some Scene {
        let prax = PraxModel(modelContainer)
        
        WindowGroup(id: "main") {
            
            ContentView()
                .environment(prax)
                .focusedSceneValue(prax)
                .modelContainer(modelContainer)
            
                .onModifierKeysChanged(mask: .option) { old, new in
                    if new.isEmpty {
                        prax.optionKeyPressed = false
                        print("Option key released") }
                    
                    else if new.contains(.option) {
                        prax.optionKeyPressed = true
                        print("Option key pressed") } }
        }
        .commands { MainCommands() }
        .windowToolbarStyle(.unified(showsTitle: true))  //.expanded)  //
        .windowResizability(.contentSize)
        
        UtilityWindow("Preview", id: "preview") {
            PreviewView()
                .environment(prax)
                .containerBackground(.panelBackground, for: .window)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        }
        .windowLevel(.floating)
        .windowToolbarStyle(.unified(showsTitle: true))
        .windowResizability(.contentMinSize)
        .windowBackgroundDragBehavior(.enabled)
        .windowStyle(.hiddenTitleBar)
        .defaultLaunchBehavior(.suppressed)

        
        UtilityWindow("Trims Editor", id: "trims-editor") {
            TrimsEditorWindow()
                .environment(prax)
                .containerBackground(.panelBackground, for: .window)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        }   
        .windowLevel(.floating)
        .windowToolbarStyle(.unified(showsTitle: true))
        .windowResizability(.contentSize)
        .windowBackgroundDragBehavior(.enabled)
        .windowStyle(.hiddenTitleBar)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        
        .defaultWindowPlacement { content, context in
            let displayBounds = context.defaultDisplay.visibleRect
            let contentSize = content.sizeThatFits(.unspecified)
            let positionX = displayBounds.midX / 2 // - (contentSize.width * 0.75)
            let positionY = displayBounds.midY / 2 // - (contentSize.height * 0.25)
            let position = CGPoint(x: positionX, y: positionY)
            return WindowPlacement(position, size: contentSize)
        }

        
        Settings {
            SettingsView()
                .environment(\.modelContext, modelContainer.mainContext)
                .environment(prax)
        }
    }
}

struct MainCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    @FocusedValue(PraxModel.self) private var prax: PraxModel?
    //   @FocusedBinding(\.setExportFilenameBody) var viewAction: (() -> Void)?
    //   @FocusState.Binding var focusBinding: MyField?
    
    
    var body: some Commands {
        CommandMenu("Prax") {
            Button("Set Export Filename") { } //setFocusedBinding focusBinding = .exportFilenameBody }
                .keyboardShortcut("s", modifiers: [.command])
                .disabled(prax?.document.totalHeight == 0)
            Divider()
            Button("Prax Test") { prax?.praxTest() }
                .keyboardShortcut("0", modifiers: [.command])
            Button("Run", systemImage: "play.fill") {}
                .keyboardShortcut("R")
            Button("Stop", systemImage: "stop.fill") {}
                .keyboardShortcut(".")
        }
        
        CommandGroup(after: .textEditing) {
            WindowVisibilityToggle(windowID: "trims-editor")
            Button("Select All Prax") { NSApp.keyWindow?.makeFirstResponder(nil) }
            .keyboardShortcut("a", modifiers: [.command, .option]) }
        
        CommandGroup(replacing: .sidebar) {

            Button("Show/Hide Library") { NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil) }
                .keyboardShortcut("1", modifiers: [.command])
            Button("Show/Hide PDF Viewer") { prax?.showTrimsEditor.toggle() }
                .keyboardShortcut("2", modifiers: [.command])
            Button("Show/Hide Trims Editor") { prax?.showTrimsEditor.toggle() }
                .keyboardShortcut("3", modifiers: [.command])

        }
    }
}

