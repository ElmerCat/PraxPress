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
//    private var settingsModel = SettingsModel()

    init() {
        self.persistence = PersistenceController(modelContainer: modelContainer)
        do {
            try Tips.configure([Tips.ConfigurationOption.displayFrequency(.daily)])
 //           try Tips.resetDatastore()
            Tips.showAllTipsForTesting()
            }
        catch {
            print("Error configuring Tips: \(error)")
        }
    }

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("App.toolbarLabelStyle")  private var toolbarLabelStyle: ToolbarLabelStyle = .titleAndIcon
    
    private let modelContainer: ModelContainer = {
        let schema = Schema([SourceFile.self, SourceFileGroup.self])
        let config = ModelConfiguration() // customize if needed
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup(id: "main") {
            MainSceneRoot()
                .ignoresSafeArea(.container, edges: .top)
                .environment(\.modelContext, modelContainer.mainContext)
                .environment(persistence)
                .background(
                    WindowReader { window in
                        window.styleMask.insert(.fullSizeContentView)
                    //    window.styleMask.insert(.unifiedTitleAndToolbar)
                    //    window.styleMask.insert(.hiddenTitleBar)
                        
                        WindowCoordinator.shared.attachIfPending(newWindow: window)
                    }
                )
       }
        .commands {
            MainCommands()
            InspectorCommands()
        }
        .windowStyle(.hiddenTitleBar)
    //    .windowToolbarStyle(.)
//        .windowToolbarStyle(.unified)
        .windowToolbarStyle(.unified(showsTitle: false))  //.expanded)  //
   //     .windowToolbarLabelStyle($toolbarLabelStyle)
        
        .windowResizability(.contentSize)
    /*    .defaultWindowPlacement { content, context in
            // 1. Get the usable screen area (excludes Dock/Menu Bar)
            let displayRect = context.defaultDisplay.visibleRect
            
            // 2. Calculate a size (e.g., 50% of the screen)
            let width = displayRect.width * 0.2
            let height = displayRect.height * 0.5
            let size = CGSize(width: width, height: height)
            
            // 3. Calculate position for centering
            let position = CGPoint(
                x: displayRect.midX - (width / 2),
                y: displayRect.midY - (height / 2)
            )
            
            return WindowPlacement(position, size: size)
        }*/


        Settings {
            SettingsView()
                .environment(\.modelContext, modelContainer.mainContext)
                .environment(persistence)
  //              .environment(settingsModel)
            
        }

    }
}



final class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        print("applicationSupportsSecureRestorableState")
        return true }
    
    private var pendingOpenURLs: [URL] = []
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Register early Apple Event handler for 'odoc' (open documents)
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleOpenDocumentsAppleEvent(event:replyEvent:)),
            forEventClass: AEEventClass(kCoreEventClass),
            andEventID: AEEventID(kAEOpenDocuments)
        )
    }
    
    
    @objc private func handleOpenDocumentsAppleEvent(event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        
        print("handleOpenDocumentsAppleEvent")
        // Extract file URLs from the event
        var urls: [URL] = []
        if let listDesc = event.paramDescriptor(forKeyword: keyDirectObject) {
            for index in 1...listDesc.numberOfItems {
                if let item = listDesc.atIndex(index), let url = item.fileURLValue {
                    urls.append(url)
                }
            }
        }
        
        // Keep only PDFs (if that’s your intent)
        urls = urls.filter { Prax.fileTypes.contains( $0.pathExtension.lowercased()) }
        guard !urls.isEmpty else { return }
        
        pendingOpenURLs = urls
        
        if NSRunningApplication.current.isFinishedLaunching {
            insertPDFPageSectionsFromPendingURLs()
            
        }
        
        // Store them for processing once the app is ready
       
    }
        
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("applicationDidFinishLaunching")
        
        if !pendingOpenURLs.isEmpty {
            // Bring app to front but don’t create extra windows
            NSApp.activate(ignoringOtherApps: true)
            
            insertPDFPageSectionsFromPendingURLs()
            
            
        }
        
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    func applicationWillTerminate(_ notification: Notification) {
        print("applicationWillTerminate")
    }
  
    
    func insertPDFPageSectionsFromPendingURLs() {
        
        
        Task {
            do {
                print("Julie d Prax", pendingOpenURLs, "Juliette: ")
                
                
 //               try await PraxModel.shared.insertPDFPageSectionsFromDocumentURLS(pendingOpenURLs, at: IndexPath(item: -1, section: -1))
 //               pendingOpenURLs.removeAll()
 //               PraxModel.shared.refreshMergedDocument()
                
            } catch let error {
                print("Julie d Prax", pendingOpenURLs, "Error: ", error)
                
            }
        }
      

    }
    
    // Handle files opened from Finder (Open With) and double-clicks on associated documents
    func application(_ application: NSApplication, open urls: [URL]) {
        print("application(_:open:) received URLs: \(urls)")
        // Example: handle only PDFs and route to your model
        
        NSApp.activate(ignoringOtherApps: true)
        
 
        
    }
    
}


final class WindowCoordinator {
    static let shared = WindowCoordinator()
    private var pendingTargetWindowNumber: Int?
    
    func requestNewTab(in keyWindow: NSWindow?) {
        print("requestNewTab")
        pendingTargetWindowNumber = keyWindow?.windowNumber
    }
    
    func attachIfPending(newWindow: NSWindow) {
        print("attachIfPending")
        guard let targetNumber = pendingTargetWindowNumber else { return }
        // Clear pending so we only attach once
        pendingTargetWindowNumber = nil
        if let target = NSApp.windows.first(where: { $0.windowNumber == targetNumber }) {
            target.addTabbedWindow(newWindow, ordered: .above)
            newWindow.makeKeyAndOrderFront(nil)
        }
    }
}

struct WindowReader: NSViewRepresentable {
    var onResolve: (NSWindow) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let v = WindowAccessorView()
        v.onResolve = onResolve
        return v
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    private final class WindowAccessorView: NSView {
        var onResolve: ((NSWindow) -> Void)?
        override func viewDidMoveToWindow() {
            print("viewDidMoveToWindow")
            super.viewDidMoveToWindow()
            if let window = window {
                print("onResolve?(window)")
                onResolve?(window)
            }
        }
    }
}

struct TempCleanupLifecycleHook: View {
    let onCleanup: () -> Void
    var body: some View {
        Color.clear
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                print("TempCleanupLifecycleHook willTerminateNotification")
                onCleanup()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { notification in
                if let window = notification.object as? NSWindow {
                    // Add logic here to check if it's the specific window you care about
                    print("Window \(window.title) is about to close.")
                    // Perform cleanup actions...
                }
                
                print("TempCleanupLifecycleHook willCloseNotification")
                onCleanup()
            }
    }
}

