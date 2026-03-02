//
//  SettingsView.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/27/26.
//

import SwiftUI
import SwiftData
import PDFKit

struct SettingsView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("selectedSettingsTab") private var selectedSettingsTab = SettingsTab.general
     
    @AppStorage("selectedPDFFileGroupId") private var selectedPDFFileGroupId: Int?

    enum PraxFocus: Hashable {
        case firstButton
        case secondButton
        case textField
        // add more if needed
    }
    @FocusState private var focusedField: PraxFocus?
    let praxTheme = PraxTheme(.erika)
    
    @Query(sort: \PDFFileGroup.name) private var pdfFileGroups: [PDFFileGroup]
    @Query(sort: \PDFFile.fileName) private var pdfFiles: [PDFFile]

    var praxLady = "Julie d'Prax"
    @State private var hoveredButton: Int? = nil
    let document: MergedPDFDocument = MergedPDFDocument()
    let pdfView = PDFView()
    
    func configure() {
        document.mergedPDFView = pdfView
    }
    
    var body: some View {
        @Bindable var document = document
        
 
        TabView(selection: $selectedSettingsTab) {
            
            Tab("General", systemImage: "gearshape", value: .general)
           {
               Text("pdfFileGroups: \(pdfFileGroups.count)")
                Text("pdfFiles: \(pdfFiles.count)")
               Button("Erase All Data", action: eraseData)
            }
            
            Tab("Advanced", systemImage: "gearshape.fill", value: .advanced){
                
                Text("Prax Settings")
                Text("Other...")
            }
            
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear() {
                configure()
            }
    }
    
    func eraseData() {
        do {
            try modelContext.delete(model: PDFFileGroup.self)
            
        } catch {
            fatalError(error.localizedDescription)
        }
        
       
    }
}

struct AdvancedSettingsButton: View {
    @AppStorage("selectedSettingsTab")
    private var selectedSettingsTab = SettingsTab.general
    
    @Environment(\.openSettings) private var openSettings
    
    var body: some View {
        Button("Open Advanced Settings…") {
            selectedSettingsTab = .advanced
            openSettings()
        }
    }
}

enum SettingsTab: Int {
    case general
    case advanced
}
#Preview {
        SettingsView()
}

