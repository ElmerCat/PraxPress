//
//  MergedDocumentView.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/12/26.
//


import SwiftUI
import PDFKit
import UniformTypeIdentifiers
internal import Combine

// Minimal SwiftUI wrapper around PDFView
struct MergedDocumentView: View {
    
    @State private var prax = PraxModel.shared
    
    var body: some View {
        
        let _ = Self._printChanges()
        
        MergedPDFView()
        
            .onAppear() {
                print("Lessie Sheffield - MergedDocumentView .onAppear()  ")
            }
        
            .onChange(of: prax.mergedPDFAutoScales) {
                print("MergedDocumentView .onChange(of: prax.mergedPDFAutoScales)")        }
        
            .onChange(of: prax.mergedPDFDocument) {
                print("Lessie Sheffield - MergedDocumentView .onChange(of: prax.mergedPDFDocument) ")
                DispatchQueue.main.async {
                    print("DispatchQueue Lessie Sheffield - MergedDocumentView .onChange(of: prax.mergedPDFDocument)  ")
                    //        updateMergedDocument()
                }
            }
    }
}

struct MergedPDFView: NSViewRepresentable {
    
    @State private var prax = PraxModel.shared
    
    func makeNSView(context: Context) -> PDFView {
        print("MergedPDFView - makeNSView")
        let _ = Self._printChanges()
        
        let pdfView = PDFView()
        prax.mergedPDFView = pdfView
         
        return pdfView
    }
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        print("MergedPDFView - updateNSView")
//        let _ = Self._printChanges()
 
  //      if pdfView.displayMode != prax.mergedPDFDisplayMode {
   //         pdfView.displayMode = prax.mergedPDFDisplayMode
  //          print("MergedPDFView - pdfView.displayMode != prax.mergedPDFDisplayMode")
  //      }
        
        
        if pdfView.document != prax.mergedPDFDocument {
            print("MergedPDFView - pdfView.document != prax.mergedPDFDocument")
            pdfView.document = prax.mergedPDFDocument
            pdfView.layoutDocumentView()
       }
    }
    
}

/*
 
 final class Coordinator: NSObject {
 @State private var prax = PraxModel.shared
 
 @objc func fileSelectionChanged(_ note: Notification) {
 print("MergedDocumentView - fileSelectionChanged")
 
 }
 }
 func makeCoordinator() -> Coordinator {
 print("Lessie Sheffield - MergedDocumentView makeCoordinator")
 return Coordinator()
 }
 
 func makeNSView(context: Context) -> PDFView {
 print("Lessie Sheffield - MergedDocumentView makeNSView")
 let pdfView = PDFView()
 prax.mergedPDFView = pdfView
 pdfView.displaysPageBreaks = true
 pdfView.displayMode = .singlePageContinuous
 pdfView.autoScales = true
 pdfView.backgroundColor = .clear
 
 NotificationCenter.default.addObserver(
 context.coordinator,
 selector: #selector(Coordinator.fileSelectionChanged(_:)),
 name: .praxFileSelectionChanged,
 object: nil
 )
 let julieDPrax = prax.pdfDisplayMode
 return pdfView
 
 }
 
 func updateNSView(_ pdfView: PDFView, context: Context) {
 print("Lessie Sheffield - MergedDocumentView updateNSView")
 
 print("\nJulie d'Prax - Da Prax is wrong!\n")
 
 if !prax.selectedFiles.isEmpty {
 let needsReload = (pdfView.document == nil) || (pdfView.document?.documentURL != prax.mergedPDFURL)
 if needsReload {
 if let doc = PDFDocument(url: prax.mergedPDFURL) {
 pdfView.document = doc
 pdfView.layoutDocumentView()
 pdfView.autoScales = true
 } else {
 pdfView.document = nil
 }
 } else {
 pdfView.layoutDocumentView()
 }
 }
 }
 
 */
