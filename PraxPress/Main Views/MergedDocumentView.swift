//
//  MergedDocumentView.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/12/26.
//

import SwiftUI
import PDFKit

struct PDFPageItemInspector: View {
    @Environment(MergedPDFDocument.self) var document
    @Environment(PraxModel.self) private var praxModel
    
    var body: some View {
        @Bindable var prax = praxModel
        VStack {
            GroupBox {
                
                Text("Inspector 1")
                    .frame(minWidth: 100, maxWidth: 1000, maxHeight: .infinity)
                    .background(.pink)
            }
            .padding(20)
            //  .background(.yellow)
            Button(prax.isLarge ? "Make Small" : "Make Large") {
                // Toggle the state when the button is tapped
                prax.isLarge.toggle()
            }
            Text("Inspector 2")
            //           .frame(maxWidth: .infinity, maxHeight: .infinity)
            //               .background(.purple)
                .background(.purple)
        }
        Text("Inspector 3")
        //    .frame(maxWidth: .infinity, maxHeight: .infinity)
            .inspectorColumnWidth(min: 50, ideal: 150, max: 500)
            .background(.gray)
        
        
    }
}


struct MergedDocumentHeader: View {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    
    var body: some View {
        @Bindable var prax = praxModel
        
        HStack {
            
            GroupBox {
                
                HStack {
                    Spacer(minLength: 5)
                    Text("Drag as...   ")
                    Spacer(minLength: 5)
                    Text(document.exportFilenamePrefix)
                    //    Spacer(minLength: 5)
                    TextField("Filename", text: Binding<String>(
                        get: { document.exportFilenameBody },
                        set: { newValue in
                            var newName = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            // Ensure we don't accidentally include a dot/extension typed by the user
                            if let dotRange = newName.range(of: ".") {
                                newName = String(newName[..<dotRange.lowerBound])}
                            document.exportFilenameBody = newName
                        })
                              
                    )
                    .frame(minWidth: 20, idealWidth: 100, alignment: .init(horizontal: .trailing, vertical: .center))
                    //.frame(maxWidth: 100, alignment: .init(horizontal: .trailing, vertical: .center))
                    .textFieldStyle(SquareBorderTextFieldStyle())
                    .disabled(document.exportFolderURL == nil)
                    .foregroundStyle(.cyan)
                    .backgroundStyle(.yellow)
                    
                    // Spacer(minLength: 5)
                    Text(document.exportFilenameSuffix)
                    Spacer(minLength: 5)
                    
                    Image(systemName: "arrow.right.doc.on.clipboard")
                    Spacer(minLength: 5)
                    Text(".\(document.exportFilenameExtension)")
                    Spacer(minLength: 15)
                    
                }
                .draggable {
                    if let data = document.mergedPDFDocument.dataRepresentation() {
                        return MergedPDFTransfer(data: data, filename: (document.exportFilename))
                        
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
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    @Environment(PraxModel.self) private var praxModel
    
    var body: some View {
        @Bindable var prax = praxModel
        
        HStack {
            
       /*     ControlGroup("", systemImage: "magnifyingglass") {
                Text("View")
                Button("Increase", systemImage: "plus.rectangle.portrait", action: prax.zoomInMergedPDFView)
                Button("Decrease", systemImage: "minus.rectangle.portrait", action: prax.zoomOutMergedPDFView)
                Spacer()
                Button("", systemImage: "inset.filled.center.rectangle.portrait", action: {prax.mergedPDFDisplayMode = .singlePage}).disabled(prax.mergedPDFDisplayMode == .singlePage)
                Button("", systemImage: "rectangle.portrait.tophalf.inset.filled", action: {prax.mergedPDFDisplayMode = .singlePageContinuous}).disabled(prax.mergedPDFDisplayMode == .singlePageContinuous)
                if document.sections.count > 1 {
                    Button("", systemImage: "rectangle.portrait.split.2x1", action: {prax.mergedPDFDisplayMode = .twoUp}).disabled(prax.mergedPDFDisplayMode == .twoUp)
                    Button("", systemImage: "inset.filled.topleft.rectangle.portrait", action: {prax.mergedPDFDisplayMode = .twoUpContinuous}).disabled(prax.mergedPDFDisplayMode == .twoUpContinuous)
                }
                if (prax.mergedPDFDisplayMode == .twoUpContinuous || prax.mergedPDFDisplayMode == .twoUp) {
                    Toggle("", systemImage: "book", isOn: $prax.mergedPDFDisplaysAsBook).toggleStyle(.button)
                }
            }
            Spacer()
       */
            //    switch prax.selectedPageItems.count {
            //    case 0: Text("No Selection")
            //    case 1: Text("Page: \((prax.selectedPageItems.first!.item) + 1) of \(prax.mergedPDFDocument.pageCount ) ")
            //    default: Text("Multiple Selection")
            //    }
            
            Spacer()
            
            Text(String("\(document.sections.count) Pages"))
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
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    //    @State private var prax = PraxModel.shared
    
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
    /*                ControlGroup("", systemImage: "magnifyingglass") {
                        Button("Increase", systemImage: "plus.rectangle.portrait", action: document.zoomInMergedPDFView)
                        Button("Decrease", systemImage: "minus.rectangle.portrait", action: document.zoomOutMergedPDFView)
                        Button("", systemImage: "inset.filled.center.rectangle.portrait", action: {document.mergedPDFDisplayMode = .singlePage}).disabled(document.mergedPDFDisplayMode == .singlePage)
                        Button("", systemImage: "rectangle.portrait.tophalf.inset.filled", action: {document.mergedPDFDisplayMode = .singlePageContinuous}).disabled(document.mergedPDFDisplayMode == .singlePageContinuous)
                        if document.sections.count > 1 {
                            Button("", systemImage: "rectangle.portrait.split.2x1", action: {document.mergedPDFDisplayMode = .twoUp}).disabled(document.mergedPDFDisplayMode == .twoUp)
                            Button("", systemImage: "inset.filled.topleft.rectangle.portrait", action: {document.mergedPDFDisplayMode = .twoUpContinuous}).disabled(document.mergedPDFDisplayMode == .twoUpContinuous)
                        }
                        if (document.mergedPDFDisplayMode == .twoUpContinuous || document.mergedPDFDisplayMode == .twoUp) {
                            Toggle("", systemImage: "book", isOn: document.mergedPDFDisplaysAsBook).toggleStyle(.button)
                        }
                    }
 */                   Spacer()
                    
                    switch document.selectedPageItems.count {
                    case 0: Text("No Selection")
                    case 1: Text("Page: \((document.selectedPageItems.first!.item) + 1) of \(document.mergedPDFDocument.pageCount ) ")
                    default: Text("Multiple Selection")
                    }
                    
                    Spacer()
                    
                    Text(String("\(document.sections.count) Pages"))
                        .font(.subheadline)
           /*         if document.mergedWidthPts > 0, document.mergedHeightPts > 0 {
                        let wIn = document.mergedWidthPts / 72.0
                        let hIn = document.mergedHeightPts / 72.0
                        Text(String(format: "Merged size: %.0f × %.0f pts (%.2f × %.2f in)", document.mergedWidthPts, document.mergedHeightPts, wIn, hIn))
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
        //     .background(Color(red: 0.0, green: 0.0, blue: 0.8, opacity: 1.0))
        //     .foregroundStyle(Color.white)
    }
}

final class Coordinator: NSObject {
  //  @State private var prax = PraxModel.shared
    
    
    
    @objc func pageChanged(_ note: Notification) {
        guard let pdfView = note.object as? PDFView,
              let doc = pdfView.document,
              let page = pdfView.currentPage else { return }
        let idx = doc.index(for: page)
        print("MergedDocumentView Coordinator - changed to page:", idx)
        //         if idx != NSNotFound, idx != prax.currentIndex { prax.currentIndex = idx }
    }
    
}



struct praxMergedDocumentInspector: View {
    var body: some View {
        VStack {
            Text("Hello, World!")
                .padding()
                .navigationBarBackButtonHidden(false)
            
            //  MergedDocumentView()
        }
    }
    
}


struct MergedDocumentView: NSViewRepresentable {
    @Environment(MergedPDFDocument.self) var document: MergedPDFDocument
    
    
    func makeCoordinator() -> Coordinator {
        print("Erika daPrax - MergedDocumentView makeCoordinator")
        return Coordinator()
    }
    
    
    func makeNSView(context: Context) -> PDFView {
        print("MergedDocumentView - makeNSView")
        
        document.mergedPDFView.document = document.mergedPDFDocument
        
        
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: Notification.Name.PDFViewPageChanged,
            object: document.mergedPDFView
        )
        document.mergedPDFView.backgroundColor = .yellow
        
        
        return document.mergedPDFView
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
