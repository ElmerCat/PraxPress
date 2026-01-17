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
    
    private func title(for mode: PDFDisplayMode) -> String {
        switch mode {
        case .singlePage: return "Single"
        case .singlePageContinuous: return "Continuous"
        case .twoUp: return "Two Up"
        case .twoUpContinuous: return "Two Up Cont."
        @unknown default: return "Unknown"
        }
    }
    
    var body: some View {
        GroupBox {
            VStack {
                HStack {
                    ControlGroup("", systemImage: "magnifyingglass") {
                        Button("Increase", systemImage: "plus.rectangle.portrait", action: prax.zoomInMergedPDFView)
                        Button("Decrease", systemImage: "minus.rectangle.portrait", action: prax.zoomOutMergedPDFView)
                        Button("", systemImage: "inset.filled.center.rectangle.portrait", action: {prax.mergedPDFDisplayMode = .singlePage}).disabled(prax.mergedPDFDisplayMode == .singlePage)
                        Button("", systemImage: "rectangle.portrait.tophalf.inset.filled", action: {prax.mergedPDFDisplayMode = .singlePageContinuous}).disabled(prax.mergedPDFDisplayMode == .singlePageContinuous)
                        if prax.mergedPDFDocument.pageCount > 1 {
                            Button("", systemImage: "rectangle.portrait.split.2x1", action: {prax.mergedPDFDisplayMode = .twoUp}).disabled(prax.mergedPDFDisplayMode == .twoUp)
                            Button("", systemImage: "inset.filled.topleft.rectangle.portrait", action: {prax.mergedPDFDisplayMode = .twoUpContinuous}).disabled(prax.mergedPDFDisplayMode == .twoUpContinuous)
                        }
                        if (prax.mergedPDFDisplayMode == .twoUpContinuous || prax.mergedPDFDisplayMode == .twoUp) {
                            Toggle("", systemImage: "book", isOn: $prax.mergedPDFDisplaysAsBook).toggleStyle(.button)
                        }
                    }
                    Spacer()
                    Text("Page: \((prax.currentIndex) + 1) of \(prax.editingPDFDocument.pageCount ) ")
                    Text("Trims: \(prax.trims.count) ")
                    
                    Spacer()
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
                .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
                .padding(8)
            }
        }
        .background(Color(red: 0.0, green: 0.0, blue: 0.8, opacity: 1.0))
        .foregroundStyle(Color.white)
    }
}


#Preview {
    MergedDocumentToolbar()
}
