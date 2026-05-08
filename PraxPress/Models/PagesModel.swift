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


@Observable @MainActor
final class MergedPage: Identifiable, Equatable, Hashable {
    nonisolated static func == (lhs: MergedPage, rhs: MergedPage) -> Bool { lhs.id == rhs.id }
    nonisolated func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: UUID
    let document: MergedPDFDocument
    var title: String
    init(
        id: UUID = UUID(),
        document: MergedPDFDocument,
        title: String,
        pageItems: [PageItem] = []
    ) {
        self.id = id
        self.document = document
        self.title = title
        self.pageItems = pageItems
    }
    
    var pdfPage: PDFPage? = nil
    var editingPDFDocument = PDFDocument()
    var aspectRatio: CGFloat {
        mergedWidthPts / mergedHeightPts}
    var minWidthPts: CGFloat = 0
    var mergedWidthPts: CGFloat = 0
    var mergedHeightPts: CGFloat = 0
    var mergeModePages = 0
    
    private var _pageItems: [PageItem] = []
    var pageItems: [PageItem] {
        get { _pageItems }
        set {
            if newValue != _pageItems {
                var wasCurrentItem: PageItem?
                if document.prax.selectedPageItem != nil && pageItems.contains(document.prax.selectedPageItem!) {
                    wasCurrentItem = document.prax.selectedPageItem!
                }
                _pageItems = newValue
                if let wasCurrentItem, !pageItems.contains(wasCurrentItem) {
                    refreshEditingDocument(wasCurrentItem)
                }
                else {
                    refreshEditingDocument()
                }
                    
          }
    } }
    
    private var _skipped: Bool = false
    var skipped: Bool {
        get { _skipped }
        set {
            if _skipped == newValue { return }
            
            let oldValue = skipped
            document.prax.undoManager.registerUndo(withTarget: self, handler: {
                $0.skipped = oldValue
            })
            _skipped = newValue
            document.prax.undoManager.setActionName("Skip Merged Page \(title)")
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
    
    var hasDataFields = false
    var dataFields: [String: FieldValue] = [:]
    

    
    var  refreshingEditingDocument = false
    var editingDocumentVersion = UUID()
    func refreshEditingDocument(_ wasCurrentItem: PageItem? = nil) {
        if refreshingEditingDocument { return }
        refreshingEditingDocument = true

        print("refreshEditingDocument - starting")
        
        let norma = Task {
            
            try? await Task.sleep(for:.milliseconds(100))
            
            var insertIndex = 0
            let pdfDocument = PDFDocument()
            
            for pageItem in pageItems {
                    if !pageItem.skipped {
                        pdfDocument.insert(pageItem.pdfPage, at: insertIndex)
                        if !pageItem.dataFields.isEmpty {
                            dataFields = pageItem.dataFields
                            hasDataFields = true
                            
                        }
                        insertIndex += 1
                    }
            }
            mergeModePages = insertIndex

/*
            if mergeModePages == 0 && document.prax.selectedPageItem?.mergedPage == self {
     //           document.prax.currentEditingMergedPage = nil
                if let curentItem = document.prax.selectedPageItem, pageItems.contains(curentItem) {
                    document.prax.selectedPageItem = nil
                }
            }
            else if let wasCurrentItem {
                document.prax.selectedPageItem = wasCurrentItem
            }
  //          else if mergeModePages > 0 && document.prax.currentEditingMergedPage == nil {
                
   //             document.prax.currentEditingMergedPage = self
   //         }
                
            
 */
              
            self.editingPDFDocument = pdfDocument
            editingDocumentVersion = UUID()
            
            refreshingEditingDocument = false
            print("refreshEditingDocument — done")

            refreshMergedPage()
        }
    }
    
    
    
    var refreshingMergedPage = false
    func refreshMergedPage() {
        
        if refreshingMergedPage || refreshingEditingDocument { return }
        refreshingMergedPage = true
        
        var pageIndex = 0
        for pageItem in pageItems {
            if !pageItem.skipped {
                // Confirm document page matches pageItem
                guard let pdfPage = editingPDFDocument.page(at: pageIndex)
                else {fatalError(" pageItem.pdfPage editingPDFDocument.page(at: pageIndex)")}
                guard pdfPage == pageItem.pdfPage
                else {fatalError(" pageItem.pdfPage == pdfPage *** NOT ***")}
                pageIndex += 1
            }
        }
        guard mergeModePages == pageIndex
        else {fatalError(" mergeModePages == pageIndexe *** NOT ***")}
        
        if mergeModePages < 1 {
            pdfPage = nil 
            refreshingMergedPage = false
            document.refreshMergedDocument()
            return
        }

        let jean = Task {
            try? await Task.sleep(for:.milliseconds(100))
 //           print("refreshMergedPage — started")
            
            
            var maxVisibleWidth: CGFloat = 0
            var minVisibleWidth: CGFloat = 9999.0
            var totalVisibleHeight: CGFloat = 0
           
            for pageItem in pageItems {
                
                if !pageItem.skipped {
                    let vis = PDFGeometry.visibleRect(media: pageItem.media, trims: pageItem.trims, seamTop: 0, seamBottom: 0)
                    maxVisibleWidth = max(maxVisibleWidth, vis.width)
                    minVisibleWidth = min(minVisibleWidth, vis.width)
                    
                    totalVisibleHeight += vis.height
                }
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
                                print("key: ", key, " - widgetStringValue: ", value, " - pageItemValue: ", pageItem.dataFields[key]!.stringValue!)
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
     /*
                    // Destination rect for this slice in merged page coordinates
                    let destSliceRect = CGRect(x: 0,
                                               y: placedOriginsY[pageIndex],
                                               width: trimmedMedia.width,
                                               height: trimmedMedia.height)
                    
                    // Fit while preserving center as much as possible
                    let minSize: CGFloat = 2.0
                    
                    // Start from original center
                    let centerX = translatedBounds.midX
                    let centerY = translatedBounds.midY
                    
                    // Compute the max size that fits within the slice while centered at (centerX, centerY)
                    var targetWidth = translatedBounds.width
                    var targetHeight = translatedBounds.height
                    
                    // Limit size to slice dimensions
                    targetWidth = min(targetWidth, destSliceRect.width)
                    targetHeight = min(targetHeight, destSliceRect.height)
                    
                    // Ensure minimum size
                    targetWidth = max(targetWidth, minSize)
                    targetHeight = max(targetHeight, minSize)
                    
                    // Build a rect of the target size centered at original center
                    var fitted = CGRect(x: centerX - targetWidth / 2.0,
                                        y: centerY - targetHeight / 2.0,
                                        width: targetWidth,
                                        height: targetHeight)
                    
                    // If this centered rect spills outside the slice, clamp position while keeping size
                    if fitted.minX < destSliceRect.minX {
                        fitted.origin.x = destSliceRect.minX
                    }
                    if fitted.maxX > destSliceRect.maxX {
                        fitted.origin.x = destSliceRect.maxX - fitted.width
                    }
                    if fitted.minY < destSliceRect.minY {
                        fitted.origin.y = destSliceRect.minY
                    }
                    if fitted.maxY > destSliceRect.maxY {
                        fitted.origin.y = destSliceRect.maxY - fitted.height
                    }
                    
                    // Final safety: ensure we still overlap the slice (in case slice is extremely small)
                    guard fitted.intersects(destSliceRect) else { continue }
   */
                    copiedAnnotation.bounds = translatedBounds
                    
                    copiedAnnotation.isReadOnly = true
                    
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
            document.refreshMergedDocument()

        }
       
    }
    
    func mergedPageItem() -> PageItem {
        return PageItem(
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
    var prax: PraxModel
    var mergedPage: MergedPage
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
        mergedPage: MergedPage,
        name: String,
        sourceBookmark: Data = Data(),
        sourceURL: URL,
        sourcePageIndex: Int = 0,
        pdfPage: PDFPage,
        dataFields: [String: FieldValue]

    ) {
        self.id = id
        self.mergedPage = mergedPage
        self.prax = mergedPage.document.prax
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
    
    var overlayView: PDFPageOverlayView {
      PDFPageOverlayView(pageItem: self)
    }

    private var _trims: EdgeTrims = .zero
    var trims: EdgeTrims {
        get { _trims }
        set {
            if _trims == newValue { return }
            
            let oldValue = trims
            prax.undoManager.registerUndo(withTarget: self, handler: {
                $0.trims = oldValue
                self.mergedPage.refreshMergedPage()
            })
            _trims = newValue
            
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
