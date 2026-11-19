
//
//  PreviewView.swift
//  PraxPress
//
//  Created by Elmer Cat on 9/27/26.
//

import SwiftUI
import SwiftData
import PDFKit

struct PreviewView: View {
    
    @Environment(PraxModel.self) private var prax
    @Environment(\.dismissWindow) private var dismissWindow
    
    @FocusState private var isViewFocused: Bool
    
    //   @Query() private var sourceFiles: [SourceFile]
    
    var body: some View {
        
        let _ = Self._printChanges()
        @Bindable var prax = prax
        
        if prax.selectedSourceFile != nil {
            VStack(spacing: 0) {
                
                GroupBox {
                    HStack {
                        Image(systemName: "x.circle")
                            .padding(.horizontal, 15).padding(.vertical, 5)
                            .font(.system(size: 20, weight: .medium))
                            .onTapGesture {prax.showFileViewer = false}
                        Text("\(prax.selectedSourceFile!.fileName)")
                        Spacer()
                    }.frame(maxWidth: .infinity, maxHeight: 40)
                }
                .focusable()
                .focused($isViewFocused)
                
                GroupBox {
                    HStack {
                        PraxButton(action: {
                            
                            /*prax.deleteSouurceFileFromDatabase(sourceFile);*/
                            
                            prax.showFileViewer = false }, symbol: "document.on.trash", help: "Remove from PraxPress Library")
                            .frame(maxWidth: 40)
                            .padding(.horizontal, 20).padding(.vertical, 5)
                        Text("\(prax.selectedSourceFile!.fileSize / 1000) KB")
                        if prax.selectedSourceFile!.pageCount > 1 {
                            Text("\(prax.selectedSourceFile!.pageCount) Pages") }
                        else { Text("One Page") }
                        Spacer()
                        HStack {
                            PraxButton(action: { prax.document.addPagesFromSourceFile(prax.selectedSourceFile!); prax.showFileViewer = false }, symbol: "inset.filled.trailinghalf.arrow.trailing.rectangle", label: "Trim / Merge", help: "Trim and Merge File Pages")
                                .frame(maxWidth: 150)
                                .padding(.horizontal, 20)
                        }.help("Trim and Merge File Pages")
                    }.padding(0)
                }
                
                PreviewPDFViewRepresentable(prax).padding(20).border(Color.blue.opacity(0.8), width: 2)
                
                GroupBox {
                    HStack {
                        Image(systemName: prax.selectedSourceFile!.fileGroup.name == FileGroup.locked.rawValue ? "lock" : "lock.open").font(.system(size: 20, weight: .medium))
                            .contentTransition(.symbolEffect(.replace))
                            .onTapGesture  {
                                let fileGroup: FileGroup
                                if prax.selectedSourceFile!.fileGroup.name == FileGroup.locked.rawValue {fileGroup = .imported}
                                else { fileGroup = .locked }
                                Task { do {
                                    print ("Moving \(prax.selectedSourceFile!.url.lastPathComponent) to \(fileGroup.rawValue)")
                                    
                                    try await prax.move(prax.selectedSourceFileID!, to: fileGroup)
                                    
                                } catch {}
                                    
                                }
                            }
                        
                            .padding(.leading, 30).padding(.vertical, 10).padding(.trailing, 10)
                        Divider().frame(height: 20)
                        
                        Image(systemName: "folder").font(.system(size: 20, weight: .medium))
                            .onTapGesture {
                                NSWorkspace.shared.selectFile(prax.selectedSourceFile!.url.path, inFileViewerRootedAtPath: "")
                            }
                        VStack {
                            HStack {
                                Text("size: \(String(prax.selectedSourceFile!.fileSize))  ")
                                Text("creationDate: \(prax.selectedSourceFile!.creationDate.formatted())  ")
                                Text("modificationDate: \(prax.selectedSourceFile!.modificationDate.formatted())  ")
                            }
                            
                            let _ = print("prax.selectedSourceFile.fileGroup.name: ",prax.selectedSourceFile!.fileGroup.name,  " - ", prax.selectedSourceFile!.url.formatted(Prax.filenameStyle) )
                            Text(prax.selectedSourceFile!.fileGroup.name)
                            Text("\(prax.selectedSourceFile!.url.formatted(Prax.filenameStyle).split(separator: ".").first ?? "")")
                            
                        }
                        Spacer()
                        
                    }.padding(0)
                }
            }
            
            
            
            
            .navigationTitle("Source File:  \(prax.selectedSourceFile!.fileName)")
            
            .gesture(WindowDragGesture())
            
            //    .frame(idealWidth: (prax.windowSize.height - 100) * 0.63, idealHeight: prax.windowSize.height - 100)
            .presentationSizing(.fitted)
            //     .interactiveDismissDisabled(true)
            .background(PraxGradient(4))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.blue, lineWidth: 5) // Adds rounded border
            )
            
            //     .border(Color.blue.opacity(0.8), width: 2)
            
            .onKeyPress(phases: .down) { keyPress in  switch keyPress.key {
            case .space: prax.showFileViewer = false; return .handled
            case .escape: prax.showFileViewer = false; return .handled
                
                default: print("PreviewView - keyPress.key: ", keyPress.key); return .ignored } }
            
            //         .onAppear() {  sourceFile.refreshTransientProperties() }
            //         .onChange(of: prax.selectedSourceFile) { sourceFile.refreshTransientProperties()  }
            
            .toolbar(content: {
                
                ToolbarItemGroup(placement: .status) {
                    
                    Button("🧪 Open Log") {
                        PraxLogger.shared.openLogFile()
                    }
                    
                    Button("🧪 Test Error") {
                        prax.praxTest()
                    }
                    
                    //       ReusableSegmentedControl(selection: $prax.praxPressMode, colorProvider: { $0.color })
                    
                    
                    
                }
            })
            .toolbarBackground(PraxGradient(), for: .windowToolbar)
            
     //       .onChange(of: prax.sourceFiles) {  }
            
            .onAppear() {
                print("Gloria")
                isViewFocused = true
                
            }
            
            .onChange(of: prax.selectedSourceFile?.fileGroup) {
                print("Lucille")
            }
            .onChange(of: prax.selectedSourceFile) {
                print("Carmen")
            }
            
            
        }
        
        
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
        prax.previewPDFView.delegate = context.coordinator
        return prax.previewPDFView
    }
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        
        print("PreviewPDFDocumentViewCoordinator - updateNSView - \(String(describing: prax.selectedSourceFile?.url.absoluteString))")
        
        guard context.coordinator.sourceFile != prax.selectedSourceFile  else { print("PreviewPDFDocumentViewCoordinator - updateNSView - no change"); return }
        context.coordinator.sourceFile = prax.selectedSourceFile
        
        var pdfDocument: PDFDocument
        
        if context.coordinator.sourceFile == nil {
            pdfDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)!
        }
        else {
            var isStale = false
            guard let url = try? URL(resolvingBookmarkData: context.coordinator.sourceFile!.bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
                    else { let praxError = PraxError.bookmarkResolutionFailed(underlyingError: nil); prax.presentError(praxError); return }
            
            let needsStop = url.startAccessingSecurityScopedResource()
            defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
            
            if let document = PDFDocument(url: url) { pdfDocument = document }
            else { pdfDocument = PDFDocument(url: Bundle.main.url(forResource: "PraxPress", withExtension: "pdf")!)!
                let praxError = PraxError.fileAccessDenied(filePath: url.absoluteString)
                prax.presentError(praxError) }
        }
        pdfView.document = pdfDocument
        
    }
    
}

final class PreviewPDFDocumentViewCoordinator: NSObject, PDFViewDelegate {
    let prax: PraxModel;  init(_ prax: PraxModel) { self.prax = prax }
    
    var documentVersion = UUID()
    
    var sourceFile: SourceFile? = nil
    
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

