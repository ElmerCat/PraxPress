//
//  MergedDocumentToolbar.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/10/26.
//


import SwiftUI
import PDFKit

struct MergedDocumentToolbar: View {

    @State private var prax = PraxModel.shared
    
    var body: some View {
        GroupBox {
            HStack {
                
                Toggle(isOn: $prax.pdfAutoScales) {
                    Label("Auto Scales", systemImage: "arrow.up.left.and.down.right.magnifyingglass")
                }
                
                // Left: Page indicator
                Text("Document pages: \(prax.editingPDFDocument.pageCount)")
                    .font(.subheadline)
                
                Spacer()
                
                // Right: Live merged size using trims
                if prax.mergedWidthPts > 0, prax.mergedHeightPts > 0 {
                    let wIn = prax.mergedWidthPts / 72.0
                    let hIn = prax.mergedHeightPts / 72.0
                    Text(String(format: "Merged size: %.0f × %.0f pts (%.2f × %.2f in)", prax.mergedWidthPts, prax.mergedHeightPts, wIn, hIn))
                        .font(.subheadline)
                    //    .foregroundStyle(Color.white)
                } else {
                    Text("Merged size: —")
                        .font(.subheadline)
                    //  .foregroundStyle(.tertiary)
                }
            }
            .padding(8)
        }
        .background(Color(red: 0.0, green: 0.0, blue: 0.8, opacity: 1.0))
        .foregroundStyle(Color.white)
    }
}


#Preview {
    MergedDocumentToolbar()
}
