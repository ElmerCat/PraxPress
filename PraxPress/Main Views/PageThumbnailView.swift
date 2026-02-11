import SwiftUI
import PDFKit


class CollectionViewPDFPageItemThumbnail: NSCollectionViewItem {
    private var hostingView: NSHostingView<CollectionViewPDFPageThumbnailView>?
    private var indexPath: IndexPath?
    private var pdfPageItem: PDFPageItem?
    private var thumbnailViewer: Bool = false
    
    func configure(at atIndexPath: IndexPath?,
                   isSelected: Bool) {
        print ("CollectionViewPDFPageItem - configure thumbnailViewer: ", thumbnailViewer)
        self.indexPath = atIndexPath
        
        
        if self.indexPath != nil {
            if let pdfPageItem = PraxModel.shared.pdfPageItem(indexPath: indexPath!) {
                self.pdfPageItem = pdfPageItem
                let root = CollectionViewPDFPageThumbnailView(pdfPageItem: self.pdfPageItem, isSelected: isSelected, highlightState: highlightState)
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
    
 /*   private func updateSelectionHighlighting() {
        if !isViewLoaded {
            return
        }
        
        let showAsHighlighted = (highlightState == .forSelection) ||
        (isSelected && highlightState != .forDeselection) ||
        (highlightState == .asDropTarget)
        
        textField?.textColor = showAsHighlighted ? .selectedControlTextColor : .labelColor
        view.layer?.backgroundColor = showAsHighlighted ? NSColor.selectedControlColor.cgColor : nil
    }
*/
    
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

struct CollectionViewPDFPageThumbnailView: View {
    @Environment(PraxContext.self) private var praxContext
    
    let pdfPageItem: PDFPageItem?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    
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
            GroupBox {
                VStack(spacing: 8) {
                    
                    Image(nsImage: pdfPageItem!.pdfPage.thumbnail(of: imageSize, for: .cropBox))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(6)
                    
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
                        .foregroundStyle(foregroundColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(foregroundColor, lineWidth: 3) )
                .foregroundColor(foregroundColor)
                .background(backgroundColor)
                
            }
//            .background(backgroundColor)
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
            if praxContext.optionKeyPressed {
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

