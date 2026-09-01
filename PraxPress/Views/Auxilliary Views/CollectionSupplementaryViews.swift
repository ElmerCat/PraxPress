//
//  CollectionSupplementaryViews.swift
//  PraxPress
//
//  Created by Elmer Cat on 3/14/26.
//

//
//  SectionBackground.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/15/26.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers


struct PageItemSectionBackgroundView: View {
    let indexPath: IndexPath
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var prax
    
    var body: some View {
        @Bindable var prax = prax
        let isSelected = prax.selectedSections.contains(indexPath.section)

        
            
        VStack {
            GroupBox {
             /*   GeometryReader { proxy in
                    VStack {
                        Text("w: \(proxy.size.width)")
                        Spacer()
                        Text("h: \(proxy.size.height)")

                        if let pdfPage = mergedPage.pdfPage {
                            Image(nsImage: pdfPage.thumbnail(of: imageSize, for: .cropBox))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: proxy.size.width * 0.45) // 40% of GroupBox width
                            //    .position(x: proxy.size.width * 0.15, y: proxy.size.height * 0.5)
                                .cornerRadius(6)
                                .padding(EdgeInsets(top: sectionHeaderHeight, leading: 0, bottom: 0, trailing: 0))
                            
                    }

                        
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    
                    //  .position(x: 0, y: 16)
                }
           */
                Text(isSelected ? "Julie d'Prax" : "Juliette M. Belanger")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(0)
            .background(isSelected ? PraxGradient(2) : PraxGradient(0))
            .opacity(0.5)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 1)
            )
        
            Spacer(minLength: 15)
        }
        


    }
}

struct EditPageSectionBackgroundView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    let indexPath: IndexPath
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    var body: some View {
        @Bindable var prax = praxModel
        
        if document.mergedPages.count > indexPath.section {
            let mergedPage = document.mergedPages[indexPath.section]
 //           let imageSize = CGSize(width: 1200, height: 1600)
 //           let sectionHeaderHeight = CGFloat(40)
            
            GroupBox {
                GeometryReader { proxy in
                    VStack {
                        Text("\(mergedPage.title)")
/*
                        if let pdfPage = mergedPage.pdfPage {
                            Image(nsImage: pdfPage.thumbnail(of: imageSize, for: .cropBox))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: proxy.size.width * 0.45, alignment: .topLeading) // 40% of GroupBox width
                            //    .position(x: proxy.size.width * 0.15, y: proxy.size.height * 0.5)
                            //    .cornerRadius(6)
                           //     .padding(EdgeInsets(top: sectionHeaderHeight, leading: 0, bottom: 0, trailing: 0))
                            
                        }
*/
                        Spacer()
                       

                        
                    }
                //    .padding(.top, sectionHeaderHeight)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    
                    //  .position(x: 0, y: 16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(0)
            .background(PraxGradient(2))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.orange, lineWidth: 5)
            )
        }
        
        else { EmptyView() }
    }
}

class CollectionViewBackground: NSView, HostingViewContainer {
    var hostingView: NSHostingView<CollectionViewBackgroundView>?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    func buildRootView() -> CollectionViewBackgroundView {
        CollectionViewBackgroundView()
    }
    
    func configure() {
        attachHostingView()
      
   /*     self.registerForDraggedTypes([
            .fileURL,
            .pdfPageDragType,
            .mergedPageType,
            .sourceFileType
        ])
   */
    }
    
    override func viewWillMove(toSuperview newSuperview: NSView?) {
        super.viewWillMove(toSuperview: newSuperview)
        if newSuperview == nil {
            detachHostingView()
        }
    }
     
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        
        print("CollectionViewBackgroundView - draggingEntered")
        layer?.backgroundColor = NSColor.green.cgColor
        return .copy
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?)  {
        print("CollectionViewBackgroundView - draggingExited")
        layer?.backgroundColor = NSColor.cyan.cgColor
    }
    
    override func concludeDragOperation(_ sender: NSDraggingInfo?)  {
        print("CollectionViewBackgroundView - concludeDragOperation")
        layer?.backgroundColor = NSColor.cyan.cgColor
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo)  {
        print("CollectionViewBackgroundView - draggingEnded")
        layer?.backgroundColor = NSColor.cyan.cgColor
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("CollectionViewBackgroundView - prepareForDragOperation")
        return true
    }
    
    func wantsPeriodicUpdates() -> Bool {
        print("CollectionViewBackgroundView - wantsPeriodicUpdates")
        return true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pboard = sender.draggingPasteboard
        
        // Extract file URLs from the pasteboard
        if let urls = pboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
            for url in urls {
                print("CollectionViewBackgroundView - Dropped file: \(url.path)")
            }
            return true // Drop was successful
        }
        return false // Drop rejected
    }
    
}

struct CollectionViewBackgroundView: View {
//    @Environment(MergedPDFDocument.self) var document
    @Environment(PraxModel.self) private var praxModel
    var body: some View {
        @Bindable var prax = praxModel
        
        GroupBox {
            GeometryReader { proxy in
                VStack {
                    HStack {
                        Text("PraxPress")
                            .font(Font.custom("BrushScriptMT", size: 30))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                  
                }
                
                //  .position(x: 0, y: 16)
            }
        }
        
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(0)
        .background(PraxGradient())
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.blue, lineWidth: 5).opacity(0.5)
        )


    }
}

struct SectionHeaderView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
   
    
    @State var showSettings = false
    @State private var hoveredButton: Int? = nil
    
    let mergedPage: MergedPage?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    var body: some View {
        if mergedPage != nil {
            @Bindable var section = mergedPage!
            @Bindable var prax = praxModel
            let clickGesture = TapGesture()
                .onEnded { value in
                    print("View tapped! - \(section.title) - PraxModel.shared.optionKeyPressed: \(prax.optionKeyPressed)")
                    clickedSectionHeader()
                }
            
            GroupBox {
                HStack {
                    Button {
                        showSettings = !showSettings
                    }
                    label: { Image(systemName: "gear")}
                    .buttonStyle(PraxButtonStyle(isHovering: hoveredButton == 2))
                    .onHover { hovering in
                        hoveredButton = hovering ? 2 : nil
                    }
                    
                    .popover(isPresented: $showSettings, arrowEdge: .leading) {
                        SectionHeaderPopover(mergedPage: mergedPage!)
                            .presentationDetents(
                                [.height(120), .medium, .large])
                            .presentationBackgroundInteraction(
                                .enabled(upThrough: .height(120)))
                            .presentationSizing(.form)
                    }
 
                    Spacer()
                    Text("\(section.title)")
                       // .font(.system(.subheadline))
                        .font(.caption)
                        .lineLimit(1)
                        .padding(.horizontal, 5)
                        .draggable({ () -> MergedPDFTransfer? in
                            guard let data = document.mergedPDFDocument.dataRepresentation() else { return nil }
                            return MergedPDFTransfer(data: data, filename: document.exportFilename)
                        }()!, preview: {
                            PraxDragPreview()
                        })
                    Spacer()
                }
                .background(Color.black.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.cyan, lineWidth: 2))
                .gesture(clickGesture)
                
            }
            .padding(0)
        }
        else {
            EmptyView()
        }
    }
    
    func clickedSectionHeader(_ modifiers: EventModifiers = [] ) {
        print ("Julie d'Prax - clickedSectionHeader")
        if modifiers.contains(.shift) {
            print("Shift + Click detected")  }
        else if modifiers.contains(.command) {
            print("Command + Click detected")  }
        else if modifiers.contains(.control) {
            print("Control + Click detected")  }
        else {
            print("Plain Click detected")
    //        praxModel.currentEditingMergedPage = mergedPage
        }
    }
}



struct SectionFooterView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    let mergedPage: MergedPage?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    func mergedSizeText() -> String {
        if mergedPage != nil {
            let w = mergedPage!.mergedWidthPts
            let h = mergedPage!.mergedHeightPts
            let wIn = w / 72.0
            let hIn = h / 72.0
            return String(format: "%.1f\" × %.1f\"", wIn, hIn)
        }
        else {
            return "No Page Section"
        }
    }
    var body: some View {
        @Bindable var prax = praxModel
        VStack(spacing: 8) {
            HStack {
                Text(mergedSizeText())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            if mergedPage == document.mergedPages.last {
          //      DropTargetControl()
            }
        }
            .padding(8)
       //     .background(Color.black.opacity(0.5))
           // .overlay(RoundedRectangle(cornerRadius: 8)
         //   .stroke(isSelected ? Color.accentColor : Color.cyan, lineWidth: 2))
        
            .inspector(isPresented: $prax.isLarge) {
                VStack {
                    GroupBox {
                        Text("Inspector 1")
                            .frame(minWidth: 100, maxWidth: 1000, maxHeight: 100)
                            .background(.pink)
                    }
                    .padding(20)
                    //  .background(.yellow)
                    Button(prax.isLarge ? "Make Small" : "Make Large") {
                        // Toggle the state when the button is tapped
                        prax.isLarge.toggle()
                    }
                    Text("Inspector 2")
                    //           .frame(maxWidth: .infinity, maxHeight: .infinity)
                    //               .background(.purple)
                        .background(.purple)
                }
                Text("Inspector 3")
                //    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .inspectorColumnWidth(min: 50, ideal: 150, max: 500)
                    .background(.gray)
            }
        }
}

struct MergedPageFooterView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    let mergedPage: MergedPage?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    @State private var hoveredButton: Int? = nil
    
    func mergedSizeText() -> String {
        if mergedPage != nil {
            let w = mergedPage!.mergedWidthPts
            let h = mergedPage!.mergedHeightPts
            let wIn = w / 72.0
            let hIn = h / 72.0
            return String(format: "Merged size: %.0f × %.0f pts (%.2f × %.2f in) %.0f KB", w, h, wIn, hIn, document.mergedDocumentSizeKB)
        }
        else {
            return "No Merged Page"
        }
    }
    
    enum PDFViewMode {
        case zoomIn
        case zoomOut
        case zoomFit
    }
    
    func pdfViewMode (_ mode: PDFViewMode) {
        guard let mergedPage = mergedPage, let pdfViewRef = praxModel.pdfViewRegistry.ref(for: mergedPage.id)
        else {
            print("No pdfViewRef")
            return
        }
                
        switch (mode) {
        case .zoomIn:
            pdfViewRef.view?.zoomIn(self)
        case .zoomOut:
            pdfViewRef.view?.zoomOut(self)
        case .zoomFit:
            pdfViewRef.view?.autoScales = true
        }
    
    }
    var body: some View {
        @Bindable var prax = praxModel
        
        
        
        HStack {
            Button("", systemImage: "plus.circle", action: {
                pdfViewMode(.zoomIn)
            })
            .buttonStyle(PraxButtonStyle(isHovering: hoveredButton == 1))
            
            Button("", systemImage: "minus.circle", action: {
                pdfViewMode(.zoomOut)
            })                .buttonStyle(PraxButtonStyle(isHovering: hoveredButton == 2))
            
            Button("", systemImage: "equal.circle", action: {
                pdfViewMode(.zoomFit)
            })                .buttonStyle(PraxButtonStyle(isHovering: hoveredButton == 2))
            
            Spacer()

            Text(mergedSizeText())
                .font(.caption)
                .lineLimit(1)
                  
        }
      //  .padding(8)
        .background(PraxGradient())
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
        )
        
/*            VStack(spacing: 8) {
                HStack {
                    Text("Footer \(mergedPage?.title ?? "No Section")")
                        .font(.caption)
                        .lineLimit(1)
                    Text(mergedSizeText())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(8)
            .background(PraxGradient())
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .inspector(isPresented: $prax.isLarge) {
                VStack {
                    GroupBox {
                        
                        Text("Inspector 1")
                            .frame(minWidth: 100, maxWidth: 1000, maxHeight: 100)
                            .background(.pink)
                    }
                    .padding(20)
                    //  .background(.yellow)
                    Button(prax.isLarge ? "Make Small" : "Make Large") {
                        // Toggle the state when the button is tapped
                        prax.isLarge.toggle()
                    }
                    Text("Inspector 2")
                    //           .frame(maxWidth: .infinity, maxHeight: .infinity)
                    //               .background(.purple)
                        .background(.purple)
                }
                Text("Inspector 3")
                //    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .inspectorColumnWidth(min: 50, ideal: 150, max: 500)
                    .background(.gray)
            }
    */
    }
}


struct MergedPageHeaderView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    let mergedPage: MergedPage?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    var body: some View {
        if mergedPage != nil {
            @Bindable var section = mergedPage!
            @Bindable var prax = praxModel
        
        
       
            
            let clickGesture = TapGesture()
                .onEnded { value in
                    print("View tapped! - \(section.title) - PraxModel.shared.optionKeyPressed: \(prax.optionKeyPressed)")
                    clickedSectionHeader()
                    
                }
            
            GroupBox {
                Group {
                    
                    Text("Julie d'Prax - \(section.title)") }
                
                .draggable({ () -> MergedPDFTransfer? in
                    guard let data = document.mergedPDFDocument.dataRepresentation() else { return nil }
                    return MergedPDFTransfer(data: data, filename: document.exportFilename)
                }()!, preview: {
                    PraxDragPreview()
                })
                
                
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .font(.caption)
                .lineLimit(1)
                .padding(8)
                
                .background(Color.black.opacity(0.7))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.cyan, lineWidth: 2))
                .gesture(clickGesture)
                
            }
          // .padding(20)
            
            
            
            
            /*        .gesture(
             TapGesture()
             .modifiers([.option, .command, .control])
             .onEnded {
             clickedSectionHeader(modifiers)
             }
             )
             .gesture(
             TapGesture()
             .modifiers(.command)
             .onEnded {
             clickedSectionHeader([.command])
             }
             )
             .gesture(
             TapGesture()
             .modifiers(.shift)
             .onEnded {
             clickedSectionHeader([.shift])
             }
             )
             //       .onTapGesture(perform: clickedSectionHeader())*/
        }
    //    else {
            EmptyView()
      //  }
            
    }
    
    func clickedSectionHeader(_ modifiers: EventModifiers = [] ) {
        print ("Julie d'Prax - clickedSectionHeader")
        
        if modifiers.contains(.shift) {
            print("Shift + Click detected")
        }
        else if modifiers.contains(.command) {
            print("Command + Click detected")
        }
        else if modifiers.contains(.control) {
            print("Control + Click detected")
        }
        else {
            print("Plain Click detected")
 //       fatalError()
            //     document.mergedPDFView.go(to: mergedPage.pdfPage!)
        }
        
   //     if PraxModel.shared.selectedSections.contains(indexPath.section) {
  //          PraxModel.shared.selectedSections.remove(indexPath.section)
  //      } else {
  //          PraxModel.shared.selectedSections.insert(indexPath.section)
  //      }
        // self.isSelected = PraxModel.shared.selectedSections.contains(indexPath.section)
        // Refresh just this section’s header to reflect the new state.
        //       self.collectionView.reloadSections(IndexSet(integer: indexPath.section))
        
    }
}




#Preview {
    CollectionViewBackgroundView()


}
