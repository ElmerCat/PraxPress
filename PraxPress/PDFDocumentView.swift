//  PDFDocumentView.swift
//  PraxPress - Prax=1229-3
//
//  SwiftUI wrapper for a full PDFKit PDFView with configurable display options and selection sync.

import SwiftUI
import PDFKit
import AppKit

struct PDFDocumentView: NSViewRepresentable {
    @Binding var document: PDFDocument?
    @Binding var currentIndex: Int

    var displayMode: PDFDisplayMode = .singlePageContinuous
    var displaysPageBreaks: Bool = true
    var autoScales: Bool = true
    var backgroundColor: NSColor = .clear
    var displaysAsBook: Bool = false

    func makeCoordinator() -> Coordinator { Coordinator(currentIndex: $currentIndex) }

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = autoScales
        pdfView.displayMode = displayMode
        pdfView.displaysPageBreaks = displaysPageBreaks
        pdfView.backgroundColor = backgroundColor
        pdfView.displaysAsBook = displaysAsBook

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: Notification.Name.PDFViewPageChanged,
            object: pdfView
        )
        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        if pdfView.document !== document {
            pdfView.document = document
        }
        if pdfView.displayMode != displayMode { pdfView.displayMode = displayMode }
        if pdfView.displaysPageBreaks != displaysPageBreaks { pdfView.displaysPageBreaks = displaysPageBreaks }
        if pdfView.backgroundColor != backgroundColor { pdfView.backgroundColor = backgroundColor }
        if pdfView.displaysAsBook != displaysAsBook { pdfView.displaysAsBook = displaysAsBook }
        if pdfView.autoScales != autoScales { pdfView.autoScales = autoScales }

        if let doc = document, currentIndex >= 0, currentIndex < doc.pageCount {
            let page = doc.page(at: currentIndex)!
            if pdfView.currentPage !== page { pdfView.go(to: page) }
        }
    }

    final class Coordinator: NSObject {
        @Binding var currentIndex: Int
        init(currentIndex: Binding<Int>) { _currentIndex = currentIndex }

        @objc func pageChanged(_ note: Notification) {
            guard let pdfView = note.object as? PDFView,
                  let doc = pdfView.document,
                  let page = pdfView.currentPage else { return }
            let idx = doc.index(for: page)
            if idx != NSNotFound, idx != currentIndex { currentIndex = idx }
        }
    }
}
