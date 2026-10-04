//
//  ImageImportEditor.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/29/26.
//

struct FooterView: View {
    @Environment(PraxModel.self) private var prax
    @Environment(\.groupHovering) private var groupHovering
    
    @State private var hovering: Bool = false
    
    func scaleView(_ direction: PDFDisplayDirection) {
        if direction == .vertical {
            let scale = prax.mergedViewSize.height / prax.document.totalHeight
            prax.mergedViewScaleFactor = scale
        }
        else {
            let scale = prax.mergedViewSize.width / prax.document.maxWidth
            prax.mergedViewScaleFactor = scale
        }
    }
    
    var body: some View {
        @Bindable var prax = prax
        HStack {
            
            Button { scaleView(.vertical) }
            label: {  Image(systemName: "arrow.up.and.down.square") }
                .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 31))
                .onHover { hovering in prax.hoveredButton = hovering ? 31 : nil }
                .help("Fit Horizontally")
            
            Text("\(Int(prax.mergedViewScaleFactor * 100))%")
                .font(.callout).foregroundStyle(Color.black)
                .padding(.leading, 20)
            
            Slider(value: $prax.mergedViewScaleFactor, in: 0.1...2.0)
                .frame(width: 100)
                .padding(.leading, 20)
            
            Button { scaleView(.horizontal) }
            label: {  Image(systemName: "arrow.left.and.right.square") }
                .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 32))
                .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                .help("Fit Horizontally")
        }
        .frame(minHeight: 10)
        .padding(10)
        .onHover { isHovering in hovering = isHovering }
        .environment(\.groupHovering, hovering)
        //    .background(PraxGradient(hovering ? 0 : 4))
        //    .opacity(groupHovering ? 1 : 0.1)
        
        
    }
}



/*
 static func scalePDFViewToFit(pdfView: PDFView) {
 if let pdfPage = pdfView.currentPage {
 let bounds = pdfPage.bounds(for: .mediaBox)
 let scaleFactor = pdfView.frame.height / bounds.height
 if pdfView.frame.width > bounds.width * scaleFactor {
 //             print ("Bounds: ", bounds.width, " wide x ", bounds.height, " high - frame w: ", pdfView.frame.width, " - h:", pdfView.frame.height, " scale: ", pdfView.scaleFactor, " to: ", scaleFactor)
 pdfView.scaleFactor = scaleFactor
 }
 else {
 pdfView.autoScales = true
 //               print ("Bounds: ", bounds.width, " wide x ", bounds.height, " high - frame w: ", pdfView.frame.width, " - h:", pdfView.frame.height, " scale: ", pdfView.scaleFactor, " to: autoScales = true")
 }
 }
 }
 
 */
}



/*struct PDFPageItemInspector: View {
 //  @Environment(MergedPDFDocument.self) var document
 @Environment(PraxModel.self) private var praxModel
 
 var body: some View {
 @Bindable var prax = praxModel
 VStack {
 GroupBox {
 
 Text("Inspector 1")
 .frame(minWidth: 100, maxWidth: 1000, maxHeight: .infinity)
 .background(.pink)
 }
 .padding(20)
 //  .background(.yellow)
 Button(prax.isLarge ? "Make Small" : "Make Large") {
 // Toggle the state when the button is tapped
 prax.isLarge.toggle()
 }
 Text("Inspector 2")
 //           .frame(maxWidth: .infinity, maxHeight: .infinity)
 //               .background(.purple)
 .background(.purple)
 }
 Text("Inspector 3")
 //    .frame(maxWidth: .infinity, maxHeight: .infinity)
 .inspectorColumnWidth(min: 50, ideal: 150, max: 500)
 .background(.gray)
 
 
 }
 }
 */



func dateFromPageItemDataField(_ pageItem: PreviewItem) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "M/d/yy" // Match your input string format
    return formatter.date(from:  ((pageItem.dataFields.contains(where: { $0.key == "Date" }) ? pageItem.dataFields["Date"]!.stringValue : "1/1/2026")!))
}



let filenameStyle = URL.FormatStyle(scheme: .never,
                                    user: .never,
                                    password: .never,
                                    host: .always,
                                    port: .never,
                                    path: .always,
                                    query: .never,
                                    fragment: .never)


extension PraxModel {
    
    
    
    
    
    
    
    // MARK: - Public import
    
    func addPageFromImageURL(
        _ url: URL,
        at indexPath: IndexPath? = nil,
        title: String? = nil,
        imageOptions: ImageImportOptions = .neutral
    ) {
        let mergedPage = prax.document.mergedPagefrom(url, at: indexPath)
        let pageInsertIndex = prax.document.normalizedInsertionIndex(
            count: mergedPage.pageItems.count,
            location: (indexPath?.item ?? 0) + 1
        )
        
        let effectiveOptions = resolvedImportOptions(imageOptions)
        
        guard let image = processedImageFromURL(url, imageOptions: effectiveOptions) else {
            assertionFailure("Failed to process image at \(url)")
            return
        }
        
        guard let pdfPage = PDFPage(image: image) else {
            assertionFailure("Failed to create PDFPage from processed image at \(url)")
            return
        }
        
        let pageItem = PageItem(
            prax: self,
            mergedPage: mergedPage,
            name: title ?? url.deletingPathExtension().lastPathComponent,
            sourceURL: url,
            pdfPage: pdfPage,
            imageOptions: imageOptions,
            dataFields: [:]
        )
        
        mergedPage.pageItems.insert(pageItem, at: pageInsertIndex)
    }
    
    /// New signature (size-limit based).
    func processedImageFromURL(_ url: URL, imageOptions: ImageImportOptions) -> NSImage? {
        guard let sourceImage = NSImage(contentsOf: url) else { return nil }
        return processedImage(sourceImage, imageOptions: resolvedImportOptions(imageOptions))
    }
    
    
    
    // MARK: - Core processing
    private static let imageCIContext = CIContext()
    private func processedImage(_ sourceImage: NSImage, imageOptions: ImageImportOptions) -> NSImage? {
        guard let tiff = sourceImage.tiffRepresentation,
              var ciImage = CIImage(data: tiff) else { return nil }
        
        // 1) Crop
        let crop = cropRect(for: ciImage.extent.size, imageOptions: imageOptions)
        ciImage = ciImage.cropped(to: crop)
        
        // 2) Adjustments
        ciImage = applyAdjustments(to: ciImage, imageOptions: imageOptions)
        
        // 3) Render CI -> NSImage
        let extent = ciImage.extent.integral
        guard let cgImage = Self.imageCIContext.createCGImage(ciImage, from: extent) else { return nil }
        var output = NSImage(cgImage: cgImage, size: NSSize(width: extent.width, height: extent.height))
        
        // 4) Size strategy
        switch imageOptions.sizingMode {
        case .fileSizeLimit:
            // Keep current manual downscale behavior
            let userScale = CGFloat(imageOptions.scaleDown).clamped(to: 0.05...1.0)
            if userScale < 0.999 {
                let px = pixelSize(of: output)
                let scaled = NSSize(
                    width: max(1, floor(px.width * userScale)),
                    height: max(1, floor(px.height * userScale))
                )
                output = output.resize(to: scaled) ?? output
            }
            
            if imageOptions.sizeLimitKB > 0 {
                output = downscaleToMeetPDFSizeLimit(output, targetKB: imageOptions.sizeLimitKB)
            }
            
        case .targetInches:
            output = scaleImageToTargetInches(
                output,
                targetWidthInches: imageOptions.targetWidthInches,
                targetHeightInches: imageOptions.targetHeightInches
            )
        }
        
        return output
    }
    
    private func scaleImageToTargetInches(
        _ image: NSImage,
        targetWidthInches: Double,
        targetHeightInches: Double
    ) -> NSImage {
        let px = pixelSize(of: image)
        let currentW = max(px.width, 1)
        let currentH = max(px.height, 1)
        
        // 0 or less means "not specified"
        let targetW: CGFloat? = targetWidthInches > 0 ? CGFloat(targetWidthInches * 72.0) : nil
        let targetH: CGFloat? = targetHeightInches > 0 ? CGFloat(targetHeightInches * 72.0) : nil
        
        guard targetW != nil || targetH != nil else { return image }
        
        let scale: CGFloat
        switch (targetW, targetH) {
        case let (.some(w), .some(h)):
            // preserve aspect ratio, fit inside requested bounds
            scale = min(w / currentW, h / currentH)
        case let (.some(w), nil):
            scale = w / currentW
        case let (nil, .some(h)):
            scale = h / currentH
        default:
            scale = 1.0
        }
        
        guard scale.isFinite, scale > 0 else { return image }
        
        let newSize = NSSize(
            width: max(1, floor(currentW * scale)),
            height: max(1, floor(currentH * scale))
        )
        
        return image.resize(to: newSize) ?? image
    }
    
    private func cropRect(for size: CGSize, imageOptions: ImageImportOptions) -> CGRect {
        let minRemainingFraction: CGFloat = 0.05
        
        let w = max(size.width, 1)
        let h = max(size.height, 1)
        
        let left = CGFloat(imageOptions.cropLeft).clamped(to: 0...0.95)
        let right = CGFloat(imageOptions.cropRight).clamped(to: 0...0.95)
        let top = CGFloat(imageOptions.cropTop).clamped(to: 0...0.95)
        let bottom = CGFloat(imageOptions.cropBottom).clamped(to: 0...0.95)
        
        let horizontalTrim = min(left + right, 1 - minRemainingFraction)
        let verticalTrim = min(top + bottom, 1 - minRemainingFraction)
        
        let effectiveRight = min(right, horizontalTrim - left)
        let effectiveTop = min(top, verticalTrim - bottom)
        
        let x = w * left
        let y = h * bottom
        let cw = max(1, w - w * (left + effectiveRight))
        let ch = max(1, h - h * (bottom + effectiveTop))
        
        return CGRect(x: x, y: y, width: cw, height: ch).integral
    }
    
    private func applyAdjustments(to image: CIImage, imageOptions: ImageImportOptions) -> CIImage {
        var output = image
        
        if imageOptions.brightness != 0 || imageOptions.contrast != 1 {
            let f = CIFilter(name: "CIColorControls")
            f?.setValue(output, forKey: kCIInputImageKey)
            f?.setValue(imageOptions.brightness, forKey: kCIInputBrightnessKey)
            f?.setValue(imageOptions.contrast, forKey: kCIInputContrastKey)
            f?.setValue(1.0, forKey: kCIInputSaturationKey)
            if let o = f?.outputImage { output = o }
        }
        
        if imageOptions.exposure != 0 {
            let f = CIFilter(name: "CIExposureAdjust")
            f?.setValue(output, forKey: kCIInputImageKey)
            f?.setValue(imageOptions.exposure, forKey: kCIInputEVKey)
            if let o = f?.outputImage { output = o }
        }
        
        if imageOptions.sharpness > 0 {
            let f = CIFilter(name: "CISharpenLuminance")
            f?.setValue(output, forKey: kCIInputImageKey)
            f?.setValue(imageOptions.sharpness, forKey: kCIInputSharpnessKey)
            if let o = f?.outputImage { output = o }
        }
        
        return output
    }
    
    // MARK: - Size-limit logic
    
    func resolvedImportOptions(_ imageOptions: ImageImportOptions) -> ImageImportOptions {
        // Convention:
        // - .neutral means "use app-wide defaults from prax.imageOptions"
        // - otherwise use explicit passed imageOptions
        if imageOptions == .neutral {
            return imageOptions
        }
        return imageOptions
    }
    
    /*
     private func storedImportSizingMode() -> ImportSizingMode {
     let defaults = UserDefaults.standard
     guard let raw = defaults.string(forKey: "import-sizing-mode"),
     let mode = ImportSizingMode(rawValue: raw) else {
     return .fileSizeLimit
     }
     return mode
     }
     
     private func storedImportTargetWidthInches() -> Double? {
     let defaults = UserDefaults.standard
     guard defaults.object(forKey: "import-target-width-inches") != nil else { return nil }
     let v = defaults.double(forKey: "import-target-width-inches")
     return v > 0 ? v : nil
     }
     
     private func storedImportTargetHeightInches() -> Double? {
     let defaults = UserDefaults.standard
     guard defaults.object(forKey: "import-target-height-inches") != nil else { return nil }
     let v = defaults.double(forKey: "import-target-height-inches")
     return v > 0 ? v : nil
     }
     
     private func storedImportSizeLimitKB() -> Int? {
     let defaults = UserDefaults.standard
     if defaults.object(forKey: "import-size-limit") == nil {
     return 1024 // default 1 MB
     }
     let value = defaults.integer(forKey: "import-size-limit")
     return value > 0 ? value : nil
     }
     */
    
    private func pixelSize(of image: NSImage) -> CGSize {
        if let rep = image.representations.compactMap({ $0 as? NSBitmapImageRep }).first {
            return CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
        }
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            return CGSize(width: cg.width, height: cg.height)
        }
        return image.size
    }
    
    private func estimatePDFSizeKB(for image: NSImage) -> Int? {
        guard let page = PDFPage(image: image) else { return nil }
        let doc = PDFDocument()
        doc.insert(page, at: 0)
        guard let data = doc.dataRepresentation() else { return nil }
        return Int(ceil(Double(data.count) / 1024.0))
    }
    
    private func downscaleToMeetPDFSizeLimit(_ image: NSImage, targetKB: Int) -> NSImage {
        guard targetKB > 0 else { return image }
        guard let startKB = estimatePDFSizeKB(for: image), startKB > targetKB else { return image }
        
        let px = pixelSize(of: image)
        let minScale: CGFloat = 0.05
        var lo = minScale
        var hi: CGFloat = 1.0
        var best: NSImage?
        
        for _ in 0..<10 { // binary search
            let mid = (lo + hi) / 2
            let candidateSize = NSSize(
                width: max(1, floor(px.width * mid)),
                height: max(1, floor(px.height * mid))
            )
            
            guard let candidate = image.resize(to: candidateSize),
                  let kb = estimatePDFSizeKB(for: candidate) else {
                hi = mid
                continue
            }
            
            if kb > targetKB {
                hi = mid
            } else {
                best = candidate
                lo = mid
            }
        }
        
        return best ?? image
    }
}


func cleanupTemporaryArtifacts() {
    print("\n\ncleanupTemporaryArtifacts()\n\n")
    
    /*        let fm = FileManager.default
     if let oldPreview = lastPreviewURL {
     try? fm.removeItem(at: oldPreview)
     lastPreviewURL = nil
     }
     if let oldCombined = lastCombinedSourceURL {
     try? fm.removeItem(at: oldCombined)
     lastCombinedSourceURL = nil
     }
     */
}

let pdfViewRegistry = PDFViewRegistry()

}



final class WeakPDFViewRef {
    weak var view: PDFView?
}

final class PDFViewRegistry {
    // Keyed by a stable id both the page and footer know.
    private var storage: [AnyHashable: WeakPDFViewRef] = [:]
    
    // Returns a stable ref object per id (creates if missing).
    func ref(for id: UUID) -> WeakPDFViewRef? {
        print( "ref for id:  ", id)
        if let existing = storage[id] {
            print("existing: ", existing)
            return existing
        }
        else { return nil }
    }
    
    
    // Optional: explicit setter when the page view gets a PDFView.
    func set(_ pdfView: PDFView, for id: AnyHashable) {
        if let existing = storage[id] {
            print("set existing for id: ", id)
            existing.view = pdfView
        }
        else {
            print("set new for id: ", id)
            let new = WeakPDFViewRef()
            new.view = pdfView
            storage[id] = new
        }
    }
    
    // Optional: housekeeping to remove entries whose weak view is gone.
    func pruneDeallocated() {
        storage = storage.filter { _, ref in ref.view != nil }
    }
}



struct PageItemTrimsView: View {
    //  @Environment(MergedPDFDocument.self) var document
    @Environment(PraxModel.self) private var praxModel
    var body: some View {
        @Bindable var prax = praxModel
        if let pageItem = prax.selectedPageItem {
            @Bindable var pageItem = pageItem
            GroupBox {
                HStack {
                    VStack {
                        Text("Top: \(pageItem.trims.top, specifier: "%.0f")")
                        Text("Left: \(pageItem.trims.left, specifier: "%.0f")")
                        Text("Right: \(pageItem.trims.right, specifier: "%.0f")")
                        Text("Bottom: \(pageItem.trims.bottom, specifier: "%.0f")")
                    }.font(.system(size: 8, weight: .ultraLight))
                    VStack {
                        Text("Set Width Guide").font(.system(size: 12, weight: .black))
                        Button { prax.document.clickedGuidePageButton(pageItem) }
                        label: { if pageItem.skipped {
                            Image(systemName: "ruler.fill")  }  else {
                                Image(systemName: "ruler") }
                        }
                        .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 235, isOn: prax.document.widthGuidePageID != nil))
                        .onHover { hovering in prax.hoveredButton = hovering ? 235 : nil }
                        .help("Set Width Guide")
                    }
                }
                
                .padding(.vertical, 10)
                .foregroundStyle(.white)
                .contentShape(.rect)
                .background {
                    RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                        .foregroundStyle(Color.prax)
                }
                
                
            }
            
            
            
            
            
        }
        else { EmptyView() }
    }
}


/*
 /// Bridge AppKit's NSVisualEffectView into SwiftUI
 struct VisualEffectView: NSViewRepresentable {
 var material: NSVisualEffectView.Material
 var blendingMode: NSVisualEffectView.BlendingMode
 var state: NSVisualEffectView.State
 var emphasized: Bool
 
 func makeNSView(context: Context) -> NSVisualEffectView {
 context.coordinator.visualEffectView
 }
 
 func updateNSView(_ view: NSVisualEffectView, context: Context) {
 context.coordinator.update(
 material: material,
 blendingMode: blendingMode,
 state: state,
 emphasized: emphasized
 )
 }
 
 func makeCoordinator() -> Coordinator {
 Coordinator()
 }
 
 class Coordinator {
 let visualEffectView = NSVisualEffectView()
 
 init() {
 visualEffectView.blendingMode = .withinWindow
 }
 
 func update(material: NSVisualEffectView.Material,
 blendingMode: NSVisualEffectView.BlendingMode,
 state: NSVisualEffectView.State,
 emphasized: Bool) {
 visualEffectView.material = material
 }
 }
 }
 
 
 struct Example: View {
 @State var dict: [String: String] = ["A": "Alpha", "B": "Beta"]
 
 var body: some View {
 List {
 ForEach(Array(dict.keys), id: \.self) { key in
 HStack {
 Text(key)
 TextField("Value", text: Binding(
 get: { dict[key] ?? "" },
 set: { dict[key] = $0 }
 ))
 }
 }
 }
 }
 }
 
 */

struct FlagControlView: View {
    // Available flag colors like Mail
    let flagColors: [(name: String, color: Color)] = [
        ("Red", .red),
        ("Orange", .orange),
        ("Yellow", .yellow),
        ("Green", .green),
        ("Blue", .blue),
        ("Purple", .purple),
        ("Gray", .gray)
    ]
    
    @State private var selectedFlagColor: Color = .gray // Default
    @State private var isFlagged: Bool = false
    
    var body: some View {
        VStack {
            Text(isFlagged ? "Item Flagged" : "No Flag")
                .foregroundColor(isFlagged ? selectedFlagColor : .primary)
                .font(.headline)
            
            // The Flag Control Button (Mac Mail Style)
            Menu {
                Button(action: { isFlagged = false }) {
                    Label("No Flag", systemImage: "flag.slash")
                }
                
                Divider()
                
                ForEach(flagColors, id: \.name) { item in
                    Button(action: {
                        selectedFlagColor = item.color
                        isFlagged = true
                    }) {
                        Label(item.name, systemImage: "flag").background(selectedFlagColor)
                    }
                }
            } label: {
                Image(systemName: "flag.fill")
                    .symbolEffect(.rotate.byLayer, options: .repeat(.continuous))
                    .foregroundStyle(selectedFlagColor, .yellow, .green)
                
                //                Label("Flag", systemImage: isFlagged ? "flag.fill" : "flag")
                //                    .foregroundColor(isFlagged ? selectedFlagColor : .secondary)
            }
            .foregroundStyle(selectedFlagColor)
        }
        .padding()
    }
}





struct EditSettingsPanel: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("import-width") var importWidth: Int = 0
    @AppStorage("import-height") var importHeight: Int = 0
    @FocusState var widthFocused: Bool
    var theTip = ImportOptionsTip()
    
    var body: some View {
        
        VStack {
            GroupBox {
                Button {
                    dismiss()
                } label: {
                    Label("Ok", systemImage: ("checkmark"))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                
                Grid {
                    GridRow {
                        Text("Import Width:")
                        TextField("",
                                  value: $importWidth,
                                  format: .number
                        ).border(Color("PraxColor"))
                            .onSubmit({
                                dismiss()
                            })
                            .focused($widthFocused)
                            .textContentType(.postalCode)
                    }
                    
                    GridRow {
                        Text("Import Height:")
                        TextField("",
                                  value: $importHeight,
                                  format: .number
                        ).border(Color("PraxColor"))
                        
                        
                    }
                }
                
                
                
                
                Text("\(importWidth)")
                //    .foregroundColor(emailFieldIsFocused ? .red : .blue)
                
                Text("Image Import Size")
                    .frame(minWidth: 100, maxWidth: 200, maxHeight: 50)
                    .background(Color("AccentColor"))
            }
            .padding(20)
            
        }
        .background(PraxGradient(0).edgesIgnoringSafeArea(.all))
        .popoverTip(theTip)
    }
}





/// <#Description#>
struct ImportOptionsInspector: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("import-width") var importWidth: Int = 0
    @AppStorage("import-height") var importHeight: Int = 0
    @Environment(PraxModel.self) private var prax
    @FocusState var widthFocused: Bool
    var theTip = ImportOptionsTip()
    
    var body: some View {
        @Bindable var prax = prax
        VStack {
            GroupBox {
                Button {
                    dismiss()
                } label: {
                    Label("Ok", systemImage: ("checkmark"))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                
                Grid {
                    GridRow {
                        Text("Maximum Width:")
                        TextField("",
                                  value: $importWidth,
                                  format: .number
                        ).border(Color("PraxColor"))
                            .onSubmit({
                                dismiss()
                            })
                            .focused($widthFocused)
                            .textContentType(.postalCode)
                    }
                    
                    GridRow {
                        Text("Maximum Height:")
                        TextField("",
                                  value: $importHeight,
                                  format: .number
                        ).border(Color("PraxColor"))
                        
                        
                    }
                }
                
                
                
                
                Text("\(importWidth)")
                //    .foregroundColor(emailFieldIsFocused ? .red : .blue)
                
                Toggle(isOn: $prax.inspectNextImageDrop, label: {
                    Text("Test on Next Drop")
                })
                Text("Image Import Size")
                    .frame(minWidth: 100, maxWidth: 300, maxHeight: .infinity)
                    .background(Color("PraxColor"))
            }
            .padding(20)
            
        }
        .background(PraxGradient(0).edgesIgnoringSafeArea(.all))
        .popoverTip(theTip)
    }
}





struct ImportOptionsTip: Tip {
    var title: Text {
        Text("Image Import Options")
    }
    var message: Text? {
        Text("Imported images are resampled to reduce the size of the resulting PDF file. Use these options to control the quality of the output.")
    }
    var image: Image? {
        Image(systemName: "photo.badge.arrow.down")
    }
}



public struct ASlideableDivider: View {
    @Binding var dimension: Double
    @Binding var otherDimension: Double
    let position: Int
    let isShowingOtherPane: Bool
    let minDimension: Double
    let maxDimension: Double
    let windowWidth: Double
    //   @Binding var collapse: Bool?
    
    @State private var dimensionStart: Double?
    
    public var body: some View {
        Rectangle()
            .fill(.orange)
            .frame(width: 10)
            .onHover { inside in
                if inside {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(drag)
    }
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: CoordinateSpace.global)
            .onChanged { val in
                if dimensionStart == nil {
                    if position == 0 {
                        dimensionStart = dimension
                    }
                    else {
                        dimensionStart = otherDimension
                    }
                    dimensionStart = dimension
                }
                let delta = val.location.x - val.startLocation.x
                let newDimension = dimensionStart! + Double(delta)
                
                
                let difference = newDimension - dimension
                
                if difference > 0 {
                    
                    
                    
                }
                else if difference < 0 {
                    if position == 0 {
                        if newDimension < minDimension {
                            print("Julie d'Prax")
                            //  collapse = false
                        }
                        else {
                            dimension = newDimension
                        }
                    }
                    else {
                        if newDimension > maxDimension {
                            print("Juliette M. Belanger")
                            //  collapse = false
                        }
                        else {
                            dimension = newDimension
                        }
                        
                    }
                    
                }
                
                if position == 0 {
                    if newDimension < minDimension {
                        print("Julie d'Prax")
                        //  collapse = false
                        return
                    }
                    
                    if newDimension < windowWidth - maxDimension {
                        dimension = newDimension
                        return
                    }
                }
                
                if newDimension + dimension < minDimension {
                    
                    print("Julie d'Prax")
                    //  collapse = false
                    return
                }
                else if isShowingOtherPane {
                    
                    if newDimension < windowWidth - dimension - otherDimension - maxDimension {
                        dimension += difference / 2
                        otherDimension += difference / 2
                    }
                    
                    
                }
                else {
                    
                    if newDimension < windowWidth - maxDimension {
                        dimension += difference
                        otherDimension += difference
                    }
                    
                    
                }
                
                
                print("dimension: ", dimension)
                
            }
            .onEnded { val in
                dimensionStart = nil
            }
    }
}

public struct SlideableDivider: View {
    let dimension: Double
    let position: Int
    let onChangedDivider: (Double, Int) -> Void
    
    @State private var dimensionStart: Double?
    
    public var body: some View {
        Rectangle()
            .fill(.orange)
            .frame(width: 10)
            .onHover { inside in
                if inside {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(drag)
    }
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: CoordinateSpace.global)
            .onChanged { val in
                if dimensionStart == nil {
                    dimensionStart = dimension
                }
                let delta = val.location.x - val.startLocation.x
                let newDimension = dimensionStart! + Double(delta)
                
                onChangedDivider(newDimension, position)
            }
            .onEnded { val in
                dimensionStart = nil
            }
    }
}



import SwiftUI
//import UniformTypeIdentifiers
import PDFKit




class praxListItem: NSCollectionViewItem {
    
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("list-item-reuse-identifier")
    
    override var highlightState: NSCollectionViewItem.HighlightState {
        didSet {
            updateSelectionHighlighting()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            updateSelectionHighlighting()
        }
    }
    
    private func updateSelectionHighlighting() {
        if !isViewLoaded {
            return
        }
        
        let showAsHighlighted = (highlightState == .forSelection) ||
        (isSelected && highlightState != .forDeselection) ||
        (highlightState == .asDropTarget)
        
        textField?.textColor = showAsHighlighted ? .selectedControlTextColor : .labelColor
        view.layer?.backgroundColor = showAsHighlighted ? NSColor.selectedControlColor.cgColor : nil
    }
}


#Preview {
    OptionKeyPressedToolbarItem()
}


func editImageOptions() {
    print("PageItem editImageOptions")
    prax?.importEditingURLBookmark = (URL(string: sourceURLString)!, sourceBookmark)
    prax?.showingImportEditor = true
    
}

// MARK: - Drop routing

func receiveDroppedSourceFile(_ payload: SourceFilePayload, at indexPath: IndexPath? = nil) {
    let needsStop = payload.fileURL.startAccessingSecurityScopedResource()
    defer { if needsStop { payload.fileURL.stopAccessingSecurityScopedResource() } }
    
    
    do { importSourceAttributes = try FileManager.default.attributesOfItem(atPath: payload.fileURL.path) }
    catch { PraxLogger.shared.logError("Import Source Error", category: .import)
        let error = NSError(domain: "FileImporting", code: -1, userInfo: [ NSLocalizedDescriptionKey: "Error reading file attributes" ])
        let praxError = PraxError.fileImportFailed(fileName: payload.fileURL.absoluteString, underlyingError: error)
        prax.document.prax.presentError(praxError)}
    
    
    let fileType = importSourceAttributes[.type] as! FileAttributeType
    
    guard fileType == .typeDirectory || fileType == .typeRegular else {
        PraxLogger.shared.logError("Import Source Alert", category: .import)
        let error = NSError(domain: "FileImporting", code: -1, userInfo: [ NSLocalizedDescriptionKey: "File type is not supported" ])
        let praxError = PraxError.fileImportFailed(fileName: payload.fileURL.absoluteString, underlyingError: error)
        prax.document.prax.presentError(praxError)
        return
    }
    
    
    if fileType == .typeDirectory {
        PraxLogger.shared.logWarning("Import Source Alert", category: .import)
        let error = NSError(domain: "FileImporting", code: -1, userInfo: [ NSLocalizedDescriptionKey: "Import Source is a Folder" ])
        let praxError = PraxError.fileImportFailed(fileName: payload.fileURL.absoluteString, underlyingError: error)
        prax.document.prax.presentError(praxError)
        
        PraxLogger.shared.logInfo("Importing Folder: \(payload.fileURL.lastPathComponent) - size: \(importSourceAttributes[.size] ?? 0) - type: \(importSourceAttributes[.type] ?? "unknown")", category: .import)
        
        Task {
            do {
                PraxLogger.shared.logInfo(
                    "Starting PDF persistence: \(payload.fileURL.lastPathComponent)",
                    category: .import
                )
                //                 try await prax.document.persistence.importURLs([payload.fileURL])
                PraxLogger.shared.logInfo(
                    "PDF persistence completed: \(payload.fileURL.lastPathComponent)",
                    category: .import
                )
            } catch {
                // Create user-facing error with recovery suggestions
                let praxError = PraxError.fileImportFailed(
                    fileName: payload.fileURL.lastPathComponent,
                    underlyingError: error
                )
                self.presentError(praxError)
            }
        }
        
    }
    
    
    
    importSourceURL = payload.fileURL
    importDropIndexPath = indexPath
    
    
    let ext = payload.fileURL.pathExtension.lowercased()
    switch ext {
        
    case "pdf":
        
        
        PraxLogger.shared.logInfo("Importing PDF: \(payload.fileURL.lastPathComponent) - size: \(importSourceAttributes[.size] ?? 0) - type: \(importSourceAttributes[.type] ?? "unknown")", category: .import)
        
        
        
        DispatchQueue.main.async { [self] in
            //              prax.document.addPagesFromPDFURL(payload.fileURL, bookmark: payload.bookmarkData, at: indexPath)
        }
        
        /*            Task {
         do {
         PraxLogger.shared.logInfo(
         "Starting PDF persistence: \(payload.fileURL.lastPathComponent)",
         category: .import
         )
         try await prax.document.persistence.importURLs([payload.fileURL])
         PraxLogger.shared.logInfo(
         "PDF persistence completed: \(payload.fileURL.lastPathComponent)",
         category: .import
         )
         } catch {
         // Create user-facing error with recovery suggestions
         let praxError = PraxError.fileImportFailed(
         fileName: payload.fileURL.lastPathComponent,
         underlyingError: error
         )
         self.presentError(praxError)
         }
         }
         */
    case "png", "jpeg", "jpg", "gif", "heic":
        
        PraxLogger.shared.logInfo("Importing Image File: \(payload.fileURL.lastPathComponent) - size: \(importSourceAttributes[.size] ?? 0) - type: \(importSourceAttributes[.type] ?? "unknown")", category: .import)
        
        
        
        if inspectNextImageDrop {
            
            let praxError = PraxError.generic(
                title: "Operation Failed",
                message: "inspectNextImageDrop - Something unexpected happened. Please try again."
            )
            self.presentError(praxError)
            
            //            showingImageDropInspector = true
        } else {
            
            showingImportEditor = true
            
            // IMPORTANT: default size limit is applied inside addPageFromImageURL
            //          DispatchQueue.main.async { [self] in addPageFromImageURL(payload.fileURL, at: indexPath, imageOptions: .neutral) }
        }
        
    default:
        break
    }
}


func clearImageInspectorState() {
    importSourceURL = nil
    importDropIndexPath = nil
    showingImportEditor = false
    //        showingImageDropInspector = false
}

var showingImportEditor: Bool = false {
    didSet {
        print("showingImportEditor: ", windowSize)
        importEditorMinWidth = showingImportEditor ? 400 : 20
        importEditorMaxWidth = showingImportEditor ? 1200 : 50
    }
}
var importEditorMinWidth: CGFloat = 0
var importEditorMaxWidth: CGFloat = 0
var inspectNextImageDrop: Bool = false

var importDropIndexPath: IndexPath?


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
            .onChange(of: prax.showImportEditor ) {
                if prax.showImportEditor {
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
