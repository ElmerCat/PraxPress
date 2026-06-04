//
//  PagesModel.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/26/26.
//

// Model objects: PDFPageItemModel & PDFPageSectionModel
//   and
// PagesPersistenceController




import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers
import OSLog


@Observable @MainActor
final class MergedPage: Identifiable, Equatable, Hashable {
    nonisolated static func == (lhs: MergedPage, rhs: MergedPage) -> Bool { lhs.id == rhs.id }
    nonisolated func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: UUID
    unowned let prax: PraxModel
    var title: String
    init(
        id: UUID = UUID(),
        prax: PraxModel,
        title: String,
        pageItems: [PageItem] = []
    ) {
        self.id = id
        self.prax = prax
        self.title = title
        self.pageItems = pageItems
    }
    
    var pdfPage: PDFPage? = nil
    var editingPDFDocument = PDFDocument()
    var aspectRatio: CGFloat {
        guard mergedHeightPts != 0 else { return 0 }
        return mergedWidthPts / mergedHeightPts
    }
    var minWidthPts: CGFloat = 0
    var mergedWidthPts: CGFloat = 0
    var mergedHeightPts: CGFloat = 0
    var mergeModePages = 0
    
    private var _pageItems: [PageItem] = []
    var pageItems: [PageItem] {
        get { _pageItems }
        set {
            guard newValue != _pageItems else { return }
            
            let oldValue = pageItems
            prax.undoManager.registerUndo(withTarget: self, handler: {
                $0.pageItems = oldValue
            })
            prax.undoManager.setActionName(oldValue.count < newValue.count ? "Add Page Items to Merged Page \(title)" : "Remove Page Items from Merged Page \(title)")

 
            _pageItems = newValue
            refreshEditingDocument()
        }
    }
    
    private var _skipped: Bool = false
    var skipped: Bool {
        get { _skipped }
        set {
            if _skipped == newValue { return }
            
            let oldValue = skipped
            prax.undoManager.registerUndo(withTarget: self, handler: {
                $0.skipped = oldValue
            })
            _skipped = newValue
            prax.undoManager.setActionName("Skip Merged Page \(title)")
            print("MergedPage skipped didSet")
            refreshEditingDocument()

        }
    }
    
    var skippedPages: Int {
        get {
            var count = 0
            for pageItem in pageItems {
                if pageItem.skipped {count += 1}
            }
            return count
        }
    }
    func skipAllPages() {
        
            for pageItem in pageItems {
                    if !pageItem.skipped {
                        pageItem.skipped = true
                    }
            }
        
    }
    
    func includeAllPages() {
        
            for pageItem in pageItems {
                    if pageItem.skipped {
                        pageItem.skipped = false
                    }
            }
       
    }
    
    var dataFieldPage: PageItem?

    @ObservationIgnored private var pendingEditingRefresh = false
    @ObservationIgnored private var pendingMergedRefresh = false
    
    var refreshingEditingDocument = false
    var editingDocumentVersion = UUID()

    func refreshEditingDocument() {
        if refreshingEditingDocument {
            pendingEditingRefresh = true
            return
        }
        refreshingEditingDocument = true

        print("refreshEditingDocument - starting")

        Task {
        //    try? await Task.sleep(for: .milliseconds(100))

            dataFieldPage = nil

            var insertIndex = 0
            let pdfDocument = PDFDocument()

            for pageItem in pageItems {
                if !pageItem.skipped {
                    pdfDocument.insert(pageItem.pdfPage, at: insertIndex)
                    if !pageItem.dataFields.isEmpty {
                        if dataFieldPage == nil {
                            dataFieldPage = pageItem
                        }
                        else {
                          //  prax.moreThanOneDataPageError()
                        }
                        
                    }
                    insertIndex += 1
                }
            }

            mergeModePages = insertIndex
            editingPDFDocument = pdfDocument
            editingDocumentVersion = UUID()
            refreshingEditingDocument = false

            print("refreshEditingDocument — done")

            if pendingEditingRefresh {
                pendingEditingRefresh = false
                refreshEditingDocument()
                return
            }

            refreshMergedPage()
        }
    }
    
    
    
    var refreshingMergedPage = false

    func refreshMergedPage() {
        if refreshingMergedPage || refreshingEditingDocument {
            pendingMergedRefresh = true
            return
        }
        refreshingMergedPage = true

        var pageIndex = 0
        for pageItem in pageItems {
            if !pageItem.skipped {
                guard let pdfPage = editingPDFDocument.page(at: pageIndex) else {
                    PraxLogger.shared.logWarning(
                        "Failed to retrieve PDF page at index \(pageIndex) for \(self.title)",
                        category: .pdf
                    )
                    refreshingMergedPage = false
                    return
                }

                guard pdfPage == pageItem.pdfPage else {
                    PraxLogger.shared.logWarning(
                        "PDF page mismatch at index \(pageIndex); pages may have been reordered",
                        category: .pdf
                    )
                    refreshingMergedPage = false
                    return
                }
                pageIndex += 1
            }
        }
        guard mergeModePages == pageIndex else {
            PraxLogger.shared.logError(
                "Page count mismatch: expected \(mergeModePages), got \(pageIndex)",
                category: .pdf
            )
            refreshingMergedPage = false
            return
        }

        if mergeModePages < 1 {
            pdfPage = nil
            minWidthPts = 0
            mergedWidthPts = 0
            mergedHeightPts = 0
            refreshingMergedPage = false

            if pendingMergedRefresh {
                pendingMergedRefresh = false
                refreshMergedPage()
                return
            }

            prax.document.refreshMergedDocument()
            return
        }

        Task {
          //  try? await Task.sleep(for: .milliseconds(100))

            var maxVisibleWidth: CGFloat = 0
            var minVisibleWidth: CGFloat = .greatestFiniteMagnitude
            var totalVisibleHeight: CGFloat = 0

            for pageItem in pageItems where !pageItem.skipped {
                let vis = PDFGeometry.visibleRect(media: pageItem.media, trims: pageItem.trims, seamTop: 0, seamBottom: 0)
                maxVisibleWidth = max(maxVisibleWidth, vis.width)
                minVisibleWidth = min(minVisibleWidth, vis.width)
                totalVisibleHeight += vis.height
            }

            minWidthPts = minVisibleWidth
            mergedWidthPts = maxVisibleWidth
            mergedHeightPts = totalVisibleHeight
 
            var mediaBox = CGRect(x: 0, y: 0, width: mergedWidthPts, height: mergedHeightPts)
            
            let tmpOut = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf")
            guard let consumer = CGDataConsumer(url: tmpOut as CFURL) else { fatalError("CGDataConsumer failed") }
            guard let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { fatalError("CGContext failed") }
            
            ctx.beginPDFPage([kCGPDFContextMediaBox as String: mediaBox] as CFDictionary)
            
            
            // Stack pages from top to bottom. Track the Y origin of each placed slice for annotation mapping.
            var currentTop = mergedHeightPts
            var placedOriginsY: [CGFloat] = Array(repeating: 0, count: pageItems.count)
            
            
            for (pageIndex, pageItem) in pageItems.enumerated() {
                if pageItem.skipped { continue }
                    
                    let trimmedMedia = pageItem.media.trimmed(pageItem.trims, seamTop: 0, seamBottom: 0)
                    let trimmedWidth = trimmedMedia.width
                    let trimmedHeight = trimmedMedia.height
                    guard trimmedWidth > 0, trimmedHeight > 0 else {
                        currentTop -= (max(0, trimmedHeight)) // + interPageGap)
                        continue
                    }

                    // Place the slice at the LEFT edge (x = 0) and directly under the running top
                    let destX: CGFloat = 0
                    let destY: CGFloat = currentTop - trimmedHeight
                    placedOriginsY[pageIndex] = destY
                    
                    ctx.saveGState()
                    // Translate so that (trimmedMedia.minX, trimmedMedia.minY) in page space lands at (destX, destY) in canvas space
                    ctx.translateBy(x: destX - trimmedMedia.minX, y: destY - trimmedMedia.minY)
                    // Clip in the CURRENT (translated) coordinate system using a rect defined in PAGE space coordinates
                    // Because we translated by (-vis.minX, -vis.minY), the clip rect is simply:
                    ctx.clip(to: trimmedMedia)
                    
                    if let cgPage = pageItem.pdfPage.pageRef {
                        ctx.drawPDFPage(cgPage)
                    } else {
                        pageItem.pdfPage.draw(with: .cropBox, to: ctx)
                    }
                    ctx.restoreGState()
                    
                    currentTop -= trimmedHeight // (visibleHeight + interPageGap)
                   
            }
            ctx.endPDFPage()
            ctx.closePDF()
            
            guard let tempDoc = PDFDocument(url: tmpOut) else { fatalError("PDFDocument(url: tmpOut) failed") }
            guard let mergedPDFPage = tempDoc.page(at: 0) else { fatalError("mergedDoc.page(at: 0) failed") }
            
            for (pageIndex, pageItem) in pageItems.enumerated() {
                if pageItem.skipped { continue }
                
                let trimmedMedia = pageItem.media.trimmed(pageItem.trims, seamTop: 0, seamBottom: 0)
                let dx = 0 - trimmedMedia.minX
                let dy = placedOriginsY[pageIndex] - trimmedMedia.minY
                
                let keys = pageItem.dataFields.keys
                print(keys)
                
                for annotation in pageItem.pdfPage.annotations {
                    // Only handle form fields; skip others as before
                    
//                    print("\(String(describing: annotation.fieldName)) - \(annotation.widgetFieldType) - \(String(describing: annotation.widgetStringValue))")
                    
                    if let key = annotation.fieldName {
                        if keys.contains(key) {
                            if let value = annotation.widgetStringValue {
                           //     print("key: ", key, " - widgetStringValue: ", value, " - pageItemValue: ", pageItem.dataFields[key]!.stringValue!)
                                if value != pageItem.dataFields[key]!.stringValue! {
                                    annotation.widgetStringValue = pageItem.dataFields[key]!.stringValue!
                                }
                            }
                            else  {
                                print("key: ", key, " - value: ")

                            }
                          //  annotation.widgetStringValue = "Julie d'Prax"

                        }
                        
                    }
                    
                    guard annotation.fieldName != nil else { continue }
                    guard let copiedAnnotation = annotation.copy() as? PDFAnnotation else { continue }
                    
                    // Translate annotation bounds from source page space into merged page space
                    let translatedBounds = annotation.bounds.offsetBy(dx: dx, dy: dy)
                    copiedAnnotation.bounds = translatedBounds
                    
                    
                    switch prax.annotationSaveMode {
                    case .locked:
                        copiedAnnotation.isReadOnly = true
                    default:
                        copiedAnnotation.isReadOnly = false
                    }
                    
                    
                    mergedPDFPage.addAnnotation(copiedAnnotation)
                    
                    // Preserve text values for text widgets
                    
                    if copiedAnnotation.widgetFieldType == .text {
                        if let v = copiedAnnotation.widgetStringValue, !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            copiedAnnotation.widgetStringValue = v
                        }
                    }
                }
            }
            
            pdfPage = mergedPDFPage
            
            do { try FileManager.default.removeItem(at: tmpOut) }
            catch {  print("FileManager.default.removeItem(at: tmpOut) failed", error.localizedDescription) }

            refreshingMergedPage = false

                    if pendingMergedRefresh {
                        pendingMergedRefresh = false
                        refreshMergedPage()
                        return
                    }

                    prax.document.refreshMergedDocument()

        }
       
    }
    
    func mergedPageItem() -> PageItem {
        return PageItem(
            prax: prax,
            mergedPage: self,
            name: self.title,
            sourceURL: URL(string: "/")!,
            pdfPage: self.pdfPage ?? PDFPage(),
            dataFields: [:]
        )
    }
    
}

@Observable @MainActor
final class PageItem: Identifiable, Equatable, Hashable {
    nonisolated static func == (lhs: PageItem, rhs: PageItem) -> Bool { lhs.id == rhs.id }
    nonisolated func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: UUID
    unowned let prax: PraxModel          // was: var prax: PraxModel
    var mergedPage: MergedPage {         // was plain stored var
        didSet {
            guard oldValue !== mergedPage else { return }
            oldValue.refreshEditingDocument()
            mergedPage.refreshEditingDocument()
        }
    }
    var name: String
    var sourceBookmark: Data
    var sourceURLString: String
    var sourcePageIndex: Int
    var dataFields: [String: FieldValue] {
        didSet {
            print("dataFields: [String: FieldValue] didSet ", dataFields)
            mergedPage.refreshEditingDocument()
        }
    }
    
  
    let pdfPage: PDFPage
    let media: CGRect
    let aspectRatio: CGFloat
    
    init(
        id: UUID = UUID(),
        prax: PraxModel,
        mergedPage: MergedPage,
        name: String,
        sourceBookmark: Data = Data(),
        sourceURL: URL,
        sourcePageIndex: Int = 0,
        pdfPage: PDFPage,
        dataFields: [String: FieldValue]

    ) {
        self.id = id
        self.prax = prax
        self.mergedPage = mergedPage
        self.name = name
        self.sourceBookmark = sourceBookmark
        self.sourceURLString = sourceURL.absoluteString
        self.sourcePageIndex = sourcePageIndex
        self.dataFields = dataFields
        self.pdfPage = pdfPage
        self.aspectRatio = {
            let bounds = pdfPage.bounds(for: .cropBox)
            return bounds.size.width / bounds.size.height
        }()
        self.media = {
            return pdfPage.bounds(for: .cropBox)
        }()
    }
    
    
    
    func trimmedPageSize() -> CGRect {
        let minX = media.minX + trims.left
        let maxX = media.maxX - trims.right
        let minY = media.minY + trims.bottom
        let maxY = media.maxY - trims.top
        let w = max(0, maxX - minX)
        let h = max(0, maxY - minY)
        return CGRect(x: minX, y: minY, width: w, height: h)
    }
    
    @ObservationIgnored
    private var _overlayView: PDFPageOverlayView?
    var overlayView: PDFPageOverlayView {
        if let view = _overlayView { return view }
        let view = PDFPageOverlayView(pageItem: self)
        _overlayView = view
        return view
    }
    

    private var _trims: EdgeTrims = .zero
    var trims: EdgeTrims {
        get { _trims }
        set {
            if _trims == newValue { return }
            
            let oldValue = trims
            prax.undoManager.registerUndo(withTarget: self, handler: {
                $0.trims = oldValue
            })
            _trims = newValue
            
            NotificationCenter.default.post(
                name: .praxPageItemTrimsChanged,
                object: self
            )
            
            prax.undoManager.setActionName("Set Trims for Page \(name)")
            print("PageItem trims didSet")
            
            mergedPage.refreshMergedPage()
        }
    }
    
    private var _skipped: Bool = false
    var skipped: Bool {
        get { _skipped }
        set {
            if _skipped == newValue { return }
            
            let oldValue = skipped
            prax.undoManager.registerUndo(withTarget: self, handler: {
                $0.skipped = oldValue
            })
            _skipped = newValue
            prax.undoManager.setActionName("Skip Page \(name)")
            print("PageItem skipped didSet")
            mergedPage.refreshEditingDocument()

        }
    }
    
    private var _merge: MergeMode = .mergeDown
    var merge: MergeMode {
        get { _merge }
        set {
            if _merge == newValue { return }
            let oldValue = merge
            prax.undoManager.registerUndo(withTarget: self, handler: {
                $0.merge = oldValue
            })
            
            _merge = newValue
            prax.undoManager.setActionName("Set Merge Mode for Page \(name)")
            print("PageItem merge didSet")
            mergedPage.refreshEditingDocument()
        }
    }
}
