//
//  MergedDocumentView.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/12/26.
//

import SwiftUI
import PDFKit

struct MergedDocumentHeader: View {
    @Bindable private var prax = PraxModel.shared
    var body: some View {
        
        HStack {
            
            GroupBox {
                
                HStack {
                    Spacer(minLength: 5)
                    Text("Drag as...   ")
                    Spacer(minLength: 5)
                    Text(prax.exportFilenamePrefix)
                    //    Spacer(minLength: 5)
                    TextField("Filename", text: Binding<String>(
                        get: { prax.exportFilenameBody },
                        set: { newValue in
                            var newName = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            // Ensure we don't accidentally include a dot/extension typed by the user
                            if let dotRange = newName.range(of: ".") {
                                newName = String(newName[..<dotRange.lowerBound])}
                            prax.exportFilenameBody = newName
                        })
                              
                    )
                    .frame(minWidth: 20, idealWidth: 100, alignment: .init(horizontal: .trailing, vertical: .center))
                    //.frame(maxWidth: 100, alignment: .init(horizontal: .trailing, vertical: .center))
                    .textFieldStyle(SquareBorderTextFieldStyle())
                    .disabled(prax.exportFolderURL == nil)
                    .foregroundStyle(.cyan)
                    .backgroundStyle(.yellow)
                    
                    // Spacer(minLength: 5)
                    Text(prax.exportFilenameSuffix)
                    Spacer(minLength: 5)
                    
                    Image(systemName: "arrow.right.doc.on.clipboard")
                    Spacer(minLength: 5)
                    Text(".\(prax.exportFilenameExtension)")
                    Spacer(minLength: 15)
                    
                }
                .draggable {
                    if let data = prax.mergedPDFDocument.dataRepresentation() {
                        return MergedPDFTransfer(data: data, filename: (prax.exportFilename))
                        
                    } else {
                        return nil
                    }
                }

            }
            
            
            Spacer()
            
            Button("Save As …", systemImage: "arrow.down.document") {
                prax.showSavePanel.toggle()
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
        .padding(8)
        
    }
}



struct MergedDocumentFooter: View {
    @Bindable private var prax = PraxModel.shared
    var body: some View {
        
        HStack {
            
            ControlGroup("", systemImage: "magnifyingglass") {
                Text("View")
                Button("Increase", systemImage: "plus.rectangle.portrait", action: prax.zoomInMergedPDFView)
                Button("Decrease", systemImage: "minus.rectangle.portrait", action: prax.zoomOutMergedPDFView)
                Spacer()
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
            
            switch prax.selectedPageItems.count {
            case 0: Text("No Selection")
            case 1: Text("Page: \((prax.selectedPageItems.first!.item) + 1) of \(prax.editingPDFDocument.pageCount ) ")
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
             */
        }
        .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
        .padding(8)
    }
}


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
                    AdvancedSettingsButton()
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
                    
                    switch prax.selectedPageItems.count {
                    case 0: Text("No Selection")
                    case 1: Text("Page: \((prax.selectedPageItems.first!.item) + 1) of \(prax.editingPDFDocument.pageCount ) ")
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
   //     .background(Color(red: 0.0, green: 0.0, blue: 0.8, opacity: 1.0))
   //     .foregroundStyle(Color.white)
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
    //MergedDocumentHeader()
    //    MergedDocumentView()
        MergedDocumentFooter()
}
