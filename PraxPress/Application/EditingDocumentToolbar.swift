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
    
    func mergedSizeText() -> String {
        if let mergedPage = praxModel.selectedMergedPage {
           
            let wIn = mergedPage.mergedWidthPts / 72.0
            let hIn = mergedPage.mergedHeightPts / 72.0
            var sizeText = "Merged Page Size: " + String(format: "%.1f\" × %.1f\"", wIn, hIn)

            if mergedPage.minWidthPts < mergedPage.mergedWidthPts {
                let mIn = mergedPage.minWidthPts / 72.0
                sizeText += "  -  Minimum Width: " + String(format: "%.1f\"", mIn)
            }
            return sizeText
            
        }
        else {
            return "No Pages"
        }
    }
    
    var body: some View {
        @Bindable var prax = praxModel
       
        HStack {
           
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
                    
                    Text(String("Page \(prax.editingDocumentCurrentPage + 1) of \(prax.editingDocumentPDFView.document?.pageCount ?? 0)"))
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
                
                Text(mergedSizeText())

                }
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
        
        let pdfView: PDFView? = prax.editingDocumentPDFView
        
   //     let pdfDocument: PDFDocument? = prax.editingDocumentPDFView.document
   //     let pageCount: Int = pdfDocument?.pageCount ?? 0
   //     let pdfPage: PDFPage? = prax.editingDocumentPDFView.currentPage
        
   //     let pageIndex = pdfDocument?.index(for: pdfPage!) ?? 0
        
        

        

       
        
        HStack {

            Button("", systemImage: "arrow.up.and.down.circle", action: {
                if let pdfView  {
                    EditingPDFDocumentView.scalePDFViewToFit(pdfView: pdfView)
                    
                }
            })
            .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 0, isFocused: false))
            .onHover { hovering in
                hoveredButton = hovering ? 0 : nil
            }

            Button("", systemImage: "minus.circle", action: {
                pdfView?.zoomOut(self)
            })                .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 2, isFocused: false))
                .onHover { hovering in
                    hoveredButton = hovering ? 2 : nil
                }

            Button("", systemImage: "plus.circle", action: {
                pdfView?.zoomIn(self)
            })
            .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 1, isFocused: false))
            .onHover { hovering in
                hoveredButton = hovering ? 1 : nil
            }

            Button("", systemImage: "arrow.left.and.right.circle", action: {
                pdfView?.autoScales = true
            })                .buttonStyle(SelectableButtonStyle(theme: praxTheme, isSelected: false, isHovering: hoveredButton == 3, isFocused: false))
                .onHover { hovering in
                    hoveredButton = hovering ? 3 : nil
                }
            
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
                    
                    Text(String("Page \(prax.editingDocumentCurrentPage + 1) of \(prax.editingDocumentPDFView.document?.pageCount ?? 0)"))
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
}

#Preview {
    
   
    EditingDocumentToolbar()
 //       MergedDocumentView()
//    MergedDocumentFooter()
   
}
