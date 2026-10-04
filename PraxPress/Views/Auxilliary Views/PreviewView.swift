
//
//  PreviewView.swift
//  PraxPress
//
//  Created by Elmer Cat on 9/27/26.
//

import SwiftUI
import PDFKit


struct PreviewView: View {
    
    @Environment(PraxModel.self) private var prax
    @Environment(\.dismiss) private var dismiss
     
    let filenameStyle = URL.FormatStyle(scheme: .never,
                                        user: .never,
                                        password: .never,
                                        host: .always,
                                        port: .never,
                                        path: .always,
                                        query: .never,
                                        fragment: .never)
    
    func deleteSouurceFileFromDatabase(_ sourceFile: SourceFile) {
        print("deleteSouurceFileFromDatabase()")
        Task {
            do {
                try await prax.document.persistence.deleteSourceFiles([sourceFile.id])
            } catch {
                // Handle or present the error appropriately
                print("Failed to delete files: \(error)")
            }
        }
        prax.selectedFiles.remove(sourceFile.id)
    }
    
    
    var body: some View {
        let _ = Self._printChanges()
        @Bindable var prax = prax
        if let sourceFile = prax.selectedSourceFile {
            VStack(spacing: 0) {
                
                
                GroupBox {
                    HStack {
                        Image(systemName: "x.circle")
                            .padding(.horizontal, 15).padding(.vertical, 5)
                            .font(.system(size: 20, weight: .medium))
                            .onTapGesture {dismiss()}
                        
                        Spacer()
                        Image(.pdfMenuIcon)
                        Text(sourceFile.url.lastPathComponent).font(.system(size: 20, weight: .medium))
                        Spacer()
                    }
                }.background(PraxGradient(3))
                
                GroupBox {
                    HStack {
                         
                        PraxButton(action: { deleteSouurceFileFromDatabase(sourceFile); dismiss() }, symbol: "document.on.trash", help: "Remove from PraxPress Library")
                            .frame(maxWidth: 40)
                            .padding(.horizontal, 20).padding(.vertical, 5)
                        Text("\(sourceFile.fileSize / 1000) KB")
                        if sourceFile.pageCount > 1 {
                            Text("\(sourceFile.pageCount) Pages") }
                        else { Text("One Page") }
                        
                        Spacer()
                        
                        HStack {
                            PraxButton(action: { prax.document.addPagesFromSourceFile(sourceFile); dismiss() }, symbol: "inset.filled.trailinghalf.arrow.trailing.rectangle", label: "Trim / Merge", help: "Trim and Merge File Pages")
                                .frame(maxWidth: 150)
                                .padding(.horizontal, 20)
                        }.help("Trim and Merge File Pages")
                        
                        

                    }.padding(0)
                }//.background(PraxGradient(2))
                
                PreviewPDFViewRepresentable(prax).padding(20).border(Color.blue.opacity(0.8), width: 2)
                
                GroupBox {
                    HStack {
                        Image(systemName: sourceFile.isLibraryFile ? "lock" : "lock.open").font(.system(size: 20, weight: .medium))
                            .onTapGesture {sourceFile.isLibraryFile.toggle() }
                            .padding(.leading, 30).padding(.vertical, 10).padding(.trailing, 10)
                        Divider().frame(height: 20)
                        
                        Image(systemName: "folder").font(.system(size: 20, weight: .medium))
                            .onTapGesture {
                                NSWorkspace.shared.selectFile(sourceFile.url.path, inFileViewerRootedAtPath: "")
                            }
                        
                        Text("\(sourceFile.url.deletingLastPathComponent().formatted(filenameStyle).split(separator: ".").first ?? "")")
                        Spacer()
                       
                    }.padding(0)
                }
            }
            .frame(idealWidth: (prax.windowSize.height - 100) * 0.63, idealHeight: prax.windowSize.height - 100)
            .presentationSizing(.fitted)
            .interactiveDismissDisabled(true)
            .background(PraxGradient(4))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.blue, lineWidth: 5) // Adds rounded border
            )
            
            //     .border(Color.blue.opacity(0.8), width: 2)
            
            .onKeyPress(phases: .down) { keyPress in  switch keyPress.key {
            case .space: dismiss(); return .handled
                default: print("PreviewView - keyPress.key: ", keyPress.key); return .ignored } }

            
        }
        
        
    }
    
    
    struct PreviewPDFViewRepresentable: NSViewRepresentable {
        init(_ prax: PraxModel) { self.prax = prax }
        let prax: PraxModel
        func makeCoordinator() -> PreviewPDFDocumentViewCoordinator { PreviewPDFDocumentViewCoordinator(prax) }
        
        func makeNSView(context: Context) -> PDFView {
            
            prax.previewPDFView.document = prax.previewPDFDocument
            prax.previewPDFView.autoScales = true
            prax.previewPDFView.displaysPageBreaks = true
            prax.previewPDFView.pageBreakMargins = NSEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
            prax.previewPDFView.displayDirection = .vertical
            prax.previewPDFView.backgroundColor = NSColor(Color.buttonDestructiveBackground)
            prax.mergedDocumentPDFView.delegate = context.coordinator
            return prax.previewPDFView
        }
        
        func updateNSView(_ pdfView: PDFView, context: Context) {
   //         print("PreviewPDFDocumentViewCoordinator - updateNSView", prax.previewPDFDocument)
            
            if context.coordinator.documentVersion != prax.previewDocumentVersion {
                context.coordinator.documentVersion = prax.previewDocumentVersion
                prax.previewPDFView.document = prax.previewPDFDocument
            }
        }
        
        
    }
    final class PreviewPDFDocumentViewCoordinator: NSObject, PDFViewDelegate {
        let prax: PraxModel
        init(_ prax: PraxModel) { self.prax = prax }
        var documentVersion = UUID()
        
        func pdfViewWillClick(onLink sender: PDFView, with url: URL) {print("PreviewPDFDocumentViewCoordinator - pdfViewWillClick: ", url) }
        
        @objc func pageChanged(_ note: Notification) {
            guard let pdfView = note.object as? PDFView,
                  let doc = pdfView.document,
                  let page = pdfView.currentPage else { return }
            let idx = doc.index(for: page)
            print("PreviewPDFDocumentViewCoordinator - changed to page:", idx)
            //         if idx != NSNotFound, idx != prax.currentIndex { prax.currentIndex = idx }
        }
    }
}

