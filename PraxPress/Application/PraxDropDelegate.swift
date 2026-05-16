//
//  PraxDropDelegate.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/18/26.
//

import SwiftUI
import UniformTypeIdentifiers
import PDFKit



extension NSPasteboard.PasteboardType {
    static let pdfPageDragType = NSPasteboard.PasteboardType("com.praxpress.pdf-page-item")
    static let mergedPageType = NSPasteboard.PasteboardType("com.praxpress.pdf-page-section")
    static let pdfFileType = NSPasteboard.PasteboardType("com.praxpress.pdf-file-item")
}

extension UTType {
    static let pdfPageDragType = UTType(exportedAs: "com.praxpress.pdf-page-item")
    static let mergedPageType = UTType(exportedAs: "com.praxpress.pdf-page-section")
    static let pdfFileType = UTType(exportedAs: "com.praxpress.pdf-file-item")
}

final class PraxDropDelegate: DropDelegate {
    var document: MergedPDFDocument
    var prax: PraxModel
    
    init(_ document: MergedPDFDocument, _ praxModel: PraxModel) {
        self.document = document
        self.prax = praxModel
    }
    
    func dropEntered(info: DropInfo) {
        print("DropTargetControl - dropEntered")    }

    
    func validateDrop(info: DropInfo) -> Bool {
        print("DropTargetControl - validateDrop")
        
        if info.hasItemsConforming(to: [.pdfPageDragType, .mergedPageType]) {
            print("DropTargetControl - dropUpdated - hasItemsConforming(to: [.pdfPageDragType, .mergedPageType])")
            return false
        }
        else {
            prax.dropTargeted = true
            return true
        }
    }
    
    func performDrop(info: DropInfo) -> Bool { //  print("DropTargetControl - performDrop")
        prax.dropTargeted = false

        if info.hasItemsConforming(to: [.pdfFileType]) {
           for provider in info.itemProviders(for: [UTType.pdfFileType]) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.pdfFileType.identifier) { [self] (data, error) in
                    if let data = data {  Task {  struct Payload: Codable {
                        let fileURL: URL
                        let bookmarkData: Data }; do {
                        let payload = try JSONDecoder().decode(Payload.self, from: data)
                            await prax.receiveDroppedURL(payload.fileURL, bookmarkData: payload.bookmarkData) }
                        catch { print("failed to decode Payload ") } }}
                    else { print("no data for forTypeIdentifier: UTType.pdfFileType.identifier")}}}}
        
        else if info.hasItemsConforming(to: [.fileURL]) {
            for provider in info.itemProviders(for: [UTType.fileURL]) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { [self] (data, error) in
                    if let data = data,
                       let path = String(data: data, encoding: .utf8),
                       let url = URL(string: path) {
                       print("Julie Belanger path = ", path, "  URL: ", url)
                        prax.receiveDroppedURL(url) }}}}

        else { return false }
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
  //      print("DropTargetControl - dropUpdated - phase: ")
        
        if info.hasItemsConforming(to: [.pdfPageDragType]) {
  //          print("DropTargetControl - dropUpdated - hasItemsConforming(to: [.pdfPageDragType])")
            return DropProposal(operation: .forbidden)
            
        }
        else if info.hasItemsConforming(to: [.mergedPageType]) {
  //          print("DropTargetControl - dropUpdated - hasItemsConforming(to: [.mergedPageType])")
            return DropProposal(operation: .forbidden)
            
        }
        else if info.hasItemsConforming(to: [.pdfFileType]) {
  //          print("DropTargetControl - dropUpdated - hasItemsConforming(to: [.pdfFileType])")
            return DropProposal(operation: .copy)
            
        }
        else if info.hasItemsConforming(to: [UTType.fileURL]) {
    //        print("DropTargetControl - dropUpdated - hasItemsConforming(to: [UTType.fileURL])")
            return DropProposal(operation: .copy)
        }
        else {
            print("DropTargetControl - dropUpdated - else ")
            return DropProposal(operation: .forbidden)
        }
    }
    
    func dropExited(info: DropInfo) {
        print("DropTargetControl - dropExited")
        prax.dropTargeted = false
    }
    



}
struct ImageInspectingPopover: View {
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

    private var cropLeftBinding: Binding<Double> {
        Binding(
            get: { prax.importImageOptions.cropLeft },
            set: { prax.importImageOptions.cropLeft = min($0, 1 - minRemainingCrop - prax.importImageOptions.cropRight) }
        )
    }

    private var cropRightBinding: Binding<Double> {
        Binding(
            get: { prax.importImageOptions.cropRight },
            set: { prax.importImageOptions.cropRight = min($0, 1 - minRemainingCrop - prax.importImageOptions.cropLeft) }
        )
    }

    private var cropTopBinding: Binding<Double> {
        Binding(
            get: { prax.importImageOptions.cropTop },
            set: { prax.importImageOptions.cropTop = min($0, 1 - minRemainingCrop - prax.importImageOptions.cropBottom) }
        )
    }

    private var cropBottomBinding: Binding<Double> {
        Binding(
            get: { prax.importImageOptions.cropBottom },
            set: { prax.importImageOptions.cropBottom = min($0, 1 - minRemainingCrop - prax.importImageOptions.cropTop) }
        )
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

                    Text("Image Drop Inspector")
                    Spacer()
                    Toggle("Test on Next Drop", isOn: $prax.inspectNextImageDrop)
                        .toggleStyle(.switch)
                }
            }

            GroupBox("Preview") {
                ZStack {
                    if let previewImage {
                        Image(nsImage: previewImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 320)
                    } else {
                        Text("No preview available")
                            .frame(maxWidth: .infinity, minHeight: 220)
                    }
                }
            }

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
                    guard let url = prax.inspectingImageURL else {
                        closeInspector()
                        return
                    }

                    importInProgress = true
                    defer { importInProgress = false }

                    prax.addPageFromImageURL(
                        url,
                        at: prax.inspectingImageDropIndexPath,
                        options: prax.importImageOptions)
                    closeInspector()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(importInProgress)
            }
        }
        .padding(20)
        .frame(minWidth: 620, minHeight: 780)
        .background(PraxGradient(0).ignoresSafeArea())
        .foregroundColor(.white)
        .onAppear { refreshPreview() }
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
        guard let url = prax.inspectingImageURL else {
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



class FilePromiseProvider: NSFilePromiseProvider, NSFilePromiseProviderDelegate {
    
    var pdfDocument: PDFDocument?
    var fileName: String = "PraxPress-Prax.pdf"
    
    struct UserInfoKeys {
        static let indexPathKey = "indexPath"
        static let urlKey = "url"
    }
    
    override func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        var types = super.writableTypes(for: pasteboard)
        types.append(.pdfPageDragType) // Add our own internal drag type (row drag and drop reordering).
        types.append(.mergedPageType) // Add our own internal drag type (row drag and drop reordering).
        types.append(.fileURL) // Add the .fileURL drag type (to promise files to other apps).
        return types
    }
    
    override func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        guard let userInfoDict = userInfo as? [String: Any] else { return nil }
        switch type {
        case .fileURL:
            // Incoming type is "public.file-url", return (from our userInfo) the item's URL.
            if let url = userInfoDict[FilePromiseProvider.UserInfoKeys.urlKey] as? NSURL {
                return url.pasteboardPropertyList(forType: type)
            }
        case .mergedPageType:
            print ("mergedPageType")
            // Incoming type is "com.mycompany.mydragdrop", return (from our userInfo) the item's indexPath.
            let indexPathData = userInfoDict[FilePromiseProvider.UserInfoKeys.indexPathKey]
            return indexPathData

        case .pdfPageDragType:
            // Incoming type is "com.mycompany.mydragdrop", return (from our userInfo) the item's indexPath.
            let indexPathData = userInfoDict[FilePromiseProvider.UserInfoKeys.indexPathKey]
            return indexPathData
        default:
            break
        }
        return super.pasteboardPropertyList(forType: type)
    }
    
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        
        print("filePromiseProvider fileNameForType: ", fileType)
        return fileName
    }
    
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL) async throws {
        
        print("filePromiseProvider writePromiseTo url:  ", url)
        pdfDocument?.write(to: url)
        
    }
    
}


struct DropTargetControl: View {
    @Environment(MergedPDFDocument.self) var document
    @Environment(PraxModel.self) private var praxModel
    
    var body: some View {
        @Bindable var prax = praxModel
        
        Group {
            HStack {
                Spacer(minLength: 25)
                Text("   Drop Files Here   ")
                    .font(.headline)
                    .padding(.vertical, 10)
                
                    .foregroundStyle(.white)
                
                    .contentShape(.rect)
                
                Button {
                    prax.showingFileImportOptions.toggle()
                } label: {
                    Label("Import Options", systemImage: (prax.showingMergedDocumentInspector ? "gearshape.fill" : "gearshape"))
                }
                .sheet(isPresented: $prax.showingFileImportOptions) {
                    ImportOptionsInspector()
                    
                        .presentationDetents(
                            [.height(120), .medium, .large])
                        .presentationBackgroundInteraction(
                            .enabled(upThrough: .height(120)))
                        .presentationSizing(.form)
                    
                    
                }
                Spacer(minLength: 25)
            }.background {
                Capsule()
                    .foregroundStyle(prax.dropTargeted ? Color.green.gradient : Color.blue.gradient )
            }
        }
        .popover(isPresented: $prax.showingImageDropInspector) { ImageInspectingPopover() }
        
        .onDrop(of: [.fileURL, .pdfFileType, .mergedPageType, .pdfPageDragType], delegate: PraxDropDelegate(document, prax))
        
        
    }
}





struct DragOutControl: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    @FocusState private var isFocused: Bool
    // 2. Track the text selection
    @State private var selection: TextSelection?
    
    var body: some View {
        @Bindable var prax = praxModel
        
        Group {
            HStack {
                Spacer(minLength: 25)
                Text("Drag out")
                    .font(.headline)
                    .padding(.vertical, 10)
                
                    .foregroundStyle(.white)
                
                    .contentShape(.rect)
                
                Spacer(minLength: 5)
                Image(systemName: "arrow.right.doc.on.clipboard")
                
                Spacer(minLength: 5)
                Text(String("\(document.exportFilename).pdf"))
                    .font(.system(size: 10, weight: .ultraLight, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .init(horizontal: .center, vertical: .center))

                Spacer(minLength: 25)
            }
            .draggable({ () -> MergedPDFTransfer? in
                guard let data = document.mergedPDFDocument.dataRepresentation() else { return nil }
                return MergedPDFTransfer(data: data, filename: document.exportFilename)
            }()!, preview: {
                PraxDragPreview()
            })
            
            
            .background {
                Capsule()
                    .foregroundStyle(Color.blue.gradient)
            }
        }
        
        .onAppear {
           
            isFocused = true
        }

    }
}



struct PraxDragPreview: View {
    @Environment(PraxModel.self) var prax: PraxModel
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @State private var rotate = false
    
    let frameSize = CGSize(width: 120, height: 160)
    
    var body: some View {
        

        
        if document.mergedPDFDocument.pageCount > 0 {
            GroupBox {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(prax.annotationSaveMode.color.opacity(0.75))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.yellow, lineWidth: 2)
                        )
                        .frame(width: frameSize.width, height: frameSize.height - 30)
                    

                    Image(nsImage: document.mergedPDFDocument.page(at: 0)!.thumbnail(of: frameSize, for: .cropBox))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(6)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .frame(width: frameSize.width - 5, height: frameSize.height - 30, alignment: .trailing)
                    
                    VStack {
                        HStack {
                            Image("PraxPress")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: frameSize.width - 60, height: frameSize.height - 80, alignment: .leading)
                                .rotationEffect(.degrees(180))
        //                        .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(prax.annotationSaveMode.color)
                        //        .animation(.easeInOut(duration: 1), value: rotate)
                        //        .onAppear {
                        //            rotate = true
                        //        }
                            
                            Spacer()
                        }
                        
                        
                        
                       Spacer()
                        
                        Text("\(document.exportFilename).pdf")
                            .font(.footnote)
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                          //  .frame(maxWidth: .infinity, alignment: .bottom)
                            .background {
                                Capsule()
                                    .foregroundStyle(Color.blue.gradient)
                            }
                        
                    }
                    
                    
                }
            }
            .frame(width: frameSize.width, height: frameSize.height)
        }
        else {
            EmptyView()
        }
    }
}

#Preview {
    PraxDragPreview()
}
