//  PraxModel.swift
//  PraxPress - Prax=0104-1
//



import Foundation
import CoreGraphics
import CoreImage
@preconcurrency import PDFKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import OSLog


@Observable
final class PraxModel {
    let modelContainer: ModelContainer
    init (_ modelContainer: ModelContainer) { self.modelContainer = modelContainer }
        
    var undoManager: UndoManager? = nil { didSet { print("Julie") }}
    var modelContext:ModelContext {modelContainer.mainContext}
    
    @ObservationIgnored
    lazy var document: MergedPDFDocument = { return MergedPDFDocument(prax: self) }()
    
    var praxPressMode: PraxPressMode = .merge
    //   var editMode: EditMode = .merge
    
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
    
    var showTrimsEditor = false
    var showFileViewer = false
    
    
    var showOptionsPopover: Bool = false
    
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
    
    var windowFrame: CGRect = .zero { didSet { print("windowFrame: ", windowFrame) } }
    var windowSize: CGSize {windowFrame.size}
    var utilityWindowFrame: CGRect = .zero { didSet { print("utilityWindowFrame: ", utilityWindowFrame) } }
    var utilityWindowSize: CGSize {utilityWindowFrame.size}
    var editorViewFrame: CGRect = .zero { didSet { print("editorViewFrame: ", editorViewFrame) } }
    var editorViewSize: CGSize {editorViewFrame.size}
    var mergedViewFrame: CGRect = .zero
    var mergedViewSize: CGSize {mergedViewFrame.size}
    
    var editingToolbarSize: CGSize = .zero
    var editorHovering = false
    
    var editorViewScaleFactor = 1.0 { didSet { editingDocumentPDFView.scaleFactor = editorViewScaleFactor }}
    var mergedViewScaleFactor = 1.0
    
    var editorViewScaleMode: ViewScaleMode = .fit
    var editorViewFitMode: ViewScaleMode = .fit
    var mergedViewScaleMode: ViewScaleMode = .fit
    var mergedViewFitMode: ViewScaleMode = .fit
    var editorPDFDocumentSize: CGSize = .zero
    
    
    var guideTop: CGFloat?
    var guideBottom: CGFloat?
    var guideLeft: CGFloat?
    var guideRight: CGFloat?
    
    
    
    
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
    
    
    
    //  var showPreview = false
    var previewPDFDocument: PDFDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)! {
        didSet { previewDocumentVersion = UUID() } }
    var previewDocumentVersion = UUID()
    
    var selectionModel = SelectionModel<UUID>()
    
     
    private var sourceFileGroups: [SourceFileGroup] = []
    private var sourceFiles: [SourceFile] = []

    var selectedSourceFiles = Set<SourceFile.ID>() {
        didSet {
            print("selectedSourceFiles didSet")
            selectedSourceFileID = selectedSourceFiles.first
        }
    }
        
    private var _selectedSourceFileID: PersistentIdentifier?
    var selectedSourceFileID: PersistentIdentifier? { get{ _selectedSourceFileID }
        set{ guard newValue != _selectedSourceFileID else { return }
            _selectedSourceFileID = newValue
        }
    }

    var selectedSourceFile: SourceFile? {
        if sourceFiles.isEmpty {return nil}
        let sourceFile = sourceFiles.first(where: { $0.id == selectedSourceFileID })
//        DispatchQueue.main.async {
//            print("PraxModel selectedSourceFile: \(sourceFile?.fileName ?? "none")")
//            self.refreshPreviewPDFDocument()
//        }
        return sourceFile
    }
    
    
    func loadSourceFileGroups() { Task { do {
        sourceFileGroups = try modelContext.fetch(FetchDescriptor<SourceFileGroup>()) }
        catch { print("Failed to load sourceFileGroups: \(error)")} } }
    
    func loadSourceFiles() { Task { do {
        sourceFiles = try modelContext.fetch(FetchDescriptor<SourceFile>()) }
        catch { print("Failed to load sourceFiles: \(error)")} } }
    
    
    func addExportedSourceFile(_ url: URL) async  {
        
        
        let predicate = #Predicate<SourceFile> { $0.url == url }
        var descriptor = FetchDescriptor<SourceFile>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        
        
        do {
            if (try sourceFiles.filter(#Predicate<SourceFile> { $0.url == url }).first) != nil {
                print("Duplicate URL: ", url)
                return
            }}catch {}
        
        
        
        do { PraxLogger.shared.logInfo("Adding new Exported SourceFile at: \(url.path)", category: .import)
            
            let needsStop = url.startAccessingSecurityScopedResource()
            defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileType = fileAttributes[.type] as! FileAttributeType
            guard fileType != .typeDirectory else {
                PraxLogger.shared.logError("Import Source Alert", category: .import)
                let error = NSError(domain: "FileImporting", code: -1, userInfo: [ NSLocalizedDescriptionKey: "File type is not supported" ])
                let praxError = PraxError.fileImportFailed(fileName: url.absoluteString, underlyingError: error)
                presentError(praxError); return }
            
            guard let data = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) else {
                PraxLogger.shared.logError("Import Source Error", category: .import)
                let error = NSError(domain: "FileImporting", code: -1, userInfo: [ NSLocalizedDescriptionKey: "Error reading file bookmark data" ])
                let praxError = PraxError.fileImportFailed(fileName: url.absoluteString, underlyingError: error)
                presentError(praxError); return }
            
            var sourceFile: SourceFile?
            
            guard let pdfDocument = PDFDocument(url: url) else {
                PraxLogger.shared.logError("Failed to open PDF: \(url.path)", category: .pdf)
                throw PraxError.fileImportFailed( fileName: url.lastPathComponent, underlyingError: NSError(domain: "PDFDocument", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not load PDF file. File may be corrupted or an unsupported PDF format." ]))}
            
            print("Opened PDF. Page count: \(pdfDocument.pageCount)")
            
            let dataFields = pdfDocument.dataFields()
            
            let mainFileGroup = try await sourceFileGroup("Merged File Group")
            
            sourceFile = SourceFile(fileGroup: mainFileGroup, bookmarkData: data, pageCount: pdfDocument.pageCount, fileType: .pdf)
            
            sourceFile?.exported = true
            sourceFile?.dataFields = dataFields
            
            
            guard let sourceFile else {
                let message = "Could not create Source File for \(url.path)"
                PraxLogger.shared.logError(message, category: .import)
                let error = PraxError.generic(title: "Import Error", message: message)
                presentError(error)
                return
            }
            modelContext.insert(sourceFile)
            try modelContext.save()
            
        }
        catch {
            let message = "Error Importing URL: \(url)"
            PraxLogger.shared.logError(message, category: .import)
            let error = PraxError.generic(title: "Import Error", message: message)
            presentError(error)
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



