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
    unowned private(set) var documment: MergedPDFDocument!

    init() {
        // Document will be attached immediately after both instances are created.
        // We keep it implicitly unwrapped to avoid unsafe placeholders while still
        // making it non-optional for consumers once attached.
    }

    func attach(document: MergedPDFDocument) {
        self.documment = document
    }

    enum PraxPressMode: String, CaseIterable {
        case data = "Data Mode"
        case merge = "Merge Mode"
        case prax = "Prax Mode"
        
        var color: Color {
            switch self {
            case .merge:
                return .pink
            case .data:
                return .blue
            case .prax:
                return .orange
            }
        }
        
        // And an icon, because why not?
        var icon: String {
            switch self {
            case .merge:
                return "apple.logo"
            case .data:
                return "swift"
            case .prax:
                return "gear"
            }
        }
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

    var selectedMergedPage: MergedPage? { didSet {
        if selectedMergedPage != nil {
            print("PraxModel - selectedMergedPage didSet:  ", selectedMergedPage!.title, "Julie d'Prax")
        }
        
    }}
    
    var editingDocumentCurrentPage: Int = -1 {
        didSet {
            print("editingDocumentCurrentPage: Int = ", editingDocumentCurrentPage)
            
            if editingDocumentCurrentPage == NSNotFound { return }
            
            if let mergedPage = selectedMergedPage {
                if mergedPage.pageItems.count > editingDocumentCurrentPage {
                    currentEditPage = mergedPage.pageItems[editingDocumentCurrentPage]
                    let indexPath = IndexPath(item: editingDocumentCurrentPage, section: 0)
                    withAnimation {
                        pageEditCollectionView.scrollToItems(at: [indexPath], scrollPosition: .centeredVertically)
                        pageEditCollectionView.selectionIndexPaths = [indexPath]
                    }
                    
                }
            }
        }
    }
 

    var currentEditPage: PageItem? { didSet {
        if let currentEditPage {
            var currentIndex = documment.editingPDFDocument.index(for: currentEditPage.pdfPage)
            if currentIndex == NSNotFound { currentIndex = 0 }
            if editingDocumentCurrentPage != currentIndex {
                editingDocumentCurrentPage = currentIndex
            }
            print("PraxModel - currentEditPage didSet:  ", currentEditPage.name, "Juliette M. Belanger")
            
            
        }
        else {
            if editingDocumentCurrentPage != 0 {
                editingDocumentCurrentPage = 0
            }
        }
        
    }}
    
    var selectedSections: Set<Int> = [] { didSet {
        print("PraxModel - electedSections didSet:  ", selectedSections)
    //    selectedSections.forEach {
    //        print("\($0)") }
    }}
    
    var selectedPageItems: Set<IndexPath> = [] { didSet {
        print("PraxModel - selectedPageItems didSet:  ", selectedPageItems)
        if !selectedPageItems.isEmpty {
            currentEditPage = documment.pageItem(indexPath: selectedPageItems.first!)
        }
    //    selectedPageItems.forEach {
    //        print("\($0)") }
    }}
    
   var selectedEditPages: Set<IndexPath> = [] { didSet {
        print("PraxModel - selectedEditPages didSet:  ", selectedEditPages)
        }
    //          selectedPages.forEach {
    //              print("\($0)") }}
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

