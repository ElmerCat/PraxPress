//
//  EditingToolbarView.swift
//  PraxPress
//
//  Created by Elmer Cat on 10/6/26.
//

import SwiftUI
import PDFKit

struct EditingOverlayView: View {
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
                            prax.editorViewScaleMode = .user
                            prax.editingDocumentPDFView.zoomOut(self) }
                        label: {  Image(systemName: "minus.circle") }
                            .buttonStyle(PageItemButtonStyle())
                            .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                            .help("Zoom Out")
                        
                        Button { prax.scaleEditorView()}
                        label: {  Image(systemName: "arrow.up.and.down.and.arrow.left.and.right") }
                            .buttonStyle(PageItemButtonStyle())
                            .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                            .help("Scale to Fit")
                            .disabled(prax.editorViewScaleMode == .fit)
                        
                        Button {
                            prax.editorViewScaleMode = .user
                            prax.editingDocumentPDFView.zoomIn(self) }
                        label: {  Image(systemName: "plus.circle") }
                            .buttonStyle(PageItemButtonStyle())
                            .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                            .help("Zoom In")
                    }
                    GridRow {
                        Button(action: { prax.scaleEditorView(.vertical)}, label: {
                            Image(systemName: "arrow.up.and.down") })
                        .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 731))
                        .onHover { hovering in prax.hoveredButton = hovering ? 731 : nil }
                        .help("Fit Vertically")
                        .disabled(!(prax.editorViewScaleMode != .vertical && prax.editorViewFitMode != .vertical))
                        
                        
                        VStack {
                            Text("Zoom").font(.caption2).foregroundStyle(Color.black)
                            Text("\(Int(prax.editorViewScaleFactor * 100))").font(.caption2).foregroundStyle(Color.black)
                        }
                        
                        Button(action: { prax.scaleEditorView(.horizontal)}, label: {
                            Image(systemName: "arrow.left.and.right") })
                        .buttonStyle(PageItemButtonStyle())
                        .onHover { hovering in prax.hoveredButton = hovering ? 32 : nil }
                        .help("Fit Horizontally")
                        .disabled(!(prax.editorViewScaleMode != .horizontal))
                    }
                    
                    Slider(value: $prax.editorViewScaleFactor, in: 0.1...2.0)
                        .gridCellColumns(2)
                        .frame(width: 100)
                        .gridCellUnsizedAxes(.horizontal)
                }
                .padding(5)
                .opacity(hovering ? 1.0 : 0.5)
                
            }
            .animation(.easeIn(duration: 0.2), value: groupHovering)
            .animation(.easeIn(duration: 0.2), value: hovering)
            .onHover { isHovering in hovering = isHovering }
            .environment(\.groupHovering, hovering)
            .background(PraxGradient(4), in: RoundedRectangle(cornerRadius: 5))
            .opacity(groupHovering ? 1.0 : 0.0)
            
            .offset(x: -50, y: 100)
        }
        else {
            EmptyView()
        }
    }
}

struct EditingToolbarView: View {
    @Environment(PraxModel.self) private var prax
    @Environment(\.groupHovering) private var groupHovering
    
    @State private var hovering: Bool = false
    
    var body: some View {
        @Bindable var prax = prax
        if prax.selectedPageItem != nil {
            
            VStack {
                Text("Editor")
                if prax.editMode == .data && prax.document.dataFieldPage != nil {  // pageItem ==
                    DataFieldsView() }  else {
                        TrimsEditorView()
                    }
                
            }
            .onGeometryChange(for: CGSize.self) { viewGeometry in return viewGeometry.size }
            action: { oldValue, newValue in prax.editingToolbarSize = newValue }
            
                .animation(.easeIn(duration: 0.5), value: prax.editMode)
                .animation(.easeIn(duration: 0.5), value: groupHovering)
                .animation(.easeIn(duration: 0.5), value: hovering)
                .frame(maxWidth: .infinity, minHeight: 20)
                .onHover { isHovering in withAnimation { hovering = isHovering  } }
                .environment(\.groupHovering, hovering)
            
                .background(PraxGradient(4))
                .background(PraxGradient(4))
            //            .opacity(hovering ? 1 : 0.1)
            
        }
        else {
            EmptyView()
        }
    }
}
