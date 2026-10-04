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
final class PageItem: @preconcurrency Transferable, Identifiable, Equatable, Hashable, @unchecked Sendable {
    nonisolated static func == (lhs: PageItem, rhs: PageItem) -> Bool { lhs.id == rhs.id }
    nonisolated func hash(into hasher: inout Hasher) { hasher.combine(id) }
    nonisolated let id: UUID
    
    init(
        id: UUID = UUID(),
        prax: PraxModel,
        mergedPage: MergedPage,
        name: String,
        sourceBookmark: Data = Data(),
        sourceURL: URL,
        isLibraryFile: Bool,
        sourcePageIndex: Int = 0,
 //       pdfPage: PDFPage?,
        imageOptions: ImageImportOptions? = nil,
        dataFields: [String: FieldValue]
        
    ) {
        self.id = id
        self.prax = prax
        self.mergedPage = mergedPage
        self.name = name
        self.sourceBookmark = sourceBookmark
        self.sourceURLString = sourceURL.absoluteString
        self.isLibraryFile = isLibraryFile
        self.sourcePageIndex = sourcePageIndex
        self.imageOptions = imageOptions
        self.dataFields = dataFields
 //       self._pdfPage = pdfPage
        
    }
    
    init(transferID: UUID) {
        self.id = transferID
        
        self.prax = nil
        self.mergedPage = nil
        self.name = ""
        self.sourceBookmark = Data()
        self.sourceURLString = ""
        self.sourcePageIndex = 0
        self.isLibraryFile = false
        self.imageOptions = nil
        self.dataFields = [:]
//        self._pdfPage = nil
        
    }
    
    unowned let prax: PraxModel?
    
    var mergedPage: MergedPage?
    var name: String = ""
    var sourceBookmark: Data = Data()
    var sourceURLString: String = ""
    var isLibraryFile: Bool = false
    var sourcePageIndex: Int = 0
    var imageOptions: ImageImportOptions?
    var dataFields: [String: FieldValue] = [:] {
        didSet {
            //    print("dataFields: [String: FieldValue] didSet ", dataFields)
            mergedPage?.refreshMergedPage(refreshEditingDocument: true)
            
        }
    }
    

    private var _pdfPage: PDFPage?
    var pdfPage: PDFPage { get {
        if _pdfPage != nil { return _pdfPage! }
        return PDFPage() }
        set { _pdfPage = newValue }
    }
  
/*    let _pdfPage: PDFPage?
    var pdfPage: PDFPage {
        if _pdfPage != nil { return _pdfPage! }
        return PDFPage()
    }
*/
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .pageItemType) { @Sendable (item: PageItem) in
            return try JSONEncoder().encode(item.id)
        } importing: { @Sendable (data: Data) in
            let itemID = try JSONDecoder().decode(UUID.self, from: data)
            return await PageItem(transferID: itemID)
        }
        
        ProxyRepresentation(exporting: { @Sendable (item: PageItem) -> UUID in
            item.id
        })
    }
    
    
    
    var aspectRatio: CGFloat {
        let bounds = pdfPage.bounds(for: .cropBox)
        return bounds.size.width / bounds.size.height
    }
    var bounds: CGRect {
        return pdfPage.bounds(for: .cropBox)
    }
    
    
    @ObservationIgnored
    lazy var thumbailImage: Image = {
        var imageSize = bounds.size
        imageSize.width = imageSize.width * 2
        imageSize.height = imageSize.height * 2
        let nsImage = pdfPage.thumbnail(of: imageSize, for: .cropBox)
        return Image(nsImage: nsImage)}()
    

    func trimmedPageSize() -> CGRect {
        let minX = bounds.minX + trims.left
        let maxX = bounds.maxX - trims.right
        let minY = bounds.minY + trims.bottom
        let maxY = bounds.maxY - trims.top
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
            prax?.undoManager.registerUndo(withTarget: self, handler: {
                $0.trims = oldValue
            })
            _trims = newValue
            
            NotificationCenter.default.post(name: .praxPageItemTrimsChanged, object: self)
            
            prax?.undoManager.setActionName("Set Trims for Page \(name)")
            //     print("PageItem trims didSet")
            mergedPage?.refreshMergedPage(refreshEditingDocument: false)
            
        }
    }
    
    private var _skipped: Bool = false
    var skipped: Bool {
        get { _skipped }
        set {
            if _skipped == newValue { return }
            
            let oldValue = skipped
            prax?.undoManager.registerUndo(withTarget: self, handler: {
                $0.skipped = oldValue
            })
            _skipped = newValue
            prax?.undoManager.setActionName("Skip Page \(name)")
            //     print("PageItem skipped didSet")
            mergedPage?.refreshMergedPage(refreshEditingDocument: true)
            
            
        }
    }
    
    private var _merge: MergeMode = .mergeDown
    var merge: MergeMode {
        get { _merge }
        set {
            if _merge == newValue { return }
            let oldValue = merge
            prax?.undoManager.registerUndo(withTarget: self, handler: {
                $0.merge = oldValue
            })
            
            _merge = newValue
            prax?.undoManager.setActionName("Set Merge Mode for Page \(name)")
            //     print("PageItem merge didSet")
            mergedPage?.refreshMergedPage(refreshEditingDocument: true)
            
        }
    }
    
    
}



@Observable @MainActor
final class MergedPage: Identifiable, Equatable, Hashable {
    nonisolated static func == (lhs: MergedPage, rhs: MergedPage) -> Bool { lhs.id == rhs.id }
    nonisolated func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: UUID
    unowned let prax: PraxModel
    var title: String
    init(id: UUID = UUID(),
         prax: PraxModel,
         title: String,
         pageItems: [PageItem] = []) { self.id = id
        self.prax = prax
        self.title = title
        self.pageItems = pageItems
    }
    
    var pdfPage: PDFPage? = nil
    
    var selectedPages = Set<PageItem.ID>()
    var aspectRatio: CGFloat {
        guard mergedHeightPts != 0 else { return 0 }
        return mergedWidthPts / mergedHeightPts
    }
    var minWidthPts: CGFloat = 0
    var mergedWidthPts: CGFloat = 0
    var mergedHeightPts: CGFloat = 0
    func mergeModePages() -> Int {
        var count = 0
        for pageItem in pageItems { if !pageItem.skipped { count += 1 } }
        return count
    }
    
    private var _pageItems: [PageItem] = []
    var pageItems: [PageItem] {
        get { _pageItems }
        set { guard newValue != _pageItems else { return }
            let oldValue = pageItems
            prax.undoManager.registerUndo(withTarget: self, handler: { $0.pageItems = oldValue })
            prax.undoManager.setActionName(oldValue.count < newValue.count ? "Add Page Items to Merged Page \(title)" : "Remove Page Items from Merged Page \(title)")
            _pageItems = newValue
            refreshMergedPage(refreshEditingDocument: true)
        }
    }
    
    private var _skipped: Bool = false
    var skipped: Bool {  get { _skipped }
        set { if _skipped == newValue { return }
            let oldValue = skipped
            prax.undoManager.registerUndo(withTarget: self, handler: { $0.skipped = oldValue })
            _skipped = newValue
            prax.undoManager.setActionName("Skip Merged Page \(title)")
            print("MergedPage skipped didSet")
            refreshMergedPage(refreshEditingDocument: true)
        }
    }
    
    var skippedPages: Int { get { var count = 0
            for pageItem in pageItems { if pageItem.skipped {count += 1} }
            return count } }
    
    func skipAllPages() { for pageItem in pageItems {
                    if !pageItem.skipped { pageItem.skipped = true } }
    }
    
    func includeAllPages() { for pageItem in pageItems {
                    if pageItem.skipped { pageItem.skipped = false } }
    }
    
    var refreshingMergedPage = false
    func refreshMergedPage(refreshEditingDocument: Bool) {
        if refreshingMergedPage {return}

        refreshingMergedPage = true
        print("refreshMergedPage - starting")

        Task {
            
            var maxVisibleWidth: CGFloat = 0
            var minVisibleWidth: CGFloat = .greatestFiniteMagnitude
            var totalVisibleHeight: CGFloat = 0
            
            for pageItem in pageItems where !pageItem.skipped {
                let vis = PDFGeometry.visibleRect(media: pageItem.bounds, trims: pageItem.trims, seamTop: 0, seamBottom: 0)
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
                
                let trimmedMedia = pageItem.bounds.trimmed(pageItem.trims, seamTop: 0, seamBottom: 0)
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
                
                let trimmedMedia = pageItem.bounds.trimmed(pageItem.trims, seamTop: 0, seamBottom: 0)
                let dx = 0 - trimmedMedia.minX
                let dy = placedOriginsY[pageIndex] - trimmedMedia.minY
                
                let keys = pageItem.dataFields.keys
                //              print(keys)
                for annotation in pageItem.pdfPage.annotations {
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
                        }
                    }
                    
                    guard annotation.fieldName != nil else { continue }
                    guard let copiedAnnotation = annotation.copy() as? PDFAnnotation else { continue }
                    
                    // Translate annotation bounds from source page space into merged page space
                    let translatedBounds = annotation.bounds.offsetBy(dx: dx, dy: dy)
                    copiedAnnotation.bounds = translatedBounds
/*
                    switch prax.annotationSaveMode {
                    case .locked: copiedAnnotation.isReadOnly = true
                    default:  copiedAnnotation.isReadOnly = false
                    }
 */
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
            if refreshEditingDocument { prax.document.refreshEditingDocument() }
            else { prax.document.refreshMergedDocument() }
        }
    }
}



