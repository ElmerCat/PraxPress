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
        let split = NSSplitView()
        split.delegate = context.coordinator
   //     split.registerForDraggedTypes([.fileURL])
        split.isVertical = true
        split.dividerStyle = .thick
        split.translatesAutoresizingMaskIntoConstraints = false
        
        //   prax.editingPDFView = PDFView()
        //    prax.editingPDFView.pageOverlayViewProvider = context.coordinator
        
        let thumbnailViewController = ThumbnailViewController(document, praxModel)
        
        
        //      thumbnailController.pdfView = prax.editingPDFView
        
        //       context.coordinator.thumbnailController = thumbnailController
        
        split.addArrangedSubview(thumbnailViewController.view)
        //     split.addArrangedSubview(prax.editingPDFView)
        let pagesViewController = PagesViewController()
        pagesViewController.document = document
        
        split.addArrangedSubview(pagesViewController.view)
        
        split.dividerStyle = .paneSplitter
        //        split.setHoldingPriority(NSLayoutConstraint.Priority.defaultLow, forSubviewAt: 0)
        //        split.setHoldingPriority(NSLayoutConstraint.Priority.defaultHigh, forSubviewAt: 1)
        
        //        split.setPosition(CGFloat(100), ofDividerAt: 0)
        
        // Initial divider position (thumbnail pane width ~180)
        DispatchQueue.main.async {
            let target: CGFloat = 150
            split.setPosition(target, ofDividerAt: 0)
            //    split.setPosition(target + 100, ofDividerAt: 1)
        }
        
        /*NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: Notification.Name.PDFViewPageChanged,
            object: prax.editingPDFView
        )*/
        
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.widthGuideChanged(_:)),
            name: .praxWidthGuideChanged,
            object: nil
        )
        
        
        /*       DispatchQueue.main.async { [weak pdfView] in
         if let v = pdfView {
         print("Julie d'Prax")
         onPDFViewReady(pdfView: v)
         }
         }
         */
        
        
        return split
    }
    
    func updateNSView(_ split: NSSplitView, context: Context) {
        print("Nadine Peeler- DocumentEditingView updateNSView")
    }
    
    final class Coordinator: NSObject, PDFPageOverlayViewProvider, NSSplitViewDelegate, NSDraggingDestination {
        
        func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
            // Return .copy to show a "+" cursor if data is valid
            print("Coordinator - draggingEntered")
            return .copy
        }
        
        func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
            let pboard = sender.draggingPasteboard
            
            // Extract file URLs from the pasteboard
            if let urls = pboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
                for url in urls {
                    print("Coordinator - Dropped file: \(url.path)")
                }
                return true // Drop was successful
            }
            return false // Drop rejected
        }
        
        
        
        func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            //           print("splitView constrainMinCoordinate proposedMinimumPosition: ", proposedMinimumPosition)
            return 100
        }
        
        @objc func pageChanged(_ note: Notification) {
            guard let pdfView = note.object as? PDFView,
                  let doc = pdfView.document,
                  let page = pdfView.currentPage else { return }
            let idx = doc.index(for: page)
            print("DocumentEditingView Coordinator - changed to page:", idx)
            //         if idx != NSNotFound, idx != prax.currentIndex { prax.currentIndex = idx }
        }
       
        @objc func widthGuideChanged(_ note: Notification) {
            print("DocumentEditingView Coordinator - widthGuideChanged")
            //       guard let pdfView = note.object as? PDFView else { return }
            /*    DispatchQueue.main.async {
             self.prax.editingPDFView.layoutDocumentView()
             self.prax.editingPDFView.needsDisplay = true
             
             }*/
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
                
                // var pdfPageItem = prax.pdfPageItem(for: pdfPage)!
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
                //                 fatalError()
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
                    //            handleImportResult(result, forFiles:&prax.listOfFiles)
                }
                
               
               /* Spacer()
                
                Button {
                    prax.isOn = true
                } label: {
                    Label(".pdf", systemImage: "arrow.right.doc.on.clipboard")
                }
                .disabled(prax.firstSelectedFileURL == nil)
                .draggable({ () -> MergedPDFTransfer? in
                    
                    guard let data = prax.mergedPDFDocument.dataRepresentation() else { return nil }
                    return MergedPDFTransfer(data: data, filename: prax.exportFilename)
                }()!, preview: {
                    dragPreviewView
                })
                
                
                if prax.multipleFilesSelected {
                    Button("", systemImage: "document.badge.gearshape", action: {prax.editingPDFDisplayMode = .singlePage}).disabled(prax.editingPDFDisplayMode == .singlePage)
                }*/
                
            }
            .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
            .padding(8)
            
        }
        .onDrop(of: [.fileURL], delegate: PraxDropDelegate(document, prax))
        
//        .onDrop(of: [.fileURL], isTargeted: $dropTargeted) { providers in
//            acceptDrop(providers)
//        }
//        .onDropSessionUpdated({ dropSession in
//            print("DocumentEditingToolbar - dropSessionUpdated phase: ", dropSession.phase)
//        })
        
        
        
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

#Preview {
    DocumentEditingToolbar()
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
            //         Spacer()
            //         if prax.selectedFiles.count > 0 {
            //             Text("Save to file: \(prax.exportFileURL?.formatted(filenameStyle) ?? "")")
            //
            //         }
        }
        .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
        .padding(8)
    }
}



#Preview {
    DocumentEditingToolbar()
    DocumentEditingView()
}

