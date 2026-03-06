//  DocumentEditingView.swift
//  PraxPress - Prax=0104-1
//
//


import SwiftUI
import PDFKit
import AppKit
//import Combine
import UniformTypeIdentifiers


struct DocumentEditingView: NSViewRepresentable {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    func makeCoordinator() -> Coordinator {
        print("Nadine Peeler- DocumentEditingView makeCoordinator")
        return Coordinator()
    }
    
    func makeNSView(context: Context) -> NSSplitView {
        print("Nadine Peeler- DocumentEditingView makeNSView")
        let splitView = NSSplitView()
        context.coordinator.splitView = splitView
        splitView.delegate = context.coordinator
        splitView.isVertical = true
        splitView.dividerStyle = .thick
        splitView.translatesAutoresizingMaskIntoConstraints = false
        
        let thumbnailViewController = ThumbnailViewController(document, praxModel)
        splitView.addArrangedSubview(thumbnailViewController.view)

        let pagesViewController = PagesViewController(document)
        
        splitView.addArrangedSubview(pagesViewController.view)
        
        splitView.dividerStyle = .paneSplitter

        DispatchQueue.main.async {
            let target: CGFloat = 250
            splitView.setPosition(target, ofDividerAt: 0)
        }
        
      /*  NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.widthGuideChanged(_:)),
            name: .praxWidthGuideChanged,
            object: nil
        )
       */
        return splitView
    }
    
    func updateNSView(_ split: NSSplitView, context: Context) {
        print("Nadine Peeler- DocumentEditingView updateNSView")
    }
    
    final class Coordinator: NSObject, NSSplitViewDelegate, NSDraggingDestination { //PDFPageOverlayViewProvider,
       
        var splitView: NSSplitView?
        func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
            print("Coordinator - draggingEntered")
            return .copy
        }
        
        func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
            let pboard = sender.draggingPasteboard
            if let urls = pboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
                for url in urls {
                    print("Coordinator - Dropped file: \(url.path)")
                }
                return true // Drop was successful
            }
            return false // Drop rejected
        }
 
        func splitView(_ splitView: NSSplitView, shouldCollapseSubview subview: NSView, forDoubleClickOnDividerAt dividerIndex: Int) -> Bool {
            print("DocumentEditingView Coordinator - shouldCollapseSubview subview: ", subview, ", forDoubleClickOnDividerAt dividerIndex:  ", dividerIndex)
             return true
        }
        func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
            print("DocumentEditingView Coordinator - canCollapseSubview subview:  ", subview)
            
            return true
        }

/*
        func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
           print("DocumentEditingView Coordinator - constrain Min Coordinate proposedMinimumPosition: ", proposedMinimumPosition, ", ofSubviewAt dividerIndex: ", dividerIndex)
            return 100
        }
        func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            print("DocumentEditingView Coordinator - constrain Max Coordinate proposedMinimumPosition: ", proposedMaximumPosition)
            return 500
        }
        func splitView(_ splitView: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            print("DocumentEditingView Coordinator - constrainSplitPosition proposedPosition: ", proposedPosition, ", ofSubviewAt dividerIndex: ", dividerIndex)
            return 250
        }
        func splitView(_ splitView: NSSplitView, resizeSubviewsWithOldSize oldSize: NSSize) {
            print("DocumentEditingView Coordinator - resizeSubviewsWithOldSize oldSize:  ", oldSize)
        }
        func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
            print("DocumentEditingView Coordinator - shouldAdjustSizeOfSubview view:  ", view)
            return true
        }
 */
        func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
            print("DocumentEditingView Coordinator - shouldHideDividerAt dividerIndex: ", dividerIndex)
            return true
        }
        func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
            print("DocumentEditingView Coordinator - proposedEffectiveRect: ", proposedEffectiveRect, ", forDrawnRect: ", drawnRect, ", ofDividerAt dividerIndex: ", dividerIndex)
            return proposedEffectiveRect
        }
        func splitView(_ splitView: NSSplitView, additionalEffectiveRectOfDividerAt dividerIndex: Int) -> NSRect {
            print("DocumentEditingView Coordinator - additionalEffectiveRectOfDividerAt dividerIndex:   ", dividerIndex)
            return NSZeroRect
        }
        func splitViewWillResizeSubviews(_ notification: Notification) {
            print("DocumentEditingView Coordinator - splitView Will ResizeSubviews")
        }
        func splitViewDidResizeSubviews(_ notification: Notification) {
            print("DocumentEditingView Coordinator - splitView Did ResizeSubviews")
        }
        
        
/*
        @objc func pageChanged(_ note: Notification) {
            guard let pdfView = note.object as? PDFView,
                  let doc = pdfView.document,
                  let page = pdfView.currentPage else { return }
            let idx = doc.index(for: page)
            print("DocumentEditingView Coordinator - changed to page:", idx)
        }
       
        @objc func widthGuideChanged(_ note: Notification) {
            print("DocumentEditingView Coordinator - widthGuideChanged")
            
            let target: CGFloat = 250
            splitView!.setPosition(target, ofDividerAt: 0)
            
        }
        
        func pdfView(_ pdfView: PDFView, overlayViewFor pdfPage: PDFPage) -> NSView? {
            print("DocumentEditingView Coordinator - overlayViewFor page")
            @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
            
            guard let pdfPageItem = document.pdfPageItem(for: pdfPage) else { return nil }
            let view = PDFPageOverlayView()
            view.pdfView = pdfView
            
            view.onFinish = { [weak pdfPage] rectInOverlay in
                guard let pdfPage = pdfPage else { return }
                
                // Convert overlay-local rect to PDFView coordinates
                let rectInView = view.convert(rectInOverlay, to: pdfView)
                
                // Clamp to page bounds in PDFView coordinates
                let pageBoundsInView = pdfView.convert(pdfPage.bounds(for: .cropBox), from: pdfPage)
                let clamped = rectInView.intersection(pageBoundsInView)
                guard !clamped.isEmpty else { return }
                
                // Convert to page coords
                let pageRect = pdfView.convert(clamped, to: pdfPage)
                let media = pdfPage.bounds(for: .cropBox)
                
                let left = max(0, pageRect.minX - media.minX)
                let right = max(0, media.maxX - pageRect.maxX)
                let bottom = max(0, pageRect.minY - media.minY)
                let top = max(0, media.maxY - pageRect.maxY)
                
                let trim = EdgeTrims(left: left, right: right, top: top, bottom: bottom)
                print("DocumentEditingView Coordinator - trim l:", trim.left, " r:", trim.right, " b:", trim.bottom, " t:", trim.top)
                
                pdfPageItem.trim = trim
            }
            
            // Seed current rect from trims
            DispatchQueue.main.async { [weak view, weak pdfPage, weak pdfView, weak pdfPageItem] in
                guard let view = view, let pdfPage = pdfPage, let pdfView = pdfView, let pdfPageItem = pdfPageItem else { return }
                let crop = pdfPage.bounds(for: .cropBox)
                let cropInView = pdfView.convert(crop, from: pdfPage)
                let cropInOverlay = view.convert(cropInView, from: pdfView)
                view.clampRect = cropInOverlay

                // Recompute visible using current trims
                let trim = pdfPageItem.trim
                let visibleInPage = CGRect(
                    x: crop.minX + trim.left,
                    y: crop.minY + trim.bottom,
                    width: crop.width - trim.left - trim.right,
                    height: crop.height - trim.top - trim.bottom
                )
                let visibleInView = pdfView.convert(visibleInPage, from: pdfPage)
                let visibleInOverlay = view.convert(visibleInView, from: pdfView)
                view.currentRect = visibleInOverlay
                
                view.needsDisplay = true
            }
            return view
        }

*/
        
    }
}

struct DocumentEditingToolbar: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    private func title(for mode: PDFDisplayMode) -> String {
        switch mode {
        case .singlePage: return "Single"
        case .singlePageContinuous: return "Continuous"
        case .twoUp: return "Two Up"
        case .twoUpContinuous: return "Two Up Cont."
        @unknown default: return "Unknown"
        }
    }
    
    let filenameStyle = URL.FormatStyle(scheme: .never,
                                        user: .never,
                                        password: .never,
                                        host: .always,
                                        port: .never,
                                        path: .always,
                                        query: .never,
                                        fragment: .never)
 
    var body: some View {
        @Bindable var prax = praxModel
        GroupBox {
            
            //    Text("Prax")
            let pageCount = "Pages: " + String(document.totalPDFPageItems())
            HStack {
                Text(pageCount)
                Button("Clear All", systemImage: "document.on.trash", action: {
                    print (pageCount)
                    
                })
                Button {
                    prax.showingFileImporter = true }
                label: {
                    Text("Import Files") //.frame(minWidth: 100, maxWidth: 200, alignment: .center)
                }
                
                //       .background(dropTargeted ? Color.green : Color.blue)
                .fileImporter(
                    isPresented: $prax.showingFileImporter,
                    allowedContentTypes: [.pdf, .image, .text, .video],
                    allowsMultipleSelection: true
                ) { result in
                    switch result {
                    case .success(let urls):
                        print (urls)
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
            .padding(8)
            
        }
        .onDrop(of: [.fileURL], delegate: PraxDropDelegate(document, prax))
        
        .fileDialogDefaultDirectory(document.sourceFolderURL)
        .fileDialogMessage("Choose the Export Folder")
        .fileDialogConfirmationLabel(Text("Choose Export Folder"))
        
        .background(prax.dropTargeted ? Color(red: 0.4, green: 0.4, blue: 0.8, opacity: 0.3) : Color.orange)
        .foregroundStyle(Color.white)
        
    }
    
    private var dragPreviewView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor, lineWidth: 2)
                )
                .frame(width: 180, height: 80)
            
            VStack(spacing: 6) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.blue)
                Text("\(document.exportFilename).pdf")
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
            }
        }
        
    }
}

struct DocumentEditingFooter: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    let filenameStyle = URL.FormatStyle(scheme: .never,
                                        user: .never,
                                        password: .never,
                                        host: .always,
                                        port: .never,
                                        path: .always,
                                        query: .never,
                                        fragment: .never)
    var body: some View {
        @Bindable var prax = praxModel
        HStack {
            switch (document.selectedFiles.count) {
            case 0:
                Text("No files selected")
            case 1:
                Text("Source file: \(document.firstSelectedFileURL?.formatted(filenameStyle) ?? "")")
            default:
                Text("\(document.selectedFiles.count) Source files selected")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
        .padding(8)
    }
}



#Preview {
    
    DocumentEditingToolbar()
    DocumentEditingView()
    DocumentEditingFooter()
}

