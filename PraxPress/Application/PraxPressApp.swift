//
//  PraxPressApp.swift
//  PraxPress - Prax=0104-1
//
//  Created by Elmer Cat on 12/21/25.
//

import SwiftUI
import AppKit
import SwiftData

@main
struct PraxPressApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var toolbarLabelStyle: ToolbarLabelStyle = .titleAndIcon
    
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
        }
        
        .windowToolbarStyle(.unified(showsTitle: true))
        .windowToolbarLabelStyle($toolbarLabelStyle)
        
        

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
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { _ in
                print("TempCleanupLifecycleHook willCloseNotification")
                onCleanup()
            }
    }
}

