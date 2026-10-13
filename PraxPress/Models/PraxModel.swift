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
    var undoManager: UndoManager? = nil { didSet {
        print("Julie")
    }}
    
    
    
    
    
    init (_ persistence: PersistenceController?) {
        self.persistence = persistence
        Task { await self.persistence?.attach(prax: self) }
    }
   
    @ObservationIgnored
    lazy var document: MergedPDFDocument = { return MergedPDFDocument(prax: self, persistence: self.persistence) }()

    var praxPressMode: PraxPressMode = .merge
    var editMode: EditMode = .merge
    
    let theme = PraxTheme()
    
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
    var showExportedFiles: Bool = true
    
    var showInspector: Bool = false
    var showMergedDocumentInspector = false
    
    var presentedError: PraxError? = nil
    var errorString: String?
    
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
    
    var exportFolderURL: URL?
    var exportFolderBookmark: Data?
    
    
    
    var showPreview = false
    var previewPDFDocument: PDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)! {
        didSet { previewDocumentVersion = UUID() } }
    var previewDocumentVersion = UUID()
    
    var selectionModel = SelectionModel<UUID>()
    
    var sourceFiles: [SourceFile] = []
    
    func refreshPreviewPDFDocument() {
        
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
        else { self.previewPDFDocument = PDFDocument() }
        


    }
    
    
    var selectedSourceFile: SourceFile? { didSet {
        refreshPreviewPDFDocument()
    }}
    
  
     
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
    
 

}



