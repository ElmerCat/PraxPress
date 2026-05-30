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
    
    @AppStorage("import-sizing-mode") private var importSizingModeRaw: String = PraxModel.ImportSizingMode.fileSizeLimit.rawValue
    @AppStorage("import-size-limit") private var importSizeLimitKB: Int = 1024
    @AppStorage("import-target-width-inches") private var importTargetWidthInches: Double = 0
    @AppStorage("import-target-height-inches") private var importTargetHeightInches: Double = 0
    
    @State private var imageAngle = 0.0
    //  @State private var options = PraxModel.ImageImportOptions()
    @State private var previewImage: NSImage?
    
    @State private var sourcePixelSize: CGSize = .zero
    @State private var outputPixelSize: CGSize = .zero
    @State private var outputInches: CGSize = .zero
    @State private var estimatedPDFKB: Int?
    @State private var loadedURLForSource: URL?
    @State private var importInProgress = false
    
    private let minRemainingCrop = 0.05
    
    /*    private var importSizingMode: PraxModel.ImportSizingMode {
     get { PraxModel.ImportSizingMode(rawValue: importSizingModeRaw) ?? .fileSizeLimit }
     set { importSizingModeRaw = newValue.rawValue }
     }
     
     private var importSizingModeBinding: Binding<PraxModel.ImportSizingMode> {
     Binding(
     get: { importSizingMode },
     set: { importSizingMode = $0 }
     )
     }
     */
    /*
     private var effectiveOptions: PraxModel.ImageImportOptions {
     var o = options
     o.sizingMode = prax.importImageOptions.sizingMode
     
     switch prax.importImageOptions.sizingMode {
     case .fileSizeLimit:
     o.sizeLimitKB = importSizeLimitKB > 0 ? importSizeLimitKB : nil
     o.targetWidthInches = nil
     o.targetHeightInches = nil
     
     case .targetInches:
     o.sizeLimitKB = nil
     o.targetWidthInches = importTargetWidthInches > 0 ? importTargetWidthInches : nil
     o.targetHeightInches = importTargetHeightInches > 0 ? importTargetHeightInches : nil
     
     }
     
     return o
     }
     */
    
    private var cropLeftBinding: Binding<Double> { Binding( get: { prax.importImageOptions.cropLeft },
            set: { prax.importImageOptions.cropLeft = min($0, 1 - minRemainingCrop - prax.importImageOptions.cropRight) } ) }
    private var cropRightBinding: Binding<Double> {Binding(get: { prax.importImageOptions.cropRight },
            set: { prax.importImageOptions.cropRight = min($0, 1 - minRemainingCrop - prax.importImageOptions.cropLeft) } )}
    private var cropTopBinding: Binding<Double> { Binding( get: { prax.importImageOptions.cropTop },
            set: { prax.importImageOptions.cropTop = min($0, 1 - minRemainingCrop - prax.importImageOptions.cropBottom) }) }
    private var cropBottomBinding: Binding<Double> {Binding( get: { prax.importImageOptions.cropBottom },set: { prax.importImageOptions.cropBottom = min($0, 1 - minRemainingCrop - prax.importImageOptions.cropTop) } ) }
    
    struct SourceInfoBox: View {
        @Bindable var prax: PraxModel
        
        var body: some View {
            VStack(spacing: 12) {
                
                
                
                Text("Preview:")
                Text("URL: \(prax.importSourceURL?.lastPathComponent ?? "no URL")")
                HStack(spacing: 12) {
                    Text(prax.importImageOptions.sizingMode.rawValue)
                }
            }
        }
    }
    
    var body: some View {
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
            
            let titleString = "Preview — Import URL: \(prax.importSourceURL?.lastPathComponent ?? "no URL"  )" + "  Size:  \(pxText(sourcePixelSize))"
            
            if let previewImage {
                VSplitView {
                     GroupBox(titleString) {
                        HStack {
                            SourceInfoBox(prax: prax)
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
                                        TextField("", value: $importSizeLimitKB, format: .number)
                                            .frame(width: 90)
                                        Text("KB")
                                    }
                                }
                                
                                GridRow {
                                    Text("Limit By:")
                                    Picker("", selection: $prax.importImageOptions.sizingMode) {
                                        Text("File Size").tag(PraxModel.ImportSizingMode.fileSizeLimit)
                                        Text("PDF Inches").tag(PraxModel.ImportSizingMode.targetInches)
                                    }
                                    .pickerStyle(.segmented)
                                }
                                
                                if prax.importImageOptions.sizingMode == .fileSizeLimit {
                                    GridRow {
                                        Text("Size Limit:")
                                        HStack {
                                            TextField("", value: $importSizeLimitKB, format: .number)
                                                .frame(width: 90)
                                            Text("KB")
                                        }
                                    }
                                    
                                    GridRow {
                                        Text("Scale Down:")
                                        HStack {
                                            Slider(value: $prax.importImageOptions.scaleDown, in: 0.1...1.0, step: 0.01)
                                            Text("\(Int(prax.importImageOptions.scaleDown * 100))%")
                                                .frame(width: 50, alignment: .trailing)
                                        }
                                    }
                                } else {
                                    GridRow {
                                        Text("PDF Width:")
                                        HStack {
                                            TextField("", value: $importTargetWidthInches, format: .number.precision(.fractionLength(0...2)))
                                                .frame(width: 90)
                                            Text("in")
                                        }
                                    }
                                    
                                    GridRow {
                                        Text("PDF Height:")
                                        HStack {
                                            TextField("", value: $importTargetHeightInches, format: .number.precision(.fractionLength(0...2)))
                                                .frame(width: 90)
                                            Text("in")
                                        }
                                    }
                                }
                                
                                
                                GridRow {
                                    Text("Scale Down:")
                                    HStack {
                                        Slider(value: $prax.importImageOptions.scaleDown, in: 0.1...1.0, step: 0.01)
                                        Text("\(Int(prax.importImageOptions.scaleDown * 100))%")
                                            .frame(width: 50, alignment: .trailing)
                                    }
                                }
                                
                                GridRow {
                                    Text("Original:")
                                    Text(pxText(sourcePixelSize))
                                        .font(.system(.caption, design: .monospaced))
                                }
                                GridRow {
                                    Text("After Resize:")
                                    Text(pxText(outputPixelSize))
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
                                    Text("\(Int(prax.importImageOptions.cropLeft * 100))").frame(width: 36, alignment: .trailing)
                                }
                                HStack {
                                    Text("Right")
                                    Slider(value: cropRightBinding, in: 0...0.9, step: 0.01)
                                    Text("\(Int(prax.importImageOptions.cropRight * 100))").frame(width: 36, alignment: .trailing)
                                }
                                HStack {
                                    Text("Top")
                                    Slider(value: cropTopBinding, in: 0...0.9, step: 0.01)
                                    Text("\(Int(prax.importImageOptions.cropTop * 100))").frame(width: 36, alignment: .trailing)
                                }
                                HStack {
                                    Text("Bottom")
                                    Slider(value: cropBottomBinding, in: 0...0.9, step: 0.01)
                                    Text("\(Int(prax.importImageOptions.cropBottom * 100))").frame(width: 36, alignment: .trailing)
                                }
                            }
                        }
                        
                        GroupBox("Adjustments") {
                            VStack {
                                HStack {
                                    Text("Brightness")
                                    Slider(value: $prax.importImageOptions.brightness, in: -0.5...0.5, step: 0.01)
                                    Text(prax.importImageOptions.brightness, format: .number.precision(.fractionLength(2)))
                                        .frame(width: 52, alignment: .trailing)
                                }
                                HStack {
                                    Text("Contrast")
                                    Slider(value: $prax.importImageOptions.contrast, in: 0.5...2.0, step: 0.01)
                                    Text(prax.importImageOptions.contrast, format: .number.precision(.fractionLength(2)))
                                        .frame(width: 52, alignment: .trailing)
                                }
                                HStack {
                                    Text("Exposure")
                                    Slider(value: $prax.importImageOptions.exposure, in: -2.0...2.0, step: 0.01)
                                    Text(prax.importImageOptions.exposure, format: .number.precision(.fractionLength(2)))
                                        .frame(width: 52, alignment: .trailing)
                                }
                                HStack {
                                    Text("Sharpness")
                                    Slider(value: $prax.importImageOptions.sharpness, in: 0.0...2.0, step: 0.01)
                                    Text(prax.importImageOptions.sharpness, format: .number.precision(.fractionLength(2)))
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
                    prax.importImageOptions = .neutral
                }
                Spacer()
                Button("Cancel") {
                    closeInspector()
                }
                Button("Import Image") {
                    guard !importInProgress else { return }
                    guard let url = prax.importSourceURL else {
                        closeInspector()
                        return
                    }
                    
                    importInProgress = true
                    defer { importInProgress = false }
                    
                    prax.addPageFromImageURL(
                        url,
                        at: prax.importDropIndexPath,
                        options: prax.importImageOptions)
                    closeInspector()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(importInProgress)
            }
        }
        .padding(20)
        .frame(minWidth: 620, maxWidth: .infinity, minHeight: 780, maxHeight: .infinity)
        .background(.clear).ignoresSafeArea(edges: .all)
        .foregroundColor(.white)
        .onAppear { refreshPreview() }
        .onChange(of: prax.importSourceURL) { refreshPreview() }
        .onChange(of: prax.importImageOptions) { refreshPreview() }
        .onChange(of: importSizingModeRaw) { refreshPreview() }
        .onChange(of: importSizeLimitKB) { refreshPreview() }
        .onChange(of: importTargetWidthInches) { refreshPreview() }
        .onChange(of: importTargetHeightInches) { refreshPreview() }
    }
    
    private func closeInspector() {
        prax.clearImageInspectorState()
        dismiss()
    }
    
    private func pixelSize(of image: NSImage) -> CGSize {
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
    
    private func refreshPreview() {
        print("Prax: refresh preview")
        guard let url = prax.importSourceURL else {
            previewImage = nil
            sourcePixelSize = .zero
            outputPixelSize = .zero
            outputInches = .zero
            estimatedPDFKB = nil
            loadedURLForSource = nil
            return
        }
        
        if loadedURLForSource != url {
            loadedURLForSource = url
            if let src = NSImage(contentsOf: url) {
                sourcePixelSize = pixelSize(of: src)
            } else {
                sourcePixelSize = .zero
            }
        }
        
        previewImage = prax.processedImageFromURL(url, options: prax.importImageOptions)
        
        guard let previewImage else {
            outputPixelSize = .zero
            outputInches = .zero
            estimatedPDFKB = nil
            return
        }
        
        outputPixelSize = pixelSize(of: previewImage)
        
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
