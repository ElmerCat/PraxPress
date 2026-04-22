//
//  EditingDocumentToolbar.swift
//  PraxPress
//
//  Created by Elmer Cat on 4/9/26.
//

import SwiftUI
import PDFKit
import TipKit


struct EditingDocumentToolbar: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    let praxTheme = PraxTheme(.erika)
    
    @State private var hoveredButton: Int? = nil
    @State private var showFilenamePrefixPopover = false
//    @State private var guideXLeft = 0.0
//    @State private var guideXRight = 0.0
    
    func mergedSizeText() -> String {
        if let mergedPage = praxModel.selectedMergedPage {
           
            let wIn = mergedPage.mergedWidthPts / 72.0
            let hIn = mergedPage.mergedHeightPts / 72.0
            
            return String(format: "%.1f\" × %.1f\"", wIn, hIn)
            
   /*         var sizeText = "Merged Page Size: " + String(format: "%.1f\" × %.1f\"", wIn, hIn)

            if mergedPage.minWidthPts < mergedPage.mergedWidthPts {
                let mIn = mergedPage.minWidthPts / 72.0
                sizeText += "  -  Minimum Width: " + String(format: "%.1f\"", mIn)
            }
           return sizeText
    */
        }
        else {
            return "No Pages"
        }
    }
    
    var body: some View {
        @Bindable var prax = praxModel
        if prax.currentEditingPageIndex != NSNotFound,  prax.currentEditingPageItem != nil {
            GeometryReader { proxy in
                let thePoint = computeGuidelines()
                
                GroupBox {
                    VStack {
                        HStack {
                            
                            GroupBox {
                                HStack {
                                    Text("Skip This Page").font(.system(size: 8))
                                    Button { document.clickedSkipPageButton(prax.currentEditingPageItem!) }
                                    label: { if prax.currentEditingPageItem!.skipped {
                                        Image(systemName: "text.page.slash") } else {
                                            Image(systemName: "text.page") }
                                        
                                    }
                                    .buttonStyle(ItemButtonStyle(theme: praxTheme, isHovering: hoveredButton == 236))
                                    .onHover { hovering in hoveredButton = hovering ? 236 : nil }
                                    .help("Skip This Page")
                                    
                                    Spacer()
                                    
                                    Text("Set Width Guide").font(.system(size: 8))
                                    Button { document.clickedGuidePageButton(prax.currentEditingPageItem!) }
                                    label: { if prax.currentEditingPageItem!.skipped {
                                            Image(systemName: "ruler.fill")  }  else {
                                            Image(systemName: "ruler") }
                                    }
                                    .buttonStyle(ItemButtonStyle(theme: praxTheme, isHovering: hoveredButton == 235))
                                    .onHover { hovering in hoveredButton = hovering ? 235 : nil }
                                    .help("Set Width Guide")
                                    
                                    Spacer()
                                    
                                    Button("", systemImage: "arrowshape.left.circle", action: {
                                        prax.editingDocumentPDFView.goToPreviousPage(self)
                                    })
                                    .disabled(!prax.editingDocumentPDFView.canGoToPreviousPage)
                                    .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 11, isFocused: false))
                                    .onHover { hovering in
                                        hoveredButton = hovering ? 11 : nil
                                    }
                                    
                                    Text(String("Page \(prax.currentEditingPageIndex + 1) of \(prax.editingDocumentPDFView.document?.pageCount ?? 0)"))
                                        .background {
                                            Capsule()
                                                .foregroundStyle(Color.blue.gradient)
                                        }
                                    
                                    Button("", systemImage: "arrowshape.right.circle", action: {
                                        prax.editingDocumentPDFView.goToNextPage(self)
                                    })
                                    .disabled(!prax.editingDocumentPDFView.canGoToNextPage)
                                    .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 12, isFocused: false))
                                    .onHover { hovering in
                                        hoveredButton = hovering ? 12 : nil
                                    }
                                }
                            }
                            
                            GroupBox {
                                Text((prax.currentEditingPageItem?.name  ?? "No Current Page") + mergedSizeText() )
                                
                            }
                        }
                    //    Text("\(thePoint.x) x \(thePoint.y)")

                        HStack(spacing: 0) {
                            Rectangle()
                                .foregroundStyle(.green)
                                .frame(width: thePoint.x, height: 10)
                            Rectangle()
                                .foregroundStyle(PraxGradient())
                                .frame(maxWidth: .infinity, minHeight: 10, maxHeight: 10)
                            Rectangle()
                                .foregroundStyle(.yellow)
                                .frame(width: thePoint.y, height: 10)
                        }

                    }.padding(0)

                }
                .background(RoundedRectangle(cornerSize: CGSize(width: 5, height: 5), style: .continuous).fill(PraxGradient(3)))
              //  .background(.yellow)

            }
        }
        else {
            EmptyView()
        }
        
      
    }
    
    
    private func computeGuidelines() -> CGPoint {
        
        if let pageItem = praxModel.currentEditingPageItem {
            
      //     let widthGuidePage = document!.widthGuidePage()
       
            
            // Normalize guide x's by the guide page's crop box, then map to the current page's crop box
            var guideXLeft = pageItem.trims.left
            var guideXRight = pageItem.trims.right
            let guideLeftX = pageItem.trims.left
            let guideRightX = pageItem.trims.right
            
            let guideCrop = pageItem.pdfPage.bounds(for: .cropBox)
            let currentCrop = pageItem.pdfPage.bounds(for: .cropBox)
            guard guideCrop.width > 0, currentCrop.width > 0 else {
                return .zero
            }
            let leftNorm = (guideLeftX - guideCrop.minX) / guideCrop.width
            let rightNorm = (guideRightX - guideCrop.minX) / guideCrop.width
            let currentLeftX = currentCrop.minX + leftNorm * currentCrop.width
            let currentRightX = currentCrop.minX + rightNorm * currentCrop.width
            // Build tall thin rects at mapped x positions in current page space
            let leftRectInPage = CGRect(x: currentLeftX, y: currentCrop.minY, width: 0.5, height: currentCrop.height)
            let rightRectInPage = CGRect(x: currentRightX, y: currentCrop.minY, width: 0.5, height: currentCrop.height)
            // Convert to view space and then overlay space
            let leftInView = (praxModel.editingDocumentPDFView.convert(leftRectInPage, from: pageItem.pdfPage))
            let rightInView = (praxModel.editingDocumentPDFView.convert(rightRectInPage, from: pageItem.pdfPage))
            let leftInOverlay = pageItem.overlayView.convert(leftInView, from: praxModel.editingDocumentPDFView)
            let rightInOverlay = pageItem.overlayView.convert(rightInView, from: praxModel.editingDocumentPDFView)
            guideXLeft = leftInOverlay.midX
            guideXRight = rightInOverlay.midX
            
            // Skip drawing if lines would be far outside clamp; otherwise clamp to bounds
  /*        let gxL = guideXLeft
                if gxL.isNaN || gxL.isInfinite { guideXLeft = 0 }
                else if gxL < pageItem.overlayView.bounds.minX - 2000 || gxL > pageItem.overlayView.bounds.maxX + 2000 { guideXLeft = 0 }
                else { guideXLeft = max(pageItem.overlayView.bounds.minX, min(pageItem.overlayView.bounds.maxX, gxL)) }
   
         let gxR = guideXRight
                if gxR.isNaN || gxR.isInfinite { guideXRight = 0 }
                else if gxR < pageItem.overlayView.bounds.minX - 2000 || gxR > pageItem.overlayView.bounds.maxX + 2000 { guideXRight = 0 }
                else { guideXRight = max(pageItem.overlayView.bounds.minX, min(pageItem.overlayView.bounds.maxX, gxR)) }
   */
            
            let thePoint = CGPoint(x: guideXLeft, y: guideXRight)
            return thePoint

            
        } else {
            
            return .zero
            
        }
        
    }
 
}


struct EditingDocumentFooter: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    let praxTheme = PraxTheme(.erika)
    
    @State private var hoveredButton: Int? = nil
    
   
    var body: some View {
        @Bindable var prax = praxModel
        
        if prax.currentEditingPDFPage != nil, prax.currentEditingPageItem != nil, prax.currentEditingPageIndex != NSNotFound {
            
            let mergedSizeText = {
                let wIn = prax.currentEditingPageItem!.trimmedPageSize().width / 72.0
                let hIn = prax.currentEditingPageItem!.trimmedPageSize().height / 72.0
                return String(format: "%.1f\" × %.1f\"", wIn, hIn)
            }
            
            HStack {

                Button("", systemImage: "arrow.up.and.down.circle", action: {
                    EditingPDFDocumentView.scalePDFViewToFit(pdfView: prax.editingDocumentPDFView)
                })
                .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 0, isFocused: false))
                .onHover { hovering in
                    hoveredButton = hovering ? 0 : nil
                }

                Button("", systemImage: "minus.circle", action: {
                    prax.editingDocumentPDFView.zoomOut(self)
                })                .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 2, isFocused: false))
                    .onHover { hovering in
                        hoveredButton = hovering ? 2 : nil
                    }

                Button("", systemImage: "plus.circle", action: {
                    prax.editingDocumentPDFView.zoomIn(self)
                })
                .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 1, isFocused: false))
                .onHover { hovering in
                    hoveredButton = hovering ? 1 : nil
                }

                Button("", systemImage: "arrow.left.and.right.circle", action: {
                    prax.editingDocumentPDFView.autoScales = true
                })                .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 3, isFocused: false))
                    .onHover { hovering in
                        hoveredButton = hovering ? 3 : nil
                    }
                
                Spacer()
                Text((prax.currentEditingPageItem?.name  ?? "No Current Page") + mergedSizeText() )
                Spacer()
                GroupBox {
                    HStack {
                        Button("", systemImage: "arrowshape.left.circle", action: {
                            prax.editingDocumentPDFView.goToPreviousPage(self)
                        })
                        .disabled(!prax.editingDocumentPDFView.canGoToPreviousPage)
                        .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 11, isFocused: false))
                        .onHover { hovering in
                            hoveredButton = hovering ? 11 : nil
                        }
                        
                        Text(String("Page \(prax.currentEditingPageIndex + 1) of \(prax.editingDocumentPDFView.document?.pageCount ?? 0)"))
                            .background {
                                Capsule()
                                    .foregroundStyle(Color.blue.gradient)
                            }
                        
                        Button("", systemImage: "arrowshape.right.circle", action: {
                            prax.editingDocumentPDFView.goToNextPage(self)
                        })
                        .disabled(!prax.editingDocumentPDFView.canGoToNextPage)
                        .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 12, isFocused: false))
                        .onHover { hovering in
                            hoveredButton = hovering ? 12 : nil
                        }
                    }
              }
            }
            .background(PraxGradient(1))
        }
        else { EmptyView() }
    }
}

#Preview {
    
   
    EditingDocumentToolbar()
 //       MergedDocumentView()
//    MergedDocumentFooter()
   
}
