//  PraxModel.swift
//  PraxPress - Prax=0104-1
//



import Foundation
import CoreGraphics
import PDFKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

//import Combine

import SwiftData
//@Model
@Observable
final class PraxModel {
    
    // Non-optional reference to the document; attached after both are created.
    unowned private(set) var document: MergedPDFDocument!
    
    init() {
        // Document will be attached immediately after both instances are created.
        // We keep it implicitly unwrapped to avoid unsafe placeholders while still
        // making it non-optional for consumers once attached.
    }
    
    func attach(document: MergedPDFDocument) {
        self.document = document
    }
    
    var undoManager = UndoManager()
    
    let theme = PraxTheme(.erika)
   
    
    enum AnnotationSaveMode: String, CaseIterable {
        case editable = "Editable"
        case locked = "Locked"
        case burnIn = "Burn In"
        
        var color: Color { switch self {
            case .editable:
                return .blue
            case .locked:
                return .red
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
    var inspectNextImageDrop: Bool = false
    var inspectingImage: NSImage?
    
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
    
    
    let editingDocumentPDFView = PDFView()
    let pageItemCollectionView = NSCollectionView()
    let pageEditCollectionView = NSCollectionView()
    let mergedDocumentPDFView = PDFView()
    
 
    enum HoverSection {
        case editingDocument
        case mergedDocument
    }
    
    
    var hoverSection: Set<HoverSection> = []
    
    
    var selectedFiles = Set<PDFFile.ID>() {
        didSet {
            print ("PraxModel - MergedPDFDocument selectedFiles didSet: ", selectedFiles.count) //, selectedFiles.description)
        }
    }
    
    var selectedSections: Set<Int> = [] { didSet {
        print("PraxModel - selectedSections didSet:  ", selectedSections)
    //    selectedSections.forEach {
    //        print("\($0)") }
    }}
    
    
    private var _selectedPageItems: Set<IndexPath> = []
    
    var selectedPageItems: Set<IndexPath> {
        get { _selectedPageItems }
        set {
            if _selectedPageItems != newValue { _selectedPageItems = newValue
                if let indexPath = selectedPageItems.first {
                    if let pageItem = document.pageItem(indexPath: indexPath) {
                        if !pageItem.skipped {
                            _selectedPageItem = pageItem
                            if document.exportFilenameBody == "" {
                                document.setExportURL(from: pageItem) }
                            return } } }
            }
            _selectedPageItem = nil
        }
    }

    
    private var _selectedPageItem: PageItem?
    var selectedPageItem: PageItem? {
        get { _selectedPageItem }
        set {
            if newValue != _selectedPageItem, let newValue {
                _selectedPageItem = newValue
                if let indexPath = document.indexPath(for: newValue) {
                    pageItemCollectionView.selectionIndexPaths = [indexPath]
                    
                }
                
                
            }
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


extension NSImage {
    func resize(to newSize: NSSize) -> NSImage? {
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
        return resizedImage
    }
}



extension Notification.Name {
    static let praxWidthGuideChanged = Notification.Name("PraxWidthGuideChanged")
    static let praxSelectedPageItemsChanged = Notification.Name("PraxSelectedPageItemsChanged")
    static let praxPageItemTrimsChanged = Notification.Name("PraxPageItemTrimsChanged")
    //  static let praxFileSelectionChanged = Notification.Name("PraxFileSelectionChanged")
}


extension PraxModel {
    
    func receiveDroppedURL(_ url: URL, bookmarkData: Data? = nil, at indexPath: IndexPath? = nil) {
        let needsStop = url.startAccessingSecurityScopedResource()
        defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
        
        
        let ext = url.pathExtension.lowercased()
        switch (ext) {

        case "pdf":
            DispatchQueue.main.async { [self] in
                document.addPagesFromPDFURL(url, bookmarkData: bookmarkData, at: indexPath) }
            
            Task { do { try await
                document.persistence.processImportedURLs([url]) }
                catch { fatalError("It didn't work") } }
            
        case "png", "jpeg", "jpg", "gif", "heic":
            if inspectNextImageDrop {
                if let image = NSImage(contentsOf: url) {
                    inspectingImage = image
                    showingImageDropInspector = true
                }
                else { print("Failed to open Image at \(url)") }
            }
            else {
                DispatchQueue.main.async { [self] in
                    document.addPageFromImageURL(url, at: indexPath) }
            }
            
        default:
            break
            
        }
        
    }
}




/*
    private var _selectedPageItem: PageItem?
    var aselectedPageItem: PageItem? {
        get { _selectedPageItem }
        set { if _selectedPageItem != newValue { _selectedPageItem = newValue
            print ("set selectedPageItem  ", aselectedPageItem?.name ?? " *** nil ***")
            
            
            /*           if selectedPageItem != nil {
             if currentEditingMergedPage == nil {
             currentEditingMergedPage = selectedPageItem!.mergedPage
             }
             else if currentEditingMergedPage != nil, currentEditingMergedPage! != selectedPageItem!.mergedPage {
             print ("set selectedPageItem - setting currentEditingMergedPage = selectedPageItem.mergedPage")
             currentEditingMergedPage = selectedPageItem!.mergedPage }
             }
             else { print ("set selectedPageItem to **** nil **** ") }
             */
        }
        }
    }
    
*/
