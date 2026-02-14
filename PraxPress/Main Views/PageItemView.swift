//
//  Untitled.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/10/26.
//

import SwiftUI
import PDFKit

enum MergeMode: String, Codable { case mergeDown, mergeRight, mergeSkip }

@Observable class PDFPageItem: Sendable, Hashable, Codable, Equatable {
    // Keep id stable after creation, but allow init/decoding to assign it
    private(set) var id: UUID
    
    let name: String
    let pdfPage: PDFPage
    var thumbnail: NSImage?
    
    var trim: EdgeTrims = .zero {
        didSet {
            print(oldValue)
            if PraxModel.shared.isLoadingPDF {
                print("isLoadingPDF - PraxModel.trims didSet")
                return }
            print("PraxModel.trims didSet")
            DispatchQueue.main.async {
                PraxModel.shared.refreshMergedDocument()
                //   PraxModel.shared.mergedPDFDocument = PraxModel.shared.mergeDocumentPagesForSections()
                print("DispatchQueue PraxModel.trims didSet")
            }
        }
    }
    private var _merge: MergeMode = .mergeDown
    var merge: MergeMode {
        get { _merge }
        set {
            if _merge == newValue { return }
            
            if PraxModel.shared.editingPDFDocument.pageCount == 1 && newValue == .mergeSkip { return }
            _merge = newValue
            
            
            if PraxModel.shared.isLoadingPDF {
                print("isLoadingPDF - PraxModel.merge didSet")
                return }
            
            print("PraxModel.merge didSet")
            DispatchQueue.main.async {
                print ("DispatchQueue - refreshEditingDocument()")
                PraxModel.shared.refreshEditingDocument()
                
                
            }
        }
    }
    
    
    // Single concrete initializer that initializes all stored properties
    init(
        id: UUID = UUID(),
        name: String,
        pdfPage: PDFPage,
        // thumbnail: NSImage,
        trim: EdgeTrims = .zero,
        merge: MergeMode = .mergeDown
    ) {
        self.id = id
        self.name = name
        self.pdfPage = pdfPage
        //  self.thumbnail = thumbnail
        self.trim = trim
        self.merge = merge
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case trim
        case merge
        // Exclude: pdfPage, thumbnail
    }
    
    // Single decoding initializer: decode codable fields and supply placeholders
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedID = try container.decode(UUID.self, forKey: .id)
        let decodedName = try container.decode(String.self, forKey: .name)
        let decodedTrim = try container.decode(EdgeTrims.self, forKey: .trim)
        let decodedMerge = try container.decode(MergeMode.self, forKey: .merge)
        
        self.id = decodedID
        self.name = decodedName
        self.pdfPage = PDFPage()
        self.trim = decodedTrim
        self.merge = decodedMerge
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(trim, forKey: .trim)
        try container.encode(merge, forKey: .merge)
    }
    
    /*    mutating func setTrim(_ trim: EdgeTrims) {
     self.trim = trim
     }
     
     mutating func setMerge(_ merge: MergeMode) {
     self.merge = merge
     }
     */
    
    static func == (lhs: PDFPageItem, rhs: PDFPageItem) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


class CollectionViewPDFPageItemView: NSCollectionViewItem {
    private var hostingView: NSHostingView<PDFPageItemView>?
    private var indexPath: IndexPath?
    private var pdfPageItem: PDFPageItem?
    private var thumbnailViewer: Bool = false
    
    func configure(at atIndexPath: IndexPath?,
                   isSelected: Bool) {
        print ("CollectionViewPDFPageItem - configure ", isSelected)
        self.indexPath = atIndexPath
        
        
        if self.indexPath != nil {
            if let pdfPageItem = PraxModel.shared.pdfPageItem(indexPath: indexPath!) {
                self.pdfPageItem = pdfPageItem
                let root = PDFPageItemView(pdfPageItem: self.pdfPageItem, isSelected: isSelected, highlightState: highlightState)
                if let hostingView {
                    print ("PageItem - hostingView")
                    hostingView.rootView = root
                } else {
                    print ("PageItem - hosting = NSHostingView(rootView: root)")
                    let hosting = NSHostingView(rootView: root)
                    hosting.translatesAutoresizingMaskIntoConstraints = false
                    self.view.addSubview(hosting)
                    NSLayoutConstraint.activate([
                        hosting.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                        hosting.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                        hosting.topAnchor.constraint(equalTo: self.view.topAnchor),
                        hosting.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                    ])
                    hostingView = hosting
                }
            }
            
        }
        
        
    }
    
    override var highlightState: NSCollectionViewItem.HighlightState {
        didSet {
            configure(at: indexPath, isSelected: isSelected)
        }
    }

    override var isSelected: Bool {
        didSet {
            configure(at: indexPath, isSelected: isSelected)
        }
    }
    
    // Called by the collection view before the view is reused
    override func prepareForReuse() {
        print ("PageItem: NSCollectionViewItem - prepareForReuse")
        super.prepareForReuse()
        pdfPageItem = nil
        configure(at: nil, isSelected: isSelected)
        
    }
    
    deinit {
        print ("PageItem: NSCollectionViewItem - deinit")
        
        
    }
    
}

struct PDFPageItemView: View {
    
    let pdfPageItem: PDFPageItem?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    
   
    
    var body: some View {
        
        let backgroundColor: Color = {
            switch highlightState {
                //      case .forSelection:
                //        Color.blue
                //     case .forDeselection:
                //         Color.yellow
            case .asDropTarget:
                Color.purple
            default:
                if isSelected {
                    Color.blue
                }
                else {
                    Color.clear
                }
            }
        }()
        
        let foregroundColor: Color = {
            switch highlightState {
                //      case .forSelection:
                //        Color.blue
                //     case .forDeselection:
                //         Color.yellow
            case .asDropTarget:
                Color.orange
            default:
                if isSelected {
                    Color.white
                }
                else {
                    Color.blue
                }
            }
        }()
        
        
        if pdfPageItem != nil {
            VStack(spacing: 8) {

                    PDFViewRepresentable(pdfPageItem: pdfPageItem!)
            
                HStack {
                    Text(pdfPageItem!.name)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    
                    Button { clickedIncludePageButton(pdfPageItem!) }
                    label: { Image(systemName: pdfPageItem!.merge == .mergeSkip ? "text.page.slash.fill" : "text.page")   }
                        .buttonStyle(.borderless)
                        .help("Toggle include page")
                    
                    Button { clickedGuidePageButton(pdfPageItem!) }
                    label: { Image(systemName: "ruler") }
                        .buttonStyle(.borderless)
                        .help("Toggle width guide")
                }
                Text("L-\(Int(pdfPageItem!.trim.left)) T-\(Int(pdfPageItem!.trim.top)) B-\(Int(pdfPageItem!.trim.bottom)) R-\(Int(pdfPageItem!.trim.right))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color("PraxColor"), lineWidth: 3) )
            .foregroundColor(foregroundColor)
            .background(backgroundColor)

            
        } else {
            EmptyView()
        }
        
    }
    
    func clickedIncludePageButton(_ pdfPageItem: PDFPageItem) {
        
        print("PageItem - clickedIncludePageButton pdfPageItem: \(pdfPageItem.name)")
        
        if pdfPageItem.merge == .mergeSkip {
            pdfPageItem.merge = .mergeDown
        }
        else {
            pdfPageItem.merge = .mergeSkip
        }
        
        
    }
    
    
    
    func clickedGuidePageButton(_ pdfPageItem: PDFPageItem) {
        
        print("PageItem - clickedGuidePageButton pdfPageItem: \(pdfPageItem.name)")
        
        if PraxModel.shared.widthGuidePageID == pdfPageItem.id {
            PraxModel.shared.clearWidthGuide()
        } else {
            if PraxModel.shared.optionKeyPressed {
                if PraxModel.shared.widthGuidePageID == nil { return }
                guard let guidePage = PraxModel.shared.pdfPageItem(id: PraxModel.shared.widthGuidePageID!) else { return }
                
                var trim = pdfPageItem.trim
                print ("old trim: ", pdfPageItem.trim )
                print (guidePage.trim)
                print (trim)
                
                
                trim.left = guidePage.trim.left
                trim.right = guidePage.trim.right
                pdfPageItem.trim = trim
                print("PageItem - clickedGuidePageButton copied guide page trim to current page")
                print ("new trim: ",pdfPageItem.trim )
                
            }
            else {
                PraxModel.shared.setWidthGuide(fromPage: pdfPageItem)
                
            }
            
        }
    }
}

final class PageItemPDFViewCoordinator: NSObject, PDFPageOverlayViewProvider {
    
    
    init(_ pdfPageItem: PDFPageItem) {
        self.pdfPageItem = pdfPageItem
    }
    let pdfPageItem: PDFPageItem
    
    @objc func pageChanged(_ note: Notification) {
        guard let pdfView = note.object as? PDFView,
              let doc = pdfView.document,
              let page = pdfView.currentPage else { return }
        let idx = doc.index(for: page)
        print("PageItemPDFViewCoordinator - changed to page:", idx)
        //         if idx != NSNotFound, idx != prax.currentIndex { prax.currentIndex = idx }
    }
    
    func pdfView(_ pdfView: PDFView, overlayViewFor page: PDFPage) -> NSView? {
        print("PageItemPDFViewCoordinator - overlayViewFor page")
        let view = PDFPageOverlayView()
        view.pdfView = pdfView
        
        view.onFinish = { [weak page] rectInOverlay in
            guard let page = page else { return }
            
            // Convert overlay-local rect to PDFView coordinates
            let rectInView = view.convert(rectInOverlay, to: pdfView)
            
            // Clamp to page bounds in PDFView coordinates
            let pageBoundsInView = pdfView.convert(page.bounds(for: .cropBox), from: page)
            let clamped = rectInView.intersection(pageBoundsInView)
            guard !clamped.isEmpty else { return }
            
            // Convert to page coords
            let pageRect = pdfView.convert(clamped, to: page)
            let media = page.bounds(for: .cropBox)
            
            let left = max(0, pageRect.minX - media.minX)
            let right = max(0, media.maxX - pageRect.maxX)
            let bottom = max(0, pageRect.minY - media.minY)
            let top = max(0, media.maxY - pageRect.maxY)
            
            let trim = EdgeTrims(left: left, right: right, top: top, bottom: bottom)
            print("DocumentEditingView Coordinator - trim l:", trim.left, " r:", trim.right, " b:", trim.bottom, " t:", trim.top)
            
            // var pdfPageItem = prax.pdfPageItem(for: page)!
            let indexPath = PraxModel.shared.pdfPageIndexPath(for: page)
            guard let indexPath = indexPath else { return }
            PraxModel.shared.pdfPageSections[indexPath.section].pdfPageItems[indexPath.item].trim = trim
        }
        
        // Seed current rect from trims
        DispatchQueue.main.async { [weak view, weak page, weak pdfView] in
            guard let view = view, let page = page, let pdfView = pdfView else { return }
            guard let pageItem = PraxModel.shared.pdfPageItem(for: page) else { return }
            let crop = page.bounds(for: .cropBox)
            let cropInView = pdfView.convert(crop, from: page)
            let cropInOverlay = view.convert(cropInView, from: pdfView)
            view.clampRect = cropInOverlay
            // Recompute visible using current trims
            //                 fatalError()
            let trim = pageItem.trim
            let visibleInPage = CGRect(
                x: crop.minX + trim.left,
                y: crop.minY + trim.bottom,
                width: crop.width - trim.left - trim.right,
                height: crop.height - trim.top - trim.bottom
            )
            let visibleInView = pdfView.convert(visibleInPage, from: page)
            let visibleInOverlay = view.convert(visibleInView, from: pdfView)
            view.currentRect = visibleInOverlay
            
            view.needsDisplay = true
        }
        
        return view
    }
    
}


struct PDFViewRepresentable: NSViewRepresentable {
    let pdfPageItem: PDFPageItem
    
    func makeCoordinator() -> PageItemPDFViewCoordinator {
        print("Erika daPrax - PageItemPDFViewCoordinator makeCoordinator")
        return PageItemPDFViewCoordinator(pdfPageItem)
    }
    
    
    
    func makeNSView(context: Context) -> PDFView {
        print("PDFViewRepresentable - makeNSView")
        let pdfDocument = PDFDocument()
        pdfDocument.insert(pdfPageItem.pdfPage, at: 0)
        let pdfView = PDFView()
        pdfView.pageOverlayViewProvider = context.coordinator
        pdfView.document = pdfDocument
        return pdfView
    }
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        print("PDFViewRepresentable - updateNSView")
        let pdfDocument = PDFDocument()
        pdfDocument.insert(pdfPageItem.pdfPage, at: 0)
        pdfView.document = pdfDocument
    }
    
}


class praxListItem: NSCollectionViewItem {
    
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("list-item-reuse-identifier")
    
    override var highlightState: NSCollectionViewItem.HighlightState {
        didSet {
            updateSelectionHighlighting()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            updateSelectionHighlighting()
        }
    }
    
    private func updateSelectionHighlighting() {
        if !isViewLoaded {
            return
        }
        
        let showAsHighlighted = (highlightState == .forSelection) ||
        (isSelected && highlightState != .forDeselection) ||
        (highlightState == .asDropTarget)
        
        textField?.textColor = showAsHighlighted ? .selectedControlTextColor : .labelColor
        view.layer?.backgroundColor = showAsHighlighted ? NSColor.selectedControlColor.cgColor : nil
    }
}
