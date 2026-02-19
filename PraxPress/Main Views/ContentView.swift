//
//  ContentView.swift
//  PraxPress - Prax=0104-1
//
//  Created by Elmer Cat on 12/21/25.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import Combine

struct ContentView: View {
    
    @Environment(PraxModel.self) private var prax
    @SceneStorage("ContentView.sidebarWidth") var sidebarWidth: Double = 200
    @SceneStorage("ContentView.contentWidth") var contentWidth: Double = 400
    @SceneStorage("ContentView.detailWidth") var detailWidth: Double = 200
    @State var windowWidth: CGFloat = 0
    let maxWidth = (NSScreen.main?.visibleFrame.width ?? 800) * 0.8
    
    @SceneStorage("ContentView.showFilesPanel") var showFilesPanel: Bool = true {
        didSet {
            if showFilesPanel == true {
                let ratio = detailWidth / contentWidth
                
                if windowWidth - sidebarWidth > 200 {
                    detailWidth -= sidebarWidth * ratio
                }
            }
            else {
                detailWidth += sidebarWidth
            }
        }
    }
    
    func onChangedDivider(_ newDimension: Double, at position: Int) {
        switch position {
        case 0:
            let difference = newDimension - sidebarWidth
            print("divider: ", position, " dragged to: ", newDimension, " difference: ", difference)
            if newDimension < 200 {
                print ("too narrow")
                return }
            
            if newDimension > windowWidth - contentWidth + detailWidth - 200 {
                print("too wide")
                return }
            
            if detailWidth < windowWidth - 200 {
                let differnce = newDimension - sidebarWidth
                sidebarWidth += differnce
                detailWidth -= differnce
            }
            
        default:
            let difference = newDimension - detailWidth
            print("divider: ", position, " dragged to: ", newDimension, " difference: ", difference)
            if newDimension < 200 {
                print("too narrow")
                return }
            
            if showFilesPanel {
                if newDimension + sidebarWidth > windowWidth - 200 {
                    print("too wide")
                    return }
                
            }
            if newDimension > windowWidth - 200 {
                print("too wide")
                return }
            detailWidth = newDimension
        }
    }
    
    var body: some View {
        @Bindable var prax = prax
        let _ = Self._printChanges()
        
        GeometryReader { proxy in
            HStack(spacing: 0) {
                
                if prax.praxPressMode == .data { // && showFilesPanel {
                    SourceFilesView()
                    //               .frame(width: CGFloat(sidebarWidth))
                    //               .layoutPriority(2)
                    //           SlideableDivider(dimension: sidebarWidth, position: 0, onChangedDivider: onChangedDivider)
                }
                else {
                    
                    NavigationSplitView(columnVisibility: $prax.columnVisibility) {
                        SourceFilesView()
                         //   .navigationTitle("PDF Files")
                            .navigationSplitViewColumnWidth(min: proxy.size.width * 0.15, ideal: 300, max: proxy.size.width * 0.75)
                    }
                    content: {
                        ContentDetailView()
                  //          .onDrop(of: [.fileURL], isTargeted: $prax.dropTargeted) { providers in
                  //              PraxModel.shared.acceptDrop(providers)
                  //          }
                  //          .onDropSessionUpdated({ dropSession in
                  //              print("ContentDetailView - dropSessionUpdated phase: ", dropSession.phase)
                  //          })
                            .navigationSplitViewColumnWidth(min: proxy.size.width * 0.25, ideal: 300, max: proxy.size.width * 0.75)
                    }
                    detail: {
                        VStack {
                            //    DocumentEditingToolbar()
                            MergedDocumentToolbar()
                            MergedDocumentView()
                            MergedDocumentFooter()
                            //       .alert(isPresented: $prax.isLarge) {
                            //           Alert(title: Text("Order Complete"),
                            //                 message: Text("Thank you for shopping with us."),
                            //                 dismissButton: .default(Text("OK")))   }
                        }
                        .navigationSplitViewColumnWidth(min: proxy.size.width * 0.25, ideal: 300, max: proxy.size.width * 0.75)
                    }
               
  /*                  .onGeometryChange(for: CGFloat.self) {  contentGeometry in
                        print("onGeometryChange - contentGeometry.size.width: ", contentGeometry.size.width, "  maxWidth: ", maxWidth,)
                        return contentGeometry.size.width
                        
                    }
                    action: {newValue in
                        print ("contentGeometry.size.width newValue: ", newValue )
                        contentWidth = newValue
                    }
*/
                }
            }
            .background(Color.indigo.opacity(0.5))
        }
        .frame(minWidth: 0, maxWidth: maxWidth, maxHeight: .infinity, alignment: .init(horizontal: .center, vertical: .top))
        .onGeometryChange(for: CGFloat.self) {  windowGeometry in
            print("onGeometryChange - windowGeometry.size.width: ", windowGeometry.size.width, "  maxWidth: ", maxWidth)
            return windowGeometry.size.width
        }
        action: {oldValue, newValue in
            print ("windowGeometry.size.width:  old: ", oldValue, "  new: ", newValue )
            windowWidth = Double(newValue)
        }
     //   .navigationTitle(prax.praxPressMode == .merge ? "Merge PDFs" : "Data File PDFs")
        .toolbar { MainToolbar() }
        .onAppear { print("ContentView  .onAppear ") }
    }
}

struct ContentDetailView: View {
    
    @Environment(PraxModel.self) private var prax
    
    var body: some View {
        @Bindable var prax = prax
        
        //     HSplitView {
        GroupBox {
            /*          DocumentEditingToolbar()
             MergedDocumentHeader()
             .draggable {
             if let data = prax.mergedPDFDocument.dataRepresentation() {
             return MergedPDFTransfer(data: data, filename: (prax.exportFilename))
             } else {
             return nil
             }
             }
             MergedDocumentFooter()
             .alert(isPresented: $prax.isLarge) {
             Alert(title: Text("Order Complete"),
             message: Text("Thank you for shopping with us."),
             dismissButton: .default(Text("OK")))   }
             
             */
            
            DocumentEditingToolbar()
            if prax.pdfPageSections.count > 0 {
                DocumentEditingView()
                    .inspector(isPresented: $prax.showingPDFPageItemInspector) {
                        PDFPageItemInspector()
                    }
                
            }
            else {
                Text("Drag files into PraxPress")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .font(Font.custom("BrushScriptMT", size: 30))
            }
            DocumentEditingFooter()
            
            //               .inspector(isPresented: $prax.showingMergedDocumentInspector) {
            //                 MergedDocumentInspector()
            //           }
            
        }
        
        
        
        .fileExporter(isPresented: $prax.showSavePanel, item: MergedPDFTransfer(data: prax.mergedPDFDocument.dataRepresentation()!, filename: prax.exportFilename), contentTypes: [.pdf], onCompletion: {
            result in
            switch result {
            case .success(let url):
                print ("Writing mergedPDFView to: ", url)
                prax.mergedPDFView.document?.write(to: url)
            case .failure(let error):
                print (error.localizedDescription)
                prax.saveError = error.localizedDescription
            }
        })
        .fileDialogDefaultDirectory(prax.exportFolderURL)
        .fileDialogMessage("Save the PraxPress Merged PDF")
        .fileExporterFilenameLabel("Save Merged PDF as:")
        .fileDialogConfirmationLabel(Text("Save Merged PDF"))
        
        
        //    .frame(maxWidth: 1000, maxHeight: .infinity)
        .padding(20)
        //  .background(prax.optionKeyPressed ? .red : .cyan)
        
        //    }
        
    }
}

/*struct aContentView: View {
    
    @Environment(PraxModel.self) private var prax
    
    var body: some View {
        @Bindable var prax = prax
        let _ = Self._printChanges()
        
        NavigationSplitView(columnVisibility: $prax.columnVisibility) {
            SourceFilesView()
        }
        
        detail: {
            
            HStack(spacing: 0) {
                ContentDetailView()
                //    .frame(width: CGFloat(detailWidth))
                    .layoutPriority(1)
                    .onChange(of: prax.isLarge) {
                        if prax.isLarge {
                            //       detailWidth = 1000
                        }
                        else {
                            //   detailWidth = 400
                            //     }
                        }
                    }

          //      SlideableDivider(dimension: detailWidth, position: 1, onChangedDivider: onChangedDivider)
                VStack {
                    //    DocumentEditingToolbar()
                    MergedDocumentToolbar()
                    MergedDocumentView()
                    MergedDocumentFooter()
                    //       .alert(isPresented: $prax.isLarge) {
                    //           Alert(title: Text("Order Complete"),
                    //                 message: Text("Thank you for shopping with us."),
                    //                 dismissButton: .default(Text("OK")))   }
                }
            }
       
        }
        .navigationTitle(prax.praxPressMode == .merge ? "Merge PDFs" : "Data File PDFs")
        .toolbar { MainToolbar() }
        .onAppear { print("ContentView  .onAppear ") }
        
    }
}
*/


#Preview {
    ContentView()
}





/*         NavigationSplitView(columnVisibility: $prax.columnVisibility) {
 SourceFilesView()
 .onGeometryChange(for: CGFloat.self) {  sidebarGeometry in
 print("onGeometryChange - sidebarGeometry.size.width: ", sidebarGeometry.size.width, "  maxWidth: ", maxWidth, "detailMaxWidth", detailMaxWidth)
 return sidebarGeometry.size.width
 
 }
 action: {newValue in
 print ("sidebarGeometry.size.width newValue: ", newValue )
 sidebarWidth = newValue
 }
 .layoutPriority(0)
 //           .navigationSplitViewColumnWidth(min: 100, ideal: 100, max: maxWidth / 2)
 } detail: {
 ContentDetailView()
 .onGeometryChange(for: CGFloat.self) {  detailGeometry in
 print("onGeometryChange - detailGeometry.size.width: ", detailGeometry.size.width, "  maxWidth: ", maxWidth, "detailMaxWidth", detailMaxWidth)
 return detailGeometry.size.width
 
 }
 action: {oldValue, newValue in
 print ("detailGeometry.size.width old: ", oldValue, "  new: ", newValue )
 detailWidth = Double(newValue)
 }
 .frame(maxWidth: detailMaxWidth)
 .layoutPriority(0)
 //    .navigationSplitViewColumnWidth(min: 100, ideal: 100, max: detailMaxWidth)
 
 .inspector(isPresented: $prax.isShowingInspector) {
 MergedDocumentInspector()
 
 .onGeometryChange(for:  CGFloat.self) {  inspectorGeometry in
 print("onGeometryChange - inspectorGeometry.size.width: ", inspectorGeometry.size.width, "  maxWidth: ", maxWidth, "detailMaxWidth", detailMaxWidth)
 return inspectorGeometry.size.width
 
 }
 action: {newValue in
 print ("inspectorGeometry.size.width - new: ", newValue )
 inspectorWidth = Double(newValue)
 }
 .interactiveDismissDisabled()
 //        .inspectorColumnWidth(min:400, ideal: 600, max: 1000)
 }
 //
 
 }
 
 
 
 
 @State private var dropTargeted: Bool = false
 
 func validateDrop(info: DropInfo) -> Bool {
 print("ContentView - validateDrop")
 return true
 }
 
 func performDrop(info: DropInfo) -> Bool {
 print("ContentView - performDrop")
 
 return acceptDrop(info.itemProviders(for: [UTType.fileURL]))
 }
 
 func dropEntered(info: DropInfo) {
 print("ContentView - dropEntered")    }
 
 func dropUpdated(info: DropInfo) -> DropProposal? {
 //       print("ContentView - dropUpdated - phase: ", info.session.phase)
 return DropProposal(operation: .copy)
 }
 
 func dropExited(info: DropInfo) {
 print("ContentView - dropExited")
 }
 
 func acceptDrop(_ providers: [NSItemProvider]) -> Bool {
 for provider in providers {
 
 provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { (data, error) in
 if let data = data, let path = String(data: data, encoding: .utf8), let url = URL(string: path) {
 
 print("Julie Belanger URL: ", url)
 
 }
 }
 
 }
 print("Julie d Prax")
 return true
 
 }
 
 
 @Environment(\.horizontalSizeClass) private var horizontalSizeClass
 @Environment(\.displayScale) private var displayScale
 
 
 */
