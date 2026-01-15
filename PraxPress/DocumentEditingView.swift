//  DocumentEditingView.swift
//  PraxPress - Prax=0104-1
//
//  SwiftUI wrapper for a full PDFKit PDFView with configurable display options and selection sync.
//

import SwiftUI
import PDFKit
import AppKit
internal import Combine

struct DocumentEditingView: NSViewRepresentable {
    @State @Bindable private var prax = PraxModel.shared
 
    func onPDFViewReady (pdfView: PDFView) -> Void {
        prax.editingPDFView = pdfView
        print("Juliette M. Belanger")
    }
    
    // Hooks for per-page trims so the overlay can seed and persist rectangles
    var trimsForPageIndex: (Int) -> EdgeTrims = { _ in .zero }
    var onTrimsChanged: (Int, EdgeTrims) -> Void = { _, _ in }
    
    func makeCoordinator() -> Coordinator {
        print("Nadine Peeler- DocumentEditingView makeCoordinator")
        return Coordinator(prax: prax)
    }
    
    func makeNSView(context: Context) -> NSSplitView {
<<<<<<< Updated upstream
        print("Nadine Peeler- DocumentEditingView makeNSView")
=======
        
        print("DocumentEditingView - makeNSView")
        
>>>>>>> Stashed changes
        let split = NSSplitView()
        split.delegate = context.coordinator
        split.isVertical = true
        split.dividerStyle = .thin
        split.translatesAutoresizingMaskIntoConstraints = false
        
        // Main PDFView
        let pdfView = PDFView()
        pdfView.pageOverlayViewProvider = context.coordinator
        
      //  context.coordinator.pdfView = pdfView
        
        pdfView.autoScales = prax.pdfAutoScales
        pdfView.displayMode = prax.pdfDisplayMode
        pdfView.displaysPageBreaks = prax.pdfDisplayPageBreaks
        pdfView.backgroundColor = prax.pdfBackgroundColor
        pdfView.displaysAsBook = prax.pdfDisplaysAsBook
        
        if let pdfURL = Bundle.main.url(forResource: "PraxPress", withExtension: "pdf") {
            let pdfDocument = PDFDocument(url: pdfURL)
            pdfView.document = pdfDocument
        } else {
            print("PDF not found in bundle.")
        }

        
        let thumbnailController = PagesViewController()
        thumbnailController.pdfView = pdfView
        
        context.coordinator.thumbnailController = thumbnailController
       
        split.addArrangedSubview(thumbnailController.view)
        split.addArrangedSubview(pdfView)
        split.dividerStyle = .paneSplitter
//        split.setHoldingPriority(NSLayoutConstraint.Priority.defaultLow, forSubviewAt: 0)
//        split.setHoldingPriority(NSLayoutConstraint.Priority.defaultHigh, forSubviewAt: 1)
        
//        split.setPosition(CGFloat(100), ofDividerAt: 0)
        
        // Initial divider position (thumbnail pane width ~180)
        DispatchQueue.main.async {
            let target: CGFloat = 150
           split.setPosition(target, ofDividerAt: 0)
        }

       NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.fileSelectionChanged(_:)),
            name: .praxFileSelectionChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: Notification.Name.PDFViewPageChanged,
            object: prax.editingPDFView
        )
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.widthGuideChanged(_:)),
            name: .praxWidthGuideChanged,
            object: nil
        )
        
        DispatchQueue.main.async { [weak pdfView] in
            if let v = pdfView {
                print("Julie d'Prax")
                onPDFViewReady(pdfView: v)
            }
        }
        
        
        
        return split
    }
    
    func updateNSView(_ split: NSSplitView, context: Context) {
<<<<<<< Updated upstream
        print("Nadine Peeler- DocumentEditingView updateNSView")
=======
        let _ = Self._printChanges()
        print("DocumentEditingView - updateNSView")
       
        
        
>>>>>>> Stashed changes
        guard let pdfView = prax.editingPDFView else { return }
        
        if pdfView.document !== prax.editingPDFDocument {
            pdfView.document = prax.editingPDFDocument
            
            prax.currentIndex = 0
            prax.trims = [:]
            prax.clearWidthGuide()
            
                var pg = 0
                while pg < prax.editingPDFDocument.pageCount {
                    prax.setTrims(EdgeTrims.zero, for: pg)
                    pg += 1
                }
            
            // Nudge layout/refresh so PDFKit asks for overlays
            pdfView.layoutDocumentView()
            pdfView.needsDisplay = true
        }
        if pdfView.displayMode != prax.pdfDisplayMode  { pdfView.displayMode = prax.pdfDisplayMode  }
        if pdfView.displaysPageBreaks != prax.pdfDisplayPageBreaks { pdfView.displaysPageBreaks = prax.pdfDisplayPageBreaks }
        if pdfView.backgroundColor != prax.pdfBackgroundColor { pdfView.backgroundColor = prax.pdfBackgroundColor }
        if pdfView.displaysAsBook != prax.pdfDisplaysAsBook { pdfView.displaysAsBook = prax.pdfDisplaysAsBook }
        if pdfView.autoScales != prax.pdfAutoScales { pdfView.autoScales = prax.pdfAutoScales }
        
        if prax.currentIndex >= 0, prax.currentIndex < prax.editingPDFDocument.pageCount {
            let page = prax.editingPDFDocument.page(at: prax.currentIndex)!
            if pdfView.currentPage !== page {
                pdfView.go(to: page)
                // Refresh overlay after page switch
                pdfView.layoutDocumentView()
                pdfView.needsDisplay = true
            }
        }
        
        
    }
    
    final class Coordinator: NSObject, PDFPageOverlayViewProvider, NSSplitViewDelegate {
        @State private var prax = PraxModel.shared

        weak var thumbnailController: PagesViewController?
//        weak var pdfView: PDFView?
        
        var trimsLookup: ((Int) -> EdgeTrims)?
        var trimsSetter: ((Int, EdgeTrims) -> Void)?
        init(prax: PraxModel) { self.prax = prax }
        
        func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {

 //           print("splitView constrainMinCoordinate proposedMinimumPosition: ", proposedMinimumPosition)
            return 100
        }

        @objc func fileSelectionChanged(_ note: Notification) {
<<<<<<< Updated upstream
            print("DocumentEditingView Coordinator - fileSelectionChanged")
=======
            print("DocumentEditingView Coordinator fileSelectionChanged")
>>>>>>> Stashed changes
       
            
        }

        
        @objc func pageChanged(_ note: Notification) {
            guard let pdfView = note.object as? PDFView,
                  let doc = pdfView.document,
                  let page = pdfView.currentPage else { return }
            let idx = doc.index(for: page)
            print("DocumentEditingView Coordinator - changed to page:", idx)
            if idx != NSNotFound, idx != prax.currentIndex { prax.currentIndex = idx }
        }
        
        @objc func widthGuideChanged(_ note: Notification) {
            print("DocumentEditingView Coordinator - widthGuideChanged")
            guard let pdfView = note.object as? PDFView else { return }
            DispatchQueue.main.async {
                pdfView.layoutDocumentView()
                pdfView.needsDisplay = true
            }
        }
        
        func pdfView(_ pdfView: PDFView, overlayViewFor page: PDFPage) -> NSView? {
            let view = PDFPageOverlayView()
            view.pdfView = pdfView
            
            
            view.onFinish = { [weak self, weak page] rectInOverlay in
             //   print("rectInOverlay: ", rectInOverlay.debugDescription)
                
                guard let self, let page = page else { return }
                // Convert overlay-local rect to PDFView coordinates
                let rectInView = view.convert(rectInOverlay, to: pdfView)
                
                // Clamp to page bounds in PDFView coordinates
                let pageBoundsInView = pdfView.convert(page.bounds(for: .cropBox), from: page)
            //    print("pageBoundsInView: ", pageBoundsInView.debugDescription)
                let clamped = rectInView.intersection(pageBoundsInView)
          //     print("clamped: ", clamped.debugDescription)
                guard !clamped.isEmpty else { return }
                
                // Convert to page coords
                let pageRect = pdfView.convert(clamped, to: page)
           //     print("pageRect ", pageRect.debugDescription)
                
                let media = page.bounds(for: .cropBox)
          //      print("media: ", media.debugDescription)
                
                let left = max(0, pageRect.minX - media.minX)
                let right = max(0, media.maxX - pageRect.maxX)
                let bottom = max(0, pageRect.minY - media.minY)
                let top = max(0, media.maxY - pageRect.maxY)
                
                let trims = EdgeTrims(left: left, right: right, top: top, bottom: bottom)
                print("DocumentEditingView Coordinator - trims l:", trims.left, " r:", trims.right, " b:", trims.bottom, " t:", trims.top)
                
                let idx = page.document?.index(for: page) ?? 0
                prax.setTrims(trims, for: idx)
            }
            
            // Seed current rect from trims
            if let doc = page.document {
                let idx = doc.index(for: page)
  
                DispatchQueue.main.async { [weak view, weak page, weak pdfView] in
                    guard let view = view, let page = page, let pdfView = pdfView else { return }
                    let crop = page.bounds(for: .cropBox)
                    let cropInView = pdfView.convert(crop, from: page)
                    let cropInOverlay = view.convert(cropInView, from: pdfView)
                    view.clampRect = cropInOverlay
                    // Recompute visible using current trims
                    let trim = self.prax.trims(for: idx)
                    let visibleInPage = CGRect(
                        x: crop.minX + trim.left,
                        y: crop.minY + trim.bottom,
                        width: crop.width - trim.left - trim.right,
                        height: crop.height - trim.top - trim.bottom
                    )
                    let visibleInView = pdfView.convert(visibleInPage, from: page)
                    let visibleInOverlay = view.convert(visibleInView, from: pdfView)
                    view.currentRect = visibleInOverlay

                    view.needsDisplay = true
                }
                
            }
            return view
        }
        
        
    }
}

