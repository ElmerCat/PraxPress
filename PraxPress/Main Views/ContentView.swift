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



public struct ASlideableDivider: View {
    @Binding var dimension: Double
    @Binding var otherDimension: Double
    let position: Int
    let isShowingOtherPane: Bool
    let minDimension: Double
    let maxDimension: Double
    let windowWidth: Double
    //   @Binding var collapse: Bool?
    
    @State private var dimensionStart: Double?
    
    public var body: some View {
        Rectangle()
            .fill(.orange)
            .frame(width: 10)
            .onHover { inside in
                if inside {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(drag)
    }
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: CoordinateSpace.global)
            .onChanged { val in
                if dimensionStart == nil {
                    if position == 0 {
                        dimensionStart = dimension
                    }
                    else {
                        dimensionStart = otherDimension
                    }
                    dimensionStart = dimension
                }
                let delta = val.location.x - val.startLocation.x
                let newDimension = dimensionStart! + Double(delta)
                
                
                let difference = newDimension - dimension
                
                if difference > 0 {
                    
                    
                    
                }
                else if difference < 0 {
                    if position == 0 {
                        if newDimension < minDimension {
                            print("Julie d'Prax")
                            //  collapse = false
                        }
                        else {
                            dimension = newDimension
                        }
                    }
                    else {
                        if newDimension > maxDimension {
                            print("Juliette M. Belanger")
                            //  collapse = false
                        }
                        else {
                            dimension = newDimension
                        }
                        
                    }
                    
                }
                
                if position == 0 {
                    if newDimension < minDimension {
                        print("Julie d'Prax")
                        //  collapse = false
                        return
                    }
                    
                    if newDimension < windowWidth - maxDimension {
                        dimension = newDimension
                        return
                    }
                }
                
                if newDimension + dimension < minDimension {
                    
                    print("Julie d'Prax")
                    //  collapse = false
                    return
                }
                else if isShowingOtherPane {
                    
                    if newDimension < windowWidth - dimension - otherDimension - maxDimension {
                        dimension += difference / 2
                        otherDimension += difference / 2
                    }
                    
                    
                }
                else {
                    
                    if newDimension < windowWidth - maxDimension {
                        dimension += difference
                        otherDimension += difference
                    }
                    
                    
                }
                
                
                print("dimension: ", dimension)
                
            }
            .onEnded { val in
                dimensionStart = nil
            }
    }
}

public struct SlideableDivider: View {
    let dimension: Double
    let position: Int
    let onChangedDivider: (Double, Int) -> Void
    
    @State private var dimensionStart: Double?
    
    public var body: some View {
        Rectangle()
            .fill(.orange)
            .frame(width: 10)
            .onHover { inside in
                if inside {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(drag)
    }
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: CoordinateSpace.global)
            .onChanged { val in
                if dimensionStart == nil {
                        dimensionStart = dimension
                }
                let delta = val.location.x - val.startLocation.x
                let newDimension = dimensionStart! + Double(delta)
                
                onChangedDivider(newDimension, position)
            }
            .onEnded { val in
                dimensionStart = nil
            }
    }
}

struct ContentView: View {
    @Environment(PraxContext.self) private var praxContext
    @Environment(PraxModel.self) private var prax
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.displayScale) private var displayScale
    
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
    
    let maxWidth = (NSScreen.main?.visibleFrame.width ?? 800) * 0.8
    
    @SceneStorage("ContentView.sidebarWidth") var sidebarWidth: Double = 200
    @SceneStorage("ContentView.contentWidth") var contentWidth: Double = 400
    @SceneStorage("ContentView.detailWidth") var detailWidth: Double = 200
    
    @State var windowWidth: CGFloat = 0
    
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
        @Bindable var praxContext = praxContext
        
        
        
        var detailMaxWidth: Double {
            if showFilesPanel {
                return (windowWidth - sidebarWidth) - 20
            }
            else {
                return windowWidth - 20
            }
            
        }
        
        
        let _ = Self._printChanges()
        
        GeometryReader { geometry in
            
            HStack(spacing: 0) {
                
                if showFilesPanel {
                    SourceFilesView()
                        .frame(width: CGFloat(sidebarWidth))
                        .layoutPriority(2)
                    
                    SlideableDivider(dimension: sidebarWidth, position: 0, onChangedDivider: onChangedDivider)
                    
                }
                
                HStack(spacing: 0) {
                    
                    VStack {
                        Text("Window Width: \(windowWidth)")
                        Text("Content Width: \(contentWidth)")
                        Text("SidebarWidth: \(sidebarWidth)")
                        Text("DetailWidth: \(detailWidth)")
                        Text("DetailMaxWidth: \(detailMaxWidth)")
                        Text("Max Width: \(maxWidth)")
                        Text("Width: \(geometry.size.width)")
                        Text("Height: \(geometry.size.height)")
            //            Text("Local (x,y): \(geometry.frame(in: .local).origin)")
            //            Text("Global (x,y): \(geometry.frame(in: .global).origin)")
                        ContentDetailView()
                            .frame(width: CGFloat(detailWidth))
                            .layoutPriority(1)
                            .onChange(of: prax.isLarge) {
                                if prax.isLarge {
                                    detailWidth = 1000
                                }
                                else {
                                    detailWidth = 400
                                }
                            }
                        
                    }
                    SlideableDivider(dimension: detailWidth, position: 1, onChangedDivider: onChangedDivider)
                    VStack {
                        MergedDocumentToolbar()
                        MergedDocumentView()
                    }
                }
                .onGeometryChange(for: CGFloat.self) {  contentGeometry in
                    print("onGeometryChange - contentGeometry.size.width: ", contentGeometry.size.width, "  maxWidth: ", maxWidth, "detailMaxWidth", detailMaxWidth)
                    return contentGeometry.size.width
                    
                }
                action: {newValue in
                    print ("contentGeometry.size.width newValue: ", newValue )
                    contentWidth = newValue
                }
                
            }
            

            
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
        
        
        .toolbar {
            MainToolbar()
        }
        
        .onAppear {
            print("ContentView  .onAppear ")
            //    prax.loadSelectedFiles()
        }
        
    }
}

struct ContentDetailView: View {
    
    @Environment(PraxContext.self) private var praxContext
    @Environment(PraxModel.self) private var prax
    
    var body: some View {
        @Bindable var prax = prax
        @Bindable var praxContext = praxContext
        
        HSplitView {
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
                 
                 */        DocumentEditingView()
                //               .inspector(isPresented: $prax.showingMergedDocumentInspector) {
                //                 MergedDocumentInspector()
                //           }
                    .inspector(isPresented: $prax.showingPDFPageItemInspector) {
                        PDFPageItemInspector()
                    }
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
            .background(praxContext.optionKeyPressed ? .red : .cyan)
            
        }
        
    }
}



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
 */
