//
//  HostingViewContainer.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/17/26.
//


import SwiftUI
import AppKit

protocol HostingViewContainer: NSView {
    associatedtype RootView: View
    var hostingView: NSHostingView<RootView>? { get set }
    func buildRootView() -> RootView
}

extension HostingViewContainer {
    /// Properly detach and clean up the hosting view
    func detachHostingView() {
        hostingView?.removeFromSuperview()
        hostingView = nil
    }
    
    /// Create or update the hosting view with proper lifecycle management
    func attachHostingView() {
        let root = buildRootView()
        
        if let existing = hostingView {
            // Reuse existing hosting view with updated root
            existing.rootView = root
        } else {
            // Create new hosting view
            let hosting = NSHostingView(rootView: root)
            hosting.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(hosting)
            
            NSLayoutConstraint.activate([
                hosting.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                hosting.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                hosting.topAnchor.constraint(equalTo: self.topAnchor),
                hosting.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            ])
            
            hostingView = hosting
        }
    }
}
