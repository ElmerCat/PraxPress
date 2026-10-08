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
    let persistence: PersistenceController?
    init (_ persistence: PersistenceController?) { self.persistence = persistence }
   
    @ObservationIgnored
    lazy var document: MergedPDFDocument = { return MergedPDFDocument(prax: self, persistence: self.persistence) }()

    var praxPressMode: PraxPressMode = .merge
    var editMode: EditMode = .merge
    
    let theme = PraxTheme()
    var undoManager = UndoManager()
    
    var dropTargeted = false
    var optionKeyPressed = false
    var hoveredButton: Int? = nil
    
   // @FocusState.Binding var focused: FieldName?

    var isOn = false
    var isLarge: Bool = false
    
    //  MARK: - View Presentation Flags
    
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
    
    // MARK: - View Sizes
    
    var windowSize: CGSize = .zero
    var editingToolbarSize: CGSize = .zero
    
    var editorViewSize: CGSize = .zero
    
    
    var mergedViewSize: CGSize = .zero
    
    var editorViewScaleFactor = 1.0 { didSet {
        editingDocumentPDFView.scaleFactor = editorViewScaleFactor }}
    var mergedViewScaleFactor = 1.0
    
    var editorViewScaleMode: ViewScaleMode = .fit
    var editorViewFitMode: ViewScaleMode = .fit
    var mergedViewScaleMode: ViewScaleMode = .fit
    var mergedViewFitMode: ViewScaleMode = .fit
    var editorPDFDocumentSize: CGSize = .zero
  
    
    
    let editingDocumentPDFView = PDFView()
    let previewPDFView = PDFView()
  
    
    var useAmountForFilename = false
    var importSourceAttributes: [FileAttributeKey: Any] = [:]
    
    var urlBookmarksToImport: [(url: URL, bookmark: Data, size: Int)] = []
    var importSourceURL: URL?
    var importSourceBookmark: Data?
    var importEditingURLBookmark: (url: URL, bookmark: Data)?
    
    var showPreview = false
    var previewPDFDocument: PDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)! {
        didSet { previewDocumentVersion = UUID() } }
    var previewDocumentVersion = UUID()
    
    var selectionModel = SelectionModel<UUID>()
    
    var sourceFiles: [SourceFile] = []
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
    
    var editingPageItems: [PageItem] = []
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


}



