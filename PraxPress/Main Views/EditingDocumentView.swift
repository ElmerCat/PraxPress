//
//  EditingDocumentView.swift
//  PraxPress
//
//  Created by Elmer Cat on 4/9/26.
//


//
//  MergedDocumentView.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/12/26.
//

import SwiftUI
import PDFKit



class EditingPDFDocumentNSView: NSView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    private var hostingView: NSHostingView<EditingPDFDocumentView>?
    
    func configure() {
        
 //      registerForDraggedTypes([.fileURL])
//        self.wantsLayer = true
//        layer?.backgroundColor = NSColor.cyan.cgColor
//        layer?.borderColor = NSColor.black.cgColor
//        layer?.borderWidth = 1
//        layer?.cornerRadius = 12

        let root = EditingPDFDocumentView()
        
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

struct EditingPDFDocumentView: View {
    @Environment(MergedPDFDocument.self) var document
    @Environment(PraxModel.self) private var praxModel
    let praxTheme = PraxTheme(.erika)
    @State private var pdfViewRef = WeakPDFViewRef()
    @State private var hoveredButton: Int? = nil
    
    var body: some View {
        @Bindable var prax = praxModel
        
        let _ = Self._printChanges()
        
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
                    EditingDocumentToolbar()

                    
                    GroupBox {
                        EditingPDFViewRepresentable(
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
                                EditingPDFDocumentView.scalePDFViewToFit(pdfView: pdfView)
                                
                            }
                        })
                        .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 0, isFocused: false))
                        .onHover { hovering in
                            hoveredButton = hovering ? 0 : nil
                        }

                        
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
    
    final class EditingPDFDocumentViewCoordinator: NSObject {
        
        
        init(_ document: MergedPDFDocument) {
            self.document = document
            
         
        }
        
        let document: MergedPDFDocument
        
        
        var documentVersion = UUID()
        
        var pdfView: PDFView?
        
        
       @objc func documentChanged(_ note: Notification) {
           print("EditingPDFDocumentViewCoordinator - documentChanged")
       }
        
        @objc func annotationHit(_ note: Notification) {
            print("EditingPDFDocumentViewCoordinator - annotationHit: ")
         }
        
        @objc func displayBoxChanged(_ note: Notification) {
            print("EditingPDFDocumentViewCoordinator - displayBoxChanged: ")
         }
        
        @objc func visiblePageChanged(_ note: Notification) {
            print("EditingPDFDocumentViewCoordinator - visiblePageChanged: ")
         }
        
    @objc func viewScaleChanged(_ note: Notification) {
            print("EditingPDFDocumentViewCoordinator - viewScaleChanged: ")
         }
        
      @objc func pageChanged(_ note: Notification) {
            guard let pdfView = note.object as? PDFView,
                  let doc = pdfView.document,
                  let page = pdfView.currentPage else { return }
            document.prax.editingDocumentCurrentPage = doc.index(for: page)
            print("EditingPDFDocumentViewCoordinator - changed to page:", document.prax.editingDocumentCurrentPage)
            //         if idx != NSNotFound, idx != prax.currentIndex { prax.currentIndex = idx }
        }
        
 
        
    }
    
    struct EditingPDFViewRepresentable: NSViewRepresentable {
        let document: MergedPDFDocument
        let onPDFViewReady: (PDFView) -> Void
        

        func makeCoordinator() -> EditingPDFDocumentViewCoordinator {
            print("EditingPDFViewRepresentable - Erika daPrax - EditingPDFDocumentViewCoordinator makeCoordinator")
            return EditingPDFDocumentViewCoordinator(document)
        }
        
        
        func makeNSView(context: Context) -> PDFView {
            print("EditingPDFViewRepresentable - makeNSView")
            let pdfView = PDFView()
            document.prax.editingDocumentPDFView = pdfView
            pdfView.document = document.editingPDFDocument
            pdfView.autoScales = true
            pdfView.displayDirection = .vertical
            pdfView.displayMode = .singlePageContinuous
            pdfView.backgroundColor = .yellow
            context.coordinator.pdfView = pdfView
            
            NotificationCenter.default.addObserver(
                context.coordinator,
                selector: #selector(EditingPDFDocumentViewCoordinator.documentChanged(_:)),
                name: Notification.Name.PDFViewDocumentChanged,
                object: context.coordinator.pdfView
            )
            NotificationCenter.default.addObserver(
                context.coordinator,
                selector: #selector(EditingPDFDocumentViewCoordinator.annotationHit(_:)),
                name: Notification.Name.PDFViewAnnotationHit,
                object: context.coordinator.pdfView
            )
            
            NotificationCenter.default.addObserver(
                context.coordinator,
                selector: #selector(EditingPDFDocumentViewCoordinator.displayBoxChanged(_:)),
                name: Notification.Name.PDFViewDisplayBoxChanged,
                object: context.coordinator.pdfView
            )
            
            NotificationCenter.default.addObserver(
                context.coordinator,
                selector: #selector(EditingPDFDocumentViewCoordinator.viewScaleChanged(_:)),
                name: Notification.Name.PDFViewScaleChanged,
                object: context.coordinator.pdfView
            )
            NotificationCenter.default.addObserver(
                context.coordinator,
                selector: #selector(EditingPDFDocumentViewCoordinator.pageChanged(_:)),
                name: Notification.Name.PDFViewPageChanged,
                object: context.coordinator.pdfView
            )

            NotificationCenter.default.addObserver(
                context.coordinator,
                selector: #selector(EditingPDFDocumentViewCoordinator.visiblePageChanged(_:)),
                name: Notification.Name.PDFViewVisiblePagesChanged,
                object: context.coordinator.pdfView
            )

            onPDFViewReady(pdfView)
            return pdfView
        }
        
        func updateNSView(_ pdfView: PDFView, context: Context) {
            
            if context.coordinator.documentVersion != document.editingDocumentVersion {
                var pageIndex: Int = 0
                if let pdfViewCurrentPage = pdfView.currentPage {
                    pageIndex = pdfView.document!.index(for: pdfViewCurrentPage)
                }
                
                print("EditingPDFViewRepresentable - updateNSView - ", context.coordinator.documentVersion, " - to ", document.editingDocumentVersion)
                context.coordinator.documentVersion = document.editingDocumentVersion
                pdfView.document = document.editingPDFDocument
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
                print ("Bounds: ", bounds.width, " wide x ", bounds.height, " high - frame w: ", pdfView.frame.width, " - h:", pdfView.frame.height, " scale: ", pdfView.scaleFactor, " to: ", scaleFactor)
                pdfView.scaleFactor = scaleFactor
            }
            else {
                pdfView.autoScales = true
                print ("Bounds: ", bounds.width, " wide x ", bounds.height, " high - frame w: ", pdfView.frame.width, " - h:", pdfView.frame.height, " scale: ", pdfView.scaleFactor, " to: autoScales = true")
            }
        }
    }
}



#Preview {
    
   
//    EditingDocumentToolbar()
 //       MergedDocumentView()
//    MergedDocumentFooter()
   
}
