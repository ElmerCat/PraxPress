//
//  TrimsEditorView.swift
//  PraxPress
//
//  Created by Elmer Cat on 10/8/26.
//


import SwiftUI
import PDFKit



struct TrimsEditorView: View {
    @Environment(PraxModel.self) private var prax
    var body: some View {
        if let pageItem = prax.selectedPageItem {
            @Bindable var prax = prax
            
            Grid {
                GridRow {
                    
                    Text("Page \((pageItem.editPageIndex) + 1) of \(prax.editingPageItems.count)")
                    
                    Button { prax.document.clickedGuidePageButton(pageItem) }
                    label: { Image(systemName: pageItem.skipped ? "ruler.fill" : "ruler") }
                    
                        .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 435, isOn: prax.document.widthGuidePageID != nil))
                        .onHover { hovering in prax.hoveredButton = hovering ? 435 : nil }
                        .help("Set Width Guide")
                    
                    Button { prax.editMode = .data }
                    label: { Image(systemName: "gear") }
                        .buttonStyle(PageItemButtonStyle(isHovering: prax.hoveredButton == 436))
                        .onHover { hovering in prax.hoveredButton = hovering ? 436 : nil }
                        .help("Edit Data")
                    
                }
                .frame(maxWidth: .infinity)
                GridRow {
                    
                    let outputInches = CGSize(width: pageItem.bounds.width / 72.0, height: pageItem.bounds.height / 72.0)

                    Text(pageSizeText(pageItem.bounds))
                    Text(inchesText(outputInches))
                    Text(pageSizeText(pageItem.mergedPage?.pdfPage?.bounds(for: .cropBox) ?? .zero))
                }.font(.caption)
                
            }
            
            
        }
    }
}

func pageSizeText(_ bounds: CGRect) -> String {
   return "\(Int(bounds.width)) × \(Int(bounds.height)) - " + String(format: "%.2f × %.2f in", bounds.width / 72.0, bounds.height / 72.0)
}


private func inchesText(_ size: CGSize) -> String {
    guard size.width > 0, size.height > 0 else { return "—" }
    return String(format: "%.2f × %.2f in", size.width, size.height)
}
