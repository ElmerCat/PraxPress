//
//  EditingDocumentToolbar.swift
//  PraxPress
//
//  Created by Elmer Cat on 4/9/26.
//

import SwiftUI
import PDFKit


struct EditingDocumentToolbar: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    let praxTheme = PraxTheme(.erika)
    
    @State private var hoveredButton: Int? = nil
    
   
    var body: some View {
        @Bindable var prax = praxModel
        
        //let pdfView: PDFView? = prax.editingDocumentPDFView
        
      //  let pdfDocument: PDFDocument? = prax.editingDocumentPDFView.document
      //  let pageCount: Int = pdfDocument?.pageCount ?? 0
      //  let pdfPage: PDFPage? = prax.editingDocumentPDFView.currentPage
        
   //     let pageIndex = pdfDocument?.index(for: pdfPage!) ?? 0
        
        
        
        

       
        
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
                
                HStack {
                   // Spacer(minLength: 5)
                    Text("Drag as...   ")
                //    Spacer(minLength: 5)
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
             //       Spacer(minLength: 5)
                    
                    Image(systemName: "arrow.right.doc.on.clipboard")
                //    Spacer(minLength: 5)
                    Text(".\(document.exportFilenameExtension)")
                   // Spacer(minLength: 15)
                    Button("Save As …", systemImage: "arrow.down.document") {
                        prax.showSavePanel.toggle()
                    }
                //    .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
              //      .padding(8)
                    .background(Color.black)
                    .draggable {
                        if let data = document.mergedPDFDocument.dataRepresentation() {
                            return MergedPDFTransfer(data: data, filename: (document.exportFilename))
                            
                        } else {
                            return nil
                        }
                    }
                    .padding(5)
                    .lineLimit(1)
                    .background {
                        Capsule()
                            .foregroundStyle(Color.blue.gradient)
                    }
                    
                }
                HStack {
                    
 
                        
                        
                    }
                .background(Color.cyan)
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
        
        let pdfDocument: PDFDocument? = prax.editingDocumentPDFView.document
        let pageCount: Int = pdfDocument?.pageCount ?? 0
        let pdfPage: PDFPage? = prax.editingDocumentPDFView.currentPage
        
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

        }
        .background(PraxGradient(1))

        
    }
}

#Preview {
    
   
    EditingDocumentToolbar()
 //       MergedDocumentView()
//    MergedDocumentFooter()
   
}
