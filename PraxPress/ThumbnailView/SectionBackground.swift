//
//  SectionBackground.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/15/26.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers




class SectionBackground: NSView, NSCollectionViewElement {
    
    private var hostingView: NSHostingView<SectionBackgroundView>?
    private var indexPath: IndexPath?
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        //       configure()
    }
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    func apply(_ layoutAttributes: NSCollectionViewLayoutAttributes) {
        if let indexPath = layoutAttributes.indexPath {
            configure(at: indexPath, isSelected: isSelected)
        }
        
    }
  
    
    func configure(at atIndexPath: IndexPath?,
                   isSelected: Bool) {
        indexPath = atIndexPath
        
        if let indexPath {
                 
                let root = SectionBackgroundView(indexPath: indexPath, isSelected: isSelected, highlightState: highlightState)
                
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
        
    }
    
    var highlightState: NSCollectionViewItem.HighlightState = .none {
        didSet {
            configure(at: indexPath, isSelected: isSelected)
        }
    }
    
    var isSelected: Bool = false {
        didSet {
            if let indexPath {
                configure(at: indexPath, isSelected: isSelected)
            }
        }
    }
    
    
}

struct SectionBackgroundView: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    let indexPath: IndexPath
    let isSelected: Bool
    let highlightState: NSCollectionViewItem.HighlightState
    
        
    
    var body: some View {
        @Bindable var prax = praxModel
        
        if document.pageSections.count > indexPath.section {
           let pdfPageSection = document.pageSections[indexPath.section]
            
            
            let imageSize = CGSize(width: 1200, height: 1600)
            
            GroupBox {
                GeometryReader { proxy in
                    HStack {
                        //          Spacer()
                        if let pdfPage = pdfPageSection.pdfPage {
                            Image(nsImage: pdfPage.thumbnail(of: imageSize, for: .cropBox))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: proxy.size.width * 0.28) // 40% of GroupBox width
                            //    .position(x: proxy.size.width * 0.15, y: proxy.size.height * 0.5)
                                .cornerRadius(6)
                                .padding(EdgeInsets(top: ThumbnailViewController.sectionHeaderHeight, leading: proxy.size.width * 0.01, bottom: 0, trailing: 0))
                            
                        }
                    }
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



#Preview {
    CollectionViewBackgroundView()


}
