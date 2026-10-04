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
final class PraxModel {
    let persistence: PersistenceController
    init (_ persistence: PersistenceController) {
        self.persistence = persistence
    }
    @ObservationIgnored
    lazy var document: MergedPDFDocument = {
        return MergedPDFDocument(prax: self, persistence: self.persistence)
    }()

    var praxPressMode: PraxPressMode = .merge
    var editMode: EditMode = .merge
    
    let theme = PraxTheme()
    var undoManager = UndoManager()
    
    
    var dropTargeted = false
    var optionKeyPressed = false
    var hoveredButton: Int? = nil
    
    var isOn = false
    var isLarge: Bool = false
    
    // MARK - View Presentation Flags
    
    var columnVisibility: NavigationSplitViewVisibility = .all
    var showDataFields = false
    var showFileImportOptions: Bool = false
    var showFileExportOptions: Bool = false
    var showPDFPageItemInspector = false
    var showFileImporter: Bool = false
    var showFileExporter: Bool = false
    var showExportFolderSelector: Bool = false
    var showInspector: Bool = false
    var showMergedDocumentInspector = false
    
    var presentedError: PraxError? = nil
    var saveError: String?
    
    var burnInAnnotations: Bool = false
    
 /*   var annotationSaveMode: AnnotationSaveMode = .editable {
        didSet { print("Prax - AnnotationSaveMode = ", annotationSaveMode)
            selectedPageItem?.mergedPage?.refreshMergedPage(refreshEditingDocument: true)} }
 */
    
    // MARK - View Sizes
    
    var windowSize: CGSize = .zero
    
    
    var editingToolbarSize: CGSize = .zero
    var editorAutoScales: PDFDisplayDirection?
    var editorViewSize: CGSize = .zero {
        didSet {
      //      if editingDocumentPDFView.autoScales != true { return }
            let scaleFactor = editingDocumentPDFView.scaleFactorForSizeToFit
            editingDocumentPDFViewScaleFactor = scaleFactor
        }
    }
//    var mergedImageSize: CGSize = .zero
//    var thumbnailSize: CGSize = .zero
    
    var editingPDFPages: [PDFPage] = []
    var editingDocumentPDFViewScaleFactor = 1.0 { didSet {
        editingDocumentPDFView.scaleFactor = editingDocumentPDFViewScaleFactor }}
    var mergedDocumentPDFViewScaleFactor = 1.0 { didSet {
        mergedDocumentPDFView.scaleFactor = mergedDocumentPDFViewScaleFactor
        print("mergedDocumentPDFViewScaleFactor: \(mergedDocumentPDFViewScaleFactor)") }}
    
    var mergedViewScaleFactor = 1.0
    var mergedViewSize: CGSize = .zero
    
    var editingDocumentPDFSize: CGSize = .zero
    var editingDocumentPDFViewSize: CGSize = .zero
    let editingDocumentPDFView = PDFView()
    let pageItemCollectionView = NSCollectionView()
    let pageEditCollectionView = NSCollectionView()
    let mergedDocumentPDFView = PDFView()
    let previewPDFView = PDFView()
    
    var useAmountForFilename = false
    var importSourceAttributes: [FileAttributeKey: Any] = [:]
    
    var urlBookmarksToImport: [(url: URL, bookmark: Data, size: Int)] = []
    var importSourceURL: URL?
    var importSourceBookmark: Data?
    var importEditingURLBookmark: (url: URL, bookmark: Data)?
    

    var sourceFiles: [SourceFile] = []
    
    var selectionModel = SelectionModel<UUID>()
    
    var showPreview = false
    var previewDocumentVersion = UUID()
    var previewPDFDocument: PDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)! {
        didSet { previewDocumentVersion = UUID() }
    }
    
    private var _selectedSourceFile: SourceFile?
    var selectedSourceFile: SourceFile? { get { _selectedSourceFile }
        set { guard newValue != _selectedSourceFile else { return }
            _selectedSourceFile = newValue
            
            if let sourceFile = selectedSourceFile {
                Task {
                    var isStale = false
                    guard let url = try? URL(resolvingBookmarkData: sourceFile.bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
                    else { let praxError = PraxError.bookmarkResolutionFailed(underlyingError: nil); presentError(praxError); return }
                    
                    let needsStop = url.startAccessingSecurityScopedResource()
                    defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
                    
                    if let document =  PDFDocument(url: url) {
                        DispatchQueue.main.async { self.previewPDFDocument = document }
                    }
                    else {
                        let praxError = PraxError
                        .fileAccessDenied(filePath: url.absoluteString); presentError(praxError); return }
                }
            }
        }
    }
        
     
    var selectedFiles = Set<SourceFile.ID>() {
        didSet {
            print("selectedFiles didSet: \(selectedFiles)")
            if let id = selectedFiles.first {
                if let sourceFile = sourceFiles.first(where: { $0.id == id }) {
                    if sourceFile != selectedSourceFile {
                        selectedSourceFile = sourceFile }
                }
            }
        }
    }
    var selectedMergedPages = Set<MergedPage.ID>()
    var selectedPages = Set<PageItem.ID>()
    
        
    var currentEditingPDFPage: PDFPage? { didSet {
            if let pdfPage = currentEditingPDFPage, let pageItem = document.pageItem(for: pdfPage) {
                if selectedPageItem != pageItem {
                    selectedPageItem = pageItem } } } }
    
    private var _selectedPageItem: PageItem?
    var selectedPageItem: PageItem? { get { _selectedPageItem }
        set { guard newValue != _selectedPageItem else { return }
            _selectedPageItem = newValue
            if let pageItem = selectedPageItem {
                if currentEditingPDFPage != pageItem.pdfPage { editingDocumentPDFView.go(to: pageItem.pdfPage) }
                selectedPages = Set([pageItem.id])
                if document.exportFilenameBody == "" { document.setExportURL(from: pageItem) } } }}
    
    var allItemIDs: [UUID] {
        var allIDs: [UUID] = []
        for mergedPage in document.mergedPages {
            //  allIDs.append(mergedPage.id)
            
            for pageItem in mergedPage.pageItems {
                allIDs.append(pageItem.id)
            }
        }
        return allIDs
    }
    
    func presentError(_ error: PraxError) {
        DispatchQueue.main.async { [self] in
            self.presentedError = error
            PraxLogger.shared.logError(
                error.userMessage,
                error: error.underlyingError,
                category: .general )  } }
    func dismissError() {  presentedError = nil }
    
    
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
        presentError(praxError1)
        
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
        presentError(praxError)
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

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}


extension Notification.Name {
    static let praxWidthGuideChanged = Notification.Name("PraxWidthGuideChanged")
    static let praxPageItemTrimsChanged = Notification.Name("PraxPageItemTrimsChanged")
    static let praxFileSelectionChanged = Notification.Name("PraxFileSelectionChanged")
}



