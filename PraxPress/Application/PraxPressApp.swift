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

@main
struct PraxPressApp: App {
    
    init() {
        try? Tips.configure([Tips.ConfigurationOption.displayFrequency(.daily)])
        try? Tips.resetDatastore()
        // Initializes TipKit with default settings
    }

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("App.toolbarLabelStyle")  private var toolbarLabelStyle: ToolbarLabelStyle = .titleAndIcon
    
    private let modelContainer: ModelContainer = {
        let schema = Schema([PDFFile.self, PDFFileGroup.self])
        let config = ModelConfiguration() // customize if needed
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup(id: "main") {
            MainSceneRoot()
                .environment(\.modelContext, modelContainer.mainContext)
                .background(
                    WindowReader { window in
                        WindowCoordinator.shared.attachIfPending(newWindow: window)
                    }
                )
       }
        .commands {
            MainCommands()
            InspectorCommands()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .windowToolbarLabelStyle($toolbarLabelStyle)
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
        }
    }
}



final class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        print("applicationSupportsSecureRestorableState")
        return true }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("applicationDidFinishLaunching")
        
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    func applicationWillTerminate(_ notification: Notification) {
        print("applicationWillTerminate")
        
        
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

