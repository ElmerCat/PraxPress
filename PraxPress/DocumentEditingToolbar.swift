//
//  DocumentEditingToolbar.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/10/26.
//


import SwiftUI
import PDFKit


struct DocumentEditingToolbar: View {
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
                        Button("Increase", systemImage: "plus.rectangle.portrait", action: prax.zoomInEditingPDFView)
                        Button("Decrease", systemImage: "minus.rectangle.portrait", action: prax.zoomOutEditingPDFView)
                        Button("", systemImage: "inset.filled.center.rectangle.portrait", action: {prax.editingPDFDisplayMode = .singlePage}).disabled(prax.editingPDFDisplayMode == .singlePage)
                        Button("", systemImage: "rectangle.portrait.tophalf.inset.filled", action: {prax.editingPDFDisplayMode = .singlePageContinuous}).disabled(prax.editingPDFDisplayMode == .singlePageContinuous)
                        if prax.editingPDFDocument.pageCount > 1 {
                            Button("", systemImage: "rectangle.portrait.split.2x1", action: {prax.editingPDFDisplayMode = .twoUp}).disabled(prax.editingPDFDisplayMode == .twoUp)
                            Button("", systemImage: "inset.filled.topleft.rectangle.portrait", action: {prax.editingPDFDisplayMode = .twoUpContinuous}).disabled(prax.editingPDFDisplayMode == .twoUpContinuous)
                        }
                        if (prax.editingPDFDisplayMode == .twoUpContinuous || prax.editingPDFDisplayMode == .twoUp) {
                            Toggle("", systemImage: "book", isOn: $prax.editingPDFDisplaysAsBook).toggleStyle(.button)
                        }
                    }
                    Spacer()

                    Text("Page: \((prax.currentIndex) + 1) of \(prax.editingPDFDocument.pageCount ) ")
                    Text("Trims: \(prax.trims.count) ")                }
                .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
                .padding(8)
            }
        }
        .background(Color(red: 0.0, green: 0.0, blue: 0.8, opacity: 1.0))
        .foregroundStyle(Color.white)
    }
}

#Preview {
    DocumentEditingToolbar()
}
