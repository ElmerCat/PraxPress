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
    @Environment(PersistenceController.self) private var persistence
  //  @Environment(SettingsModel.self) private var settingsModel
    
    @AppStorage("selectedSettingsTab") private var selectedSettingsTab = SettingsTab.general
     
    @AppStorage("selectedSourceFileGroupId") private var selectedSourceFileGroupId: Int?

    enum PraxFocus: Hashable {
        case firstButton
        case secondButton
        case textField
        // add more if needed
    }
    @FocusState private var focusedField: PraxFocus?
    
    @Query(sort: \SourceFileGroup.name) private var sourceFileGroups: [SourceFileGroup]
    @Query(sort: \SourceFile.fileName) private var sourceFiles: [SourceFile]

    var praxLady = "Julie d'Prax"
    @State private var hoveredButton: Int? = nil

    @State private var selectedFileType = Set<UUID>()
    @State private var importFileTypes: [FileType] = [
        FileType(fileType: "PDF"),
        FileType(fileType: "DOCX"),
        FileType(fileType: "TXT")
    ]
    
    struct FileType: Identifiable, Hashable {
        let fileType: String
        let id = UUID()
    }

    
    
    
    var body: some View {
        @Bindable var settingsModel = SettingsModel.shared
        
 
        TabView(selection: $selectedSettingsTab) {
            
            Tab(SettingsTab.general.name, systemImage: SettingsTab.general.icon, value: .general)
           {


               VStack {
                   
                   GroupBox(label: Text("Import File Types")) {
                       
                       NavigationView {
                           List(importFileTypes, id: \.id, selection: $selectedFileType) { fileType in
                               Text(fileType.fileType)
                           }
                           .frame(height: 200)
                           .listStyle(.plain)
                           .navigationTitle("Oceans")
        //                   .toolbar { EditButton() }
                       }
                       Text("\(selectedFileType.count) selections")
                       
                       
                       
                           
                      
                       
                       
                   }
                   
                   HStack(spacing: 8) {
                       Text("Import File Count Limit:")
                       
                       // Text field updates the same Int state bound to the stepper
                       TextField("", value: $settingsModel.importFileCountLimit, format: .number)
                          
                           .textFieldStyle(.roundedBorder)
                           .frame(width: 60)
                           .multilineTextAlignment(.center)
                       
                       // Stepper changes the value and automatically triggers UI updates
                       Stepper("", value: $settingsModel.importFileCountLimit, in: 0...100)
                           .labelsHidden()
                   }
                   .onChange(of: settingsModel.importFileCountLimit) {
                       print("importFileCountLimit: \(settingsModel.importFileCountLimit)")
                       
                   }
                   .padding()

                   Divider()

                   Text("sourceFileGroups: \(sourceFileGroups.count)")
                   Text("sourceFiles: \(sourceFiles.count)")
                   Button("Erase All Data", action: eraseData)
                   Button("PraxTest", action: praxTest)

                   
               }
               
      }
            
            Tab(SettingsTab.advanced.name, systemImage: SettingsTab.advanced.icon, value: .advanced) {
     
                Text("Prax Settings")
                Text("Other...")
            }
            
            Tab(SettingsTab.dataImportTypes.name, systemImage: SettingsTab.dataImportTypes.icon, value: .dataImportTypes) {
         //       Text("Eloise")
                DataImportEditor()
                
            }
            
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
      
            .onKeyPress { event in
                print("KeyPress - ", event.modifiers, event.characters)
                
                if event.modifiers.contains(.command) && event.characters == "Z" {
                    print("KeyPress - Redo", event.modifiers, event.characters)
                    
                    
                    settingsModel.undoManager.redo()
                    return .handled
                }
                if event.modifiers.contains(.command) && event.characters == "z" {
                    print("KeyPress - Undo", event.modifiers, event.characters)
                    
                    settingsModel.undoManager.undo()
                    return .handled
                }
                return .ignored
            }




    }
    
    func praxTest() {
        
     

        print ("\nJulie d'Prax")
        for sourceFile in sourceFiles {
            print (sourceFile.fileName)
        }
        
        print ("\nJuliette M. Belanger")
        for sourceFileGroup in sourceFileGroups {
            print (sourceFileGroup.name)
        }
       
       
    }
    
    func eraseData() {
        do {
            try modelContext.delete(model: SourceFileGroup.self)
            
        } catch {
            fatalError(error.localizedDescription)
        }
        
       
    }
}

struct ShowSettingsButton: View {
    @Environment(\.openSettings) private var openSettings
    @AppStorage("selectedSettingsTab") private var selectedSettingsTab = SettingsTab.general

    let settingsTab: SettingsTab
    init(_ settingsTab: SettingsTab = SettingsTab.general) {
        self.settingsTab = settingsTab
    }
    
    var body: some View {
        Button(settingsTab.name) {
            selectedSettingsTab = settingsTab
            openSettings()
        }
    }
}

enum SettingsTab: Int {
    case general
    case advanced
    case dataImportTypes

    
    var name: String { switch self {
    case .advanced: return "Advanced Settings"
    case .dataImportTypes: return "Data Import Types"
    default: return "General Settings" } }
    
    var icon: String { switch self {
    case .advanced: return "gearshape.2"
    case .dataImportTypes: return "slider.horizontal.2.square.badge.arrow.down"
    default: return "gearshape" } }
    
    
    
    
    
}
#Preview {
        SettingsView()
}
