//
//  Untitled.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/10/26.
//

import SwiftUI
import PDFKit
import TipKit


struct PageItemView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    let pageItem: PageItem?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    let praxTheme = PraxTheme(.erika)
    let deleteTheme = PraxTheme(.julie)
    
    @State var showSettings = false
    @State private var hoveredButton: Int? = nil
    
    
    


    
    var body: some View {
        
        
        let imageSize = CGSize(width: 85, height: 110)
        let backgroundColor: Color = {
            switch highlightState {
            case .forSelection:
                Color.orange
            case .forDeselection:
                Color.green
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
            case .forSelection:
                Color.green
            case .forDeselection:
                Color.orange
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
        
        if pageItem != nil {
            GeometryReader { proxy in
                GroupBox {
                    
                    HStack(alignment: .center, spacing: 0, content: {
                        
                        
                        Image(nsImage: pageItem!.pdfPage.thumbnail(of: imageSize, for: .cropBox))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                          //  .cornerRadius(6)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            .padding(3)
                            .opacity(pageItem!.skipped ? 0.25 : 1.0)
                        
                        VStack {
                            
                            Button {
                                document.clickedSkipPageButton(pageItem!)
                                }
                            label: {
                                if pageItem!.skipped {
                                    Image(systemName: "rectangle.portrait.slash.fill")
                                }
                                else {
                                    Image(systemName: "rectangle.portrait.slash")
                                }
                            }
                            .buttonStyle(ItemButtonStyle(theme: praxTheme, isHovering: hoveredButton == 126))
                            .onHover { hovering in hoveredButton = hovering ? 126 : nil }
                            
                            Button {
                                showSettings = !showSettings
                            }
                            label: { Image(systemName: "gear")}
                            .buttonStyle(ItemButtonStyle(theme: praxTheme, isHovering: hoveredButton == 2))
                            .onHover { hovering in
                                hoveredButton = hovering ? 2 : nil
                            }
                            .popover(isPresented: $showSettings) {
                                PageItemPopover(pageItem: pageItem!)
                                
                                    .presentationDetents(
                                        [.height(120), .medium, .large])
                                    .presentationBackgroundInteraction(
                                        .enabled(upThrough: .height(120)))
                                    .presentationSizing(.form)
                                
                            }
                            
                            

                            
                     /*       Button { document.clickedMergeModeButton(pageItem!) }
                            
                            label: {
                                switch(pageItem!.merge) {
                                case .mergeSkip:
                                    Image(systemName: "rectangle.portrait.slash.fill")
                                 case .mergeDown:
                                    Image(systemName: "arrow.down.document.fill")
                                case .mergeRight:
                                    Image(systemName: "inset.filled.trailinghalf.arrow.trailing.rectangle")
                                }
                            }
                            .buttonStyle(ItemButtonStyle(theme: praxTheme, isHovering: hoveredButton == 1))
                            .onHover { hovering in
                                hoveredButton = hovering ? 1 : nil
                            }
                            .help("Merge page mode")
                            
                            Button("", systemImage: "ruler", action: {
                                document.clickedGuidePageButton(pageItem!)
                            })                .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 4, isFocused: false))
                                .onHover { hovering in
                                    hoveredButton = hovering ? 4 : nil
                                }
                                .help("Set width guide")
                     */
                            
                     //       FlagControlView()
                            
                    //       Text("\(pageItem!.name)  L-\(Int(pageItem!.trims.left)) T-\(Int(pageItem!.trims.top)) B-\(Int(pageItem!.trims.bottom)) R-\(Int(pageItem!.trims.right))")
                            
                        }
                    }
                    )
                }
                
                .padding(proxy.size.width * 0.01)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(foregroundColor, lineWidth: 3) )
                .foregroundColor(foregroundColor)
                .background(backgroundColor)
                
            }
 //           .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0)) // proxy.size.width * 0.01))
            //     .frame(width: proxy.size.width * 0.58)
            //     .position(x: proxy.size.width * 0.72, y: proxy.size.height * 0.5)
            
            //                .inspector(isPresented: $showInspector) {
            //                    PDFPageItemInspector()
            //                }
        }
    
            
//            .background(backgroundColor)
         else {
            EmptyView()
        }
        
    }
}

struct SectionHeaderPopover: View {
    let mergedPage: MergedPage
    @Environment(\.dismiss) private var dismiss
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    let praxTheme = PraxTheme(.erika)
    let deleteTheme = PraxTheme(.julie)
    
    @State private var hoveredButton: Int? = nil
    
    var theTip = PageItemTip()
    
    var body: some View {
        
        VStack {
            Text(mergedPage.title)
            Divider()
            GroupBox {
   
                
                Grid(alignment: .trailing) {
                    GridRow {
                        if prax.optionKeyPressed {
                            Text( "Skip All Pages")
                        }
                        else {
                            Text("Include All Pages")
                        }

                        Button {
                            document.clickedSkipPageButton(mergedPage.mergedPageItem())
                            dismiss() }
                        label: {
                            
                                Image(systemName: "rectangle.portrait.slash")
                          
                        }
                        .buttonStyle(ItemButtonStyle(theme: praxTheme, isHovering: hoveredButton == 156))
                        .onHover { hovering in hoveredButton = hovering ? 156 : nil }
                        
                    }
                    

                    GridRow {
                        Text("Delete All Pages In This Section")
                        Button {
                            document.clickedDeletePageButton(mergedPage.mergedPageItem())
                            dismiss() }
                        label: { Image(systemName: "trash")   }
                        .buttonStyle(ItemButtonStyle(theme: deleteTheme, isHovering: hoveredButton == 150))
                        .onHover { hovering in
                            hoveredButton = hovering ? 150 : nil
                        }
                        .help("Delete page")
                        
                        
                    }
                }

            }
            .padding(5)
            Button {
                dismiss()
            } label: {
                Label("Ok", systemImage: ("checkmark"))
            }
            
        }
        .background(PraxGradient(0).ignoresSafeArea())
        .foregroundColor(.white)
 //       .popoverTip(theTip)
    }
}

struct PageItemPopover: View {
    let pageItem: PageItem
    @Environment(\.dismiss) private var dismiss
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    let praxTheme = PraxTheme(.erika)
    let deleteTheme = PraxTheme(.julie)
    
    @State private var hoveredButton: Int? = nil
    
    var theTip = PageItemTip()
    
    var body: some View {
        
        VStack {
            Text(pageItem.name)
            Divider()
            GroupBox {
   
                
                Grid(alignment: .trailing) {
                    GridRow {
                        if prax.optionKeyPressed {
                            Text(pageItem.skipped ? "Include All Except This Page" : "Skip All Except This Page")
                        }
                        else {
                            Text(pageItem.skipped ? "Include This Page" : "Skip This Page")
                        }

                        Button {
                            document.clickedSkipPageButton(pageItem)
                            dismiss() }
                        label: {
                            if pageItem.skipped {
                                Image(systemName: "rectangle.portrait.slash.fill")
                            }
                            else {
                                Image(systemName: "rectangle.portrait.slash")
                            }
                        }
                        .buttonStyle(ItemButtonStyle(theme: praxTheme, isHovering: hoveredButton == 126))
                        .onHover { hovering in hoveredButton = hovering ? 126 : nil }
                        
                    }
                    
                    GridRow {
                        Text("Merge Mode")
                        Button { document.clickedMergeModeButton(pageItem)
                            dismiss() }
                        label: {
                            switch(pageItem.merge) {
                            case .mergeSkip:
                                Image(systemName: "rectangle.portrait.slash.fill")
                             case .mergeDown:
                                Image(systemName: "arrow.down.document.fill")
                            case .mergeRight:
                                Image(systemName: "inset.filled.trailinghalf.arrow.trailing.rectangle")
                            }
                        }
                        .buttonStyle(ItemButtonStyle(theme: praxTheme, isHovering: hoveredButton == 121))
                        .onHover { hovering in hoveredButton = hovering ? 121 : nil }
                        .help("Merge page mode")
                    }
                    
                    GridRow {
                        Text("Set Width Guide")
                        Button {
                            document.clickedGuidePageButton(pageItem)
                            dismiss() }
                        label: { Image(systemName: "ruler") }
                        .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 124, isFocused: false))
                        .onHover { hovering in hoveredButton = hovering ? 124 : nil }
                        .help("Set width guide")
                        
                        
                    }
                    GridRow {
                        Text("Delete page")
                        Button {
                            document.clickedDeletePageButton(pageItem)
                            dismiss() }
                        label: { Image(systemName: "trash")   }
                        .buttonStyle(ItemButtonStyle(theme: deleteTheme, isHovering: hoveredButton == 120))
                        .onHover { hovering in
                            hoveredButton = hovering ? 120 : nil
                        }
                        .help("Delete page")
                        
                        
                    }
                }

            }
            .padding(5)
            Button {
                dismiss()
            } label: {
                Label("Ok", systemImage: ("checkmark"))
            }
            
        }
        .background(PraxGradient(0).ignoresSafeArea())
        .foregroundColor(.white)
 //       .popoverTip(theTip)
    }
}

struct PageItemTip: Tip {
    var title: Text {
        Text("Page Item Options")
    }
    var message: Text? {
        Text("Hide or Delele page items")
    }
    var image: Image? {
        Image(systemName: "doc.badge.gearshape")
    }
}



struct PageEditView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    let praxTheme = PraxTheme(.erika)
    
    let pageItem: PageItem?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    @State private var hoveredButton: Int? = nil
    
    @State private var pdfViewRef = WeakPDFViewRef()
   
    
    var body: some View {
        
        
        let imageSize = CGSize(width: 170, height: 220)
        let backgroundColor: Color = {
            switch highlightState {
            case .forSelection:
                Color.orange
            case .forDeselection:
                Color.green
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
            case .forSelection:
                Color.green
            case .forDeselection:
                Color.orange
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
        
        if pageItem != nil {
            GeometryReader { proxy in
                GroupBox {
                        
                        VStack {

                            Image(nsImage: pageItem!.pdfPage.thumbnail(of: imageSize, for: .cropBox))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                              //  .cornerRadius(6)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                .padding(3)
                            
                            Button("", systemImage: "arrow.up.and.down.circle", action: {
                                if let pdfView =  pdfViewRef.view {
                                    MergedPDFDocumentView.scalePDFViewToFit(pdfView: pdfView)
                                    
                                }
                            })
                            .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 0, isFocused: false))
                            .onHover { hovering in
                                hoveredButton = hovering ? 0 : nil
                            }
                            
                            .help(Text("\(pageItem!.name)  L-\(Int(pageItem!.trims.left)) T-\(Int(pageItem!.trims.top)) B-\(Int(pageItem!.trims.bottom)) R-\(Int(pageItem!.trims.right))"))
                            
                            
                            Button("", systemImage: "plus.circle", action: {
                                pdfViewRef.view?.zoomIn(self)
                            })
                            .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 1, isFocused: false))
                            .onHover { hovering in
                                hoveredButton = hovering ? 1 : nil
                            }
                            
                            

                            Button("", systemImage: "minus.circle", action: {
                                pdfViewRef.view?.zoomOut(self)
                            })                .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 2, isFocused: false))
                                .onHover { hovering in
                                    hoveredButton = hovering ? 2 : nil
                                }

                            Button("", systemImage: "arrow.left.and.right.circle", action: {
                                pdfViewRef.view?.autoScales = true
                            })                .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 3, isFocused: false))
                                .onHover { hovering in
                                    hoveredButton = hovering ? 3 : nil
                                }
                            
                            Button("", systemImage: "ruler", action: {
                                document.clickedGuidePageButton(pageItem!)
                            })                .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 4, isFocused: false))
                                .onHover { hovering in
                                    hoveredButton = hovering ? 4 : nil
                                }
                                .help("Set width guide")
                            
                           Text("\(pageItem!.name)  L-\(Int(pageItem!.trims.left)) T-\(Int(pageItem!.trims.top)) B-\(Int(pageItem!.trims.bottom)) R-\(Int(pageItem!.trims.right))")
                            
                        }
                        

                }
                
                .padding(proxy.size.width * 0.01)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(foregroundColor, lineWidth: 3) )
                .foregroundColor(foregroundColor)
                .background(backgroundColor)
                
            }
 //           .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0)) // proxy.size.width * 0.01))
            //     .frame(width: proxy.size.width * 0.58)
            //     .position(x: proxy.size.width * 0.72, y: proxy.size.height * 0.5)
            
            //                .inspector(isPresented: $showInspector) {
            //                    PDFPageItemInspector()
            //                }
        }
    
            
//            .background(backgroundColor)
         else {
            EmptyView()
        }
        
    }

    /*
    var body: some View {
        @Bindable var prax = prax
        let preferredFormat = Date.FormatStyle()
            .hour(.defaultDigits(amPM: .omitted))
            .minute()
            .second(.twoDigits)
            .secondFraction(.fractional(3))
        
        GeometryReader { geometry in
            
            if pageItem != nil {
                VStack(spacing: 8) {
                    
                    GeometryReader { boxGeometry in
                        let boxSize = boxGeometry.size
                        let pageAspect = pageItem!.aspectRatio // width / height
                        
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
                        
                      /*  GroupBox {
                            PDFViewRepresentable(
                                document: document,
                       pageItem: pageItem!,
                                onPDFViewReady: { pdfView in
                                    
                                    print(Date().formatted(preferredFormat), "Julia Martin - PageEditView - onPDFViewReady ", pageItem!.name)
                                    
                                    // Store a weak reference so buttons can use it
                                    pdfViewRef.view = pdfView
                              //      prax.pdfViewRegistry.set(pdfView, for: pageItem!.id)

                                }
                            )
                        }
                        .frame(width: fittedSize.width, height: fittedSize.height)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .help(Text("\(pageItem!.name)  L-\(Int(pageItem!.trims.left)) T-\(Int(pageItem!.trims.top)) B-\(Int(pageItem!.trims.bottom)) R-\(Int(pageItem!.trims.right))"))
                     */
                    }
                    
                    
                   
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
                    
              //      print ("pageItem?.pdfPage.bounds(for: .cropBox)", pageItem?.pdfPage.bounds(for: .cropBox) as Any)
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
*/
 
    final class PageEditViewCoordinator: NSObject, PDFPageOverlayViewProvider {
        
        
        init(_ document: MergedPDFDocument,_ pageItem: PageItem) {
            self.document = document
            self.pageItem = pageItem
           
        }
        
        let document: MergedPDFDocument
        let pageItem: PageItem
    //    let pdfDocument = PDFDocument()
        var pdfView: PDFView?
        var overlayView: PDFPageOverlayView?
        
    //    var pdfPage: PDFPage?
         
        @objc func pageChanged(_ note: Notification) {
            guard let pdfView = note.object as? PDFView,
                  let doc = pdfView.document,
                  let page = pdfView.currentPage else { return }
            let idx = doc.index(for: page)
            print(Date().formatted(preferredFormat), "PageItemPDFViewCoordinator - changed to page:", idx)
            //         if idx != NSNotFound, idx != prax.currentIndex { prax.currentIndex = idx }
        }
        

        let preferredFormat = Date.FormatStyle()
            .hour(.defaultDigits(amPM: .omitted))
            .minute()
            .second(.twoDigits)
            .secondFraction(.fractional(3))

        
        func pdfView(_ pdfView: PDFView, overlayViewFor page: PDFPage) -> NSView? {
            print(Date().formatted(preferredFormat), "PageItemPDFViewCoordinator - overlayViewFor page  ", pageItem.name)
            
            let pageItemForPDFPage = document.pageItem(for: page)
            if pageItemForPDFPage != pageItem {
                print(Date().formatted(preferredFormat), "PageItemPDFViewCoordinator - pageItemForPDFPage != pageItem ", pageItem.name, " - ", pageItemForPDFPage?.name ?? "nil", "\n")
            }
            
            let pdfPage = self.pageItem.pdfPage
            if pdfPage != page {
                print(Date().formatted(preferredFormat), "PageItemPDFViewCoordinator - overlayViewFor page != pageItem.pdfPage ", pageItem.name, "\n")
          //      pageItem.pdfPage = page
            }
            
            if pdfView != self.pdfView {
                print(Date().formatted(preferredFormat), "PageItemPDFViewCoordinator - overlayViewFor pdfView != self.pdfView ", pageItem.name, "\n")

            }
           // return nil
            
            
            // Seed current rect from trims
            DispatchQueue.main.async { [self] in // [weak overlayView, weak pdfPage, weak pdfView] in
              //  guard let overlayView = overlayView, let pdfPage = pdfPage, let pdfView = pdfView else { return }
            //    guard let pageItem = self.document.pageItem(for: page) else { return }
                let crop = self.pageItem.pdfPage.bounds(for: .cropBox)
                let cropInView = pdfView.convert(crop, from: self.pageItem.pdfPage)
                let cropInOverlay = overlayView!.convert(cropInView, from: pdfView)
                overlayView!.clampRect = cropInOverlay
                // Recompute visible using current trims
                //                 fatalError()
                let trims = self.pageItem.trims
                let visibleInPage = CGRect(
                    x: crop.minX + trims.left,
                    y: crop.minY + trims.bottom,
                    width: crop.width - trims.left - trims.right,
                    height: crop.height - trims.top - trims.bottom
                )
                let visibleInView = pdfView.convert(visibleInPage, from: self.pageItem.pdfPage)
                let visibleInOverlay = overlayView!.convert(visibleInView, from: pdfView)
                overlayView!.currentRect = visibleInOverlay
                
                overlayView!.needsDisplay = true
            }
            
            return overlayView
        }
        
    }
    
    
    struct PDFViewRepresentable: NSViewRepresentable {
        let document: MergedPDFDocument
        let pageItem: PageItem
        let onPDFViewReady: (PDFView) -> Void
        
        let preferredFormat = Date.FormatStyle()
            .hour(.defaultDigits(amPM: .omitted))
            .minute()
            .second(.twoDigits)
            .secondFraction(.fractional(3))

        func makeCoordinator() -> PageEditViewCoordinator {
            print(Date().formatted(preferredFormat), "Erika daPrax - PageItemPDFViewCoordinator makeCoordinator ", pageItem.name)
            return PageEditViewCoordinator(document, pageItem)
        }
        
        func makeNSView(context: Context) -> PDFView {
            print(Date().formatted(preferredFormat), "PDFViewRepresentable - makeNSView")
            
            context.coordinator.pdfView = PDFView()
            context.coordinator.overlayView = PDFPageOverlayView(pageItem: pageItem)
            context.coordinator.overlayView!.document = document
            context.coordinator.overlayView!.pdfView = context.coordinator.pdfView
            
 /*           context.coordinator.overlayView!.onFinish = { [self] rectInOverlay in
                
                print("overlayView.onFinish - \(pageItem.name)")
                // Convert overlay-local rect to PDFView coordinates
                let rectInView = context.coordinator.overlayView!.convert(rectInOverlay, to: context.coordinator.pdfView)
                
                // Clamp to page bounds in PDFView coordinates
                let pageBoundsInView = context.coordinator.pdfView!.convert(pageItem.pdfPage.bounds(for: .cropBox), from: pageItem.pdfPage)
                let clamped = rectInView.intersection(pageBoundsInView)
                guard !clamped.isEmpty else { return }
                
                // Convert to page coords
                let pageRect = context.coordinator.pdfView!.convert(clamped, to: pageItem.pdfPage)
                let media = pageItem.pdfPage.bounds(for: .cropBox)
                
                let left = max(0, pageRect.minX - media.minX)
                let right = max(0, media.maxX - pageRect.maxX)
                let bottom = max(0, pageRect.minY - media.minY)
                let top = max(0, media.maxY - pageRect.maxY)
                
                let trims = EdgeTrims(left: left, right: right, top: top, bottom: bottom)
                print("DocumentEditingView Coordinator - trims l:", trims.left, " r:", trims.right, " b:", trims.bottom, " t:", trims.top, "pageItem.name: ", self.pageItem.name)
                
                self.pageItem.trims = trims
/*
                // var pageItem = prax.pageItem(for: page)!
                let indexPath = self.document.pdfPageIndexPath(for: page)
                guard let indexPath = indexPath else { return }
                self.document.pageSections[indexPath.section].pageItems[indexPath.item].trims = trims
*/
            }
   */
            context.coordinator.pdfView!.pageOverlayViewProvider = context.coordinator
            context.coordinator.pdfView!.document = PDFDocument()
            
            
            
            context.coordinator.pdfView!.autoScales = true
            context.coordinator.pdfView!.displayDirection = .vertical
            context.coordinator.pdfView!.backgroundColor = .blue
            
            
            onPDFViewReady(context.coordinator.pdfView!)
            return context.coordinator.pdfView!
        }

        func updateNSView(_ pdfView: PDFView, context: Context) {
 
            if pdfView.document!.page(at: 0) == pageItem.pdfPage {
                print(Date().formatted(preferredFormat), "No Update  - PDFViewRepresentable - pdfDocument.page(at: 0) == pageItem.pdfPage ", pageItem.name)
                return
            }
 
            print(Date().formatted(preferredFormat), "Updating - pdfView.document ", pageItem.name)
       
            pdfView.pageOverlayViewProvider = context.coordinator
            
            while pdfView.document!.pageCount > 0 {
                pdfView.document!.removePage(at: 0)
            }
            pdfView.document!.insert(pageItem.pdfPage, at: 0)
            
        }
    }
}


struct MergedPageView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    
    let praxTheme = PraxTheme(.erika)
    
    @State private var hoveredButton: Int? = nil

    let pageItem: PageItem?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    @State private var pdfViewRef = WeakPDFViewRef()
    @State var viewScale = 1.0
    @State private var isEditing = false
    
    var body: some View {
        
        if pageItem == nil {
            EmptyView()
        }
        else {
            @Bindable var pageItem = pageItem!
            @Bindable var prax = prax
            
            GeometryReader { geometry in
                
                /*
                
                GroupBox {
                    
                    VStack(alignment: .center, spacing: 0, content: {
                        
                        
                        HStack {
                            
                            Button("", systemImage: "plus.circle", action: {
                                viewScale += 0.5
                            })
                            .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 1, isFocused: false))
                            .onHover { hovering in
                                hoveredButton = hovering ? 1 : nil
                            }
                            
                            
                            
                            Button("", systemImage: "minus.circle", action: {
                                viewScale -= 0.5
                            })                .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 2, isFocused: false))
                                .onHover { hovering in
                                    hoveredButton = hovering ? 2 : nil
                                }
                            
                            Button("", systemImage: "equal.circle", action: {
                                viewScale = 1.0
                            })                .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 3, isFocused: false))
                                .onHover { hovering in
                                    hoveredButton = hovering ? 3 : nil
                                }
                            Slider(
                                value: $viewScale,
                                in: 0.2...2.0,
                                step: 0.1,
                                onEditingChanged: { editing in
                                    isEditing = editing
                                }
                            )
                            Text("\(viewScale)")
                                        .foregroundColor(isEditing ? .red : .blue)
                        
                            
                        }
                        
                        let imageSize = CGSize(width: (geometry.size.width * viewScale), height: geometry.size.height * viewScale)
                     //   let imageMode: ContentMode = imageSize.width < 500 ? .fit : .fill
                            
                        Text("imageSize \(imageSize)")
 
                        Image(nsImage: pageItem!.pdfPage.thumbnail(of: imageSize, for: .cropBox))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .cornerRadius(6)
                            .frame(maxWidth: .infinity, maxHeight: geometry.size.height - 30, alignment: .center)
                          //  .frame(width: imageSize.width, height: geometry.size.height, alignment: .top)
                            .border(.blue)
                            .clipped()
                        

                    }
                    ).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                
                */
                
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
                                    prax.pdfViewRegistry.set(pdfView, for: pageItem.mergedPage.id)
                                    
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
/*                .onGeometryChange(for: CGFloat.self) {  contentGeometry in
                    print("onGeometryChange - contentGeometry.size.width: ", contentGeometry.size.width)
                    return contentGeometry.size.width
                    
                }
                action: {newValue in
                    print ("contentGeometry.size.width newValue: ", newValue )
                    
                    //      print ("pageItem?.pdfPage.bounds(for: .cropBox)", pageItem?.pdfPage.bounds(for: .cropBox) as Any)
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
    

    final class Coordinator: NSObject {
        
        
        init(_ document: MergedPDFDocument,_ pageItem: PageItem) {
            self.document = document
            self.pageItem = pageItem
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
            
            let pdfView = document.prax.mergedDocumentPDFView
            
            context.coordinator.pdfView = pdfView
            onPDFViewReady(pdfView)
            return pdfView
        }
        
        func updateNSView(_ pdfView: PDFView, context: Context) {
            print("PDFViewRepresentable - updateNSView - rowSize: ", pdfView.rowSize(for: pageItem.pdfPage))
            
            pdfView.document = document.mergedPDFDocument
            
            onPDFViewReady(pdfView)
        }
        
    }
}


/*
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

*/
