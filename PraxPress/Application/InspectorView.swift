//
//  InspectorView.swift
//  PraxPress
//
//  Created by Elmer Cat on 10/18/26.
//


import SwiftUI
import SwiftData
import PDFKit

struct InspectorView: View {
    
    @Environment(PraxModel.self) private var prax
    @Environment(\.dismiss) private var dismiss
    
    
    //   @State private var fileSize: Int64 = 0
    //    @State private var creationDate: Date = .distantPast
    //    @State private var modificationDate: Date = .distantPast
    
    var body: some View {
        let _ = Self._printChanges()
        @Bindable var prax = prax
        
        //    VSplitView {
                
                
       //         MergedPDFDocumentView()
                
/*                VStack {
                    HStack {
                        if let sourceFile = prax.selectedSourceFile {
                            
                            PraxButton(action: { prax.deleteSouurceFileFromDatabase(sourceFile); dismiss() }, symbol: "document.on.trash", help: "Remove from PraxPress Library")
                                .frame(maxWidth: 40)
                                .padding(.horizontal, 20).padding(.vertical, 5)
                            Spacer()
                            Text("\(sourceFile.fileName)")
                            Text("\(sourceFile.fileSize / 1000) KB")
                            if sourceFile.pageCount > 1 {
                                Text("\(sourceFile.pageCount) Pages") }
                            else { Text("One Page") }
                            
                            Spacer()
                            
                            HStack {
                                PraxButton(action: { prax.document.addPagesFromSourceFile(sourceFile) }, symbol: "inset.filled.trailinghalf.arrow.trailing.rectangle", label: "Trim / Merge", help: "Trim and Merge File Pages")
                                    .frame(maxWidth: 150)
                                    .padding(.horizontal, 20)
                            }.help("Trim and Merge File Pages")
                        }
                    }.padding(0)
                }
 */
                MergedFilesView()
                
                
                
                
                
/*
                HStack {
                    if let sourceFile = prax.selectedSourceFile {
                        Image(systemName: sourceFile.fileGroup.name == FileGroup.locked.rawValue ? "lock" : "lock.open").font(.system(size: 20, weight: .medium))
                            .contentTransition(.symbolEffect(.replace))
                            .onTapGesture  {
                                let fileGroup: FileGroup
                                let _ = print(sourceFile.fileGroup.name)
                                if sourceFile.fileGroup.name == FileGroup.locked.rawValue {fileGroup = .imported
                                }
                                else { fileGroup = .locked }
                                Task { do {
                                    print ("Moving \(sourceFile.url.lastPathComponent) to \(fileGroup.rawValue)")
                                    try await prax.persistence?.move(sourceFile, to: fileGroup)  }
                                    catch {
                                        let message = "Error moving SourceFile to \(fileGroup.rawValue) -  \(error.localizedDescription)"
                                        PraxLogger.shared.logError(message, category: .import)
                                        let error = PraxError.generic(title: "Move Error", message: message)
                                        prax.presentError(error)
                                    }
                                }
                            }
                        
                            .padding(.leading, 30).padding(.vertical, 10).padding(.trailing, 10)
                        Divider().frame(height: 20)
                        
                        Image(systemName: "folder").font(.system(size: 20, weight: .medium))
                            .onTapGesture {
                                NSWorkspace.shared.selectFile(sourceFile.url.path, inFileViewerRootedAtPath: "")
                            }
                        VStack {
                            HStack {
                                Text("size: \(String(sourceFile.fileSize))  ")
                                Text("creationDate: \(sourceFile.creationDate.formatted())  ")
                                Text("modificationDate: \(sourceFile.modificationDate.formatted())  ")
                            }
                            Text(sourceFile.fileGroup.name)
                            Text("\(sourceFile.url.formatted(Prax.filenameStyle).split(separator: ".").first ?? "")")
                            
                        }
                        Spacer()
                    }
                }.padding(0)
*/
     //           PreviewPDFViewRepresentable(prax).padding(20).border(Color.blue.opacity(0.8), width: 2)
         //   }
        
   //         .background(PraxGradient(1))
       //     .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.blue, lineWidth: 5))
            
            
            .toolbar(content: {
                ToolbarItemGroup(placement: .automatic) {
                    
                    Button(role: .confirm, action: { prax.showInspector.toggle() }, label: {
                        Image(systemName: "tray.full").resizable().aspectRatio(contentMode: .fit)
                            .rotationEffect(Angle(degrees: prax.showInspector ? 180 : 0))
                    })
                    .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 1044))
                    .onHover { hovering in prax.hoveredButton = hovering ? 1044 : nil }
                    .padding(.horizontal, 20)
                    
                }.visibilityPriority(.high)
            })

        
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
            prax.previewPDFView.delegate = context.coordinator
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

