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
    
    
    
    //    var mergedDocumentPDFView: PDFView?
    /*
     var splitView: NSSplitView?
     var dividerZeroMinPos: CGFloat = 100
     var dividerZeroMaxPos: CGFloat = 400
     var dividerOneMinPos: CGFloat = 400
     var dividerOneMaxPos: CGFloat = 700
     var dividerZeroPos: CGFloat = 100 {
     didSet { updateDividerLimits() }
     }
     var dividerOnePos: CGFloat = 400 {
     didSet { updateDividerLimits() }
     }
     
     var splitViewFrameWidth: CGFloat = 1000 {
     didSet { updateDividerLimits() }
     }
     func updateDividerLimits() {
     //   dividerZeroMinPos = min(100, splitViewFrameWidth / 10)
     dividerZeroMaxPos = max(100, (splitView!.arrangedSubviews[1].frame.size.width) / 2)
     dividerOneMaxPos = splitViewFrameWidth - 200
     dividerOneMinPos = dividerZeroPos + 300
     //    print ("updateDividerLimits dividerZeroMinPos: ", dividerZeroMinPos, " dividerZeroMaxPos: ", dividerZeroMaxPos, "dividerOneMinPos: ", dividerOneMinPos, " dividerOneMaxPos: ", dividerOneMaxPos )
     }
     
     */
    
    
    enum HoverSection {
        case editingDocument
        case mergedDocument
    }
    
    
    var hoverSection: Set<HoverSection> = []
    
    
    var selectedFiles = Set<PDFFile.ID>() {
        didSet {
            print ("PraxModel - MergedPDFDocument selectedFiles didSet: ", selectedFiles.count) //, selectedFiles.description)
            //         isLoadingPDF = true
            //            selectedPageItems = []
            //           clearWidthGuide()
            
            
            /*            DispatchQueue.main.async {
             print ("Dispatch setEditingPDFDocumentFromSelectedFiles()")
             self.setPageSectionsFromSelectedFiles()
             self.refreshMergedDocument()
             }
             */    }
    }
    
    /*
     private var _currentEditingPDFPage: PDFPage?
     var currentEditingPDFPage: PDFPage? {
     get { _currentEditingPDFPage }
     set {
     if _currentEditingPDFPage != newValue {
     _currentEditingPDFPage = newValue
     
     if let currentEditingPDFPage {
     if let currentEditingPageItem {
     if currentEditingPageItem.pdfPage != currentEditingPDFPage {
     print("PraxModel - currentEditingPDFPage didSet:  currentEditingPageItem.pdfPage != currentEditingPDFPage")
     self.currentEditingPageItem = document.pageItem(for: currentEditingPDFPage)
     }
     editingDocumentPDFView.go(to: currentEditingPDFPage)
     }
     else {
     if document.editingPDFDocument.pageCount > 0 {
     currentEditingPageIndex = document.editingPDFDocument.index(for: currentEditingPDFPage)
     }
     }
     }
     
     print("PraxModel - currentEditingPDFPage didSet:  ", currentEditingPDFPage != nil ? currentEditingPDFPage! : "No PDFPage", " - Marie")
     }
     }
     }
     */
    
    /*    private var _currentEditingPageIndex: Int = NSNotFound
     var currentEditingPageIndex: Int {
     get { _currentEditingPageIndex }
     set {
     if document.refreshingEditingDocument { return }
     
     print("set currentEditingPageIndex: Int = ", newValue)
     if newValue == NSNotFound {
     if document.editingPDFDocument.pageCount > 0 {
     _currentEditingPageIndex = currentEditingMergedPage?.pageItems.firstIndex(of: currentEditingPageItem)
     }
     else { fatalError("set currentEditingPageIndex:  document.editingPDFDocument.pageCount > 0  *** NOT ***") }
     
     }
     else {
     _currentEditingPageIndex = newValue
     
     if let pdfPage = document.editingPDFDocument.page(at: currentEditingPageIndex) {
     guard let pageItem = document.pageItem(for: pdfPage)
     
     else {
     print ("No Such Number")
     return
     //       fatalError("set currentEditingPageIndex:  No pageItem = document.pageItem(for: pdfPage) ")
     }
     
     guard let indexPath = document.indexPath(for: pageItem)
     else { fatalError("set currentEditingPageIndex:  No indexPath for pageItem ") }
     
     if currentEditingMergedPage !=  pageItem.mergedPage {
     currentEditingMergedPage =  pageItem.mergedPage
     }
     
     if currentEditingPageItem != pageItem {
     currentEditingPageItem = pageItem
     }
     
     DispatchQueue.main.async { [self] in
     withAnimation {
     selectedEditPages = [indexPath]
     pageEditCollectionView.scrollToItems(at: [indexPath], scrollPosition: .centeredVertically)
     pageEditCollectionView.selectionIndexPaths = [indexPath]
     }
     }
     }
     else {
     
     fatalError("set currentEditingPageIndex:  document.editingPDFDocument.pageCount > 0  *** NOT ***")
     
     }
     
     
     
     
     
     
     }
     }
     }
     */
    
    
    private var _currentEditingMergedPage: MergedPage?
    var currentEditingMergedPage: MergedPage? {
        get { _currentEditingMergedPage }
        set {
            if let mergedPage = newValue {
                if mergedPage.mergeModePages > 0 {
                    _currentEditingMergedPage = newValue
                    if currentEditingPageItem == nil {
                        currentEditingPageItem = mergedPage.pageItems.first(where: {$0.skipped == false})
                    }
                }
                else {
                    print ("do not set currentEditingMergedPage - mergedPage.mergeModePages 0 ")
                }
            }
            else {
                print ("set currentEditingMergedPage to **** nil **** ")
                _currentEditingMergedPage = newValue
            }
            
            if _currentEditingMergedPage != newValue {
            _currentEditingMergedPage = newValue
            if let currentEditingMergedPage, let pageItem = currentEditingMergedPage.pageItems.first {
                    print ("set currentEditingMergedPage document.setExportURL(from: pageItem) ")
                    document.setExportURL(from: pageItem)
                    if currentEditingPageItem == nil {
                        print ("set currentEditingMergedPage currentEditingPageItem = pageItem) ")
                        currentEditingPageItem = pageItem } }
            else { print ("set currentEditingMergedPage to **** nil **** ") } }
    } }
    
    private var _currentEditingPageItem: PageItem?
    var currentEditingPageItem: PageItem? {
        get { _currentEditingPageItem }
        set { if _currentEditingPageItem != newValue { _currentEditingPageItem = newValue
            print ("set currentEditingPageItem  ", currentEditingPageItem?.name ?? " *** nil ***")
            if currentEditingPageItem != nil {
                if currentEditingMergedPage == nil {
                    currentEditingMergedPage = currentEditingPageItem!.mergedPage
                }
                else if currentEditingMergedPage != nil, currentEditingMergedPage! != currentEditingPageItem!.mergedPage {
                    print ("set currentEditingPageItem - setting currentEditingMergedPage = currentEditingPageItem.mergedPage")
                    currentEditingMergedPage = currentEditingPageItem!.mergedPage }
            }
            else { print ("set currentEditingPageItem to **** nil **** ") }
        }
    } }
    
    var selectedSections: Set<Int> = [] { didSet {
        print("PraxModel - selectedSections didSet:  ", selectedSections)
    //    selectedSections.forEach {
    //        print("\($0)") }
    }}
    
    var selectedPageItems: Set<IndexPath> = [] { didSet {
        print("PraxModel - selectedPageItems didSet:  ", selectedPageItems)
        if let indexPath = selectedPageItems.first {
            if let pageItem = document.pageItem(indexPath: indexPath) {
                if !pageItem.skipped {
                    currentEditingPageItem = pageItem
                }
            }
        }
    }}
    
    
    private var _selectedEditPages: Set<IndexPath> = []
    var selectedEditPages: Set<IndexPath> {
        get { _selectedEditPages  }
        set {
            if newValue == _selectedEditPages {return}
            _selectedEditPages = newValue
            if selectedPageItems != newValue {
                pageItemCollectionView.selectionIndexPaths = newValue
                selectedPageItems = newValue
            }
            
            if let indexPath = selectedEditPages.first {
                if let collectionItem = pageEditCollectionView.item(at: indexPath) {
                    guard let pageItem = collectionItem.representedObject as? PageItem
                    else { fatalError("selectedEditPages: representedObject as? PageItem - NOT FOUND") }
                    
                    if currentEditingPageItem != pageItem {
                        currentEditingPageItem = pageItem
                    }
                }
            }
            print("selectedEditPages set to: ", selectedEditPages)
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
    //  static let praxFileSelectionChanged = Notification.Name("PraxFileSelectionChanged")
}


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

