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


struct SectionBackgroundView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    let indexPath: IndexPath
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    var body: some View {
        @Bindable var prax = praxModel
        
        if document.pageSections.count > indexPath.section {
            let mergedPage = document.pageSections[indexPath.section]
            let imageSize = CGSize(width: 1200, height: 1600)
            let sectionHeaderHeight = CGFloat(30)
            
            GroupBox {
                GeometryReader { proxy in
                    VStack {

  //          Spacer()
                       if let pdfPage = mergedPage.pdfPage {
                            Image(nsImage: pdfPage.thumbnail(of: imageSize, for: .cropBox))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: proxy.size.width * 0.28) // 40% of GroupBox width
                            //    .position(x: proxy.size.width * 0.15, y: proxy.size.height * 0.5)
                                .cornerRadius(6)
                                .padding(EdgeInsets(top: sectionHeaderHeight, leading: proxy.size.width * 0.01, bottom: 0, trailing: 0))
                            
                        }
                    
                        
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    
                    //  .position(x: 0, y: 16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(0)
            .background(PraxGradient())
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.orange, lineWidth: 5)
            )
        }
        
        else { EmptyView() }
    }
}



class CollectionViewBackground: NSView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    private var hostingView: NSHostingView<CollectionViewBackgroundView>?
    
    func configure() {
        
 //      registerForDraggedTypes([.fileURL])
//        self.wantsLayer = true
//        layer?.backgroundColor = NSColor.cyan.cgColor
//        layer?.borderColor = NSColor.black.cgColor
//        layer?.borderWidth = 1
//        layer?.cornerRadius = 12

        let root = CollectionViewBackgroundView()
        
        if let hostingView {
            hostingView.rootView = root
        } else {
            let hosting = NSHostingView(rootView: root)
            hosting.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(hosting)
            NSLayoutConstraint.activate([
                hosting.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                hosting.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                hosting.topAnchor.constraint(equalTo: self.topAnchor),
                hosting.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            ])
            self.hostingView = hosting
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
    @Environment(MergedPDFDocument.self) var document
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
 //       .onDrop(of: [.fileURL], isTargeted: $prax.dropTargeted) { providers in
 //           PraxModel.shared.acceptDrop(providers)
 //       }
 //       .onDropSessionUpdated({ dropSession in
 //           print("CollectionViewBackgroundView - dropSessionUpdated phase: ", dropSession.phase)
//        })
        

    }
}

struct SectionHeaderView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    let pdfPageSection: MergedPage?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    var body: some View {
        if pdfPageSection != nil {
            @Bindable var section = pdfPageSection!
            @Bindable var prax = praxModel
        
        
       
            
            let clickGesture = TapGesture()
                .onEnded { value in
                    print("View tapped! - \(section.title) - PraxModel.shared.optionKeyPressed: \(prax.optionKeyPressed)")
                    clickedSectionHeader()
                    
                }
            
            GroupBox {
                Group {
                    TextField("Title", text: $section.title )
                    Text("Merged Page \(section.title)") }
                
                .draggable({ () -> MergedPDFTransfer? in
                    guard let data = document.mergedPDFDocument().dataRepresentation() else { return nil }
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
            .padding(20)
            
            
            
            
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
       fatalError()
            //     document.mergedPDFView.go(to: pdfPageSection.pdfPage!)
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



struct SectionFooterView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    let pdfPageSection: MergedPage?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    func mergedSizeText() -> String {
        if pdfPageSection != nil {
            let w = pdfPageSection!.mergedWidthPts
            let h = pdfPageSection!.mergedHeightPts
            let wIn = w / 72.0
            let hIn = h / 72.0
            return String(format: "Merged size: %.0f × %.0f pts (%.2f × %.2f in)", w, h, wIn, hIn)
        }
        else {
            return "No Page Section"
        }
    }
    

 
    var body: some View {
        @Bindable var prax = praxModel
            
            VStack(spacing: 8) {
                HStack {
                    Text("Footer \(pdfPageSection?.title ?? "No Section")")
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
        }
}


struct MergedPageHeaderView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    let pdfPageSection: MergedPage?
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
    var body: some View {
        if pdfPageSection != nil {
            @Bindable var section = pdfPageSection!
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
                    guard let data = document.mergedPDFDocument().dataRepresentation() else { return nil }
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
            .padding(20)
            
            
            
            
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
       fatalError()
            //     document.mergedPDFView.go(to: pdfPageSection.pdfPage!)
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
