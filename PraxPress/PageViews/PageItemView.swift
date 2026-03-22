//
//  Untitled.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/10/26.
//

import SwiftUI
import PDFKit


struct PageItemView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    let pdfPageItem: PageItem?
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
            GeometryReader { proxy in
                GroupBox {
                    VStack {
                        
                        HStack(alignment: .center, spacing: 0, content: {
                            Button { document.clickedIncludePageButton(pdfPageItem!) }
                            label: { Image(systemName: pdfPageItem!.merge == .mergeSkip ? "text.page.slash.fill" : "text.page")   }
                                .buttonStyle(.borderless)
                                .help("Toggle include page")
                            
                            Button { clickedGuidePageButton(pdfPageItem!) }
                            label: { Image(systemName: "ruler") }
                                .buttonStyle(.borderless)
                                .help("Toggle width guide")
                        })
                        
                        
                        
                        Image(nsImage: pdfPageItem!.pdfPage.thumbnail(of: imageSize, for: .cropBox))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(6)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    }
                
                    .padding(proxy.size.width * 0.01)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(foregroundColor, lineWidth: 3) )
                    .foregroundColor(foregroundColor)
                    .background(backgroundColor)
                    
                }
                .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0)) // proxy.size.width * 0.01))
                .frame(width: proxy.size.width * 0.58)
                .position(x: proxy.size.width * 0.72, y: proxy.size.height * 0.5)
            }
            
//            .background(backgroundColor)
        } else {
            EmptyView()
        }
        
    }
    

    
    
    func clickedGuidePageButton(_ pdfPageItem: PageItem) {
        
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





struct PageEditView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    let pdfPageItem: PageItem?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    @State private var pdfViewRef = WeakPDFViewRef()
   
    var body: some View {
        @Bindable var prax = prax
        
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
                                document: document,
                                pdfPageItem: pdfPageItem!,
                                onPDFViewReady: { pdfView in
                                    // Store a weak reference so buttons can use it
                                    pdfViewRef.view = pdfView
                              //      prax.pdfViewRegistry.set(pdfView, for: pdfPageItem!.id)

                                }
                            )
                        }
                        .frame(width: fittedSize.width, height: fittedSize.height)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        
                    }
                    
                    PDFPageItemToolbar(document: document, pdfPageItem: pdfPageItem!, pdfViewRef: pdfViewRef)
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
                        
                        
                        Button { document.clickedIncludePageButton(pdfPageItem!) }
                        label: { Image(systemName: pdfPageItem!.merge == .mergeSkip ? "text.page.slash.fill" : "text.page")   }
                            .buttonStyle(.borderless)
                            .help("Toggle include page")
                        
                        Button { clickedGuidePageButton(pdfPageItem!) }
                        label: { Image(systemName: "ruler") }
                            .buttonStyle(.borderless)
                            .help("Toggle width guide")
                    }
                    Text("L-\(Int(pdfPageItem!.trims.left)) T-\(Int(pdfPageItem!.trims.top)) B-\(Int(pdfPageItem!.trims.bottom)) R-\(Int(pdfPageItem!.trims.right))")
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
/*                .onGeometryChange(for: CGFloat.self) {  contentGeometry in
                    print("onGeometryChange - contentGeometry.size.width: ", contentGeometry.size.width)
                    return contentGeometry.size.width
                    
                }
                action: {newValue in
                    print ("contentGeometry.size.width newValue: ", newValue )
                    
              //      print ("pdfPageItem?.pdfPage.bounds(for: .cropBox)", pdfPageItem?.pdfPage.bounds(for: .cropBox) as Any)
                    //         contentWidth = newValue
                }
*/
                
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
    
    
    

    
    
    func clickedGuidePageButton(_ pdfPageItem: PageItem) {
        
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
    final class Coordinator: NSObject, PDFPageOverlayViewProvider {
        
        
        init(_ document: MergedPDFDocument,_ pdfPageItem: PageItem) {
            self.document = document
            self.pdfPageItem = pdfPageItem
         //   self.pdfPageItemView = pdfPageItemView
        }
        
        let document: MergedPDFDocument
        let pdfPageItem: PageItem
        
        var pdfView: PDFView?
        
         
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
            view.document = document
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
                
                let trims = EdgeTrims(left: left, right: right, top: top, bottom: bottom)
                print("DocumentEditingView Coordinator - trims l:", trims.left, " r:", trims.right, " b:", trims.bottom, " t:", trims.top)
                
                self.pdfPageItem.trims = trims
/*
                // var pdfPageItem = prax.pdfPageItem(for: page)!
                let indexPath = self.document.pdfPageIndexPath(for: page)
                guard let indexPath = indexPath else { return }
                self.document.pageSections[indexPath.section].pdfPageItems[indexPath.item].trims = trims
*/
            }
            
            // Seed current rect from trims
            DispatchQueue.main.async { [weak view, weak page, weak pdfView] in
                guard let view = view, let page = page, let pdfView = pdfView else { return }
            //    guard let pageItem = self.document.pdfPageItem(for: page) else { return }
                let crop = page.bounds(for: .cropBox)
                let cropInView = pdfView.convert(crop, from: page)
                let cropInOverlay = view.convert(cropInView, from: pdfView)
                view.clampRect = cropInOverlay
                // Recompute visible using current trims
                //                 fatalError()
                let trims = self.pdfPageItem.trims
                let visibleInPage = CGRect(
                    x: crop.minX + trims.left,
                    y: crop.minY + trims.bottom,
                    width: crop.width - trims.left - trims.right,
                    height: crop.height - trims.top - trims.bottom
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
        let document: MergedPDFDocument
        let pdfPageItem: PageItem
        let onPDFViewReady: (PDFView) -> Void

        func makeCoordinator() -> Coordinator {
            print("Erika daPrax - PageItemPDFViewCoordinator makeCoordinator")
            return Coordinator(document, pdfPageItem)
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
            pdfView.backgroundColor = .clear
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


struct MergedPageView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    
    let praxTheme = PraxTheme(.erika)
    
    @State private var hoveredButton: Int? = nil

    let pdfPageItem: PageItem?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    @State private var pdfViewRef = WeakPDFViewRef()
   
    var body: some View {
        
        if pdfPageItem == nil {
            EmptyView()
        }
        else {
            @Bindable var pageItem = pdfPageItem!
            @Bindable var prax = prax
            
            GeometryReader { geometry in
                
                
            //    VStack(spacing: 8) {
                    
           //         GeometryReader { boxGeometry in
            //            let boxSize = boxGeometry.size
            //            let pageAspect = pageItem.aspectRatio // width / height
                        
                        // Compute the largest size that fits inside boxSize while preserving aspect ratio
                        
            /*            let fittedSize: CGSize = {
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
            */
                        GroupBox {
                            PDFViewRepresentable(
                                document: document,
                                pageItem: pageItem,
                                onPDFViewReady: { pdfView in
                                    // Store a weak reference so buttons can use it
                                    pdfViewRef.view = pdfView
                                    prax.pdfViewRegistry.set(pdfView, for: pdfPageItem!.mergedPage.id)
                                    
                                }
                            )
                        }
        //                .background(Color.blue).opacity(0.25)
        //                .frame(width: fittedSize.width, height: fittedSize.height)
                       // .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
          //      }
          //      .padding(8)
                
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color("PraxColor"), lineWidth: 3) )
                .foregroundColor(foregroundColor())
                .background(backgroundColor())
/*                .onGeometryChange(for: CGFloat.self) {  contentGeometry in
                    print("onGeometryChange - contentGeometry.size.width: ", contentGeometry.size.width)
                    return contentGeometry.size.width
                    
                }
                action: {newValue in
                    print ("contentGeometry.size.width newValue: ", newValue )
                    
                    //      print ("pdfPageItem?.pdfPage.bounds(for: .cropBox)", pdfPageItem?.pdfPage.bounds(for: .cropBox) as Any)
                    //         contentWidth = newValue
                }
*/
                
            //}
            
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
    
    
    

    
    
    
    func clickedGuidePageButton(_ pdfPageItem: PageItem) {
        
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
    final class Coordinator: NSObject {
        
        
        init(_ document: MergedPDFDocument,_ pdfPageItem: PageItem) {
            self.document = document
            self.pageItem = pdfPageItem
         //   self.pdfPageItemView = pdfPageItemView
        }
        
        let document: MergedPDFDocument
        let pageItem: PageItem
        
        var pdfView: PDFView?
        
         
        @objc func pageChanged(_ note: Notification) {
            guard let pdfView = note.object as? PDFView,
                  let doc = pdfView.document,
                  let page = pdfView.currentPage else { return }
            let idx = doc.index(for: page)
            print("PageItemPDFViewCoordinator - changed to page:", idx)
            //         if idx != NSNotFound, idx != prax.currentIndex { prax.currentIndex = idx }
        }
        
 
        
    }
    
    
    struct PDFViewRepresentable: NSViewRepresentable {
        let document: MergedPDFDocument
        let pageItem: PageItem
        let onPDFViewReady: (PDFView) -> Void

        func makeCoordinator() -> Coordinator {
            print("Erika daPrax - PageItemPDFViewCoordinator makeCoordinator")
            return Coordinator(document, pageItem)
        }
        
        
        func makeNSView(context: Context) -> PDFView {
            print("PDFViewRepresentable - makeNSView")
            let pdfDocument = PDFDocument()
            let pdfView = PDFView()
            pdfDocument.insert(pageItem.pdfPage, at: 0)
          
            pdfView.document = pdfDocument
            pdfView.autoScales = true
            pdfView.displayDirection = .vertical
            pdfView.backgroundColor = .green
            context.coordinator.pdfView = pdfView
            onPDFViewReady(pdfView)
            return pdfView
        }
        
        func updateNSView(_ pdfView: PDFView, context: Context) {
            print("PDFViewRepresentable - updateNSView - rowSize: ", pdfView.rowSize(for: pageItem.pdfPage))
            let pdfDocument = PDFDocument()
            pdfDocument.insert(pageItem.pdfPage, at: 0)
            
            pdfView.document = pdfDocument
            
            onPDFViewReady(pdfView)
        }
        
    }
}



struct PDFPageItemToolbar: View {
    let document: MergedPDFDocument
    let pdfPageItem: PageItem
    let pdfViewRef: WeakPDFViewRef
    
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

