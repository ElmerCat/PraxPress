//
//  EditingDocumentView.swift
//  PraxPress
//
//  Created by Elmer Cat on 4/9/26.
//


//
//  EditingDocumentView.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/12/26.
//

import SwiftUI
import PDFKit

struct EditingDocumentView: View {
    @Environment(PraxModel.self) private var prax
    @State private var hovering: Bool = false
    var body: some View {
  //      let _ = Self._printChanges()
        
        VStack{
            Text("Editor")
            ZStack{
                EditingToolbarView()
                    .zIndex(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                EditingPDFViewRepresentable(prax)
                    .padding(.horizontal, 10)
                    .padding(.top, prax.editingToolbarSize.height)
                    .zIndex(1)
                    .onGeometryChange(for: CGSize.self) { viewGeometry in return viewGeometry.size }
                action: { oldValue, newValue in prax.editingDocumentPDFViewSize = newValue }
                FooterView()
                    .zIndex(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        
        .animation(.easeInOut(duration: 0.50), value: prax.editingToolbarSize.height)
        .onHover { isHovering in hovering = isHovering }
        .environment(\.groupHovering, hovering)
        .onGeometryChange(for: CGSize.self) { viewGeometry in return viewGeometry.size }
        action: { oldValue, newValue in prax.editorViewSize = newValue }
        
        

    }
    
    struct EditingPDFViewRepresentable: NSViewRepresentable {
        init(_ prax: PraxModel) { self.prax = prax }
        let prax: PraxModel
        func makeCoordinator() -> EditingPDFDocumentViewCoordinator { return EditingPDFDocumentViewCoordinator(prax) }
        
        func makeNSView(context: Context) -> PDFView {
            prax.editingDocumentPDFView.autoScales = true
            prax.editingDocumentPDFView.displayDirection = .vertical
            prax.editingDocumentPDFView.displaysPageBreaks = true
            prax.editingDocumentPDFView.pageBreakMargins = Prax.pdfPageBreakMargins
            prax.editingDocumentPDFView.displayMode = .singlePageContinuous
            prax.editingDocumentPDFView.backgroundColor = .blue
            prax.editingDocumentPDFView.pageOverlayViewProvider = context.coordinator
            prax.editingDocumentPDFView.delegate = context.coordinator
            addObservers(observer: context.coordinator)
            return prax.editingDocumentPDFView
        }
        
        
        func updateNSView(_ pdfView: PDFView, context: Context) {
            print("EditingPDFViewRepresentable - updateNSView")
            if prax.document.mergedDocumentSizeKB == 0 {
                pdfView.document = prax.document.defaultPDFDocument
                pdfView.isHidden = true
            }
            else {
                pdfView.isHidden = false
                if let pageItem = prax.selectedPageItem {
                    if context.coordinator.documentVersion != prax.document.editingDocumentVersion {
                        context.coordinator.documentVersion = prax.document.editingDocumentVersion
                        pdfView.document = prax.document.editingPDFDocument
           //             prax.updateEditingPDFDocumentViewSize()
//                        pdfView.autoScales = true

                   //     scalePDFViewToFit(pdfView: context.coordinator.prax.editingDocumentPDFView)
                        scalePDFViewToFitViewSize(prax.editingDocumentPDFView, prax.editorViewSize, .vertical, forPDFDocument: prax.document.editingPDFDocument)
                        
                        if !pdfView.visiblePages.contains(pageItem.pdfPage) { pdfView.go(to: pageItem.pdfPage) }
                    }
                }
                else {
                    print("EditingPDFViewRepresentable - updateNSView - No selectedPageItem ")
                }
            }
            
            
        }
        
        func addObservers( observer: EditingPDFDocumentViewCoordinator) {
            NotificationCenter.default.addObserver (observer, selector: #selector(EditingPDFDocumentViewCoordinator.selectionChanged(_:)),
                                                    name: Notification.Name.PDFViewSelectionChanged, object: observer.prax.editingDocumentPDFView)
            NotificationCenter.default.addObserver (observer, selector: #selector(EditingPDFDocumentViewCoordinator.viewScaleChanged(_:)),
                                                    name: Notification.Name.PDFViewScaleChanged, object: observer.prax.editingDocumentPDFView)
            NotificationCenter.default.addObserver( observer, selector: #selector(EditingPDFDocumentViewCoordinator.pageChanged(_:)),
                                                    name: Notification.Name.PDFViewPageChanged, object: observer.prax.editingDocumentPDFView)
            NotificationCenter.default.addObserver (observer, selector: #selector(EditingPDFDocumentViewCoordinator.visiblePagesChanged(_:)),
                                                    name: Notification.Name.PDFViewVisiblePagesChanged, object: observer.prax.editingDocumentPDFView)
            NotificationCenter.default.addObserver (observer, selector: #selector(EditingPDFDocumentViewCoordinator.annotationHit(_:)),
                                                    name: Notification.Name.PDFViewAnnotationHit, object: observer.prax.editingDocumentPDFView)
        }

    }
    
    final class EditingPDFDocumentViewCoordinator: NSObject, PDFPageOverlayViewProvider, PDFViewDelegate {
        
        let prax: PraxModel
        init(_ prax: PraxModel) {
            self.prax = prax
            prax.editingDocumentPDFView.document = PDFDocument()
        }
        var documentVersion = UUID()
        
        func pdfView(_ pdfView: PDFView, overlayViewFor pdfPage: PDFPage) -> NSView? {
            if let pageItem = prax.document.pageItem(for: pdfPage) {
                let overlayView = pageItem.overlayView
                overlayView.pdfView = pdfView
                pdfView.wantsLayer = true
                pdfView.layer?.masksToBounds = false
                return overlayView
            }
            else { print( "EditingPDFDocumentViewCoordinator - overlayViewFor pdfPage - NO PAGE ITEM"); return nil }
        }
        
        func pdfViewWillClick(onLink sender: PDFView, with url: URL) {print("EditingPDFDocumentViewCoordinator - pdfViewWillClick: ", url) }
    
        @objc func selectionChanged(_ note: Notification) {print("EditingPDFDocumentViewCoordinator - selectionChanged")}
        @objc func annotationHit(_ note: Notification) {print("EditingPDFDocumentViewCoordinator - annotationHit: ", note)}
        @objc func visiblePagesChanged(_ note: Notification) {if let pdfView = note.object as? PDFView { print("EditingPDFDocumentViewCoordinator - visiblePagesChanged: ", pdfView.visiblePages) } }
        @objc func viewScaleChanged(_ note: Notification) { } //          print("EditingPDFDocumentViewCoordinator - viewScaleChanged: ")
        
        @objc func pageChanged(_ note: Notification) {//          print("EditingPDFDocumentViewCoordinator - pageChanged ")
            guard let pageItem = prax.selectedPageItem, prax.editingDocumentPDFView.visiblePages.contains(pageItem.pdfPage) else {
                prax.currentEditingPDFPage = prax.editingDocumentPDFView.currentPage
                return
            }
            
        }
    }
    

    struct FooterView: View {
        @Environment(PraxModel.self) private var prax
        @Environment(\.groupHovering) private var groupHovering
        
            @State private var hovering: Bool = false
        
        var body: some View {
            @Bindable var prax = prax
            HStack {
                
                Spacer()
                Button { scalePDFViewToFitViewSize(prax.editingDocumentPDFView, prax.editorViewSize, .vertical, forPDFDocument: prax.document.editingPDFDocument) }
                label: {  Image(systemName: "arrow.up.and.down.square") }
                    .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 31))
                    .onHover { hovering in prax.hoveredButton = hovering ? 31 : nil }
                    .help("Fit Horizontally")
                
                Button { prax.editingDocumentPDFView.zoomOut(self) }
                label: {  Image(systemName: "minus.circle") }
                    .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 32))
                    .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                    .help("Zoom Out")
                
             
                
                Text("\(Int(prax.editingDocumentPDFView.scaleFactor * 100))%")
                    .font(.callout).foregroundStyle(Color.black)
                    .padding(.leading, 20)

                Slider(value: $prax.editingDocumentPDFViewScaleFactor, in: 0.1...max(0.2, prax.editingDocumentPDFView.scaleFactorForSizeToFit),)
                    .frame(width: 100)
                    .padding(.leading, 20)
                
                
                Button { prax.editingDocumentPDFView.zoomIn(self) }
                label: {  Image(systemName: "plus.circle") }
                    .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 32))
                    .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                    .help("Zoom In")

                Button { scalePDFViewToFitViewSize(prax.editingDocumentPDFView, prax.editorViewSize, .horizontal, forPDFDocument: prax.document.editingPDFDocument) }
                label: {  Image(systemName: "arrow.left.and.right.square") }
                    .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 3))
                    .onHover { hovering in prax.hoveredButton = hovering ? 3 : nil }
                    .help("Fit Horizontally")
                
                Spacer()
            }
            .frame(minHeight: 10)
            .onHover { isHovering in hovering = isHovering }
            .environment(\.groupHovering, hovering)
            //    .background(PraxGradient(hovering ? 0 : 4))
            //    .opacity(groupHovering ? 1 : 0.1)
            
            
        }
    }
    
     

  /*
    static func scalePDFViewToFit(pdfView: PDFView) {
        if let pdfPage = pdfView.currentPage {
            let bounds = pdfPage.bounds(for: .mediaBox)
            let scaleFactor = pdfView.frame.height / bounds.height
            if pdfView.frame.width > bounds.width * scaleFactor {
                print ("Bounds: ", bounds.width, " wide x ", bounds.height, " high - frame w: ", pdfView.frame.width, " - h:", pdfView.frame.height, " scale: ", pdfView.scaleFactor, " to: ", scaleFactor)
                pdfView.scaleFactor = scaleFactor
            }
            else {
                pdfView.autoScales = true
                print ("Bounds: ", bounds.width, " wide x ", bounds.height, " high - frame w: ", pdfView.frame.width, " - h:", pdfView.frame.height, " scale: ", pdfView.scaleFactor, " to: autoScales = true")
            }
        }
    } */
}



struct EditingToolbarView: View {
    @Environment(PraxModel.self) private var prax
    @Environment(\.groupHovering) private var groupHovering
    
    @State private var hovering: Bool = false
    
    
    var body: some View {
        @Bindable var prax = prax
        GroupBox {
            if let pageItem = prax.selectedPageItem {
                //     let _ = Self._printChanges()
                GroupBox {
                    VStack {
                        Text("PDF Height: \(Int(prax.editingDocumentPDFSize.height))  Width: \(Int(prax.editingDocumentPDFSize.width))  PDF View Height: \(Int(prax.editingDocumentPDFViewSize.height))  Width: \(Int(prax.editingDocumentPDFViewSize.width))")
                            .font(.callout).foregroundStyle(Color.black)
                            .padding(.leading, 20)
                        if pageItem == prax.document.dataFieldPage {
                            HStack {
                                PraxSegmentedControl(selection: $prax.editMode, colorProvider: { $0.color }, iconProvider: {$0.icon} )
                                Spacer()
                            }
                            
                            //        Picker("", selection: $dataMode) {
                            //            Text("Trims").tag(false)
                            //            Text("Data").tag(true)
                            //          }
                            //          .pickerStyle(.segmented)
                            
                        }
                        if prax.editMode == .data && pageItem == prax.document.dataFieldPage {
                            DataFieldsView()
                            
                        }
                        else {
                            Button { prax.document.clickedGuidePageButton(pageItem) }
                            label: { if pageItem.skipped { Image(systemName: "ruler.fill") } else { Image(systemName: "ruler") }}
                            
                                .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 435, isOn: prax.document.widthGuidePageID != nil))
                                .onHover { hovering in prax.hoveredButton = hovering ? 435 : nil }
                                .help("Set Width Guide")
                        }
                        
                        HStack {
                            
                            Button { scalePDFViewToFitViewSize(prax.editingDocumentPDFView, prax.editorViewSize, .vertical, forPDFDocument: prax.document.editingPDFDocument) }
                            label: {  Image(systemName: "arrow.up.and.down.square") }
                                .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 31))
                                .onHover { hovering in prax.hoveredButton = hovering ? 31 : nil }
                                .help("Fit Vertically")
                            
                            
                            Button { prax.editingDocumentPDFView.zoomOut(self) }
                            label: {  Image(systemName: "minus.circle") }
                                .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 32))
                                .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                                .help("Zoom Out")
                            
                            
                            
                            Text("\(Int(prax.editingDocumentPDFView.scaleFactor * 100))%")
                                .font(.callout).foregroundStyle(Color.black)
                                .padding(.leading, 20)
                            
                            Slider(value: $prax.editingDocumentPDFViewScaleFactor, in: 0.1...max(0.2, prax.editingDocumentPDFView.scaleFactorForSizeToFit),)
                                .frame(width: 100)
                                .padding(.leading, 20)
                            
                            
                            
                            Button { prax.editingDocumentPDFView.zoomIn(self) }
                            label: {  Image(systemName: "plus.circle") }
                                .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 32))
                                .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                                .help("Zoom In")
                            
                            
                            
                            Button { scalePDFViewToFitViewSize(prax.editingDocumentPDFView, prax.editorViewSize, .horizontal, forPDFDocument: prax.document.editingPDFDocument) }
                            label: {  Image(systemName: "arrow.left.and.right.square") }
                                .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 3))
                                .onHover { hovering in prax.hoveredButton = hovering ? 3 : nil }
                                .help("Fit Horizontally")
                        }
                        
                        
                    }
                }
            }
            else {
                Text("No Such Number!")
                    .frame(maxWidth: .infinity, minHeight: 10.0, maxHeight: .infinity, alignment: .init(horizontal: .center, vertical: .center))
            }
        }
        .onGeometryChange(for: CGSize.self) { viewGeometry in return viewGeometry.size }
        action: { oldValue, newValue in prax.editingToolbarSize = newValue }
            .animation(.easeIn(duration: 0.5), value: prax.editMode)
            .animation(.easeIn(duration: 0.5), value: groupHovering)
            .animation(.easeIn(duration: 0.5), value: hovering)
            .frame(maxWidth: .infinity, minHeight: 20)
            .onHover { isHovering in hovering = isHovering }
            .environment(\.groupHovering, hovering)
            .background(PraxGradient(4))
            .opacity(groupHovering ? 1 : 0.1)
            .animation(.easeIn(duration: 1.25), value: hovering)
            .animation(.easeIn(duration: 1.25), value: groupHovering)
        
    }
    
    /*
     var body: some View {
     @Bindable var prax = prax
     //      let _ = Self._printChanges()
     VStack {
     
     HStack {
     GroupBox {
     VStack {
     Text("Prefix")
     TextField("Filename", text: Binding<String>(
     get: { prax.document.exportFilenamePrefix },
     set: { newValue in
     prax.document.exportFilenamePrefix = newValue.filter{!Prax.filechars.contains($0)}}))
     }
     .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
     }
     .frame(maxWidth: 100)
     .groupBoxStyle(PraxGroupBoxStyle(isHovering: prax.hoveredButton == 427 ))
     .onHover { hovering in prax.hoveredButton = hovering ? 427 : nil }
     
     GroupBox {
     VStack {
     Text("Filename")
     TextField("Filename", text: Binding<String>(
     get: { prax.document.exportFilenameBody },
     set: { newValue in
     prax.document.exportFilenameBody = newValue.filter{!Prax.filechars.contains($0)}}))
     .frame(maxWidth: .infinity)
     }
     .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
     }
     .groupBoxStyle(PraxGroupBoxStyle(isHovering: prax.hoveredButton == 437 ))
     .onHover { hovering in prax.hoveredButton = hovering ? 437 : nil }
     
     GroupBox {
     VStack {
     Text("Suffix")
     TextField("Filename", text: Binding<String>(
     get: { prax.document.exportFilenameSuffix },
     set: { newValue in
     prax.document.exportFilenameSuffix = newValue.filter{!Prax.filechars.contains($0)}}))
     }
     .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
     }
     .frame(maxWidth: 100)
     .groupBoxStyle(PraxGroupBoxStyle(isHovering: prax.hoveredButton == 447 ))
     .onHover { hovering in prax.hoveredButton = hovering ? 447 : nil }
     
     }
     
     HStack {
     
     Button { scalePDFViewToFitViewSize(prax.editingDocumentPDFView, prax.editorViewSize, .vertical, forPDFDocument: prax.document.editingPDFDocument) }
     label: {  Image(systemName: "arrow.up.and.down.square") }
     .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 31))
     .onHover { hovering in prax.hoveredButton = hovering ? 31 : nil }
     .help("Fit Vertically")
     
     
     Button { prax.editingDocumentPDFView.zoomOut(self) }
     label: {  Image(systemName: "minus.circle") }
     .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 32))
     .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
     .help("Zoom Out")
     
     
     
     Text("\(Int(prax.editingDocumentPDFView.scaleFactor * 100))%")
     .font(.callout).foregroundStyle(Color.black)
     .padding(.leading, 20)
     
     Slider(value: $prax.editingDocumentPDFViewScaleFactor, in: 0.1...max(0.2, prax.editingDocumentPDFView.scaleFactorForSizeToFit),)
     .frame(width: 100)
     .padding(.leading, 20)
     
     
     
     Button { prax.editingDocumentPDFView.zoomIn(self) }
     label: {  Image(systemName: "plus.circle") }
     .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 32))
     .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
     .help("Zoom In")
     
     
     
     Button { scalePDFViewToFitViewSize(prax.editingDocumentPDFView, prax.editorViewSize, .horizontal, forPDFDocument: prax.document.editingPDFDocument) }
     label: {  Image(systemName: "arrow.left.and.right.square") }
     .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 3))
     .onHover { hovering in prax.hoveredButton = hovering ? 3 : nil }
     .help("Fit Horizontally")
     }
     
     
     
     //         .frame(minHeight: 10)
     .onHover { isHovering in hovering = isHovering }
     .environment(\.groupHovering, hovering)
     
     }
     }
     
     */
    
    func scaleView(_ direction: PDFDisplayDirection) {
        if direction == .vertical {
            let scale = prax.mergedViewSize.height / prax.document.totalHeight
            prax.mergedViewScaleFactor = scale
        }
        else {
            let scale = prax.mergedViewSize.width / prax.document.maxWidth
            prax.mergedViewScaleFactor = scale
        }
    }
    
    
    
    
    
}


#Preview {
    
   
//    EditingDocumentToolbar()
 //       MergedDocumentView()
//    MergedDocumentFooter()
   
}
