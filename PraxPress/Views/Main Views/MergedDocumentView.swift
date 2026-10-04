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
            ToolbarView()
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
    
    struct ToolbarView: View {
        @Environment(PraxModel.self) private var prax
        
        
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
                        }
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
                    }
                    .frame(maxWidth: 100)
                    .groupBoxStyle(PraxGroupBoxStyle(isHovering: prax.hoveredButton == 447 ))
                    .onHover { hovering in prax.hoveredButton = hovering ? 447 : nil }
                    
                }
                
                HStack {
                    
                    Button { scaleView(.vertical) }
                    label: {  Image(systemName: "arrow.up.and.down.square") }
                        .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 31))
                        .onHover { hovering in prax.hoveredButton = hovering ? 31 : nil }
                        .help("Fit Horizontally")
                    
                    Text("\(Int(prax.mergedViewScaleFactor * 100))%")
                        .font(.callout).foregroundStyle(Color.black)
                        .padding(.leading, 20)
                    
                    Slider(value: $prax.mergedViewScaleFactor, in: 0.1...2.0)
                        .frame(width: 100)
                        .padding(.leading, 20)
                    
                    Button { scaleView(.horizontal) }
                    label: {  Image(systemName: "arrow.left.and.right.square") }
                        .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 32))
                        .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                        .help("Fit Horizontally")
                }
                
            }
        }
        
        func scaleView(_ direction: PDFDisplayDirection) {
            if direction == .vertical {
                let scale = prax.mergedViewSize.height / prax.document.totalHeight
                prax.mergedViewScaleFactor = scale
            }
            else {
                let scale = prax.mergedViewSize.width / prax.document.maxWidth
                prax.mergedViewScaleFactor = scale
            }
        }
    }
    
    struct DocumentView: View {
        @Environment(PraxModel.self) private var prax
        
        var body: some View {
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                
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
            .onGeometryChange(for: CGSize.self) { viewGeometry in return viewGeometry.size }
            action: { oldValue, newValue in prax.mergedViewSize = newValue }
        }
    }
}
