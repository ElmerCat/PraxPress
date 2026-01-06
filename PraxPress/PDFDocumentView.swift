//  PDFDocumentView.swift
//  PraxPress - Prax=0104-1
//
//  SwiftUI wrapper for a full PDFKit PDFView with configurable display options and selection sync.
//

import SwiftUI
import PDFKit
import AppKit

struct PDFDocumentView: NSViewRepresentable {
    @Bindable var viewModel:  ViewModel
    @Bindable var pdfModel: PDFModel
    
    var onPDFViewReady: (PDFView) -> Void = {
        _ in
        print("Juliette M. Belanger")
    }
    
    // Hooks for per-page trims so the overlay can seed and persist rectangles
    var trimsForPageIndex: (Int) -> EdgeTrims = { _ in .zero }
    var onTrimsChanged: (Int, EdgeTrims) -> Void = { _, _ in }
    
    func makeCoordinator() -> Coordinator {
        print("Nadine Peeler")
        return Coordinator(pdfModel: pdfModel)
    }
    
    func makeNSView(context: Context) -> NSSplitView {
        let split = NSSplitView()
        split.isVertical = true
        split.dividerStyle = .thin
        split.translatesAutoresizingMaskIntoConstraints = false
        
        // Main PDFView
        let pdfView = PDFView()
        pdfView.pageOverlayViewProvider = context.coordinator
        
        context.coordinator.pdfView = pdfView
        
        pdfView.autoScales = viewModel.pdfAutoScales
        pdfView.displayMode = viewModel.pdfDisplayMode
        pdfView.displaysPageBreaks = viewModel.pdfDisplayPageBreaks
        pdfView.backgroundColor = viewModel.pdfBackgroundColor
        pdfView.displaysAsBook = viewModel.pdfDisplaysAsBook
        
        //let thumbnailView = ReorderablePDFThumbnailView()
       // let thumbnailView = NSCollectionView()
        
        let thumbnailController = ThumbnailViewController( with: viewModel, pdfModel: pdfModel)

        thumbnailController.pdfView = pdfView
        
        context.coordinator.thumbnailController = thumbnailController
        
//        thumbnailView.allowsDragging = false
        
 //       thumbnailView.translatesAutoresizingMaskIntoConstraints = false
   //     thumbnailView.backgroundColor = viewModel.pdfBackgroundColor
  //      thumbnailView.thumbnailSize = CGSize(width: 120, height: 160)
       
        
        
        split.addArrangedSubview(thumbnailController.view)
        split.addArrangedSubview(pdfView)
        
        // Initial divider position (thumbnail pane width ~180)
        DispatchQueue.main.async {
            let target: CGFloat = 180
            split.setPosition(target, ofDividerAt: 0)
        }
        
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: Notification.Name.PDFViewPageChanged,
            object: pdfView
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
                onPDFViewReady(v)
            }
        }
        
        
        
        return split
    }
    
    func updateNSView(_ split: NSSplitView, context: Context) {
        guard let pdfView = context.coordinator.pdfView else { return }
        
        if pdfView.document !== pdfModel.pdfDocument {
            pdfView.document = pdfModel.pdfDocument
            
            pdfModel.currentIndex = 0
            pdfModel.trims = [:]
            pdfModel.clearWidthGuide()
            
            if pdfModel.pdfDocument != nil {
                var pg = 0
                while pg < pdfModel.pdfDocument!.pageCount {
                    pdfModel.setTrims(EdgeTrims.zero, for: pg)
                    pg += 1
                }
            }
            // Nudge layout/refresh so PDFKit asks for overlays
            pdfView.layoutDocumentView()
            pdfView.needsDisplay = true
        }
        if pdfView.displayMode != viewModel.pdfDisplayMode  { pdfView.displayMode = viewModel.pdfDisplayMode  }
        if pdfView.displaysPageBreaks != viewModel.pdfDisplayPageBreaks { pdfView.displaysPageBreaks = viewModel.pdfDisplayPageBreaks }
        if pdfView.backgroundColor != viewModel.pdfBackgroundColor { pdfView.backgroundColor = viewModel.pdfBackgroundColor }
        if pdfView.displaysAsBook != viewModel.pdfDisplaysAsBook { pdfView.displaysAsBook = viewModel.pdfDisplaysAsBook }
        if pdfView.autoScales != viewModel.pdfAutoScales { pdfView.autoScales = viewModel.pdfAutoScales }
        
        if (pdfModel.pdfDocument != nil), pdfModel.currentIndex >= 0, pdfModel.currentIndex < pdfModel.pdfDocument!.pageCount {
            let page = pdfModel.pdfDocument!.page(at: pdfModel.currentIndex)!
            if pdfView.currentPage !== page {
                pdfView.go(to: page)
                // Refresh overlay after page switch
                pdfView.layoutDocumentView()
                pdfView.needsDisplay = true
            }
        }
        
        
    }
    
    final class Coordinator: NSObject, PDFPageOverlayViewProvider {
        let pdfModel: PDFModel
        weak var thumbnailController: ThumbnailViewController?
        weak var pdfView: PDFView?
        
        var trimsLookup: ((Int) -> EdgeTrims)?
        var trimsSetter: ((Int, EdgeTrims) -> Void)?
        init(pdfModel: PDFModel) { self.pdfModel = pdfModel }
        
        @objc func pageChanged(_ note: Notification) {
            guard let pdfView = note.object as? PDFView,
                  let doc = pdfView.document,
                  let page = pdfView.currentPage else { return }
            let idx = doc.index(for: page)
            print("changed to page:", idx)
            if idx != NSNotFound, idx != pdfModel.currentIndex { pdfModel.currentIndex = idx }
        }
        
        @objc func widthGuideChanged(_ note: Notification) {
            guard let pdfView = self.pdfView else { return }
            DispatchQueue.main.async {
                pdfView.layoutDocumentView()
                pdfView.needsDisplay = true
            }
        }
        
        func pdfView(_ pdfView: PDFView, overlayViewFor page: PDFPage) -> NSView? {
            let view = PDFPageOverlayView()
            view.pdfView = pdfView
            view.pdfModel = pdfModel
            
            
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
//                print("trims l:", trims.left, " r:", trims.right, " b:", trims.bottom, " t:", trims.top)
                
                let idx = page.document?.index(for: page) ?? 0
                pdfModel.setTrims(trims, for: idx)
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
                    let trim = self.pdfModel.trims(for: idx)
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

