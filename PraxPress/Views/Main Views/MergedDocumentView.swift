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
        ZStack {
            MergedDocumentToolbarView()
                .zIndex(2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
            DocumentView().zIndex(1)
                .padding(.top, 70)
                .background(PraxGradient(3))
        }
        .animation(.easeInOut(duration: 0.50), value: prax.editingToolbarSize.height)
        .onHover { isHovering in hovering = isHovering }
        .environment(\.groupHovering, hovering)
    }
    

    
    struct DocumentView: View {
        @Environment(PraxModel.self) private var prax
        @State private var editingDocumentVersion: UUID = UUID()
        
        
        
        var body: some View {
            let parameters = prax.scrollViewParameters()
            
            let axs: Axis.Set = [.horizontal, .vertical]
            let _ = print("axes: ", parameters.axes.rawValue, "  axs: ", axs.rawValue, "  margin: ", parameters.margin)
            HStack {
                Spacer()
                ScrollView(parameters.axes, showsIndicators: true) {
                    
                    VStack(spacing: 20) {
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

struct MergedDocumentToolbarView: View {
    @Environment(PraxModel.self) private var prax
    @FocusState private var focusedField: FieldName?
    
    var body: some View {
        @Bindable var prax = prax
        //      let _ = Self._printChanges()
        VStack {
            Text("Merged PDF Document")
            
            
            Divider()
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
            
            HStack {
                
                Button {
                    focusedField = .exportFilenamePrefix
                    prax.scaleMergedView() }
                label: {  Image(systemName: "gear") }
                    .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 31))
                    .onHover { hovering in prax.hoveredButton = hovering ? 31 : nil }
                    .help("Scale to Fit")
                
                Button { prax.scaleMergedView(.vertical) }
                label: {  Image(systemName: "arrow.up.and.down.square") }
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
                label: {  Image(systemName: "arrow.left.and.right.square") }
                    .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 32))
                    .onHover { hovering in prax.hoveredButton = hovering ? 34 : nil }
                    .help("Fit Horizontally")
            }
            
        }
        .focusedSceneValue(\.setExportFilenameBody, {
            focusedField = .exportFilenameBody
        })
    }
       
}
