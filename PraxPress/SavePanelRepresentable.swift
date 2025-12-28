//
//  SavePanelRepresentable.swift
//  PraxPDF - Prax=1225-0

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// A small wrapper around NSSavePanel to pick a destination URL
struct SaveAsPanel: View {
    let suggestedURL: URL
    let onSave: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        SavePanelRepresentable(suggestedURL: suggestedURL) { url in
            if let url { onSave(url) }
            dismiss()
        }
        .frame(width: 0, height: 0)
    }
}


struct SavePanelRepresentable: NSViewControllerRepresentable {
    typealias NSViewControllerType = NSViewController

    let suggestedURL: URL
    let onCompletion: (URL?) -> Void

    func makeNSViewController(context: Context) -> NSViewController {
        let controller = NSViewController()
        DispatchQueue.main.async {
            presentSavePanel(from: controller.view.window)
        }
        return controller
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        // no-op
    }

    private func presentSavePanel(from window: NSWindow?) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.allowsOtherFileTypes = false
        panel.allowedContentTypes = [.pdf]
        panel.level = .modalPanel

        // Pre-fill name and directory from suggestedURL
        panel.directoryURL = suggestedURL.deletingLastPathComponent()
        panel.nameFieldStringValue = suggestedURL.lastPathComponent

        let completion: (NSApplication.ModalResponse) -> Void = { response in
            if response == .OK {
                onCompletion(panel.url)
            } else {
                onCompletion(nil)
            }
        }

        if let window {
            panel.beginSheetModal(for: window, completionHandler: completion)
        } else {
            // Fallback if no window is available
            completion(panel.runModal())
        }
    }
}

