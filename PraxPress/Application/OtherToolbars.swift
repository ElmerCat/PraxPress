//
//  OtherToolbars.swift
//  PraxPress
//
//  Created by Elmer Cat on 4/9/26.
//

import SwiftUI
import PDFKit
import TipKit
import UniformTypeIdentifiers

struct ExportFilenameView: View {
    @Environment(PraxModel.self) private var prax
    @Environment(\.dismiss) private var dismiss
    @State private var hovering: Bool = false
    @State private var presentAlert = false
    
    @State private var imageAngle = 0.0
    
    private func clickedSaveButton() {
        if let pageItem = prax.selectedPageItem {
            if pageItem.isLibraryFile { presentAlert = true }
            else {
                print("Saving Library File")
                save()} }
   }
    
    private func save() {
        if let pageItem = prax.selectedPageItem {
            var isStale = false
            guard let url = try? URL(resolvingBookmarkData: pageItem.sourceBookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            else { let praxError = PraxError.bookmarkResolutionFailed(underlyingError: nil); prax.presentError(praxError); return }
            if url == prax.document.exportFileURL {
                let needsStop = url.startAccessingSecurityScopedResource(); defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
                if !prax.document.mergedPDFDocument.write(to: url) {
                    let praxError = PraxError.saveFailed(reason: "Failed to save:  \(url.deletingPathExtension())", underlyingError: nil); prax.presentError(praxError) } }
            else {prax.showFileExporter = true} }
    }
    
    
    var body: some View {
        @Bindable var prax = prax
        HStack{
            
            Image("PraxPress").resizable().aspectRatio(contentMode: .fit).frame(width: 30)
                .rotationEffect(Angle(degrees: hovering ? 540 : 0))
                .padding(.horizontal, 10)
           //     .opacity(hovering ? 0.85 : 0.1)
            
            
            Text("Drag").font(.system(size: 20, weight: .ultraLight).italic()).opacity(hovering ? 0.85 : 0.1)
            
            Spacer()
            
            Image("PDFFileIcon").resizable().aspectRatio(contentMode: .fill).frame(width: 30)
            Text("\(prax.document.exportFilename).pdf").padding(.trailing, 20)
            
            Spacer()
    
            if prax.document.dataFieldPage != nil {
                PraxButton(action: {prax.burnInAnnotations.toggle()}, symbol: "burn", help: "Burn in annotations", isOn: prax.burnInAnnotations, theme: .burn)}
            
            PraxButton(action: {self.clickedSaveButton()}, symbol: "square.and.arrow.down.fill", help: "Save")
                .padding(.horizontal, 10)
            Spacer()
          
        }
        .disabled(!prax.document.readyToExport)
        .font(.system(size: 20, weight: .medium))
        .foregroundStyle(prax.document.readyToExport ? .white : .green)
        .border(Color.gray, width: hovering ? 1 : 0)
        //   .frame(maxWidth: 500)
        //.padding(hovering ? 4 : 0)
        .background(prax.document.readyToExport ? .blue.opacity(0.7) : .blue.opacity(0.1), in: RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
        .onHover { hovering in withAnimation {self.hovering = hovering}}
        .environment(\.groupHovering, hovering)
        
        .draggable({ () -> MergedPDFTransfer? in
            guard let data = prax.document.mergedPDFDocument.dataRepresentation(options: [PDFDocumentWriteOption.burnInAnnotationsOption: prax.burnInAnnotations]) else { return nil }
            return MergedPDFTransfer(data: data, filename: prax.document.exportFilename) }()!, preview: { PraxDragPreview()})
        
        .alert(isPresented: $presentAlert) {
            Alert(
                title: Text("Replace Library File?"),
                message: Text("This is a Library file. Are you sure you wish to change it?"),
                primaryButton: .destructive(Text("Replace")) {
                save()
                },
                secondaryButton: .cancel() {
                    dismiss()
                }
            )
        }

    }
}


struct ContentHeader: View {
    @Environment(PraxModel.self) private var prax

    @State private var showingOptions: Bool = false
    var body: some View {
        @Bindable var prax = prax
        VStack {
            HStack {
                GroupBox {
                    
                    HStack {
                        
                        Button(role: .destructive, action: { prax.document.mergedPages.removeAll() }, label: {
                            HStack {
                                if !prax.document.mergedPages.isEmpty && prax.hoveredButton == 40 { Text("Clear Merged Document") }
                                Image(systemName: prax.document.mergedPages.isEmpty ? "rectangle.dashed" : "rectangle.stack.slash") }
                            .padding(.horizontal, 5)})
                        .disabled(prax.document.mergedPages.isEmpty)
                        .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 40, hoverWidth: 200))
                        .onHover { hovering in prax.hoveredButton = hovering ? 40 : nil }
                        
                        Spacer()
                            ExportFilenameView()
                            .frame(minWidth: 200, maxWidth: 400)
                        
                        Spacer()
                        Button(role: .confirm, action: { showingOptions.toggle() }, label: {
                            HStack {
                                if !prax.document.mergedPages.isEmpty && prax.hoveredButton == 41 { Text("Options") }
                                Image(systemName: prax.document.mergedPages.isEmpty ? "gear" : "gear.circle") }})
                        //   .disabled(prax.document.mergedPages.isEmpty)
                        .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 41))
                        .onHover { hovering in prax.hoveredButton = hovering ? 41 : nil }
                        
                        .padding(.trailing, 20)
                        
                       
                    }
                    
                }
                .popover(isPresented: $showingOptions, content: {
                    VStack {
                        Text("Julie d'Prax")
                        
                        Button {
                            withAnimation {
                                prax.columnVisibility = prax.columnVisibility == .detailOnly ? .all : .detailOnly
                            }
                            //   NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
                            
                        } label: {
                            Label("Sidebar", systemImage: "sidebar.left")
                        }
                        
                        
                        Button("🧪 Open Log") {
                            PraxLogger.shared.openLogFile()
                        }
                        
                        Button("🧪 Test Error") {
                            prax.praxTest()
                        }
                        
                        ReusableSegmentedControl(selection: $prax.praxPressMode, colorProvider: { $0.color })
                        
                        
                        Button {
                            prax.showMergedDocumentInspector.toggle()
                        } label: {
                            Label((prax.showMergedDocumentInspector ? "Hide Merged" : "Show Merged"), systemImage: (prax.showMergedDocumentInspector ? "minus.magnifyingglass" : "plus.magnifyingglass"))
                        }
                        Button {
                            prax.showPDFPageItemInspector.toggle()
                        } label: {
                            Label((prax.showPDFPageItemInspector ? "Hide PDFPageItemInspector" : "Show PDFPageItemInspector"), systemImage: (prax.showPDFPageItemInspector ? "minus.magnifyingglass" : "plus.magnifyingglass"))
                        }
                        Button {
                            prax.isLarge.toggle()
                            Task {
                                do {
                                    await prax.persistence?.praxTest()
                                }
                            }
                            
                            
                        } label: {
                            Label((prax.isLarge ? "Status Small" : "Status Large"), systemImage: (prax.isLarge ? "minus.magnifyingglass" : "plus.magnifyingglass"))
                        }
                        
                    }
                    
                    
                    
                })
                
            }
            .frame(maxHeight: 40)
        

        }
        .frame(maxWidth: .infinity)
        

    }
}








struct ContentFooter: View {
    @Environment(PraxModel.self) private var prax
    
    
    var body: some View {
        @Bindable var prax = prax
        HStack {
            Text(String(format: "Merged size:  %u KB", prax.document.mergedDocumentSizeKB))
            GroupBox {
                switch (prax.selectedFiles.count) {
                case 0:
                    Text("No files selected")
                case 1:
                    Text("Source file: \(prax.document.exportFilenameBody)")
                default:
                    Text("\(prax.selectedFiles.count) Source files selected")
                }}
            
            Text("\(prax.editingDocumentPDFView.document?.pageCount ?? 0) Pages").font(.system(size: 8))
            
            Button { prax.editingDocumentPDFView.goToPreviousPage(self) }
            label: { Image(systemName: "arrowtriangle.up")  }
                .disabled(!prax.editingDocumentPDFView.canGoToPreviousPage)
                .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 11, isFocused: false))
                .onHover { hovering in prax.hoveredButton = hovering ? 11 : nil }
            
            Button { prax.editingDocumentPDFView.goToNextPage(self) }
            label: {  Image(systemName: "arrowtriangle.down")}
                .disabled(!prax.editingDocumentPDFView.canGoToNextPage)
                .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 12, isFocused: false))
                .onHover { hovering in  prax.hoveredButton = hovering ? 12 : nil }
            
            Spacer()
            
        /*
            Slider(value: Binding<CGFloat>(
                get: { prax.editingDocumentPDFView.scaleFactor },
                set: { newValue in
                    prax.editingDocumentPDFView.scaleFactor = newValue; print(newValue)
                }), in: 0.15...2.5,)
            .frame(width: 100)
            .padding(.horizontal, 5)
            
       //     Button { scalePDFViewToFit(prax.editingDocumentPDFView, .vertical) }
            
            
            Button("", systemImage: "arrow.up.and.down.circle", action: {
        //        EditingDocumentView.scalePDFViewToFit(pdfView: prax.editingDocumentPDFView)
            })
            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 0))
            .onHover { hovering in
                prax.hoveredButton = hovering ? 0 : nil
            }
            
            Button("", systemImage: "plus.circle", action: {
                prax.editingDocumentPDFView.zoomIn(self)
            })
            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 1))
            .onHover { hovering in
                prax.hoveredButton = hovering ? 1 : nil
            }
            
            Button("", systemImage: "minus.circle", action: {
                prax.editingDocumentPDFView.zoomOut(self)
            })                .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 2))
                .onHover { hovering in
                    prax.hoveredButton = hovering ? 2 : nil
                }
            
            Button("", systemImage: "arrow.left.and.right.circle", action: {
                prax.editingDocumentPDFView.autoScales = true
            })                .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 3))
                .onHover { hovering in
                    prax.hoveredButton = hovering ? 3 : nil
                }
            
            
            
            Spacer()
            
            
        
            
            Button("", systemImage: "arrow.up.and.down.circle", action: {
                MergedPDFDocumentView.scalePDFViewToFit(pdfView: prax.mergedDocumentPDFView)})
            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 10))
            .onHover { hovering in prax.hoveredButton = hovering ? 10 : nil }
            
            Button("", systemImage: "plus.circle", action: {
                prax.mergedDocumentPDFView.zoomIn(self) })
            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 11))
            .onHover { hovering in prax.hoveredButton = hovering ? 11 : nil }
            
            Button("", systemImage: "minus.circle", action: {
                prax.mergedDocumentPDFView.zoomOut(self) })
            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 12))
            .onHover { hovering in prax.hoveredButton = hovering ? 12 : nil }
            
            Button("", systemImage: "arrow.left.and.right.circle", action: {
                prax.mergedDocumentPDFView.autoScales = true })
            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 13))
            .onHover { hovering in prax.hoveredButton = hovering ? 13 : nil }
            
         */
            
        }
        .frame(maxWidth: .infinity, maxHeight: 40, alignment: .leading)
        .padding(8)
    }
}

struct MergedPagesFooter: View {
    @Environment(PraxModel.self) private var prax
    
    
    var body: some View {
        @Bindable var prax = prax
        GroupBox {
            
            HStack {
                Text("\(prax.selectedPages.count)  of \(prax.allItemIDs.count)  Pages Selected")
                    .font(.subheadline)
        //        Slider(value: $prax.pageItemHeight, in: 100...300, step: 10)
        //            .padding(.horizontal, 5)
            }
            
        }
        .dropDestination(
            for: SourceFileTransfer.self,
            action: {
                items, location in
                for item in items {
                    prax.document.addPagesFromSourceFilePayload(item.payload, at: IndexPath(item: -1, section: 0), toMergedPage: nil)
                    
                }
                return true},
            isTargeted: { targeted in prax.dropTargeted = targeted })
    }
}




#Preview {
    @Previewable @State var prax = PraxModel(nil)
    VStack {
        ContentHeader()
        ExportFilenameView()
        MergedDocumentToolbarView()
        EditingToolbarView()
        
    }
    .environment(prax)
    .frame(width: 1500)

}

#Preview {
    @Previewable @State var prax = PraxModel(nil)
    
    ContentHeader()
        .environment(prax)
        .frame(width: 1500)
}

#Preview {
    @Previewable @State var prax = PraxModel(nil)
    
    ContentView()
        .environment(prax)
        .frame(width: 1500, height: 800)
}

