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
    
    let theme = PraxTheme()
   
    
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
//    var showingImageDropInspector: Bool = false
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
    
   // var imageOptions = ImageImportOptions()
    
    
    let editingDocumentPDFView = PDFView()
    let pageItemCollectionView = NSCollectionView()
    let pageEditCollectionView = NSCollectionView()
    let mergedDocumentPDFView = PDFView()
    
 
    enum HoverSection {
        case editingDocument
        case mergedDocument
    }
    
    
    var hoverSection = Set<HoverSection>()
    
    var importSourceAttributes: [FileAttributeKey: Any] = [:]
    
    var urlBookmarksToImport: [(url: URL, bookmark: Data, size: Int)] = []
    var importSourceURL: URL?
    var importSourceBookmark: Data?
    var importEditingURLBookmark: (url: URL, bookmark: Data)?

    
    var selectedFiles = Set<SourceFile.ID>()
    var selectedSections = Set<Int>()
    
    private var _selectedPageItems = Set<IndexPath>()
    var selectedPageItems: Set<IndexPath> {
        get { _selectedPageItems }
        set {
            guard newValue != _selectedPageItems else { return }
            
            print("setting selectedPageItems to: ", newValue )
            _selectedPageItems = newValue
            
            if pageItemCollectionView.selectionIndexPaths != selectedPageItems {
                pageItemCollectionView.selectionIndexPaths = selectedPageItems
            }
            if newValue.isEmpty { endSelectedPage() }
            else if selectedPageItem == nil { beginSelectedPage() }
            else { updateSelectedPage() }
        }
    }

    
    private var _selectedPageItem: PageItem?
    var selectedPageItem: PageItem?
    
    {
        get { _selectedPageItem }
        set {
            
            guard newValue != _selectedPageItem else { return }

            let oldValue = _selectedPageItem
            _selectedPageItem = newValue
  
            if let pageItem = selectedPageItem {
                if let indexPath = document.indexPath(for: pageItem) {
                    selectedPageItems = Set([indexPath])
                }
            }
            
            
            
/*            if newValue != nil, oldValue == nil {
                beginSelectedPage()
            }
            else if oldValue != nil, newValue == nil {
                endSelectedPage()
            }
 */
            
        }
    }
    
    
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
            
            if selectedPageItems.contains(selectedIndexPath) { return }
            else if let indexPath = selectedPageItems.first,
                    let pageItem = document.pageItem(indexPath: indexPath) {
                self.selectedPageItem = pageItem }
            else { self.selectedPageItem = nil }
        }
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
        let praxError1 = PraxError.fileImportFailed(
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

    
    
    
    func clearImageInspectorState() {
        importSourceURL = nil
        importDropIndexPath = nil
        showingImportEditor = false
//        showingImageDropInspector = false
    }

    // MARK: - Drop routing

    func receiveDroppedSourceFile(_ payload: SourceFileTransfer.Payload, at indexPath: IndexPath? = nil) {
        let needsStop = payload.fileURL.startAccessingSecurityScopedResource()
        defer { if needsStop { payload.fileURL.stopAccessingSecurityScopedResource() } }

        
        do { importSourceAttributes = try FileManager.default.attributesOfItem(atPath: payload.fileURL.path) }
        catch { PraxLogger.shared.logError("Import Source Error", category: .import)
            let error = NSError(domain: "FileImporting", code: -1, userInfo: [ NSLocalizedDescriptionKey: "Error reading file attributes" ])
            let praxError = PraxError.fileImportFailed(fileName: payload.fileURL.absoluteString, underlyingError: error)
            document.prax.presentError(praxError)}
        
        
        let fileType = importSourceAttributes[.type] as! FileAttributeType
        
        guard fileType == .typeDirectory || fileType == .typeRegular else {
            PraxLogger.shared.logError("Import Source Alert", category: .import)
            let error = NSError(domain: "FileImporting", code: -1, userInfo: [ NSLocalizedDescriptionKey: "File type is not supported" ])
            let praxError = PraxError.fileImportFailed(fileName: payload.fileURL.absoluteString, underlyingError: error)
            document.prax.presentError(praxError)
            return
        }
        
        
        if fileType == .typeDirectory {
            PraxLogger.shared.logWarning("Import Source Alert", category: .import)
            let error = NSError(domain: "FileImporting", code: -1, userInfo: [ NSLocalizedDescriptionKey: "Import Source is a Folder" ])
            let praxError = PraxError.fileImportFailed(fileName: payload.fileURL.absoluteString, underlyingError: error)
            document.prax.presentError(praxError)
            
            PraxLogger.shared.logInfo("Importing Folder: \(payload.fileURL.lastPathComponent) - size: \(importSourceAttributes[.size] ?? 0) - type: \(importSourceAttributes[.type] ?? "unknown")", category: .import)
  
            Task {
                do {
                    PraxLogger.shared.logInfo(
                        "Starting PDF persistence: \(payload.fileURL.lastPathComponent)",
                        category: .import
                    )
   //                 try await document.persistence.importURLs([payload.fileURL])
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
  //              document.addPagesFromPDFURL(payload.fileURL, bookmark: payload.bookmarkData, at: indexPath)
            }

/*            Task {
                do {
                    PraxLogger.shared.logInfo(
                        "Starting PDF persistence: \(payload.fileURL.lastPathComponent)",
                        category: .import
                    )
                    try await document.persistence.importURLs([payload.fileURL])
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

    // MARK: - Public import

    func addPageFromImageURL(
        _ url: URL,
        at indexPath: IndexPath? = nil,
        title: String? = nil,
        imageOptions: ImageImportOptions = .neutral
    ) {
        let mergedPage = document.mergedPagefrom(url, at: indexPath)
        let pageInsertIndex = document.normalizedInsertionIndex(
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
