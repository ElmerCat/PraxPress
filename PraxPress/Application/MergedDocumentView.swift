//
//  MergedDocumentView.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/12/26.
//

import SwiftUI
import PDFKit




struct MergedPDFDocumentView: View {
    @Environment(PraxModel.self) private var prax
    @State private var hovering: Bool = false
    @State private var presentAlert = false

    var body: some View {
        @Bindable var prax = prax
        VStack {
            
            Text("Merged PDF Document").padding(.top, 5)
            Divider()
            HStack {
                
                
                ExportFilenameView()
                    .frame(minWidth: 200, maxWidth: 600, maxHeight: 40)
                    .padding(.horizontal, 20)
                
                if prax.document.dataFieldPage != nil {
                    PraxButton(action: {prax.burnInAnnotations.toggle()}, symbol: "burn", help: "Burn in annotations", isOn: prax.burnInAnnotations, theme: .burn)}
                
                if prax.document.readyToExport {
                    
                    Button { prax.showFileExporter = true }
                    label: { Image(systemName: "square.and.arrow.down.fill") }
                        .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 486))
                        .onHover { hovering in prax.hoveredButton = hovering ? 486 : nil }
                        .help("Save As...")
                        .padding(.leading, 20)
                }
                
         //       PraxButton(action: {self.clickedSaveButton()}, symbol: "square.and.arrow.down.fill", help: "Save").padding(.horizontal, 10)
                Spacer()
            }
            
            
            
            MergedDocumentToolbarView()
              //  .zIndex(2)
                .frame(maxWidth: .infinity)
            
            ZStack(alignment: .topLeading) {
                
                DocumentView().zIndex(1)
                    .padding(.top, 10)
                    .background(PraxGradient(4))

                MergedDocumentOverlayView().zIndex(2).background(.clear)

                
            }
        }
        .onHover { isHovering in hovering = isHovering }
        .environment(\.groupHovering, hovering)
        
        .alert(isPresented: $presentAlert) {
            Alert(
                title: Text("Replace Library File?"),
                message: Text("This is a Library file. Are you sure you wish to change it?"),
                primaryButton: .destructive(Text("Replace")) {
                    save()
                },
                secondaryButton: .cancel() {
             //       dismiss()
                }
            )
        }
    }
    

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
    
    struct DocumentView: View {
        @Environment(PraxModel.self) private var prax
        @State private var editingDocumentVersion: UUID = UUID()
        
        
        
        var body: some View {
            HStack {
                Spacer()
                ScrollView(prax.scrollViewParameters().axes, showsIndicators: true) {
                    
                    VStack(spacing: 30) {
                        ForEach(0..<prax.document.pageImages.count, id: \.self) { index in
                            let img = prax.document.pageImages[index]
                            let size = img.size
                            Image(nsImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: size.width * prax.mergedViewScaleFactor,
                                       height: size.height * prax.mergedViewScaleFactor)
                        }
                    }
                }
                Spacer()
            }
            
            .onChange(of: prax.document.mergedPDFDocument) {
                
                if editingDocumentVersion != prax.document.editingDocumentVersion {
                    editingDocumentVersion = prax.document.editingDocumentVersion
                    prax.scaleMergedView()
                }
            }
            
            .onGeometryChange(for: CGRect.self) {  viewGeometry in return viewGeometry.frame(in: .named("MainWindow")) }
            action: { oldValue, newValue in prax.mergedViewFrame = newValue }
        }
    }
    
   
}



struct MergedDocumentOverlayView: View {
    @Environment(PraxModel.self) private var prax
    @Environment(\.groupHovering) private var groupHovering
    
    @State private var hovering: Bool = false
    
    var body: some View {
        @Bindable var prax = prax
        if prax.selectedPageItem != nil {
            GroupBox {
                Grid {
                    GridRow {
                        Button {
                            prax.mergedViewScaleMode = .user
                            prax.mergedViewScaleFactor -= 0.05 }
                        label: {  Image(systemName: "minus.circle") }
                            .buttonStyle(PraxButtonStyle())
                            .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                            .help("Zoom Out")
                        
                        Button { prax.scaleMergedView()}
                        label: {  Image(systemName: "arrow.up.and.down.and.arrow.left.and.right") }
                            .buttonStyle(PraxButtonStyle())
                            .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                            .help("Scale to Fit")
                            .disabled(prax.mergedViewScaleMode == .fit)
                        
                        Button {
                            prax.mergedViewScaleMode = .user
                            prax.mergedViewScaleFactor += 0.05 }
                        label: {  Image(systemName: "plus.circle") }
                            .buttonStyle(PraxButtonStyle())
                            .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                            .help("Zoom In")
                    }.opacity(hovering ? 1.0 : 0.0)
                    
                    
 
                    GridRow {
                        Button(action: { prax.scaleMergedView(.vertical)}, label: {
                            Image(systemName: "arrow.up.and.down") })
                        .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 731))
                        .onHover { hovering in prax.hoveredButton = hovering ? 731 : nil }
                        .help("Fit Vertically")
                        .disabled(!(prax.mergedViewScaleMode != .vertical && prax.mergedViewFitMode != .vertical))
                        .opacity(hovering ? 1.0 : 0.0)
                        
                        
                        Button(action: { prax.scaleMergedView()}, label: {
                            Image(systemName: "eye") })
                        .buttonStyle(PraxButtonStyle())
                        .opacity(hovering ? 1.0 : 0.75)
                        
                        Button(action: { prax.scaleMergedView(.horizontal)}, label: {
                            Image(systemName: "arrow.left.and.right") })
                        .buttonStyle(PraxButtonStyle())
                        .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                        .help("Fit Horizontally")
                        .disabled(!(prax.mergedViewScaleMode != .horizontal))
                        .opacity(hovering ? 1.0 : 0.0)
                    }
                   
                        Slider(value: $prax.mergedViewScaleFactor, in: 0.1...max(0.2, prax.editingDocumentPDFView.scaleFactorForSizeToFit))
                            .gridCellColumns(2)
                            .frame(width: 100)
                            .gridCellUnsizedAxes(.horizontal)
                            .opacity(hovering ? 1.0 : 0.0)
                }

                .padding(0)
         //       .opacity(hovering ? 1.0 : 0.5)
                
            }
            .animation(.easeIn(duration: 0.2), value: groupHovering)
            .animation(.easeIn(duration: 0.2), value: hovering)
            .onHover { isHovering in hovering = isHovering }
            .environment(\.groupHovering, hovering)
 //            .background(PraxGradient(4), in: RoundedRectangle(cornerRadius: 5))
            .opacity(groupHovering ? 1.0 : 0.0)
            .offset(x: 20, y: 10)
        }
        else {
            EmptyView()
        }
    }
}



struct MergedDocumentToolbarView: View {
    @Environment(PraxModel.self) private var prax
    
    
    var body: some View {
        @Bindable var prax = prax
        //      let _ = Self._printChanges()
    //    VStack {

            DataFieldsView()
            .opacity(prax.showDataFields && prax.document.dataFieldPage != nil ? 100 : 0)
                .frame(maxWidth: .infinity, maxHeight: prax.showDataFields && prax.document.dataFieldPage != nil ? nil : 5)
            
         //       if prax.editMode == .data && prax.document.dataFieldPage != nil {
         //           DataFieldsView()
         //           }
                
           

//        }
    }
       
}
