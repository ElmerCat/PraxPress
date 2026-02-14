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
    @Bindable var prax = PraxModel.shared
    
    @SceneStorage("ContentView.showFilesPanel") var showFilesPanel: Bool = true
    
    
    var body: some ToolbarContent {
        
        ToolbarItemGroup(placement: .navigation) {
            
            ReusableSegmentedControl(selection: $prax.praxPressMode, colorProvider: { $0.color })
            
            Group {
                if prax.praxPressMode == .merge {
                    Button {
                        withAnimation(.bouncy) {
                            showFilesPanel.toggle()
                        }
                    } label: {
                        Label((showFilesPanel ? "Hide Files" : "Show Files"), systemImage: (showFilesPanel ? "sidebar.squares.left" : "sidebar.left"))
                    }
                }
            }
        }
        

        ToolbarItemGroup(placement: .secondaryAction) {
            DropTargetControl()
            
        }
        
        ToolbarItemGroup(placement: .principal) {
            OptionKeyPressedToolbarItem()
        }
        
        ToolbarItemGroup(placement: .status) {
            DragOutControl()
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

   /*     ToolbarItemGroup(placement: .primaryAction) {
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
      */
    }
}


struct SegmentedControlSwiftUI: View {
    @State private var selectedTab: AppTab = .swiftUI
    @Namespace private var animation
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                // A fun display area that changes with the selection
                VStack {
                    Image(systemName: selectedTab.icon)
                        .font(.system(size: 80))
                        .foregroundColor(selectedTab.color)
                    Text(selectedTab.rawValue)
                        .font(.largeTitle.bold())
                }
                .padding(60)
                .frame(width: 300, height: 200)
                .background(selectedTab.color.opacity(0.15).gradient, in: RoundedRectangle(cornerRadius: 20))
                
                Spacer()
                
                // Here is our custom segmented control!
                ReusableSegmentedControl(selection: $selectedTab, colorProvider: { $0.color })
                
                Spacer()
            }
            .navigationTitle("DevTechie.com")
        }
    }
    
}
import SwiftUI

// Our menu of options!
enum AppTab: String, CaseIterable {
    case swiftUI = "SwiftUI"
    case iOS = "iOS"
    case uIKit = "UIKit"
    
    // Let's give each tab a unique color for fun
    var color: Color {
        switch self {
        case .iOS:
            return .pink
        case .swiftUI:
            return .blue
        case .uIKit:
            return .purple
        }
    }
    
    // And an icon, because why not?
    var icon: String {
        switch self {
        case .iOS:
            return "apple.logo"
        case .swiftUI:
            return "swift"
        case .uIKit:
            return "macwindow"
        }
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
