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
    let prax: PraxModel
    
    init(prax: PraxModel) {
        self.prax = prax
        super.init(frame: .zero)
        configure()
    }
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        configure()
//    }
  
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    override func mouseEntered(with event: NSEvent) {
        print("EditingPDFDocumentNSView - mouseEntered")
        prax.hoverSection.insert(.editingDocument)

    }
    override func mouseExited(with event: NSEvent) {
        print("EditingPDFDocumentNSView - mouseExited")
        prax.hoverSection.remove(.editingDocument)
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
    
    let imageSize = CGSize(width: 1200, height: 1600)
    
    var body: some View {
        @Bindable var prax = praxModel
        @Bindable var document = self.document
        
        let _ = Self._printChanges()
        
   //     let pdfPage = prax.selectedMergedPage?.pdfPage
        
        GroupBox {
            GeometryReader { proxy in
                VStack {

                    EditingDocumentToolbar()
                        .frame(maxWidth: .infinity, maxHeight: 10.0)
                        .zIndex(258)
                    
                    GroupBox {
                      
                            
                            
                            EditingPDFViewRepresentable(
                                document: document,
                                onPDFViewReady: { pdfView in
                                    // Store a weak reference so buttons can use it
                                    pdfViewRef.view = pdfView
                                    
                                }
                            )

                            
                            
                        }
                        .opacity(document.refreshingMergedDocument ? 0.75 : 1)
                        .animation(.easeOut(duration: 0.25), value: document.refreshingMergedDocument)
                        .overlay(ProgressView().progressViewStyle(.circular).opacity(document.refreshingMergedDocument ? 1 : 0)).zIndex(4)
                    
                    
                    EditingDocumentFooter()
                    
                    
                    
                    
                }
                
                //  .position(x: 0, y: 16)
            }
        }
        
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(0)
     //   .background(PraxGradient())
      //  .overlay(
      //      RoundedRectangle(cornerRadius: 5)
      //          .stroke(Color.blue, lineWidth: 5).opacity(0.5)
      //  )
        
        
        
        //       .onDrop(of: [.fileURL], isTargeted: $prax.dropTargeted) { providers in
        //           PraxModel.shared.acceptDrop(providers)
        //       }
        //       .onDropSessionUpdated({ dropSession in
        //           print("CollectionViewBackgroundView - dropSessionUpdated phase: ", dropSession.phase)
        //        })
        
        
    }
    
    
    
    final class EditingPDFDocumentViewCoordinator: NSObject, PDFPageOverlayViewProvider {
        
        let document: MergedPDFDocument
     //  let overlayView: PDFPageOverlayView
        init(_ document: MergedPDFDocument) {
            self.document = document
            
            document.prax.editingDocumentPDFView.document = document.editingPDFDocument
            
            
       //    self.overlayView = PDFPageOverlayView()
            
            
            
            
        }
        
        var documentVersion = UUID()
      //  var pdfPageItem: PageItem?
        
        func pdfView(_ pdfView: PDFView, overlayViewFor pdfPage: PDFPage) -> NSView? {
            
            if let pageItem = document.pageItem(for: pdfPage) {
  //              print( "EditingPDFDocumentViewCoordinator - overlayViewFor pdfPage - ", pageItem.name)
                let overlayView = pageItem.overlayView
                overlayView.pdfView = pdfView
                overlayView.document = document
            //    let overlayControlView = OverlayControlNSView(frame: CGRect(x: -50, y: 0, width: 100, height: 100))
                
                pdfView.wantsLayer = true
                pdfView.layer?.masksToBounds = false
                
           //     overlayView.addSubview(overlayControlView)
                
                /*
                // Seed current rect from trims
                            DispatchQueue.main.async { [weak overlayView, weak pdfPage, weak pdfView] in
                                guard let view = overlayView, let pdfPage = pdfPage, let pdfView = pdfView else { return }
                                guard let pageItem = self.document.pdfPageItem(for: pdfPage) else { return }
                                
                                let crop = pdfPage.bounds(for: .cropBox)
                                let cropInView = pdfView.convert(crop, from: pdfPage)
                                let cropInOverlay = view.convert(cropInView, from: pdfView)
                          //      view.clampRect = cropInOverlay
                                // Recompute visible using current trims
                                //                 fatalError()
                                let trims = pageItem.trims
                                let visibleInPage = CGRect(
                                    x: crop.minX + trims.left,
                                    y: crop.minY + trims.bottom,
                                    width: crop.width - trims.left - trims.right,
                                    height: crop.height - trims.top - trims.bottom
                                )
                                
                                let visibleInView = pdfView.convert(visibleInPage, from: pdfPage)
                                let visibleInOverlay = view.convert(visibleInView, from: pdfView)
                                
                                view.currentRect = visibleInOverlay
                                
                                view.needsDisplay = true
                            }
                  */
                
                return overlayView
            }
            else {
 //               print( "EditingPDFDocumentViewCoordinator - overlayViewFor pdfPage - NO PAGE ITEM")
                return nil
            }
            
            
        }
        

    
    

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
//            print("EditingPDFDocumentViewCoordinator - viewScaleChanged: ")
         }
        
      @objc func pageChanged(_ note: Notification) {
            guard let pdfView = note.object as? PDFView,
                  let doc = pdfView.document,
                  let page = pdfView.currentPage else { return }
                    let pageIndex = doc.index(for: page)
         
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
             
            
          
            document.prax.editingDocumentPDFView.autoScales = true
            document.prax.editingDocumentPDFView.displayDirection = .vertical
            document.prax.editingDocumentPDFView.displaysPageBreaks = true
            document.prax.editingDocumentPDFView.pageBreakMargins = NSEdgeInsets(top: 30, left: 0, bottom: 0, right: 0)
            document.prax.editingDocumentPDFView.displayMode = .singlePageContinuous
            document.prax.editingDocumentPDFView.backgroundColor = .clear
                
           document.prax.editingDocumentPDFView.pageOverlayViewProvider = context.coordinator
         //   context.coordinator.overlayView.onFinish = context.coordinator.overlayViewOnFinish
            
      //      context.coordinator.overlayView.document = document
       //     context.coordinator.overlayView.pdfView = document.prax.editingDocumentPDFView
            
            addObservers(observer: context.coordinator)
            
    

            onPDFViewReady(document.prax.editingDocumentPDFView)
            return document.prax.editingDocumentPDFView
        }
        
        func addObservers( observer: EditingPDFDocumentViewCoordinator) {
            NotificationCenter.default.addObserver (observer,
                selector: #selector(EditingPDFDocumentViewCoordinator.documentChanged(_:)),
                name: Notification.Name.PDFViewDocumentChanged,
                object: observer.document.prax.editingDocumentPDFView
            )
            NotificationCenter.default.addObserver (observer,
                selector: #selector(EditingPDFDocumentViewCoordinator.annotationHit(_:)),
                name: Notification.Name.PDFViewAnnotationHit,
                object: observer.document.prax.editingDocumentPDFView
            )
            
            NotificationCenter.default.addObserver (observer,
                selector: #selector(EditingPDFDocumentViewCoordinator.displayBoxChanged(_:)),
                name: Notification.Name.PDFViewDisplayBoxChanged,
                object: observer.document.prax.editingDocumentPDFView
            )
            
            NotificationCenter.default.addObserver (observer,
                selector: #selector(EditingPDFDocumentViewCoordinator.viewScaleChanged(_:)),
                name: Notification.Name.PDFViewScaleChanged,
                object: observer.document.prax.editingDocumentPDFView
            )
            NotificationCenter.default.addObserver( observer,
                selector: #selector(EditingPDFDocumentViewCoordinator.pageChanged(_:)),
                name: Notification.Name.PDFViewPageChanged,
                object: observer.document.prax.editingDocumentPDFView
            )

            NotificationCenter.default.addObserver (observer,
                selector: #selector(EditingPDFDocumentViewCoordinator.visiblePageChanged(_:)),
                name: Notification.Name.PDFViewVisiblePagesChanged,
                object: observer.document.prax.editingDocumentPDFView
            )
            
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
                
                scalePDFViewToFit(pdfView: context.coordinator.document.prax.editingDocumentPDFView)
                
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
 //               print ("Bounds: ", bounds.width, " wide x ", bounds.height, " high - frame w: ", pdfView.frame.width, " - h:", pdfView.frame.height, " scale: ", pdfView.scaleFactor, " to: ", scaleFactor)
                pdfView.scaleFactor = scaleFactor
            }
            else {
                pdfView.autoScales = true
 //               print ("Bounds: ", bounds.width, " wide x ", bounds.height, " high - frame w: ", pdfView.frame.width, " - h:", pdfView.frame.height, " scale: ", pdfView.scaleFactor, " to: autoScales = true")
            }
        }
    }
}



#Preview {
    
   
//    EditingDocumentToolbar()
 //       MergedDocumentView()
//    MergedDocumentFooter()
   
}
