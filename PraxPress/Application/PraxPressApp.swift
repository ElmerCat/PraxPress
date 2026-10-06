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
    private let persistence: PersistenceController

    init() { self.persistence = PersistenceController(modelContainer: modelContainer)
        do { try Tips.configure([Tips.ConfigurationOption.displayFrequency(.daily)])
 //           try Tips.resetDatastore()
            Tips.showAllTipsForTesting() }
        catch { print("Error configuring Tips: \(error)") }
    }

     private let modelContainer: ModelContainer = {
        let schema = Schema([SourceFile.self, SourceFileGroup.self])
        let config = ModelConfiguration() // customize if needed
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        let prax = PraxModel(persistence)
        WindowGroup(id: "main") {
            
            ContentView()
                .environment(prax) //.environment(document)
                .focusedSceneValue(prax)
                .environment(\.modelContext, modelContainer.mainContext)
              
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
        
  //      UtilityWindow("Preview", id: "preview") { Text("Juliette M. Belanger") } //PreviewView() }
        
        Settings {
            SettingsView()
                .environment(\.modelContext, modelContainer.mainContext)
                .environment(persistence)
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
                .keyboardShortcut("p", modifiers: [.command])
            
            Button("Run", systemImage: "play.fill") {
                 }
                .keyboardShortcut("R")
            
            
            Button("Stop", systemImage: "stop.fill") {  }
                .keyboardShortcut(".")
        }
        
        CommandGroup(after: .textEditing) {
            Button("Select All Prax") { NSApp.keyWindow?.makeFirstResponder(nil) }
            .keyboardShortcut("a", modifiers: [.command, .option]) }
        
  /*
        CommandGroup(after: .newItem) {
            Button("New Tab") {
                let keyWindow = NSApp.keyWindow
                WindowCoordinator.shared.requestNewTab(in: keyWindow)
                openWindow(id: "main") }
            .keyboardShortcut("t", modifiers: [.command]) }
  */
        CommandGroup(after: .sidebar) {
            Button("Show/Hide Sidebar") {
                NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil) }
            .keyboardShortcut("s", modifiers: [.command, .control]) }
    }
}

