//
//  PraxPressApp.swift
//  PraxPress
//
//  Created by Elmer Cat on 12/21/25.
//

import SwiftUI
import AppKit

@main
struct PraxPressApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var toolbarLabelStyle: ToolbarLabelStyle = .titleAndIcon
    
    
    var body: some Scene {
        WindowGroup(id: "main") {
            MainSceneRoot()
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
    }
}
   


final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
}


final class WindowCoordinator {
    static let shared = WindowCoordinator()
    private var pendingTargetWindowNumber: Int?
    
    func requestNewTab(in keyWindow: NSWindow?) {
        pendingTargetWindowNumber = keyWindow?.windowNumber
    }
    
    func attachIfPending(newWindow: NSWindow) {
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
            super.viewDidMoveToWindow()
            if let window = window {
                onResolve?(window)
            }
        }
    }
}


