//
//  Untitled.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/10/26.
//

import SwiftUI
import PDFKit



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

struct PDFPageItemToolbar: View {
    let pdfPageItem: PDFPageItem
    let pdfViewRef: WeakPDFViewRef
    
    @Bindable private var prax = PraxModel.shared
    var body: some View {
        
        HStack {
            Text(pdfPageItem.name)
                .font(.caption)
                .lineLimit(1)
            Spacer()
            
            Menu("View", systemImage: "plus.circle"){
                
                Button(action: {
                    pdfViewRef.view!.zoomIn(nil)
                    pdfViewRef.view!.autoScales = true
                }) {
                    Label("Zoom In", systemImage: "plus.circle")
                }
                
                
                Button {
                    pdfViewRef.view!.zoomOut(nil)
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.borderedProminent)
                .help("Zoom Out")
                
                Button {
                    pdfViewRef.view!.scaleFactor = pdfViewRef.view!.scaleFactorForSizeToFit }
                label: {
                    Image(systemName: "equal.circle")
                }
                .buttonStyle(.borderedProminent)
                .help("Zoom In")
                
                Button {
                    pdfViewRef.view!.zoomOut(nil)
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.borderedProminent)
                .help("Zoom Out")

            }
            ControlGroup("", systemImage: "magnifyingglass") {
                Text("View")
                
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
        .padding(8)
    }
}




final class WeakPDFViewRef {
    weak var view: PDFView?
}
struct PDFPageItemView: View {
    
    let pdfPageItem: PDFPageItem?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    @State private var pdfViewRef = WeakPDFViewRef()
   
    var body: some View {
        
        GeometryReader { geometry in
            
            if pdfPageItem != nil {
                VStack(spacing: 8) {
                    
                    GeometryReader { boxGeometry in
                        let boxSize = boxGeometry.size
                        let pageAspect = pdfPageItem!.aspectRatio // width / height
                        
                        // Compute the largest size that fits inside boxSize while preserving aspect ratio
                        let fittedSize: CGSize = {
                            guard boxSize.width > 0, boxSize.height > 0 else { return .zero }
                            let containerAspect = boxSize.width / boxSize.height
                            if containerAspect > pageAspect {
                                // Container is wider than the page: limit by height
                                let h = boxSize.height
                                let w = h * pageAspect
                                return CGSize(width: w, height: h)
                            } else {
                                // Container is taller/narrower: limit by width
                                let w = boxSize.width
                                let h = w / pageAspect
                                return CGSize(width: w, height: h)
                            }
                        }()
                        
                        GroupBox {
                            PDFViewRepresentable(
                                pdfPageItem: pdfPageItem!,
                                onPDFViewReady: { pdfView in
                                    // Store a weak reference so buttons can use it
                                    pdfViewRef.view = pdfView

                                }
                            )
                        }
                        .frame(width: fittedSize.width, height: fittedSize.height)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        
                    }
                    
                    PDFPageItemToolbar(pdfPageItem: pdfPageItem!, pdfViewRef: pdfViewRef)   
                    HStack {
                        Text(pdfPageItem!.name)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        
                        Button {
                            pdfViewRef.view?.zoomIn(nil)
                            pdfViewRef.view!.autoScales = true
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .help("Zoom In")
                        
                        Button {
                            pdfViewRef.view?.zoomOut(nil)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .help("Zoom Out")
                        
                        Button {
                            pdfViewRef.view!.scaleFactor = pdfViewRef.view!.scaleFactorForSizeToFit }
                        label: {
                            Image(systemName: "equal.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .help("Zoom In")
                        
                        Button {
                            pdfViewRef.view?.zoomOut(nil)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .help("Zoom Out")
                        
                        
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
                .foregroundColor(foregroundColor())
                .background(backgroundColor())
                .onGeometryChange(for: CGFloat.self) {  contentGeometry in
                    print("onGeometryChange - contentGeometry.size.width: ", contentGeometry.size.width)
                    return contentGeometry.size.width
                    
                }
                action: {newValue in
                    print ("contentGeometry.size.width newValue: ", newValue )
                    
                    print ("pdfPageItem?.pdfPage.bounds(for: .cropBox)", pdfPageItem?.pdfPage.bounds(for: .cropBox))
                    //         contentWidth = newValue
                }
                
            } else {
                EmptyView()
            }
            

            
        }
    }
    
    func backgroundColor() -> Color {
        switch highlightState {
            //      case .forSelection:
            //        Color.blue
            //     case .forDeselection:
            //         Color.yellow
        case .asDropTarget:
            Color.purple
        default:
            if isSelected {
                Color.blue.opacity(0.9)
            }
            else {
                Color.blue.opacity(0.3) }}}
    
    func foregroundColor() -> Color {
        switch highlightState {
            //      case .forSelection:
            //        Color.blue
            //     case .forDeselection:
            //         Color.yellow
        case .asDropTarget:
            Color.purple
        default:
            if isSelected {
                Color.white
            }
            else {
                Color.blue }}}
    
    
    
    
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
    final class Coordinator: NSObject, PDFPageOverlayViewProvider {
        
        init(_ pdfPageItem: PDFPageItem) {
            self.pdfPageItem = pdfPageItem
         //   self.pdfPageItemView = pdfPageItemView
        }
        
        let pdfPageItem: PDFPageItem
        
        var pdfView: PDFView?
        
        
     //   @Binding var pdfPageItemView: PDFPageItemView
        
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
        let onPDFViewReady: (PDFView) -> Void

        func makeCoordinator() -> Coordinator {
            print("Erika daPrax - PageItemPDFViewCoordinator makeCoordinator")
            return Coordinator(pdfPageItem)
        }
        
        
        func makeNSView(context: Context) -> PDFView {
            print("PDFViewRepresentable - makeNSView")
            let pdfDocument = PDFDocument()
            pdfDocument.insert(pdfPageItem.pdfPage, at: 0)
            let pdfView = PDFView()
            pdfView.pageOverlayViewProvider = context.coordinator
            pdfView.document = pdfDocument
            pdfView.autoScales = true
            pdfView.displayDirection = .vertical
            context.coordinator.pdfView = pdfView
            onPDFViewReady(pdfView)
            return pdfView
        }
        
        func updateNSView(_ pdfView: PDFView, context: Context) {
            print("PDFViewRepresentable - updateNSView")
            let pdfDocument = PDFDocument()
            pdfDocument.insert(pdfPageItem.pdfPage, at: 0)
            pdfView.document = pdfDocument
            
            onPDFViewReady(pdfView)
        }
        
    }
}


