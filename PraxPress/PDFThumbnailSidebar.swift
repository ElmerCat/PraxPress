//  PDFThumbnailSidebar.swift
//  PraxPress - Prax=1229-3
//
//  Minimal SwiftUI wrapper for PDFKit's PDFThumbnailView bound to an external PDFView.

import SwiftUI
import PDFKit
import AppKit

struct PDFThumbnailSidebar: NSViewRepresentable {
    let pdfView: PDFView

    var sidebarWidth: CGFloat = 180
    var thumbSize: CGSize = CGSize(width: 120, height: 160)
    var backgroundColor: NSColor = .quaternaryLabelColor

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = true
        scrollView.backgroundColor = backgroundColor
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let thumbnailView = PDFThumbnailView()
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.backgroundColor = backgroundColor
        thumbnailView.thumbnailSize = thumbSize
        thumbnailView.pdfView = pdfView

        scrollView.documentView = thumbnailView
        NSLayoutConstraint.activate([
            thumbnailView.widthAnchor.constraint(equalToConstant: sidebarWidth)
        ])
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let tv = nsView.documentView as? PDFThumbnailView {
            tv.thumbnailSize = thumbSize
            tv.backgroundColor = backgroundColor
            if tv.pdfView !== pdfView {
                tv.pdfView = pdfView
            }
        }
    }
}

