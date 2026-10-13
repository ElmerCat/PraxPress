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

    var body: some View {
        @Bindable var prax = prax
        VStack {
            
            Text("Merged PDF Document")
            MergedDocumentToolbarView()
              //  .zIndex(2)
                .frame(maxWidth: .infinity)
            
            ZStack(alignment: .topLeading) {
                
                DocumentView().zIndex(1)
                    .background(PraxGradient(4))

                MergedDocumentOverlayView().zIndex(2)
                
            }
        }
        .onHover { isHovering in hovering = isHovering }
        .environment(\.groupHovering, hovering)
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
            
            .onGeometryChange(for: CGSize.self) { viewGeometry in return viewGeometry.size }
            action: { oldValue, newValue in prax.mergedViewSize = newValue }
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
                            .buttonStyle(PageItemButtonStyle())
                            .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                            .help("Zoom Out")
                        
                        Button { prax.scaleMergedView()}
                        label: {  Image(systemName: "arrow.up.and.down.and.arrow.left.and.right") }
                            .buttonStyle(PageItemButtonStyle())
                            .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                            .help("Scale to Fit")
                            .disabled(prax.mergedViewScaleMode == .fit)
                        
                        Button {
                            prax.mergedViewScaleMode = .user
                            prax.mergedViewScaleFactor += 0.05 }
                        label: {  Image(systemName: "plus.circle") }
                            .buttonStyle(PageItemButtonStyle())
                            .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                            .help("Zoom In")
                    }
                    
                    
 
                    GridRow {
                        Button(action: { prax.scaleMergedView(.vertical)}, label: {
                            Image(systemName: "arrow.up.and.down") })
                        .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 731))
                        .onHover { hovering in prax.hoveredButton = hovering ? 731 : nil }
                        .help("Fit Vertically")
                        .disabled(!(prax.mergedViewScaleMode != .vertical && prax.mergedViewFitMode != .vertical))
                        
                        
                        VStack {
                            
                            Text("Zoom").font(.caption2).foregroundStyle(Color.black)
                            Text("\(Int(prax.mergedViewScaleFactor * 100))").font(.caption2).foregroundStyle(Color.black)
                        }
                        
                        Button(action: { prax.scaleMergedView(.horizontal)}, label: {
                            Image(systemName: "arrow.left.and.right") })
                        .buttonStyle(PageItemButtonStyle())
                        .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                        .help("Fit Horizontally")
                        .disabled(!(prax.mergedViewScaleMode != .horizontal))
                    }
                   
                        Slider(value: $prax.mergedViewScaleFactor, in: 0.1...max(0.2, prax.editingDocumentPDFView.scaleFactorForSizeToFit))
                            .gridCellColumns(2)
                            .frame(width: 100)
                            .gridCellUnsizedAxes(.horizontal)

                }
                .padding(0)
                .opacity(hovering ? 1.0 : 0.5)
                
            }
            .animation(.easeIn(duration: 0.2), value: groupHovering)
            .animation(.easeIn(duration: 0.2), value: hovering)
            .onHover { isHovering in hovering = isHovering }
            .environment(\.groupHovering, hovering)
            .background(PraxGradient(4), in: RoundedRectangle(cornerRadius: 5))
            .opacity(groupHovering ? 1.0 : 0.0)
            .offset(x: 50, y: 100)
        }
        else {
            EmptyView()
        }
    }
}



struct MergedDocumentToolbarView: View {
    @Environment(PraxModel.self) private var prax
    @FocusState private var focusedField: FieldName?
    
    var body: some View {
        @Bindable var prax = prax
        //      let _ = Self._printChanges()
        VStack {
            
            HStack {
                GroupBox {
                    VStack {
                        Text("Prefix")
                        TextField("Filename", text: Binding<String>(
                            get: { prax.document.exportFilenamePrefix },
                            set: { newValue in
                                prax.document.exportFilenamePrefix = newValue.filter{!Prax.filechars.contains($0)}}))
                        .focused($focusedField, equals: .exportFilenamePrefix)
                    }
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
                }
                .frame(maxWidth: 100)
                .groupBoxStyle(PraxGroupBoxStyle(isHovering: prax.hoveredButton == 427 ))
                .onHover { hovering in prax.hoveredButton = hovering ? 427 : nil }
                
                GroupBox {
                    VStack {
                        Text("Filename")
                        TextField("Filename", text: Binding<String>(
                            get: { prax.document.exportFilenameBody },
                            set: { newValue in
                                prax.document.exportFilenameBody = newValue.filter{!Prax.filechars.contains($0)}}))
                        .frame(maxWidth: .infinity)
                        .focused($focusedField, equals: .exportFilenameBody)
                    }
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
                }
                .groupBoxStyle(PraxGroupBoxStyle(isHovering: prax.hoveredButton == 437 ))
                .onHover { hovering in prax.hoveredButton = hovering ? 437 : nil }
                
                GroupBox {
                    VStack {
                        Text("Suffix")
                        TextField("Filename", text: Binding<String>(
                            get: { prax.document.exportFilenameSuffix },
                            set: { newValue in
                                prax.document.exportFilenameSuffix = newValue.filter{!Prax.filechars.contains($0)}}))
                        .focused($focusedField, equals: .exportFilenameSuffix)
                    }
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
                }
                .frame(maxWidth: 100)
                .groupBoxStyle(PraxGroupBoxStyle(isHovering: prax.hoveredButton == 447 ))
                .onHover { hovering in prax.hoveredButton = hovering ? 447 : nil }
                
            }
/*
// MARK: - Zoom Controls
            
            HStack {
                
                Button {
                    focusedField = .exportFilenamePrefix
                    prax.scaleMergedView() }
                label: {  Image(systemName: "arrow.up.and.down.and.arrow.left.and.right") }
                    .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 31))
                    .onHover { hovering in prax.hoveredButton = hovering ? 31 : nil }
                    .help("Scale to Fit")
                
                Button { prax.scaleMergedView(.vertical) }
                label: {  Image(systemName: "arrow.up.and.down") }
                    .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 31))
                    .onHover { hovering in prax.hoveredButton = hovering ? 31 : nil }
                    .help("Fit Horizontally")
                
                Button { prax.mergedViewScaleFactor -= 0.05}
                label: {  Image(systemName: "minus.circle") }
                    .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 32))
                    .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                    .help("Zoom Out")
                
                
                
                
                Text("\(Int(prax.mergedViewScaleFactor * 100))%")
                    .font(.callout).foregroundStyle(Color.black)
                    .padding(.leading, 20)
                
                Slider(value: $prax.mergedViewScaleFactor, in: 0.1...2.0)
                    .frame(width: 100)
                    .padding(.leading, 20)
                
                Button { prax.mergedViewScaleFactor += 0.05}
                label: {  Image(systemName: "plus.circle") }
                    .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 32))
                    .onHover { hovering in prax.hoveredButton = hovering ? 33 : nil }
                    .help("Zoom In")
                
                
                
                Button { prax.scaleMergedView(.horizontal) }
                label: {  Image(systemName: "arrow.left.and.right") }
                    .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 32))
                    .onHover { hovering in prax.hoveredButton = hovering ? 34 : nil }
                    .help("Fit Horizontally")
            }
*/
        }
        .focusedSceneValue(\.setExportFilenameBody, {
            focusedField = .exportFilenameBody
        })
    }
       
}
