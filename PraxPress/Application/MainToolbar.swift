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
    
    @Environment(\.modelContext) private var modelContext
    @Environment(PraxModel.self) private var praxModel
    @SceneStorage("ContentView.showFilesPanel") var showFilesPanel: Bool = true
    
    
    var body: some ToolbarContent {
        @Bindable var prax = praxModel
        
        ToolbarItemGroup(placement: .status) {
            ReusableSegmentedControl(selection: $prax.praxPressMode, colorProvider: { $0.color })
        }
        
        ToolbarItemGroup(placement: .secondaryAction) {
            DropTargetControl()
        }
        
        ToolbarItemGroup(placement: .principal) {
            OptionKeyPressedToolbarItem()
        }
        
        ToolbarItemGroup(placement: .secondaryAction) {
            DragOutControl()
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            Text(prax.optionKeyPressed ? "Julie d'Prax" : "Juliette M. Belanger")
        }
      
        ToolbarItemGroup(placement: .status) {
            Button {
                prax.showingMergedDocumentInspector.toggle()
            } label: {
                Label((prax.showingMergedDocumentInspector ? "Hide Merged" : "Show Merged"), systemImage: (prax.showingMergedDocumentInspector ? "minus.magnifyingglass" : "plus.magnifyingglass"))
            }
            Button {
                prax.showingPDFPageItemInspector.toggle()
            } label: {
                Label((prax.showingPDFPageItemInspector ? "Hide PDFPageItem" : "Show PDFPageItem"), systemImage: (prax.showingPDFPageItemInspector ? "minus.magnifyingglass" : "plus.magnifyingglass"))
            }
            Button {
                prax.isLarge.toggle()
            } label: {
                Label((prax.isLarge ? "Status Small" : "Status Large"), systemImage: (prax.isLarge ? "minus.magnifyingglass" : "plus.magnifyingglass"))
            }
        }

        ToolbarItemGroup(placement: .primaryAction) {
            
            Text("Save As")
                .font(.default)
                .padding(.vertical, 10)
                .padding(.leading, 8)
                .foregroundStyle(.white)
                .contentShape(.rect)
            
            Button("Save As …", systemImage: "arrow.down.document") {
                prax.showSavePanel.toggle()
            }.padding(.horizontal, 4)
            
        }
        
        
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
