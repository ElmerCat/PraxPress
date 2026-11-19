//
//  MainToolbar.swift
//  PraxPress
//
//  Created by Elmer Cat on 2/7/26.
//

import SwiftUI
import SwiftData
import PDFKit

struct MainToolbar: ToolbarContent {
    
    @Environment(PraxModel.self) private var praxModel
    @SceneStorage("ContentView.showFilesPanel") var showFilesPanel: Bool = true
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    @State var showDelete = false
    
    var body: some ToolbarContent {
        @Bindable var prax = praxModel
        

        
        
        ToolbarItemGroup(placement: .navigation) {
            
            Button(role: .destructive, action: { prax.document.mergedPages.removeAll() }, label: {
                HStack {
                    if !prax.document.mergedPages.isEmpty && prax.hoveredButton == 1040 { Text("Clear Merged Document") }
                    Image(systemName: prax.document.mergedPages.isEmpty ? "rectangle.dashed" : "rectangle.stack.slash") }
                .padding(.horizontal, 5)})
            .disabled(prax.document.mergedPages.isEmpty)
            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 1040 && !prax.document.mergedPages.isEmpty, hoverWidth: 200))
            .onHover { hovering in prax.hoveredButton = hovering ? 1040 : nil }
            .padding(.leading, 20)
 
           
            Button { prax.showTrimsEditor.toggle()
            }  label: { Image(systemName: "scissors") }
                .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 1039, isOn: prax.showTrimsEditor))
                .onHover { hovering in prax.hoveredButton = hovering ? 1039: nil }
                .disabled(prax.document.mergedPages.isEmpty)
                .padding(.horizontal, 30)
            
            Button {prax.undoManager?.undo() }  label: { Image(systemName: "arrow.uturn.backward.circle") }
                .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 1088))
                .onHover { hovering in prax.hoveredButton = hovering ? 1088: nil }
                .disabled(!(prax.undoManager?.canUndo ?? true))
            Button {prax.undoManager?.redo() }  label: { Image(systemName: "arrow.uturn.forward.circle") }
                .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 1089))
                .onHover { hovering in prax.hoveredButton = hovering ? 1089: nil }
                .disabled(!(prax.undoManager?.canRedo ?? true))
            
            Button { prax.showFileExporter = true }
            label: { Image(systemName: "square.and.arrow.up") }
                .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 486))
                .onHover { hovering in prax.hoveredButton = hovering ? 486 : nil }
                .disabled(!prax.document.readyToExport)
                .help("Save As...")
                .padding(.horizontal, 20)


  //     OptionKeyPressedToolbarItem()
       

        }
 
        
        ToolbarItemGroup(placement: .status) {
            
            Button {} label: {
                Image("PraxPress").resizable().aspectRatio(contentMode: .fit).frame(width: 30, height: 30)
                    .rotationEffect(Angle(degrees: prax.hoveredButton == 1639 ? 540 : 0))
                    .padding(.leading, 10)
                    .animation(.easeIn(duration: 0.25), value: prax.hoveredButton)
                
                Text("drag").foregroundStyle(prax.document.readyToExport ? .buttonDefaultBackground : .buttonDisabledForeground).font(.callout).italic().padding(.trailing, 30)
                
                Image("pdfFileIcon").resizable().aspectRatio(contentMode: .fill).frame(width: 30)
                Text("\(prax.document.exportFilename).pdf").padding(.trailing, 20)
                
            }
            .background(prax.document.readyToExport ? .buttonDefaultBackgroundPressed : .buttonDisabledBackground)
            .opacity(prax.document.readyToExport ? 1.0 : 0.5)
            .onHover { hovering in  prax.hoveredButton = hovering ? 1639: nil }
            .disabled(!prax.document.readyToExport)
            .draggable({ () -> MergedPDFTransfer? in
                guard let data = prax.document.mergedPDFDocument.dataRepresentation(options: [PDFDocumentWriteOption.burnInAnnotationsOption: prax.burnInAnnotations]) else { return nil }
                return MergedPDFTransfer(data: data, filename: prax.document.exportFilename) }()!, preview: { PraxDragPreview()})
            
        }
        
        
        
        
        ToolbarItemGroup(placement: .primaryAction) {
            
            Button(role: .confirm, action: { PraxLogger.shared.openLogFile() }, label: {
                Image(systemName: "book.and.wrench") })
            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 1048))
            .onHover { hovering in prax.hoveredButton = hovering ? 1048 : nil }
            .padding(.horizontal, 20)
            
            Button(role: .confirm, action: { prax.showOptionsPopover.toggle() }, label: {
                Image(systemName: "gear") })
            .buttonStyle(PraxButtonStyle(isHovering: prax.hoveredButton == 1042))
            .onHover { hovering in prax.hoveredButton = hovering ? 1042 : nil }
            .padding(.trailing, 20)
            

            .popover(isPresented: $prax.showOptionsPopover, content: {
                VStack {
                    Text("Julie d'Prax")
                    
                    Button {
                        withAnimation {
                            prax.columnVisibility = prax.columnVisibility == .detailOnly ? .all : .detailOnly
                        }
                        //   NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
                        
                    } label: {
                        Label("Sidebar", systemImage: "sidebar.left")
                    }
                    
                    
                    Button("🧪 Open Log") {
                        PraxLogger.shared.openLogFile()
                    }
                    
                    Button("🧪 Test Error") {
                        prax.praxTest()
                    }
                    
                    ReusableSegmentedControl(selection: $prax.praxPressMode, colorProvider: { $0.color })
                    
                    
                    Button {
                        prax.showMergedDocumentInspector.toggle()
                    } label: {
                        Label((prax.showMergedDocumentInspector ? "Hide Merged" : "Show Merged"), systemImage: (prax.showMergedDocumentInspector ? "minus.magnifyingglass" : "plus.magnifyingglass"))
                    }
                    Button {
                        prax.showPDFPageItemInspector.toggle()
                    } label: {
                        Label((prax.showPDFPageItemInspector ? "Hide PDFPageItemInspector" : "Show PDFPageItemInspector"), systemImage: (prax.showPDFPageItemInspector ? "minus.magnifyingglass" : "plus.magnifyingglass"))
                    }
                    Button {
                        prax.isLarge.toggle()
                        Task {
                            do {
                                prax.praxTest()
                            }
                        }
                        
                        
                    } label: {
                        Label((prax.isLarge ? "Status Small" : "Status Large"), systemImage: (prax.isLarge ? "minus.magnifyingglass" : "plus.magnifyingglass"))
                    }
                    
                }
                
                
                
            })
   
            
        }
        
        
        
        
    //    ToolbarItemGroup(placement: .secondaryAction) { DragOutControl() }
        
   //     ToolbarItemGroup(placement: .status) { Text(prax.optionKeyPressed ? "Julie d'Prax" : "Juliette M. Belanger")  }
        
        

        
        /* ToolbarItemGroup(placement: .principal) {
         Button("Save As …", systemImage: "arrow.down.document") {
         prax.showSavePanel.toggle()
         }
         HStack {
         Text("          Drag as...   ")
         Spacer(minLength: 5)
         Text(prax.exportFilenamePrefix)
         TextField("Filename", text: Binding<String>(
         get: { prax.exportFilenameBody },
         set: { newValue in
         var newName = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
         if let dotRange = newName.range(of: ".") {
         newName = String(newName[..<dotRange.lowerBound])
         }
         prax.exportFilenameBody = newName
         })
         )
         .frame(minWidth: 20, idealWidth: 100, alignment: .init(horizontal: .trailing, vertical: .center))
         .textFieldStyle(SquareBorderTextFieldStyle())
         .disabled(prax.exportFolderURL == nil)
         .foregroundStyle(.cyan)
         .backgroundStyle(.yellow)
         
         Text(prax.exportFilenameSuffix)
         Spacer(minLength: 5)
         Image(systemName: "arrow.right.doc.on.clipboard")
         Spacer(minLength: 5)
         Text(".\(prax.exportFilenameExtension)          ")
         
         }
         .draggable {
         if let data = prax.mergedPDFDocument.dataRepresentation() {
         return MergedPDFTransfer(data: data, filename: (prax.exportFilename))
         } else { return nil }
         }
         }
         */
        
        /*
         */
    }
}





struct BottomLabelGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .center, spacing: 8) {
            // The main content of the box
            configuration.content
            
            // The label placed at the bottom
            configuration.label
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.red)))
    }
}

// Usage
/*
 
 
 Menu("More") {
 Button("Settings") {
 
 }
 }
 Button {} label: {
 
 }
 
 GroupBox(label: Text("Sensor Data")) {
 Text("180°C").font(.title).bold()
 }
 .groupBoxStyle(BottomLabelGroupBoxStyle())
 
 
 
 
 
 */
#Preview {
    //MergedDocumentHeader()
    //    MergedDocumentView()
    ImportOptionsInspector()
}
