//  ReorderablePDFThumbnailView.swift
//  PraxPress - Prax=0104-1

import AppKit
import PDFKit

final class ReorderablePDFThumbnailView: NSView, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, NSDraggingSource {
    
    weak var pdfView: PDFView? { didSet { reloadData() } }
    var thumbnailSize: CGSize = CGSize(width: 120, height: 160) { didSet { flow.itemSize = thumbnailSize } }

    private let scroll = NSScrollView()
    private let collection = NSCollectionView()
    private let flow = NSCollectionViewFlowLayout()

    private let itemIdentifier = NSUserInterfaceItemIdentifier("ThumbCell")
    private let internalUTI = NSPasteboard.PasteboardType("com.praxpress.internal-pages")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        flow.itemSize = thumbnailSize
        flow.sectionInset = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        flow.minimumLineSpacing = 8
        flow.minimumInteritemSpacing = 8

        collection.collectionViewLayout = flow
        collection.register(ThumbCell.self, forItemWithIdentifier: itemIdentifier)
        collection.dataSource = self
        collection.delegate = self
        collection.isSelectable = true
        collection.setDraggingSourceOperationMask([.move], forLocal: true)
        collection.setDraggingSourceOperationMask([.copy], forLocal: false)
        collection.registerForDraggedTypes([internalUTI, .fileURL, .pdf])
 //       collection.setDraggingDestinationFeedbackStyle(.regular)
        // Optional: also register the scroll view to ensure events route correctly
        scroll.registerForDraggedTypes([internalUTI, .fileURL, .pdf])

        scroll.documentView = collection
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        addSubview(scroll)
    }

    override func layout() {
        super.layout()
        scroll.frame = bounds
    }

    func reloadData() {
        collection.reloadData()
    }

    // MARK: Data Source
    func numberOfSections(in collectionView: NSCollectionView) -> Int { 1 }
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return pdfView?.document?.pageCount ?? 0
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: itemIdentifier, for: indexPath) as! ThumbCell
        if let page = pdfView?.document?.page(at: indexPath.item) {
            item.image = page.thumbnail(of: thumbnailSize, for: .cropBox)
            item.text = "\(indexPath.item + 1)"
        } else {
            item.image = nil
            item.text = "?"
        }
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let pdfView = self.pdfView, let doc = pdfView.document else { return }
        guard let idx = indexPaths.first?.item, let page = doc.page(at: idx) else { return }
        pdfView.go(to: page)
    }
    
    func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        let pb = NSPasteboardItem()
        let data = try? NSKeyedArchiver.archivedData(withRootObject: [indexPath.item], requiringSecureCoding: false)
        if let d = data { pb.setData(d, forType: internalUTI) }
        if let dataRep = pdfView?.document?.dataRepresentation() { pb.setData(dataRep, forType: .pdf) }
        return pb
    }
    
    func collectionView(_ collectionView: NSCollectionView, writeItemsAt indexPaths: Set<IndexPath>, to pasteboard: NSPasteboard) -> Bool {
        guard let first = indexPaths.first else { return false }
        let data = try? NSKeyedArchiver.archivedData(withRootObject: [first.item], requiringSecureCoding: false)
        if let d = data { pasteboard.setData(d, forType: internalUTI) }
        if let rep = pdfView?.document?.dataRepresentation() { pasteboard.setData(rep, forType: .pdf) }
        return true
    }

    func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent) -> Bool {
        // Allow dragging any item for internal reordering
        return true
    }

    func collectionView(_ collectionView: NSCollectionView, moveItemsAt indexPaths: Set<IndexPath>, to destinationIndexPath: IndexPath) {
        guard let doc = pdfView?.document else { return }
        // NSCollectionView provides the set of source indexes and the destination indexPath (before insertion)
        let sourceIndexes = IndexSet(indexPaths.map { $0.item })
        movePages(in: doc, from: sourceIndexes, to: destinationIndexPath.item)
        reloadData()
        // Optionally, select and reveal the first moved item at its new location
        let newIndex = min(destinationIndexPath.item, (doc.pageCount > 0 ? doc.pageCount - 1 : 0))
        if let page = doc.page(at: newIndex) { pdfView?.go(to: page) }
    }

    // MARK: Drag Source / Destination
    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexPaths: Set<IndexPath>) {
        session.draggingFormation = .stack
    }
    
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        switch context {
        case .withinApplication:
            return [.move]
        default:
            return [.copy]
        }
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        // No-op cleanup hook; keep for future use
    }

    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        switch context { case .withinApplication: return [.move]; default: return [.copy] }
    }

    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath: AutoreleasingUnsafeMutablePointer<IndexPath>, dropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
        print("Thumbs validateDrop at index: \(proposedIndexPath.pointee.item)")
        dropOperation.pointee = .before
        if draggingInfo.draggingPasteboard.availableType(from: [internalUTI]) != nil { return .move }
        if draggingInfo.draggingPasteboard.availableType(from: [.fileURL, .pdf]) != nil { return .copy }
        return []
    }

    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
        print("Thumbs acceptDrop at index: \(indexPath.item)")
        guard let doc = pdfView?.document else { return false }
        let pb = draggingInfo.draggingPasteboard
        if let data = pb.data(forType: internalUTI), let array = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [Int] {
            movePages(in: doc, from: IndexSet(array), to: indexPath.item)
            if let first = array.first, let newPage = doc.page(at: min(indexPath.item, doc.pageCount - 1)) {
                pdfView?.go(to: newPage)
            }
            reloadData()
            return true
        }
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], let url = urls.first, let importDoc = PDFDocument(url: url) {
            insertAllPages(from: importDoc, into: doc, at: indexPath.item)
            if let newPage = doc.page(at: min(indexPath.item, doc.pageCount - 1)) {
                pdfView?.go(to: newPage)
            }
            reloadData()
            return true
        }
        if let pdfData = pb.data(forType: .pdf), let importDoc = PDFDocument(data: pdfData) {
            insertAllPages(from: importDoc, into: doc, at: indexPath.item)
            if let newPage = doc.page(at: min(indexPath.item, doc.pageCount - 1)) {
                pdfView?.go(to: newPage)
            }
            reloadData()
            return true
        }
        return false
    }

    // MARK: Flow Layout
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return thumbnailSize
    }

    // MARK: Helpers
    private func movePages(in document: PDFDocument, from indexes: IndexSet, to destination: Int) {
        guard !indexes.isEmpty else { return }
        var pages: [PDFPage] = []
        for i in indexes.sorted() { if let p = document.page(at: i) { pages.append(p) } }
        for i in indexes.sorted(by: >) { document.removePage(at: i) }
        var insertIndex = destination
        if let minIndex = indexes.min(), destination > minIndex { insertIndex -= indexes.count }
        insertIndex = max(0, min(insertIndex, document.pageCount))
        for (offset, page) in pages.enumerated() { document.insert(page, at: insertIndex + offset) }
    }

    private func insertAllPages(from source: PDFDocument, into target: PDFDocument, at destination: Int) {
        var insertIndex = max(0, min(destination, target.pageCount))
        for i in 0..<source.pageCount { if let page = source.page(at: i) { target.insert(page, at: insertIndex); insertIndex += 1 } }
    }
    
    func selectItemForCurrentPDFViewPage() {
        guard let pdfView = self.pdfView, let doc = pdfView.document, let page = pdfView.currentPage else { return }
        let idx = doc.index(for: page)
        guard idx != NSNotFound else { return }
        collection.selectItems(at: [IndexPath(item: idx, section: 0)], scrollPosition: .nearestHorizontalEdge)
    }
}

final class ThumbCell: NSCollectionViewItem {
    private let imageViewInternal = NSImageView()
    private let textFieldInternal = NSTextField(labelWithString: "")

    var image: NSImage? { didSet { imageViewInternal.image = image } }
    var text: String? { didSet { textFieldInternal.stringValue = text ?? "" } }

    override func loadView() { self.view = NSView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        imageViewInternal.imageAlignment = .alignCenter
        imageViewInternal.imageScaling = .scaleProportionallyUpOrDown
        imageViewInternal.translatesAutoresizingMaskIntoConstraints = false

        textFieldInternal.alignment = .center
        textFieldInternal.font = NSFont.systemFont(ofSize: 11)
        textFieldInternal.textColor = .secondaryLabelColor
        textFieldInternal.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(imageViewInternal)
        view.addSubview(textFieldInternal)

        NSLayoutConstraint.activate([
            imageViewInternal.topAnchor.constraint(equalTo: view.topAnchor),
            imageViewInternal.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageViewInternal.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            textFieldInternal.topAnchor.constraint(equalTo: imageViewInternal.bottomAnchor, constant: 4),
            textFieldInternal.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textFieldInternal.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textFieldInternal.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    override var isSelected: Bool {
        didSet {
            view.wantsLayer = true
            view.layer?.cornerRadius = 6
            view.layer?.borderWidth = isSelected ? 2 : 0
            view.layer?.borderColor = (isSelected ? NSColor.controlAccentColor.cgColor : NSColor.clear.cgColor)
            view.layer?.backgroundColor = (isSelected ? NSColor.controlAccentColor.withAlphaComponent(0.12).cgColor : NSColor.clear.cgColor)
        }
    }
}

