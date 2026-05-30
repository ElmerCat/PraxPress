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

/*

class EditingPDFDocumentNSView: NSView, HostingViewContainer {
    let prax: PraxModel
    var hostingView: NSHostingView<EditingPDFDocumentView>?
    
    init(prax: PraxModel) {
        self.prax = prax
        super.init(frame: .zero)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    override func mouseEntered(with event: NSEvent) {
        prax.hoverSection.insert(.editingDocument)
    }
    
    override func mouseExited(with event: NSEvent) {
        prax.hoverSection.remove(.editingDocument)
    }
    
    func buildRootView() -> EditingPDFDocumentView {
        EditingPDFDocumentView()
    }
    
    func configure() {
        attachHostingView()
    }
    
    override func viewWillMove(toSuperview newSuperview: NSView?) {
        super.viewWillMove(toSuperview: newSuperview)
        if newSuperview == nil {
            detachHostingView()
        }
    }
}
*/

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
        
    //    let _ = Self._printChanges()
        let hovering = prax.hoverSection.contains(.editingDocument)
        
   //     let pdfPage = prax.currentEditingMergedPage?.pdfPage
        
        GroupBox {
            GeometryReader { proxy in
                VStack {
                    let toolbarHeight = prax.selectedPageItem != nil ? 100 : 20.0
                    EditingDocumentToolbar()
                        .frame(maxWidth: .infinity, minHeight: toolbarHeight, maxHeight: toolbarHeight, alignment: .center)
                        .animation(.snappy(duration: 0.25), value: toolbarHeight)
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
            }
        }
        
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(0)
        .background(PraxGradient(hovering ? 0 : 1)).animation(.easeInOut(duration: 1.5), value: praxModel.hoverSection)
        
        
        
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
        let prax: PraxModel
        init(_ document: MergedPDFDocument) {
            self.document = document
            self.prax = document.prax
            document.prax.editingDocumentPDFView.document = PDFDocument()
        }
        
        var documentVersion = UUID()
      //  var pdfPageItem: PageItem?
        
        func pdfView(_ pdfView: PDFView, overlayViewFor pdfPage: PDFPage) -> NSView? {
            
            if let pageItem = document.pageItem(for: pdfPage) {
  //              print( "EditingPDFDocumentViewCoordinator - overlayViewFor pdfPage - ", pageItem.name)
                let overlayView = pageItem.overlayView
                overlayView.pdfView = pdfView
         //       overlayView.document = document
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
            print("EditingPDFDocumentViewCoordinator - pageChanged ")
       //     guard let pdfView = note.object as? PDFView  else { fatalError("No PDFView") }
            
 /*           if let pdfPage = document.prax.currentEditingPDFPage {
                if !pdfView.visiblePages.contains(pdfPage) {
                    document.prax.currentEditingPDFPage = pdfView.currentPage
                }
            }
 */
            
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
            document.prax.editingDocumentPDFView.pageBreakMargins = NSEdgeInsets(top: 20, left: 10, bottom: 0, right: 10)
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
            pdfView.isHidden = document.mergedPages.isEmpty
            
            print("EditingPDFViewRepresentable - updateNSView - context.coordinator.documentVersion:  ", context.coordinator.documentVersion)
            
            if let pageItem = document.prax.selectedPageItem {
                if context.coordinator.documentVersion != pageItem.mergedPage.editingDocumentVersion {
                    context.coordinator.documentVersion = pageItem.mergedPage.editingDocumentVersion
                    pdfView.document = pageItem.mergedPage.editingPDFDocument
                    scalePDFViewToFit(pdfView: context.coordinator.document.prax.editingDocumentPDFView)
                    if !pdfView.visiblePages.contains(pageItem.pdfPage) {
                        pdfView.go(to: pageItem.pdfPage)
                    }
                }
                else {
                    print("EditingPDFViewRepresentable - updateNSView - No Change selectedPageItem: ", pageItem.name)
                }
                

            }
            else {
                print("EditingPDFViewRepresentable - updateNSView - No selectedPageItem ")
            }
            
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
