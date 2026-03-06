import SwiftUI
import PDFKit


class PDFPageThumbnail: NSCollectionViewItem {
    private var document: MergedPDFDocument?
    private var hostingView: NSHostingView<PDFPageThumbnailView>?
    private var indexPath: IndexPath?
    private var pdfPageItem: PDFPageItemModel?
    
    
    func configure(for document: MergedPDFDocument?, at atIndexPath: IndexPath?,
                   isSelected: Bool) {
        print ("PDFPageThumbnailView - configure ")
        self.indexPath = atIndexPath
        self.document = document
        
        if self.indexPath != nil && document != nil {
            if let pdfPageItem = document!.pdfPageItem(indexPath: indexPath!) {
                self.pdfPageItem = pdfPageItem
                let root = PDFPageThumbnailView(document: document!, pdfPageItem: self.pdfPageItem!, isSelected: isSelected, highlightState: highlightState)
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
            configure(for: document, at: indexPath, isSelected: isSelected)
        }
    }
    
    override var isSelected: Bool {
        didSet {
            configure(for: document, at: indexPath, isSelected: isSelected)
        }
    }
    
    // Called by the collection view before the view is reused
    override func prepareForReuse() {
        print ("PageItem: NSCollectionViewItem - prepareForReuse")
        super.prepareForReuse()
        pdfPageItem = nil
        configure(for: document, at: nil, isSelected: isSelected)
    }
    
    deinit {
        print ("PageItem: NSCollectionViewItem - deinit")
    }
}

struct PDFPageThumbnailView: View {
    let document: MergedPDFDocument
    let pdfPageItem: PDFPageItemModel?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    @Environment(PraxModel.self) private var prax
    
    var body: some View {
       
        
        let imageSize = CGSize(width: 120, height: 160)
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
            GeometryReader { proxy in
                GroupBox {
                    VStack {
                        HStack(spacing: 0) {
                            
                            Image(nsImage: pdfPageItem!.pdfPage.thumbnail(of: imageSize, for: .cropBox))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(6)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                        
                            VStack {
                                Button { clickedIncludePageButton(pdfPageItem!) }
                                label: { Image(systemName: pdfPageItem!.mergeMode == .mergeSkip ? "text.page.slash.fill" : "text.page")   }
                                    .buttonStyle(.borderless)
                                    .help("Toggle include page")
                                
                                Button { clickedGuidePageButton(pdfPageItem!) }
                                label: { Image(systemName: "ruler") }
                                    .buttonStyle(.borderless)
                                    .help("Toggle width guide")
                            }
                        }
                        
                        Text(pdfPageItem!.name)
                            .font(.caption)
                            .lineLimit(1)
                        
                    }
                    .padding(proxy.size.width * 0.01)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(foregroundColor, lineWidth: 3) )
                    .foregroundColor(foregroundColor)
                    .background(backgroundColor)
                    
                }
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: proxy.size.width * 0.01))
                .frame(width: proxy.size.width * 0.69)
                .position(x: proxy.size.width * 0.65, y: proxy.size.height * 0.5)
            }
            
//            .background(backgroundColor)
        } else {
            EmptyView()
        }
        
    }
    
    func clickedIncludePageButton(_ pdfPageItem: PDFPageItemModel) {
        
        print("PageItem - clickedIncludePageButton pdfPageItem: \(pdfPageItem.name)")
        
        if pdfPageItem.mergeMode == .mergeSkip {
            pdfPageItem.mergeMode = .mergeDown
        }
        else {
            pdfPageItem.mergeMode = .mergeSkip
        }
        
        
    }
    
    
    
    func clickedGuidePageButton(_ pdfPageItem: PDFPageItemModel) {
        
        print("PageItem - clickedGuidePageButton pdfPageItem: \(pdfPageItem.name)")
        
        if document.widthGuidePageID == pdfPageItem.id {
            document.clearWidthGuide()
        } else {
            if prax.optionKeyPressed {
                if document.widthGuidePageID == nil { return }
                guard let guidePage = document.pdfPageItem(id: document.widthGuidePageID!) else { return }
                
                var trims = pdfPageItem.trims
                print ("old trims: ", pdfPageItem.trims )
                print (guidePage.trims)
                print (trims)
                
                
                trims.left = guidePage.trims.left
                trims.right = guidePage.trims.right
                pdfPageItem.trims = trims
                print("PageItem - clickedGuidePageButton copied guide page trims to current page")
                print ("new trims: ",pdfPageItem.trims )
                
            }
            else {
                document.setWidthGuide(fromPage: pdfPageItem)
                
            }
            
        }
    }
}

