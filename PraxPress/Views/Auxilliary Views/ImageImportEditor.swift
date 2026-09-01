//
//  ImageImportEditor.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/29/26.
//

import SwiftUI
//import UniformTypeIdentifiers
import PDFKit



struct ImageImportEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PraxModel.self) private var prax
    
    @State private var imageOptions = SettingsModel.shared.imageImportOptions
     
    @State private var imageAngle = 0.0
   
    @State private var previewImage: NSImage?
    
    @State private var sourceImageSize: CGSize = .zero
    @State private var outputImageSize: CGSize = .zero
    @State private var outputInches: CGSize = .zero
    @State private var estimatedPDFKB: Int?
    @State private var loadedURLForSource: URL?
    @State private var importInProgress = false
    
    private let minRemainingCrop = 0.05

    private var cropLeftBinding: Binding<Double> { Binding( get: { imageOptions.cropLeft },
                                                            set: { imageOptions.cropLeft = min($0, 1 - minRemainingCrop - (imageOptions.cropRight )) } ) }
    private var cropRightBinding: Binding<Double> {Binding(get: { imageOptions.cropRight },
                                                           set: { imageOptions.cropRight = min($0, 1 - minRemainingCrop - (imageOptions.cropLeft )) } )}
    private var cropTopBinding: Binding<Double> { Binding( get: { imageOptions.cropTop },
                                                           set: { imageOptions.cropTop = min($0, 1 - minRemainingCrop - (imageOptions.cropBottom )) }) }
    private var cropBottomBinding: Binding<Double> {Binding( get: { imageOptions.cropBottom },set: { imageOptions.cropBottom = min($0, 1 - minRemainingCrop - (imageOptions.cropTop )) } ) }
    
    
    var body: some View {
        @Bindable var prax = prax
  
        if let pageItem = prax.selectedPageItem {
            
        
//        if let urlBookmark = prax.importEditingURLBookmark {
            
            @Bindable var prax = prax
           
            VStack(spacing: 12) {
                GroupBox {
                    HStack {
                        Image("PraxPress")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20)
                            .padding(3)
                            .rotationEffect(.degrees(imageAngle))
                            .onAppear { withAnimation { imageAngle -= (2 * 360) - 120 } }
                            .onDisappear { withAnimation { imageAngle = 0 } }
                        
                        Text("PraxPress   Import  Editor")
                            .font(prax.theme.fontFeature)
                        Spacer()
                        Toggle("Test on Next Drop", isOn: $prax.inspectNextImageDrop)
                            .toggleStyle(.switch)
                    }
                }
                
                let titleString = "Preview "//— Import URL: \(prax.importEditingURLBookmark.url?.lastPathComponent ?? "no URL"  )" + "  Size:  \(pxText(sourceImageSize))"
                
                if let previewImage {
                    VSplitView {
                        GroupBox(titleString) {
                            HStack {
                                
                                
                                VStack(spacing: 12) {
                                    
                                    
                                    if let urlBookmark = prax.importEditingURLBookmark {
                                        Text("Preview:")
                                        Text("URL: \(urlBookmark.url.lastPathComponent)")
                                        HStack(spacing: 12) {
                                            Text(imageOptions.sizingMode.rawValue)
                                        }
                                        
                                    }
                                    
                                    
                                }
                                
                                Spacer()
                                
                                Image(nsImage: previewImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing) }
                        }
                        
                        ScrollView {
                            
                            
                            GroupBox("Import Size") {
                                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                                    GridRow {
                                        Text("Size Limit:")
                                        HStack {
                                            TextField("", value: $imageOptions.sizeLimitKB, format: .number)
                                                .frame(width: 90)
                                            Text("KB")
                                        }
                                    }
                                    
                                    GridRow {
                                        Text("Limit By:")
                                        Picker("", selection: $imageOptions.sizingMode) {
                                            Text("File Size").tag(ImportSizingMode.fileSizeLimit)
                                            Text("PDF Inches").tag(ImportSizingMode.targetInches)
                                        }
                                        .pickerStyle(.segmented)
                                    }
                                    
                                    if imageOptions.sizingMode == .fileSizeLimit {
                                        GridRow {
                                            Text("Size Limit:")
                                            HStack {
                                                TextField("", value: $imageOptions.sizeLimitKB, format: .number)
                                                    .frame(width: 90)
                                                Text("KB")
                                            }
                                        }
                                        
                                        GridRow {
                                            Text("Scale Down:")
                                            HStack {
                                                Slider(value: $imageOptions.scaleDown, in: 0.1...1.0, step: 0.01)
                                                Text("\(Int(imageOptions.scaleDown * 100))%")
                                                    .frame(width: 50, alignment: .trailing)
                                            }
                                        }
                                    } else {
                                        GridRow {
                                            Text("PDF Width:")
                                            HStack {
                                                TextField("", value: $imageOptions.targetWidthInches, format: .number.precision(.fractionLength(0...2)))
                                                    .frame(width: 90)
                                                Text("in")
                                            }
                                        }
                                        
                                        GridRow {
                                            Text("PDF Height:")
                                            HStack {
                                                TextField("", value: $imageOptions.targetHeightInches, format: .number.precision(.fractionLength(0...2)))
                                                    .frame(width: 90)
                                                Text("in")
                                            }
                                        }
                                    }
                                    
                                    
                                    GridRow {
                                        Text("Scale Down:")
                                        HStack {
                                            Slider(value: $imageOptions.scaleDown, in: 0.1...1.0, step: 0.01)
                                            Text("\(Int(imageOptions.scaleDown * 100))%")
                                                .frame(width: 50, alignment: .trailing)
                                        }
                                    }
                                    
                                    GridRow {
                                        Text("Original:")
                                        Text(pxText(sourceImageSize))
                                            .font(.system(.caption, design: .monospaced))
                                    }
                                    GridRow {
                                        Text("After Resize:")
                                        Text(pxText(outputImageSize))
                                            .font(.system(.caption, design: .monospaced))
                                    }
                                    GridRow {
                                        Text("PDF Page Size:")
                                        Text(inchesText(outputInches))
                                            .font(.system(.caption, design: .monospaced))
                                    }
                                    GridRow {
                                        Text("Est. PDF Size:")
                                        Text(estimatedSizeText)
                                            .font(.system(.caption, design: .monospaced))
                                    }
                                }
                            }
                            
                            
                            
                            
                            GroupBox("Crop (%)") {
                                VStack {
                                    HStack {
                                        Text("Left")
                                        Slider(value: cropLeftBinding, in: 0...0.9, step: 0.01)
                                        Text("\(Int(imageOptions.cropLeft * 100))").frame(width: 36, alignment: .trailing)
                                    }
                                    HStack {
                                        Text("Right")
                                        Slider(value: cropRightBinding, in: 0...0.9, step: 0.01)
                                        Text("\(Int(imageOptions.cropRight * 100))").frame(width: 36, alignment: .trailing)
                                    }
                                    HStack {
                                        Text("Top")
                                        Slider(value: cropTopBinding, in: 0...0.9, step: 0.01)
                                        Text("\(Int(imageOptions.cropTop * 100))").frame(width: 36, alignment: .trailing)
                                    }
                                    HStack {
                                        Text("Bottom")
                                        Slider(value: cropBottomBinding, in: 0...0.9, step: 0.01)
                                        Text("\(Int(imageOptions.cropBottom * 100))").frame(width: 36, alignment: .trailing)
                                    }
                                }
                            }
                            
                            
                            
                            GroupBox("Adjustments") {
                                VStack {
                                    HStack {
                                        Text("Brightness")
                                        Slider(value: $imageOptions.brightness, in: -0.5...0.5, step: 0.01)
                                        Text(imageOptions.brightness, format: .number.precision(.fractionLength(2)))
                                            .frame(width: 52, alignment: .trailing)
                                    }
                                    HStack {
                                        Text("Contrast")
                                        Slider(value: $imageOptions.contrast, in: 0.5...2.0, step: 0.01)
                                        Text(imageOptions.contrast, format: .number.precision(.fractionLength(2)))
                                            .frame(width: 52, alignment: .trailing)
                                    }
                                    HStack {
                                        Text("Exposure")
                                        Slider(value: $imageOptions.exposure, in: -2.0...2.0, step: 0.01)
                                        Text(imageOptions.exposure, format: .number.precision(.fractionLength(2)))
                                            .frame(width: 52, alignment: .trailing)
                                    }
                                    HStack {
                                        Text("Sharpness")
                                        Slider(value: $imageOptions.sharpness, in: 0.0...2.0, step: 0.01)
                                        Text(imageOptions.sharpness, format: .number.precision(.fractionLength(2)))
                                            .frame(width: 52, alignment: .trailing)
                                    }
                                }
                            }
                            
                            
                            
                        }
                        
                    }
                }
                
                
                
                else {
                    Text("No preview available")
                    //        .frame(maxWidth: .infinity, minHeight: 220)
                }
                
                
                
                HStack {
                    Button("Reset Controls") {
                        imageOptions = .neutral
                    }
                    Spacer()
                    Button("Cancel") {
                        closeInspector()
                    }
                    
                    Button("Save Settings") {
                        SettingsModel.shared.imageImportOptions = imageOptions
                        pageItem.imageOptions = imageOptions
                        closeInspector()
                    }
                    
                    Button("Import Image") {
                        guard !importInProgress else { return }
                        guard let urlBookmark = prax.importEditingURLBookmark else {
                            closeInspector()
                            return
                        }
                        
                        importInProgress = true
                        defer { importInProgress = false }
                        
            //            prax.addPageFromImageURL(url, at: prax.importDropIndexPath, options: imageOptions)
                         
                        
                        
                        
                        closeInspector()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(importInProgress)
                }
            }
            .padding(20)
       //     .frame(minWidth: prax.importEditorMinWidth, idealWidth: prax.importEditorMaxWidth, maxWidth: prax.importEditorMaxWidth, maxHeight: .infinity, alignment: .init(horizontal: .leading, vertical: .top))
       //     .animation(.easeIn(duration: 1.25), value: prax.importEditorMinWidth)
       //     .animation(.easeIn(duration: 1.25), value: prax.importEditorMaxWidth)
            .background(.clear).ignoresSafeArea(edges: .all)
            .foregroundColor(.white)
            .onAppear {
                if let options = pageItem.imageOptions {
                    imageOptions = options
                }
                refreshPreview() }
            .onChange(of: pageItem) { refreshPreview() }
            .onChange(of: prax.showingImportEditor ) {
                if prax.showingImportEditor {
                    refreshPreview()
                }
                
            }
            .onChange(of: imageOptions) { refreshPreview() }    }
        else {
            EmptyView()
        }

        

    }
    
    private func closeInspector() {
        prax.clearImageInspectorState()
        dismiss()
    }
    
    private func imageSize(of image: NSImage) -> CGSize {
        if let rep = image.representations.compactMap({ $0 as? NSBitmapImageRep }).first {
            return CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
        }
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            return CGSize(width: cg.width, height: cg.height)
        }
        return image.size
    }
    
    private func pxText(_ size: CGSize) -> String {
        guard size.width > 0, size.height > 0 else { return "—" }
        return "\(Int(size.width)) × \(Int(size.height)) px"
    }
    
    private func inchesText(_ size: CGSize) -> String {
        guard size.width > 0, size.height > 0 else { return "—" }
        return String(format: "%.2f × %.2f in", size.width, size.height)
    }
    
    private var estimatedSizeText: String {
        guard let estimatedPDFKB else { return "—" }
        return "\(estimatedPDFKB) KB"
    }
    
    private func clearPreviewImage() {
        previewImage = nil
        sourceImageSize = .zero
        outputImageSize = .zero
        outputInches = .zero
        estimatedPDFKB = nil
        loadedURLForSource = nil
    }
    
    private func refreshPreview() {
        print("Prax: refresh preview")
        
        guard let pageItem = prax.selectedPageItem else { clearPreviewImage(); return }
        
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: pageItem.sourceBookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
        else {  print("addPagesFromPDFURL - Error resolvingBookmarkData for PageItem ", pageItem.name) ; return  }
        let needsStop = url.startAccessingSecurityScopedResource(); defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
        if loadedURLForSource != url { loadedURLForSource = url }
        
        guard let image = NSImage(contentsOf: url)
        else { PraxLogger.shared.logError("Import Source Error", category: .import)
            let error = NSError(domain: "FileImporting", code: -1, userInfo: [ NSLocalizedDescriptionKey: "Error reading source image file" ])
            let praxError = PraxError.fileImportFailed(fileName: url.absoluteString, underlyingError: error)
            prax.presentError(praxError)
            clearPreviewImage(); return
        }
        
        sourceImageSize = imageSize(of: image)
        
        previewImage = prax.processedImageFromURL(url, imageOptions: imageOptions)
        
        guard let previewImage else {
            PraxLogger.shared.logError("Import Source Error", category: .import)
            let error = NSError(domain: "FileImporting", code: -1, userInfo: [ NSLocalizedDescriptionKey: "Error applying Image Optiions" ])
            let praxError = PraxError.fileImportFailed(fileName: url.absoluteString, underlyingError: error)
            prax.presentError(praxError)
            clearPreviewImage()
            return
        }
        
        outputImageSize = imageSize(of: previewImage)
        
        if let page = PDFPage(image: previewImage) {
            let bounds = page.bounds(for: .mediaBox)
            outputInches = CGSize(width: bounds.width / 72.0, height: bounds.height / 72.0)
            
            let doc = PDFDocument()
            doc.insert(page, at: 0)
            if let data = doc.dataRepresentation() {
                estimatedPDFKB = Int(ceil(Double(data.count) / 1024.0))
            } else {
                estimatedPDFKB = nil
            }
        } else {
            outputInches = .zero
            estimatedPDFKB = nil
        }
   }
}
