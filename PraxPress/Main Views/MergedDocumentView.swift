//
//  MergedDocumentView.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/12/26.
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
                    
                    switch prax.selectionIndexPaths.count {
                    case 0: Text("No Selection")
                    case 1: Text("Page: \((prax.selectionIndexPaths.first!.item) + 1) of \(prax.editingPDFDocument.pageCount ) ")
                    default: Text("Multiple Selection")
                    }
                    
                    Spacer()
                    
                    Text(String("\(prax.pdfPageSections.count) Pages"))
                        .font(.subheadline)
   /*                 if prax.mergedWidthPts > 0, prax.mergedHeightPts > 0 {
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
     */           }
                .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
                .padding(8)
            }
        }
        .background(Color(red: 0.0, green: 0.0, blue: 0.8, opacity: 1.0))
        .foregroundStyle(Color.white)
    }
}

final class Coordinator: NSObject {
    @State private var prax = PraxModel.shared


    
    @objc func pageChanged(_ note: Notification) {
        guard let pdfView = note.object as? PDFView,
              let doc = pdfView.document,
              let page = pdfView.currentPage else { return }
        let idx = doc.index(for: page)
        print("MergedDocumentView Coordinator - changed to page:", idx)
        //         if idx != NSNotFound, idx != prax.currentIndex { prax.currentIndex = idx }
    }
    
}



struct MergedDocumentView: NSViewRepresentable {
    @State private var prax = PraxModel.shared
    
    func makeCoordinator() -> Coordinator {
        print("Erika daPrax - MergedDocumentView makeCoordinator")
        return Coordinator()
    }
    
    
    func makeNSView(context: Context) -> PDFView {
        print("MergedDocumentView - makeNSView")
        prax.mergedPDFView = PDFView()

        
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: Notification.Name.PDFViewPageChanged,
            object: prax.mergedPDFView
        )
        
        return prax.mergedPDFView!
    }
    
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        print("\n\nMergedDocumentView - updateNSView\n\n")
    }

}

#Preview {
    MergedDocumentToolbar()
    MergedDocumentView()
}
