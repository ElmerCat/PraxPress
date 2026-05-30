//
//  DataImportEditor.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/25/26.
//



//
//  DataImportEditor.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/22/26.
//

import SwiftUI


struct DataImportEditor: View {
    @Environment(SettingsModel.self) private var settingsModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: String?
    @State private var hoveredButton: Int?
    @State private var isEditorPresented = false
    @State private var pastedText = ""
    //    @State private var analysisResult: AnalysisResult?
    @State private var templateName = ""
    @State private var focusPatternTypeID: UUID? = nil // Used to track which patternType ID needs to auto-select text in Name field after adding
    
    
    
    //    private let analyzer = TemplateAnalyzer()
    
    var body: some View {
        @Bindable var settingsModel = settingsModel
            
            VStack {
                Text("PraxPress Import Editor").font(Font.custom("BrushScriptMT", size: 20))
                GroupBox {
                    HStack {
                        Spacer()
                        Text("Copy Text From Clipboard")
                        Button { if let string = NSPasteboard.general.string(forType: .string){
                            pastedText = string } }
                        label: {
                            Image(systemName: "arrow.right.page.on.clipboard").padding(0)
                        }
                        //                        .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 161))
                        .onHover { hovering in hoveredButton = hovering ? 161: nil }
                        
                        Spacer()
                    }
                    TextEditor(text: Binding<String>(
                        get: { pastedText },
                        set: { newValue in
                            pastedText = newValue
                        }
                    ) )
                    .font(.system(.subheadline, design: .monospaced))
                    .padding(10)
                    .contentMargins(.all, 20, for: .scrollContent)
                    .scrollContentBackground(.hidden)
                    .background(Color.blue)
                    .border(.cyan, width: 2)
                    .frame(maxWidth: .infinity, maxHeight: 100)
             //       .contentMargins(.horizontal, 20.0, for: .scrollContent)
                    
                }
                .padding(4)
                
                Divider()
                
                GroupBox {
                    
                    VStack {
                        List($settingsModel.importPatternTypes, id: \.id, selection: $settingsModel.selected​Pattern​Type​ID) { $patternType in
                            HStack {
                                // TextField with focus and auto-select logic to improve UX after adding new pattern type
                                TextField("Name", text: $patternType.name)
                                    .focused($focusedField, equals: patternType.id.uuidString)
                                    // Added onAppear to reliably trigger focus and text selection after adding a new pattern type
                                    .onAppear {
                                        if focusPatternTypeID == patternType.id {
                                            focusedField = patternType.id.uuidString
                                            DispatchQueue.main.async {
                                                // Select all text in the TextField using the responder chain
                                                if let responder = NSApp.keyWindow?.firstResponder as? NSTextView {
                                                    responder.selectAll(nil)
                                                }
                                                focusPatternTypeID = nil // Only auto-select once
                                            }
                                        }
                                    }
                                Picker("", selection: $patternType.type) {
                                    Text("Date").tag(ImportPatternType.FieldType.date)
                                    Text("Currency").tag(ImportPatternType.FieldType.currency)
                                    Text("Fixed").tag(ImportPatternType.FieldType.fixed)
                                    Text("Variable").tag(ImportPatternType.FieldType.variable)
                                }
                                .pickerStyle(.menu)
                                TextField("Options", text: .init(get: { patternType.options ?? "" }, set: { patternType.options = $0.isEmpty ? nil : $0 }))
                                TextField("Description", text: .init(get: { patternType.description ?? "" }, set: { patternType.description = $0.isEmpty ? nil : $0 }))
                            }
                        }
                        .frame(height: 200)

                        .listStyle(.plain)
                        
              
                        HStack {
                            Button(action: {
                                // Add new pattern type, select and focus its Name field for immediate editing
                                let newType = ImportPatternType(name: "New Pattern", type: .fixed, options: nil, description: nil)
                                settingsModel.importPatternTypes.append(newType)
                                settingsModel.selected​Pattern​Type​ID = newType.id
                                focusPatternTypeID = newType.id
                                // Set focusedField here to ensure focus triggers immediately upon adding new pattern
                                focusedField = newType.id.uuidString
                                
                            }) {
                                Text("Add")
                            }
                            
                            
                            Button(action: {
                                if let selected = settingsModel.selectedPatternType {
                                    settingsModel.deletePatternType(selected)
                                }
                            }) {
                                Text("Delete")
                            }
                            .disabled(settingsModel.selectedPatternType == nil)
                            
                            
                        }
            
                        
                    }
      
                    
    /*
                    .alert(isPresented: $settingsModel.showUnsavedChangesAlert) {
                        Alert(
                            title: Text("Unsaved Changes"),
                            message: Text("You have unsaved changes. Are you sure you want to discard them?"),
                            primaryButton: .destructive(Text("Discard")) {
                                dismiss()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    
    */
                    
                }

                
                
            }
            .frame(minWidth: 500, maxWidth: 1000, minHeight: 600, maxHeight: 1200, alignment: .topLeading)
            .onAppear {
                settingsModel.loadPatternTypes()
            }
            .onChange(of: settingsModel.importPatternTypes) {
                if !settingsModel.loadingPatterns {
                    settingsModel.savePatternTypes()
                }
            }
            
        //}
        
        

    }

    
    
}
