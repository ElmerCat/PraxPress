//  DocumentEditingView.swift
//  PraxPress - Prax=0104-1
//
//


import SwiftUI
import PDFKit
import AppKit
import Combine
import UniformTypeIdentifiers


struct DocumentEditingToolbar: View {
    @State private var prax = PraxModel.shared
    @Environment(PraxContext.self) private var praxContext
    
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
        GroupBox {
            VStack {
                HStack {
                    
                    
                    switch (prax.selectedFiles.count) {
                    case 0:
                        Text("No files selected")
                    case 1:
                        Text("Source file: \(prax.firstSelectedFileURL?.formatted(filenameStyle) ?? "")")
                    default:
                        Text("\(prax.selectedFiles.count) Files selected")
                    }
                    Spacer()
                    if prax.selectedFiles.count > 0 {
                        Text("Save to file: \(prax.exportFileURL?.formatted(filenameStyle) ?? "")")
                        
                    }
                }
                
                HStack {
                    ControlGroup("", systemImage: "magnifyingglass") {
                        Button("Increase", systemImage: "plus.rectangle.portrait", action: prax.zoomInEditingPDFView)
                        Button("Decrease", systemImage: "minus.rectangle.portrait", action: prax.zoomOutEditingPDFView)
                        Button("", systemImage: "inset.filled.center.rectangle.portrait", action: {prax.editingPDFDisplayMode = .singlePage}).disabled(prax.editingPDFDisplayMode == .singlePage)
                        Button("", systemImage: "rectangle.portrait.tophalf.inset.filled", action: {prax.editingPDFDisplayMode = .singlePageContinuous}).disabled(prax.editingPDFDisplayMode == .singlePageContinuous)
                        if prax.editingPDFDocument.pageCount > 1 {
                            Button("", systemImage: "rectangle.portrait.split.2x1", action: {prax.editingPDFDisplayMode = .twoUp}).disabled(prax.editingPDFDisplayMode == .twoUp)
                            Button("", systemImage: "inset.filled.topleft.rectangle.portrait", action: {prax.editingPDFDisplayMode = .twoUpContinuous}).disabled(prax.editingPDFDisplayMode == .twoUpContinuous)
                        }
                        if (prax.editingPDFDisplayMode == .twoUpContinuous || prax.editingPDFDisplayMode == .twoUp) {
                            Toggle("", systemImage: "book", isOn: $prax.editingPDFDisplaysAsBook).toggleStyle(.button)
                        }
                    }
                    Spacer()
                    Button {
                        prax.showingExportFolderSelector = true
                    } label: {
                        Label(prax.exportFolderURL?.lastPathComponent ?? "No folder selected", systemImage: "arrow.forward.folder")
                    }
                    
                    ZStack {
                        TextField("Prefix", text: $prax.exportFilenamePrefix)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                            .overlay(alignment: .trailing) {
                                if !prax.exportFilenamePrefix.isEmpty {
                                    Button {
                                        prax.exportFilenamePrefix = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                            .padding(.trailing, 6) // adjust for your field style
                                    }
                                    .buttonStyle(.plain)
                                    .help("Clear")
                                }
                            }
                    }
                    //     .frame(minWidth: 10, idealWidth: 20, alignment: .init(horizontal: .trailing, vertical: .center))
                    
                    
                    TextField("Filename", text: Binding<String>(
                        get: { prax.exportFilenameBody },
                        set: { newValue in
                            var newName = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            // Ensure we don't accidentally include a dot/extension typed by the user
                            if let dotRange = newName.range(of: ".") {
                                newName = String(newName[..<dotRange.lowerBound])}
                            prax.exportFilenameBody = newName
                        })
                              
                    )
                    //   .frame(minWidth: 10, idealWidth: 20, alignment: .init(horizontal: .trailing, vertical: .center))
                    //.frame(maxWidth: 100, alignment: .init(horizontal: .trailing, vertical: .center))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(prax.exportFolderURL == nil)
                    
                    Spacer()
                    
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
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
                .padding(8)
            }
        }
        
        .fileImporter(
            isPresented: $prax.showingExportFolderSelector,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false,
            
        )
        { result in
            switch result {
            case .success(let urls):
                prax.exportFolderURL = urls.first!
                //                        prax.exportFolderURLBookmark = try? prax.exportFolderURL!.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
            case .failure(let error):
                prax.saveError = error.localizedDescription
            }
            
        }
        .fileDialogDefaultDirectory(prax.sourceFolderURL)
        .fileDialogMessage("Choose the Export Folder")
        .fileDialogConfirmationLabel(Text("Choose Export Folder"))
        
        .background(Color(red: 0.4, green: 0.4, blue: 0.8, opacity: 0.3))
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
                Text("\(prax.exportFilename).pdf")
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


struct DocumentEditingView: NSViewRepresentable {
    
    @State @Bindable private var prax = PraxModel.shared
    
    func makeCoordinator() -> Coordinator {
        print("Nadine Peeler- DocumentEditingView makeCoordinator")
        return Coordinator()
    }
    
    func makeNSView(context: Context) -> NSSplitView {
        print("Nadine Peeler- DocumentEditingView makeNSView")
        let split = NSSplitView()
        split.delegate = context.coordinator
        split.isVertical = true
        split.dividerStyle = .thick
        split.translatesAutoresizingMaskIntoConstraints = false
        
     //   prax.editingPDFView = PDFView()
    //    prax.editingPDFView.pageOverlayViewProvider = context.coordinator
        
        let thumbnailViewController = ThumbnailViewController()
       
        //      thumbnailController.pdfView = prax.editingPDFView
        
        //       context.coordinator.thumbnailController = thumbnailController
        
        split.addArrangedSubview(thumbnailViewController.view)
   //     split.addArrangedSubview(prax.editingPDFView)
        let pagesViewController = PagesViewController()
        
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
    
    final class Coordinator: NSObject, PDFPageOverlayViewProvider, NSSplitViewDelegate {
        @State private var prax = PraxModel.shared
        
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
            DispatchQueue.main.async {
                self.prax.editingPDFView.layoutDocumentView()
                self.prax.editingPDFView.needsDisplay = true
                
            }
        }
        
        func pdfView(_ pdfView: PDFView, overlayViewFor pdfPage: PDFPage) -> NSView? {
            print("DocumentEditingView Coordinator - overlayViewFor page")
            guard let pdfPageItem = self.prax.pdfPageItem(for: pdfPage) else { return nil }
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

#Preview {
    DocumentEditingToolbar()
    DocumentEditingView()
}

