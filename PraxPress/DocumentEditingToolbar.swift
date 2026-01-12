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
                    Picker("", selection: $prax.pdfDisplayMode) {
                        Image(systemName: "square").tag(PDFDisplayMode.singlePage)
                        Image(systemName: "square.stack.3d.down.right").tag(PDFDisplayMode.singlePageContinuous)
                        Image(systemName: "rectangle.split.2x1").tag(PDFDisplayMode.twoUp)
                        Image(systemName: "rectangle.split.2x1.fill").tag(PDFDisplayMode.twoUpContinuous)
                    }
                    .pickerStyle(.segmented)
                    ControlGroup("", systemImage: "magnifyingglass") {
                        Toggle("", systemImage: "book", isOn: $prax.pdfDisplaysAsBook).toggleStyle(.button)
                        Button("Increase", systemImage: "plus.magnifyingglass", action: prax.zoomInEditingPDFView)
                        Button("Decrease", systemImage: "minus.magnifyingglass", action: prax.zoomOutEditingPDFView)
                        Button("Fit", systemImage: "1.magnifyingglass", action: prax.zoomToFitEditingPDFView)
                        Toggle("Auto", systemImage: "1.magnifyingglass", isOn: $prax.pdfAutoScales)
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
    DocumentEditingToolbar()
}
