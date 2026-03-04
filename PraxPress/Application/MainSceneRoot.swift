//
//  MainSceneRoot.swift
//  PraxPress - Prax=0104-1
//
//  Created by Elmer Cat on 12/21/25.
//

import SwiftUI

//import Combine
import PDFKit
import SwiftData

struct MainSceneRoot: View {

    @Environment(PersistenceController.self) private var persistence
//    @Environment(\.modelContext) private var modelContext
    @State private var praxModel = PraxModel()
    @State private var document = MergedPDFDocument()
 //   @Query() var pdfFiles: [PDFFile]
 //   @Query() var pdfFileGroups: [PDFFileGroup]

    var body: some View {
        ContentView()
           
            .environment(document)
            .environment(praxModel)
            .onModifierKeysChanged(mask: .option) { old, new in
                if new.isEmpty {
                    praxModel.optionKeyPressed = false
                    // Option key released
                    print("Option key released")
                }
                else if new.contains(.option) {
                    praxModel.optionKeyPressed = true
                    // Option key pressed
                    print("Option key pressed")
                }
            }
            .task {
                praxModel.documment = document
                document.prax = praxModel
                document.persistence = persistence
 //               document.pdfFiles = pdfFiles
 //               document.pdfFileGroups = pdfFileGroups
            }
  //          .onChange(of: pdfFiles) {
  //              document.pdfFiles = pdfFiles
  //              document.pdfFileGroups = pdfFileGroups
  //          }
        
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

