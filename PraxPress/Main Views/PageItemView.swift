import SwiftUI
import PDFKit


enum MergeMode: String, Codable { case mergeDown, mergeRight, mergeSkip }

struct PDFPageItem: Hashable, Codable, Equatable {
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
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedID = try container.decode(UUID.self, forKey: .id)
        let decodedName = try container.decode(String.self, forKey: .name)
        let decodedTrim = try container.decode(EdgeTrims.self, forKey: .trim)
        let decodedMerge = try container.decode(MergeMode.self, forKey: .merge)
        
        self = PDFPageItem(
            id: decodedID,
            name: decodedName,
            pdfPage: PDFPage(),   // placeholder; replace with real page later in app logic
   //         thumbnail: NSImage(), // placeholder; replace with real image later
            trim: decodedTrim,
            merge: decodedMerge
        )
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



class PageItem: NSCollectionViewItem {
    private var hostingView: NSHostingView<PageItemView>?
    private var indexPath: IndexPath?
    private var thumbnailViewer: Bool = false
    
    func configure(at atIndexPath: IndexPath,
                   isSelected: Bool,
                   thumbnailViewer: Bool) {
        indexPath = atIndexPath
        self.thumbnailViewer = thumbnailViewer
        
        let root = PageItemView(indexPath: indexPath!, isSelected: isSelected, thumbnailViewer: thumbnailViewer)
        
        if let hostingView {
            hostingView.rootView = root
        } else {
            let hosting = NSHostingView(rootView: root)
            hosting.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(hosting)
            NSLayoutConstraint.activate([
                hosting.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                hosting.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                hosting.topAnchor.constraint(equalTo: self.view.topAnchor),
                hosting.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            ])
            self.hostingView = hosting
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if let indexPath {
                configure(at: indexPath, isSelected: isSelected, thumbnailViewer: thumbnailViewer)
            }
        }
    }
}

struct PageItemView: View {
    @Environment(PraxContext.self) private var praxContext
    let indexPath: IndexPath
    let isSelected: Bool
    let thumbnailViewer: Bool
    
    func pdfPageItem() -> PDFPageItem? {
        if indexPath.section >= 0,
           indexPath.section < PraxModel.shared.pdfPageSections.count,
           indexPath.item >= 0,
           indexPath.item < PraxModel.shared.pdfPageSections[indexPath.section].pdfPageItems.count {
            return PraxModel.shared.pdfPageSections[indexPath.section].pdfPageItems[indexPath.item]
        } else {
            return nil
        }
    }

    var body: some View {
        if let page = pdfPageItem() {
            VStack(spacing: 8) {
                MergedDocumentView()
                
                Image(nsImage: (page.thumbnail ?? NSImage(systemSymbolName: "multiply.circle.fill",
                                                          accessibilityDescription: "A multiply symbol inside a filled circle."))! )
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(6)
                HStack {
                    Text(page.name)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()

                    Button { clickedIncludePageButton(page) }
                    label: { Image(systemName: page.merge == .mergeSkip ? "text.page.slash.fill" : "text.page")   }
                    .buttonStyle(.borderless)
                    .help("Toggle include page")

                    Button { clickedGuidePageButton(page) }
                    label: { Image(systemName: "ruler") }
                    .buttonStyle(.borderless)
                    .help("Toggle width guide")
                }
                Text("\(Int(page.trim.left))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        } else {
            EmptyView()
        }
    }
    
    func clickedIncludePageButton(_ page: PDFPageItem) {
        
        print("PageItem - clickedIncludePageButton pdfPageItem: \(page.name)")
        if page.merge == .mergeSkip {
            PraxModel.shared.pdfPageSections[indexPath.section].pdfPageItems[indexPath.item].merge = .mergeDown
        }
        else {
            PraxModel.shared.pdfPageSections[indexPath.section].pdfPageItems[indexPath.item].merge = .mergeSkip
        }

        
    }
    
    

    func clickedGuidePageButton(_ page: PDFPageItem) {
        
        print("PageItem - clickedGuidePageButton pdfPageItem: \(page.name)")
        if PraxModel.shared.widthGuidePageID == page.id {
            PraxModel.shared.clearWidthGuide()
        } else {
            if praxContext.optionKeyPressed {
                if PraxModel.shared.widthGuidePageID == nil { return }
                guard let guidePage = PraxModel.shared.pdfPageItem(id: PraxModel.shared.widthGuidePageID!) else { return }

                var trim = page.trim
                print ("old trim: ", PraxModel.shared.pdfPageSections[indexPath.section].pdfPageItems[indexPath.item].trim )
                print (guidePage.trim)
                print (trim)
                
                
                trim.left = guidePage.trim.left
                trim.right = guidePage.trim.right
                PraxModel.shared.pdfPageSections[indexPath.section].pdfPageItems[indexPath.item].trim = trim
                print("PageItem - clickedGuidePageButton copied guide page trim to current page")
                print ("new trim: ",PraxModel.shared.pdfPageSections[indexPath.section].pdfPageItems[indexPath.item].trim )
                
            }
            else {
                PraxModel.shared.setWidthGuide(fromPage: page)

            }

        }
    }
}

