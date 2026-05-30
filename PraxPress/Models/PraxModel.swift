//  PraxModel.swift
//  PraxPress - Prax=0104-1
//



import Foundation
import CoreGraphics
import CoreImage
import PDFKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import OSLog



@Observable
final class ViewAdjuster {

    let prax: PraxModel
    
    init(prax: PraxModel) {
        self.prax = prax
    }
    
    var windowSize = CGSize(width: 1000, height: 1000) {
        didSet {
            print("Window size changed: \(windowSize)")
        }
    }
    
}

@Observable
final class PraxModel {
    
    // Non-optional reference to the document; attached after both are created.
    unowned private(set) var document: MergedPDFDocument!
    
    private(set) var viewAdjuster: ViewAdjuster!
    
    init() {
        // Document will be attached immediately after both instances are created.
        // We keep it implicitly unwrapped to avoid unsafe placeholders while still
        // making it non-optional for consumers once attached.
        
        
    }
    
    func attach(document: MergedPDFDocument) {
        self.document = document
        self.viewAdjuster = ViewAdjuster(prax: self)
    }
    
    
    var undoManager = UndoManager()
    
    let theme = PraxTheme(.erika)
   
    
    enum AnnotationSaveMode: String, CaseIterable {
        case editable = "Editable"
        case locked = "Locked"
        case burnIn = "Burn In"
        
        var color: Color { switch self {
            case .editable:
                return .green
            case .locked:
                return .blue
            case .burnIn:
                return .orange } }
        
        var icon: String { switch self {
            case .editable:
                return "lock.open"
        case .locked:
                return "lock"
            case .burnIn:
                return "burn" }}
    }
    
    var annotationSaveMode: AnnotationSaveMode = .editable {
        didSet {
            print("Prax - AnnotationSaveMode = ", annotationSaveMode)
            selectedPageItem?.mergedPage.refreshMergedPage()
        }
    }
    
    // MARK: - Error Handling (ADD THIS SECTION)

    /// Current error to display in UI alert
    var presentedError: PraxError? = nil

    /// Present an error to the user with title, message, and recovery suggestions
    func presentError(_ error: PraxError) {
        DispatchQueue.main.async { [self] in
            self.presentedError = error
            
            // Also log for debugging in Console.app
            PraxLogger.shared.logError(
                error.userMessage,
                error: error.underlyingError,
                category: .general
            )
        }
    }

    /// Dismiss the currently presented error
    func dismissError() {
        presentedError = nil
    }
    

    enum PraxPressMode: String, CaseIterable {
        case data = "Data Mode"
        case merge = "Merge Mode"
        case prax = "Prax Mode"
        
        var color: Color { switch self {
            case .merge:
                return .pink
            case .data:
                return .blue
            case .prax:
                return .orange } }
        
        var icon: String { switch self {
            case .merge:
                return "apple.logo"
            case .data:
                return "swift"
            case .prax:
                return "gear" }}
    }

    var praxPressMode: PraxPressMode = .merge
    
    var dropTargeted = false
    var optionKeyPressed = false
    
    var windowSize: CGSize = CGSize(width: 0, height: 0)
    
    var saveError: String?
    
    var isOn = false
    var isLarge: Bool = false
    var showFilesPanel = true
    var showingImageDropInspector: Bool = false
    var showingImportImageEditor: Bool = false
    var inspectNextImageDrop: Bool = false
    var importSourceURL: URL?
    var importDropIndexPath: IndexPath?
    
    var useAmountForFilename = false
    var showDataFields = false
    var showingFileImportOptions: Bool = false
    var showingFileExportOptions: Bool = false
    var showingMergedDocumentInspector = false
    var showingPDFPageItemInspector = false
    var showingImporter: Bool = false
    var showingFileImporter: Bool = false
    var showingExportFolderSelector: Bool = false
    var isShowingInspector: Bool = false
    var showSavePanel: Bool = false
    var columnVisibility: NavigationSplitViewVisibility = .all
    
    var importImageOptions = ImageImportOptions()
    
    
    let editingDocumentPDFView = PDFView()
    let pageItemCollectionView = NSCollectionView()
    let pageEditCollectionView = NSCollectionView()
    let mergedDocumentPDFView = PDFView()
    
 
    enum HoverSection {
        case editingDocument
        case mergedDocument
    }
    
    
    var hoverSection = Set<HoverSection>()
    
    var selectedFiles = Set<PDFFile.ID>()
    var selectedSections = Set<Int>()
    
    private var _selectedPageItems = Set<IndexPath>()
    var selectedPageItems: Set<IndexPath> {
        get { _selectedPageItems }
        set {
            guard newValue != _selectedPageItems else { return }
            _selectedPageItems = newValue
            
            if pageItemCollectionView.selectionIndexPaths != selectedPageItems {
                pageItemCollectionView.selectionIndexPaths = selectedPageItems
            }
            if newValue.isEmpty { endSelectedPage() }
            else if selectedPageItem == nil { beginSelectedPage() }
            else { updateSelectedPage() }
        }
    }

    
  //  private var _selectedPageItem: PageItem?
    var selectedPageItem: PageItem?
    /*
    {
        get { _selectedPageItem }
        set {
            
            guard newValue != _selectedPageItem else { return }

            let oldValue = _selectedPageItem
            _selectedPageItem = newValue
            
            if newValue != nil, oldValue == nil {
                beginSelectedPage()
                
                
                
            }
            else if oldValue != nil, newValue == nil {
                endSelectedPage()
            }
 
        }
    }
    
    */
    func beginSelectedPage() {
        print("beginSelectedPage")
        if selectedPageItem == nil {
            if let indexPath = selectedPageItems.first {
                if let pageItem = document.pageItem(indexPath: indexPath) {
                    selectedPageItem = pageItem
                    if document.exportFilenameBody == "" {
                        document.setExportURL(from: pageItem) } } } }
    }


    func updateSelectedPage() {
        print("updateSelectedPage")
        if let selectedPageItem, let selectedIndexPath = document.indexPath(for: selectedPageItem) {
            if !selectedPageItems.contains(selectedIndexPath) {
                if let indexPath = selectedPageItems.first,
                   let pageItem = document.pageItem(indexPath: indexPath) {
                    self.selectedPageItem = pageItem
                return } } }
        self.selectedPageItem = nil
    }
    
    func endSelectedPage() {
        print("endSelectedPage")
        selectedPageItem = nil
        pageItemCollectionView.selectionIndexPaths.removeAll()
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


extension NSImage {
    func resize(to newSize: NSSize, interpolation: NSImageInterpolation = .high) -> NSImage? {
        guard let tiffData = self.tiffRepresentation,
              let bitmapImageRep = NSBitmapImageRep(data: tiffData) else { return nil }
        
        let newRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(newSize.width),
            pixelsHigh: Int(newSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: newRep!)
        bitmapImageRep.draw(in: NSRect(origin: .zero, size: newSize))
        NSGraphicsContext.restoreGraphicsState()
        
        let resizedImage = NSImage(size: newSize)
        resizedImage.addRepresentation(newRep!)

        resizedImage.lockFocus()
        
        // Apply resize quality
        if let currentContext = NSGraphicsContext.current {
            currentContext.imageInterpolation = interpolation
        }
        
        // Draw the source image into the new rect
        self.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .copy,
                  fraction: 1.0)
        
        resizedImage.unlockFocus()


        return resizedImage
    }
}



extension Notification.Name {
    static let praxWidthGuideChanged = Notification.Name("PraxWidthGuideChanged")
    static let praxSelectedPageItemsChanged = Notification.Name("PraxSelectedPageItemsChanged")
    static let praxPageItemTrimsChanged = Notification.Name("PraxPageItemTrimsChanged")
    //  static let praxFileSelectionChanged = Notification.Name("PraxFileSelectionChanged")
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension PraxModel {
    

    func praxTest() {
        print("\nJulie d'Prax")
        
        // MARK: - Test Error Alert (Add this section)
        
        // Test 1: PDF Import Error
        PraxLogger.shared.logWarning("Testing PDF import error alert", category: .general)
        let testError1 = NSError(domain: "TestDomain", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "File not found or corrupted"
        ])
        let praxError1 = PraxError.pdfImportFailed(
            fileName: "test-document.pdf",
            underlyingError: testError1
        )
        document.prax.presentError(praxError1)
        
        // Uncomment below to test other error types:
        
        /*
        // Test 2: Image Processing Error
        let praxError2 = PraxError.imageProcessingFailed(
            fileName: "test-image.png",
            reason: "Image format not supported or file corrupted"
        )
        document.prax.presentError(praxError2)
        
        // Test 3: File Access Error
        let praxError3 = PraxError.fileAccessDenied(
            filePath: "/Volumes/NetworkDrive/restricted-folder/file.pdf"
        )
        document.prax.presentError(praxError3)
        
        // Test 4: Bookmark Error
        let testError4 = NSError(domain: "BookmarkDomain", code: -2, userInfo: [
            NSLocalizedDescriptionKey: "Bookmark data is invalid or stale"
        ])
        let praxError4 = PraxError.bookmarkResolutionFailed(underlyingError: testError4)
        document.prax.presentError(praxError4)
        
        // Test 5: Generic Error
        let praxError5 = PraxError.generic(
            title: "Operation Failed",
            message: "Something unexpected happened. Please try again."
        )
        document.prax.presentError(praxError5)
        */
    }
    
    func moreThanOneDataPageError() {
        print("\nJulie d'Prax")
        PraxLogger.shared.logWarning("More than one data page", category: .general)
        
        let praxError = PraxError.generic(
            title: "More Than One Data Page",
            message: "Only one Page Item should contain Data Fields.\n\nThe first Page Item will be used for the data source and it's fields will be filled on export.\n\nHowever, unless you use the Burn option, the form fields on other pages will blank and no longer editable.\n\nRemove the extra Data Page Item(s) if you don't wish for this behavior."
        )
        document.prax.presentError(praxError)
    }

    enum ImportSizingMode: String, CaseIterable, Identifiable {
        case fileSizeLimit
        case targetInches
        var id: String { rawValue }
    }

    struct ImageImportOptions: Equatable {
        var cropLeft: Double = 0
        var cropRight: Double = 0
        var cropTop: Double = 0
        var cropBottom: Double = 0

        var scaleDown: Double = 1.0

        var brightness: Double = 0.0
        var contrast: Double = 1.0
        var exposure: Double = 0.0
        var sharpness: Double = 0.0

        // nil means "resolve from saved defaults"
        var sizingMode: ImportSizingMode = .fileSizeLimit

        // used in .fileSizeLimit mode
        var sizeLimitKB: Int = 1024

        // used in .targetInches mode
        var targetWidthInches: Double = 8.5
        var targetHeightInches: Double = 11.0

        static let neutral = ImageImportOptions()
    }
    
    
    func clearImageInspectorState() {
        importSourceURL = nil
        importDropIndexPath = nil
        showingImageDropInspector = false
    }

    // MARK: - Drop routing

    func receiveDroppedURL(_ url: URL, bookmarkData: Data? = nil, at indexPath: IndexPath? = nil) {
        let needsStop = url.startAccessingSecurityScopedResource()
        defer { if needsStop { url.stopAccessingSecurityScopedResource() } }

        let ext = url.pathExtension.lowercased()
        switch ext {

        case "pdf":
            PraxLogger.shared.logInfo(
                "Received PDF drop: \(url.lastPathComponent)",
                category: .import
            )
            
            DispatchQueue.main.async { [self] in
                document.addPagesFromPDFURL(url, bookmarkData: bookmarkData, at: indexPath)
            }

            Task {
                do {
                    PraxLogger.shared.logInfo(
                        "Starting PDF persistence: \(url.lastPathComponent)",
                        category: .import
                    )
                    try await document.persistence.processImportedURLs([url])
                    PraxLogger.shared.logInfo(
                        "PDF persistence completed: \(url.lastPathComponent)",
                        category: .import
                    )
                } catch {
                    // Create user-facing error with recovery suggestions
                    let praxError = PraxError.pdfImportFailed(
                        fileName: url.lastPathComponent,
                        underlyingError: error
                    )
                    self.presentError(praxError)
                }
            }

        case "png", "jpeg", "jpg", "gif", "heic":
            importSourceURL = url
            importDropIndexPath = indexPath
            if inspectNextImageDrop {
                showingImageDropInspector = true
            } else {
                
                showingImportImageEditor = true
                
                // IMPORTANT: default size limit is applied inside addPageFromImageURL
      //          DispatchQueue.main.async { [self] in addPageFromImageURL(url, at: indexPath, options: .neutral) }
            }

        default:
            break
        }
    }

    // MARK: - Public import

    func addPageFromImageURL(
        _ url: URL,
        at indexPath: IndexPath? = nil,
        title: String? = nil,
        options: ImageImportOptions = .neutral
    ) {
        let mergedPage = document.mergedPagefrom(url, at: indexPath)
        let pageInsertIndex = document.normalizedInsertionIndex(
            count: mergedPage.pageItems.count,
            location: (indexPath?.item ?? 0) + 1
        )

        let effectiveOptions = resolvedImportOptions(options)

        guard let image = processedImageFromURL(url, options: effectiveOptions) else {
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
            dataFields: [:]
        )

        mergedPage.pageItems.insert(pageItem, at: pageInsertIndex)
    }

    /// New signature (size-limit based).
    func processedImageFromURL(_ url: URL, options: ImageImportOptions) -> NSImage? {
        guard let sourceImage = NSImage(contentsOf: url) else { return nil }
        return processedImage(sourceImage, options: resolvedImportOptions(options))
    }



    // MARK: - Core processing
    private static let imageCIContext = CIContext()
    private func processedImage(_ sourceImage: NSImage, options: ImageImportOptions) -> NSImage? {
        guard let tiff = sourceImage.tiffRepresentation,
              var ciImage = CIImage(data: tiff) else { return nil }

        // 1) Crop
        let crop = cropRect(for: ciImage.extent.size, options: options)
        ciImage = ciImage.cropped(to: crop)

        // 2) Adjustments
        ciImage = applyAdjustments(to: ciImage, options: options)

        // 3) Render CI -> NSImage
        let extent = ciImage.extent.integral
        guard let cgImage = Self.imageCIContext.createCGImage(ciImage, from: extent) else { return nil }
        var output = NSImage(cgImage: cgImage, size: NSSize(width: extent.width, height: extent.height))

        // 4) Size strategy
        switch importImageOptions.sizingMode {
        case .fileSizeLimit:
            // Keep current manual downscale behavior
            let userScale = CGFloat(options.scaleDown).clamped(to: 0.05...1.0)
            if userScale < 0.999 {
                let px = pixelSize(of: output)
                let scaled = NSSize(
                    width: max(1, floor(px.width * userScale)),
                    height: max(1, floor(px.height * userScale))
                )
                output = output.resize(to: scaled) ?? output
            }

            if importImageOptions.sizeLimitKB > 0 {
                output = downscaleToMeetPDFSizeLimit(output, targetKB: importImageOptions.sizeLimitKB)
            }

        case .targetInches:
            output = scaleImageToTargetInches(
                output,
                targetWidthInches: options.targetWidthInches,
                targetHeightInches: options.targetHeightInches
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
    
    private func cropRect(for size: CGSize, options: ImageImportOptions) -> CGRect {
        let minRemainingFraction: CGFloat = 0.05

        let w = max(size.width, 1)
        let h = max(size.height, 1)

        let left = CGFloat(options.cropLeft).clamped(to: 0...0.95)
        let right = CGFloat(options.cropRight).clamped(to: 0...0.95)
        let top = CGFloat(options.cropTop).clamped(to: 0...0.95)
        let bottom = CGFloat(options.cropBottom).clamped(to: 0...0.95)

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

    private func applyAdjustments(to image: CIImage, options: ImageImportOptions) -> CIImage {
        var output = image

        if options.brightness != 0 || options.contrast != 1 {
            let f = CIFilter(name: "CIColorControls")
            f?.setValue(output, forKey: kCIInputImageKey)
            f?.setValue(options.brightness, forKey: kCIInputBrightnessKey)
            f?.setValue(options.contrast, forKey: kCIInputContrastKey)
            f?.setValue(1.0, forKey: kCIInputSaturationKey)
            if let o = f?.outputImage { output = o }
        }

        if options.exposure != 0 {
            let f = CIFilter(name: "CIExposureAdjust")
            f?.setValue(output, forKey: kCIInputImageKey)
            f?.setValue(options.exposure, forKey: kCIInputEVKey)
            if let o = f?.outputImage { output = o }
        }

        if options.sharpness > 0 {
            let f = CIFilter(name: "CISharpenLuminance")
            f?.setValue(output, forKey: kCIInputImageKey)
            f?.setValue(options.sharpness, forKey: kCIInputSharpnessKey)
            if let o = f?.outputImage { output = o }
        }

        return output
    }

    // MARK: - Size-limit logic

    private func resolvedImportOptions(_ options: ImageImportOptions) -> ImageImportOptions {
        // Convention:
        // - .neutral means "use app-wide defaults from prax.importImageOptions"
        // - otherwise use explicit passed options
        if options == .neutral {
            return importImageOptions
        }
        return options
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
