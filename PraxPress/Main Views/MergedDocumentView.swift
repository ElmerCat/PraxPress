//
//  MergedDocumentView.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/12/26.
//

import SwiftUI
import PDFKit



class MergedPDFDocumentNSView: NSView {
    let prax: PraxModel
    
    init(prax: PraxModel) {
        self.prax = prax
        super.init(frame: .zero)
        configure()
    }
    
//    override init(frame: CGRect) {
//       super.init(frame: frame)
//        configure()
//    }
 
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    
    override func mouseEntered(with event: NSEvent) {
 //       print("MergedPDFDocumentNSView - mouseEntered")
        prax.hoverSection.insert(.mergedDocument)

    }
    override func mouseExited(with event: NSEvent) {
 //       print("MergedPDFDocumentNSView - mouseExited")
        prax.hoverSection.remove(.mergedDocument)
    }

    private var hostingView: NSHostingView<MergedPDFDocumentView>?
    
    func configure() {
        
 //      registerForDraggedTypes([.fileURL])
//        self.wantsLayer = true
//        layer?.backgroundColor = NSColor.cyan.cgColor
//        layer?.borderColor = NSColor.black.cgColor
//        layer?.borderWidth = 1
//        layer?.cornerRadius = 12

        let root = MergedPDFDocumentView()
        
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

struct MergedPDFDocumentView: View {
    @Environment(MergedPDFDocument.self) var document
    @Environment(PraxModel.self) private var praxModel
    let praxTheme = PraxTheme(.erika)
    @State private var pdfViewRef = WeakPDFViewRef()
    @State private var hoveredButton: Int? = nil
    
    var body: some View {
        @Bindable var prax = praxModel
        
   //     let _ = Self._printChanges()
        
        GroupBox {
            GeometryReader { proxy in
                VStack {
                    
                 /*
                    HStack {

                        Text("PraxPress - ")
                            .font(Font.custom("BrushScriptMT", size: 30))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("\(document.documentVersion)")
                            .font(Font.custom("BrushScriptMT", size: 12))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                   

                    }
*/
                    

                    
                    GroupBox {
                        PDFViewRepresentable(
                            document: document,
                            onPDFViewReady: { pdfView in
                                // Store a weak reference so buttons can use it
                                pdfViewRef.view = pdfView
                                 
                            }
                        )
                        .opacity(document.refreshingMergedDocument ? 0.75 : 1)
                        .animation(.easeOut(duration: 0.25), value: document.refreshingMergedDocument)
                        .overlay(ProgressView().progressViewStyle(.circular).opacity(document.refreshingMergedDocument ? 1 : 0)).zIndex(4)
                    }
                    
                    HStack {

                        Button("", systemImage: "arrow.up.and.down.circle", action: {
                            if let pdfView =  pdfViewRef.view {
                                MergedPDFDocumentView.scalePDFViewToFit(pdfView: pdfView)
                                
                            }
                        })
                        .buttonStyle(SelectableButtonStyle(isSelected: false, isHovering: hoveredButton == 0, isFocused: false))
                        .onHover { hovering in
                            hoveredButton = hovering ? 0 : nil
                        }

                        
                        Button("", systemImage: "plus.circle", action: {
                            pdfViewRef.view?.zoomIn(self)
                        })
                        .buttonStyle(SelectableButtonStyle(isSelected: false, isHovering: hoveredButton == 1, isFocused: false))
                        .onHover { hovering in
                            hoveredButton = hovering ? 1 : nil
                        }
                        
                        

                        Button("", systemImage: "minus.circle", action: {
                            pdfViewRef.view?.zoomOut(self)
                        })                .buttonStyle(SelectableButtonStyle(isSelected: false, isHovering: hoveredButton == 2, isFocused: false))
                            .onHover { hovering in
                                hoveredButton = hovering ? 2 : nil
                            }

                        Button("", systemImage: "arrow.left.and.right.circle", action: {
                            pdfViewRef.view?.autoScales = true
                        })                .buttonStyle(SelectableButtonStyle(isSelected: false, isHovering: hoveredButton == 3, isFocused: false))
                            .onHover { hovering in
                                hoveredButton = hovering ? 3 : nil
                            }
                        

                    }
                    
                    
                }
                
                //  .position(x: 0, y: 16)
            }
        }
        
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(0)
        .background(PraxGradient(prax.hoverSection.contains(.mergedDocument) ? 0 : 1))

 //       .overlay(
 //
 //           RoundedRectangle(cornerRadius: 5)
 //               .stroke(Color.blue, lineWidth: 5).opacity(0.5)
 //       )
 //       .onDrop(of: [.fileURL], isTargeted: $prax.dropTargeted) { providers in
 //           PraxModel.shared.acceptDrop(providers)
 //       }
 //       .onDropSessionUpdated({ dropSession in
 //           print("CollectionViewBackgroundView - dropSessionUpdated phase: ", dropSession.phase)
//        })
        

    }
    
    final class MergedPDFDocumentViewCoordinator: NSObject {
        
        
        init(_ document: MergedPDFDocument) {
            self.document = document
            
         
        }
        
        let document: MergedPDFDocument
        
        
        var documentVersion = UUID()
        
        var pdfView: PDFView?
        
         
        @objc func pageChanged(_ note: Notification) {
            guard let pdfView = note.object as? PDFView,
                  let doc = pdfView.document,
                  let page = pdfView.currentPage else { return }
            let idx = doc.index(for: page)
            print("MergedPDFDocumentViewCoordinator - changed to page:", idx)
            //         if idx != NSNotFound, idx != prax.currentIndex { prax.currentIndex = idx }
        }
        
 
        
    }
    
    struct PDFViewRepresentable: NSViewRepresentable {
        let document: MergedPDFDocument
        let onPDFViewReady: (PDFView) -> Void
        

        func makeCoordinator() -> MergedPDFDocumentViewCoordinator {
    //        print("MergedPDFDocumentView - Erika daPrax - MergedPDFDocumentViewCoordinator makeCoordinator")
            return MergedPDFDocumentViewCoordinator(document)
        }
        
        
        func makeNSView(context: Context) -> PDFView {
      //      print("MergedPDFDocumentView - PDFViewRepresentable - makeNSView")
            document.prax.mergedDocumentPDFView.document = document.mergedPDFDocument
            document.prax.mergedDocumentPDFView.autoScales = true
            document.prax.mergedDocumentPDFView.displaysPageBreaks = true
            document.prax.mergedDocumentPDFView.pageBreakMargins = NSEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
            
            document.prax.mergedDocumentPDFView.displayDirection = .vertical
            document.prax.mergedDocumentPDFView.backgroundColor = .green
            context.coordinator.pdfView = document.prax.mergedDocumentPDFView
            onPDFViewReady(document.prax.mergedDocumentPDFView)
            return document.prax.mergedDocumentPDFView
        }
        
        func updateNSView(_ pdfView: PDFView, context: Context) {
            
            if context.coordinator.documentVersion != document.mergedDocumentVersion {
                var pageIndex: Int = 0
                if let pdfViewCurrentPage = pdfView.currentPage {
                    pageIndex = pdfView.document!.index(for: pdfViewCurrentPage)
                }
                
               // print("MergedPDFDocumentViewCoordinator - updateNSView - ", document.mergedDocumentVersion)
                context.coordinator.documentVersion = document.mergedDocumentVersion
                pdfView.document = document.mergedPDFDocument
                if let pdfPage = pdfView.document?.page(at: pageIndex) {
                    pdfView.go(to: pdfPage)
                }
                
                scalePDFViewToFit(pdfView: context.coordinator.pdfView!)
                
            }
            else {
       //         print("MergedPDFDocumentViewCoordinator - updateNSView - No Change ")
            }
        
    //
            
        }
        

    }
    
    static func scalePDFViewToFit(pdfView: PDFView) {
        if let pdfPage = pdfView.currentPage {
            let bounds = pdfPage.bounds(for: .mediaBox)
            let scaleFactor = pdfView.frame.height / bounds.height
            if pdfView.frame.width > bounds.width * scaleFactor {
   //             print ("Bounds: ", bounds.width, " wide x ", bounds.height, " high - frame w: ", pdfView.frame.width, " - h:", pdfView.frame.height, " scale: ", pdfView.scaleFactor, " to: ", scaleFactor)
                pdfView.scaleFactor = scaleFactor
            }
            else {
                pdfView.autoScales = true
 //               print ("Bounds: ", bounds.width, " wide x ", bounds.height, " high - frame w: ", pdfView.frame.width, " - h:", pdfView.frame.height, " scale: ", pdfView.scaleFactor, " to: autoScales = true")
            }
        }
    }
}



struct PDFPageItemInspector: View {
    @Environment(MergedPDFDocument.self) var document
    @Environment(PraxModel.self) private var praxModel
    
    var body: some View {
        @Bindable var prax = praxModel
        VStack {
            GroupBox {
                
                Text("Inspector 1")
                    .frame(minWidth: 100, maxWidth: 1000, maxHeight: .infinity)
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

/*
struct MergedDocumentHeader: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    
    var body: some View {
        @Bindable var prax = praxModel
        
        HStack {
            
            GroupBox {
                
                HStack {
                    Spacer(minLength: 5)
                    Text("Drag as...   ")
                    Spacer(minLength: 5)
                    Text(document.exportFilenamePrefix)
                    //    Spacer(minLength: 5)
                    TextField("Filename", text: Binding<String>(
                        get: { document.exportFilenameBody },
                        set: { newValue in
                            var newName = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            // Ensure we don't accidentally include a dot/extension typed by the user
                            if let dotRange = newName.range(of: ".") {
                                newName = String(newName[..<dotRange.lowerBound])}
                            document.exportFilenameBody = newName
                        })
                              
                    )
                    .frame(minWidth: 20, idealWidth: 100, alignment: .init(horizontal: .trailing, vertical: .center))
                    //.frame(maxWidth: 100, alignment: .init(horizontal: .trailing, vertical: .center))
                    .textFieldStyle(SquareBorderTextFieldStyle())
                    .disabled(document.exportFolderURL == nil)
                    .foregroundStyle(.cyan)
                    .backgroundStyle(.yellow)
                    
                    // Spacer(minLength: 5)
                    Text(document.exportFilenameSuffix)
                    Spacer(minLength: 5)
                    
                    Image(systemName: "arrow.right.doc.on.clipboard")
                    Spacer(minLength: 5)
                    Text(".\(document.exportFilenameExtension)")
                    Spacer(minLength: 15)
                    
                }
                .draggable {
                    if let data = document.mergedPDFDocument.dataRepresentation() {
                        return MergedPDFTransfer(data: data, filename: (document.exportFilename))
                        
                    } else {
                        return nil
                    }
                }
                
            }
            
            
            Spacer()
            
            Button("Save As …", systemImage: "arrow.down.document") {
                prax.showSavePanel.toggle()
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
        .padding(8)
        
    }
}


struct MergedDocumentFooter: View {
    enum PraxFocus: Hashable {
        case firstButton
        case secondButton
        case textField
        // add more if needed
    }
    @FocusState private var focusedField: PraxFocus?
    @Environment(MergedPDFDocument.self) var _document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    let praxTheme = PraxTheme(.erika)
    
    @State private var hoveredButton: Int? = nil
    
    var body: some View {
        @Bindable var prax = praxModel
        @Bindable var document = _document
        HStack {
            
            
           
            
            Button("", systemImage: "plus.circle", action: {
                document.autoScales = false
                document.mergedPDFView.zoomIn(self)
            })
            .buttonStyle(SelectableButtonStyle(isSelected: false, isHovering: hoveredButton == 1, isFocused: focusedField == .firstButton))
            .onHover { hovering in
                hoveredButton = hovering ? 1 : nil
            }
         //   .focusable(true)
        //    .focused($focusedField, equals: .firstButton)
       //     .keyboardShortcut(.space, modifiers: [])
            
            Button("", systemImage: "minus.circle", action: {
                document.autoScales = false
                document.mergedPDFView.zoomOut(self)
            })                .buttonStyle(SelectableButtonStyle(isSelected: false, isHovering: hoveredButton == 2, isFocused: focusedField == .secondButton))
                .onHover { hovering in
                    hoveredButton = hovering ? 2 : nil
                }
        //        .focusable(true)
        //        .focused($focusedField, equals: .secondButton)
       //         .keyboardShortcut(.space, modifiers: [])
            
            Toggle("", systemImage: document.autoScales ? "circle.inset.filled" : "equal.circle", isOn: $document.autoScales).toggleStyle(.button)
                .buttonStyle(SelectableButtonStyle(isSelected: document.autoScales, isHovering: hoveredButton == 3, isFocused: focusedField == .textField))
                .onHover { hovering in
                    hoveredButton = hovering ? 3 : nil
                }
       //         .focusable(true)
      //          .focused($focusedField, equals: .textField)
       //         .keyboardShortcut(.space, modifiers: [])
            
            
                     Picker("", selection: $document.mergedPDFView.displayMode, content: {
                         
                         Image(systemName: "inset.filled.center.rectangle.portrait").tag(PDFDisplayMode.singlePage)
                         Image(systemName: "rectangle.portrait.tophalf.inset.filled").tag(PDFDisplayMode.singlePageContinuous)
                       
                         if document.mergedPages.count > 1 {
                         
                             Image(systemName: "rectangle.portrait.split.2x1").tag(PDFDisplayMode.twoUp)
                             
                             Image(systemName: "inset.filled.topleft.rectangle.portrait").tag(PDFDisplayMode.twoUpContinuous)
                         }
                              
                     }).pickerStyle(.segmented)
          
                     if (document.mergedPDFView.displayMode == .twoUpContinuous || document.displayMode == .twoUp) {
                         Toggle("", systemImage: "book", isOn: $document.mergedPDFView.displaysAsBook).toggleStyle(.button)
                     }

                
             
                 Spacer()
                 
                 Text(String("Page \(prax.selectedSections.first) of \(document.mergedPages.count)"))
                     .font(.subheadline)
            Spacer(minLength: 10)
            
        }
        .background(Rectangle().foregroundColor(.black).opacity(0.50).cornerRadius(4))
        .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.bottom, 4)

    }
}


struct MergedDocumentToolbar: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel: PraxModel
    //    @State private var prax = PraxModel.shared
    
    private func title(for mode: PDFDisplayMode) -> String {
        switch mode {
        case .singlePage: return "Single"
        case .singlePageContinuous: return "Continuous"
        case .twoUp: return "Two Up"
        case .twoUpContinuous: return "Two Up Cont."
        @unknown default: return "Unknown"
        }
    }
    
    var body: some View {
        
        @Bindable var document = self.document
     //   @Bindable var prax = self.praxModel
        
        GroupBox {
            VStack {
                HStack {
                    
                    ZStack {
                        TextField("Prefix", text: $document.exportFilenamePrefix)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                            .overlay(alignment: .trailing) {
                                if !document.exportFilenamePrefix.isEmpty {
                                    Button {
                                        document.exportFilenamePrefix = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                            .padding(.trailing, 6) // adjust for your field style
                                    }
                                    .buttonStyle(.plain)
                                    .help("Clear")
                                }
                            }
                    }
                    
                    TextField("Filename", text: Binding<String>(
                        get: { document.exportFilenameBody },
                        set: { newValue in
                            var newName = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            // Ensure we don't accidentally include a dot/extension typed by the user
                            if let dotRange = newName.range(of: ".") {
                                newName = String(newName[..<dotRange.lowerBound])}
                            document.exportFilenameBody = newName
                        })
                              
                    )
                    //   .frame(minWidth: 10, idealWidth: 20, alignment: .init(horizontal: .trailing, vertical: .center))
                    //.frame(maxWidth: 100, alignment: .init(horizontal: .trailing, vertical: .center))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(document.exportFolderURL == nil)
                    
                    
                    AdvancedSettingsButton()
    /*                ControlGroup("", systemImage: "magnifyingglass") {
                        Button("Increase", systemImage: "plus.rectangle.portrait", action: document.zoomInMergedPDFView)
                        Button("Decrease", systemImage: "minus.rectangle.portrait", action: document.zoomOutMergedPDFView)
                        Button("", systemImage: "inset.filled.center.rectangle.portrait", action: {document.mergedPDFDisplayMode = .singlePage}).disabled(document.mergedPDFDisplayMode == .singlePage)
                        Button("", systemImage: "rectangle.portrait.tophalf.inset.filled", action: {document.mergedPDFDisplayMode = .singlePageContinuous}).disabled(document.mergedPDFDisplayMode == .singlePageContinuous)
                        if document.sections.count > 1 {
                            Button("", systemImage: "rectangle.portrait.split.2x1", action: {document.mergedPDFDisplayMode = .twoUp}).disabled(document.mergedPDFDisplayMode == .twoUp)
                            Button("", systemImage: "inset.filled.topleft.rectangle.portrait", action: {document.mergedPDFDisplayMode = .twoUpContinuous}).disabled(document.mergedPDFDisplayMode == .twoUpContinuous)
                        }
                        if (document.mergedPDFDisplayMode == .twoUpContinuous || document.mergedPDFDisplayMode == .twoUp) {
                            Toggle("", systemImage: "book", isOn: document.mergedPDFDisplaysAsBook).toggleStyle(.button)
                        }
                    }
 */                   Spacer()
                    
             /*       switch prax.selectedPageItems.count {
                    case 0: Text("No Selection")
                    case 1: Text("Page: \((document.selectedPageItems.first!.item) + 1) of \(document.mergedPDFDocument.pageCount ) ")
                    default: Text("Multiple Selection")
                    }
           */
                    Spacer()
                    
                    Text(String("\(document.mergedPages.count) Pages"))
                        .font(.subheadline)
           /*         if document.mergedWidthPts > 0, document.mergedHeightPts > 0 {
                        let wIn = document.mergedWidthPts / 72.0
                        let hIn = document.mergedHeightPts / 72.0
                        Text(String(format: "Merged size: %.0f × %.0f pts (%.2f × %.2f in)", document.mergedWidthPts, document.mergedHeightPts, wIn, hIn))
                            .font(.subheadline)
                        //    .foregroundStyle(Color.white)
                    } else {
                        Text("Merged size: —")
                            .font(.subheadline)
                        //  .foregroundStyle(.tertiary)
                    }
           */
                }
                .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
                .padding(8)
            }
        }
        //     .background(Color(red: 0.0, green: 0.0, blue: 0.8, opacity: 1.0))
        //     .foregroundStyle(Color.white)
    }
}



final class Coordinator: NSObject {
  //  @State private var prax = PraxModel.shared
    
    
    
    @objc func pageChanged(_ note: Notification) {
        guard let pdfView = note.object as? PDFView,
              let doc = pdfView.document,
              let page = pdfView.currentPage else { return }
        let idx = doc.index(for: page)
        print("MergedDocumentView Coordinator - changed to page:", idx)
        //         if idx != NSNotFound, idx != prax.currentIndex { prax.currentIndex = idx }
    }
    
}



struct praxMergedDocumentInspector: View {
    var body: some View {
        VStack {
            Text("Hello, World!")
                .padding()
                .navigationBarBackButtonHidden(false)
            
            //  MergedDocumentView()
        }
    }
    
}


struct MergedDocumentView: NSViewRepresentable {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    
    
    func makeCoordinator() -> Coordinator {
        print("Erika daPrax - MergedDocumentView makeCoordinator")
        return Coordinator()
    }
    
    
    func makeNSView(context: Context) -> PDFView {
        print("MergedDocumentView - makeNSView")
        
        document.mergedPDFView.document = document.mergedPDFDocument
        
        
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: Notification.Name.PDFViewPageChanged,
            object: document.mergedPDFView
        )
        document.mergedPDFView.backgroundColor = .mergedPDFViewBackground
        
        
        return document.mergedPDFView
    }
    
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        print("\n\nMergedDocumentView - updateNSView\n\n")
    }
    
   
    
}
*/

#Preview {
    
   
//    MergedDocumentHeader()
 //       MergedDocumentView()
//    MergedDocumentFooter()
   
}
