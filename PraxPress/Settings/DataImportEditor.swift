
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
    
    @AppStorage("savedTemplates") private var savedTemplatesData: Data = Data()
    
    // Note: Changed selection from pattern object to selection by ID for clearer state management
    private var selectedPatternType: ImportPatternType? {
        if let id = settingsModel.selected​Pattern​Type​ID {
            return settingsModel.importPatternTypes.first(where: { $0.id == id })
        }
        return nil
    }
    
    private func deletePatternType(_ patternType: ImportPatternType) {
        if let index = settingsModel.importPatternTypes.firstIndex(where: { $0.id == patternType.id }) {
            settingsModel.importPatternTypes.remove(at: index)
   //         settingsModel.hasUnsavedChanges = true
            settingsModel.selected​Pattern​Type​ID = nil
        }
    }

/*
    private func editPatternType(_ patternType: ImportPatternType) {
        print("Editing pattern type: \(patternType.name)")
        settingsModel.hasUnsavedChanges = true
    }
*/
    private func savePatternTypes() {
        // Save the ImportPatternType records to AppStorage
        do {
            let data = try JSONEncoder().encode(settingsModel.importPatternTypes)
            savedTemplatesData = data
//            settingsModel.hasUnsavedChanges = false
        } catch {
            print("Error saving pattern types: \(error)")
        }
    }


/*
    private func cancelChanges() {
        // Restore the original ImportPatternType records
        loadPatternTypes()
    }
*/
    
    private func loadPatternTypes() {
        settingsModel.loadingPatterns = true
        // Load the ImportPatternType records from AppStorage
        do {
            let data = savedTemplatesData
            settingsModel.importPatternTypes = try JSONDecoder().decode([ImportPatternType].self, from: data)
        } catch {
            print("Error loading pattern types: \(error)")
            settingsModel.importPatternTypes = []
        }
        settingsModel.loadingPatterns = false
       
    }
    
    
    //    private let analyzer = TemplateAnalyzer()
    
    var body: some View {
        @Bindable var settingsModel = settingsModel
        
        if let undoManager = settingsModel.undoManager {
            
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
                                if let selected = selectedPatternType {
                                    deletePatternType(selected)
                                }
                            }) {
                                Text("Delete")
                            }
                            .disabled(selectedPatternType == nil)
                            
                            
                            Button {undoManager.undo() }
                            label: {
                                Text(String("\(undoManager.undoCount)")) // .font(.system(size: 8))
                                Image(systemName: undoManager.undoCount > 0 ? "arrow.uturn.backward.circle.fill" : "arrow.uturn.backward.circle" )                                    }
                            .disabled(undoManager.undoCount < 1)
                //            .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 274))
                            .onHover { hovering in hoveredButton = hovering ? 274 : nil }
                            
                            //         Text(String("\(undoManager.undoCount)"))
                            
                            //               Text("\(pageItem.name)  Redo").font(.system(size: 8))
                            Button {undoManager.redo() }
                            label: { if undoManager.redoCount > 0 {
                                Image(systemName: "arrow.uturn.forward.circle.fill") } else {
                                    Image(systemName: "arrow.uturn.forward.circle") }
                                Text(String("\(undoManager.redoCount)")).font(.system(size: 8)) }
                            .disabled(undoManager.redoCount < 1)
                      //      .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 276))
                            .onHover { hovering in hoveredButton = hovering ? 276 : nil }
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
                loadPatternTypes()
            }
            .onChange(of: settingsModel.importPatternTypes) {
                if !settingsModel.loadingPatterns {
                    savePatternTypes()
                }
            }
            
        }
        
        

    }

    
    
}
extension ImportPatternType: Codable, Hashable {
    enum CodingKeys: String, CodingKey {
        case name
        case type
        case options
        case description
    }
    
    static func == (lhs: ImportPatternType, rhs: ImportPatternType) -> Bool {
        lhs.name == rhs.name &&
        lhs.type == rhs.type &&
        lhs.options == rhs.options &&
        lhs.description == rhs.description
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
        hasher.combine(options)
        hasher.combine(description)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let typeString = try container.decode(String.self, forKey: .type)
        switch typeString {
        case "date":
            type = .date
        case "currency":
            type = .currency
        case "fixed":
            type = .fixed
        case "variable":
            type = .variable
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type")
        }
        options = try container.decodeIfPresent(String.self, forKey: .options)
        description = try container.decodeIfPresent(String.self, forKey: .description)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        let typeString: String
        switch type {
        case .date:
            typeString = "date"
        case .currency:
            typeString = "currency"
        case .fixed:
            typeString = "fixed"
        case .variable:
            typeString = "variable"
        }
        try container.encode(typeString, forKey: .type)
        try container.encodeIfPresent(options, forKey: .options)
        try container.encodeIfPresent(description, forKey: .description)
    }
}




/*

struct PatternTypeEditor: View {
    @Environment(SettingsModel.self) private var settingsModel
    @Environment(\.dismiss) private var dismiss
    
    
    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("Name", text: .init(get: { settingsModel.patternTypeToEdit?.name ?? "" }, set: { settingsModel.patternTypeToEdit?.name = $0 }))
                }
                Section {
                    Picker("Type", selection: .init(get: { settingsModel.patternTypeToEdit?.type ?? .fixed }, set: { settingsModel.patternTypeToEdit?.type = $0 })) {
                        Text("Date").tag(ImportPatternType.FieldType.date)
                        Text("Currency").tag(ImportPatternType.FieldType.currency)
                        Text("Fixed").tag(ImportPatternType.FieldType.fixed)
                        Text("Variable").tag(ImportPatternType.FieldType.variable)
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    TextField("Options", text: .init(get: { settingsModel.patternTypeToEdit?.options ?? "" }, set: { settingsModel.patternTypeToEdit?.options = $0.isEmpty ? nil : $0 }))
                }
                Section {
                    TextField("Description", text: .init(get: { settingsModel.patternTypeToEdit?.description ?? "" }, set: { settingsModel.patternTypeToEdit?.description = $0.isEmpty ? nil : $0 }))
                }
            }
            HStack {
                Button(action: {
                    savePatternType()
                    dismiss()
                }) {
                    Text("Save")
                }
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                }
            }
        }
        .onAppear {
            if settingsModel.patternTypeToEdit == nil {
                settingsModel.patternTypeToEdit = ImportPatternType(name: "New Pattern", type: .fixed, options: nil, description: nil)
                settingsModel.importPatternTypes.append(settingsModel.patternTypeToEdit!)
            }
        }
    }
    
    private func savePatternType() {
        if let patternTypeToEdit = settingsModel.patternTypeToEdit,
           let index = settingsModel.importPatternTypes.firstIndex(where: { $0.id == patternTypeToEdit.id }) {
            settingsModel.importPatternTypes[index] = patternTypeToEdit
        }
        settingsModel.hasUnsavedChanges = true
    }
}

/*





















/*

















//
//  DataImportEditor.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/22/26.
//

import SwiftUI

struct DataImportEditor: View {
    @Environment(PraxModel.self) private var prax
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: String?
    @State private var hoveredButton: Int?

    @State private var pastedText = ""
    @State private var analysisResult: AnalysisResult?
    @State private var templateName = ""
    
    @AppStorage("savedTemplates") private var savedTemplatesData: Data = Data()
    
    private let analyzer = TemplateAnalyzer()
    
    var body: some View {
        @Bindable var prax = prax
             
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
                        .buttonStyle(ItemButtonStyle(isHovering: hoveredButton == 161))
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
                    .scrollContentBackground(.hidden)
                    .background(Color.blue)
                    .border(.cyan, width: 10)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .contentMargins(.all, 20, for: .scrollContent)
                    
                }
                
                Divider()
                
                GroupBox {
                    
                    // Button to start pattern analysis
                    HStack {
                        Button("Analyze Pattern") {
                            let lines = pastedText.components(separatedBy: .newlines)
                            analysisResult = analyzer.analyze(lines: lines)
                        }
                        .disabled(pastedText.isEmpty)
                        
                        if let result = analysisResult {
                            Text("Method: \(result.method.rawValue)")
                                .foregroundStyle(.secondary)
                            Text(String(format: "Confidence: %.0f%%", result.confidence * 100))
                                .foregroundStyle(.secondary)
                            if !result.mismatchedLines.isEmpty {
                                Text("\(result.mismatchedLines.count) mismatched")
                                    .foregroundStyle(.orange)
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 4)
                    
                    // Display template segments
                    if let result = analysisResult {
                        VStack(alignment: .leading, spacing: 8) {
                            
                            // Show the discovered template pattern
                            Text("Template Pattern:").font(.headline)
                            HStack(spacing: 0) {
                                ForEach(Array(result.segments.enumerated()), id: \.offset) { _, segment in
                                    switch segment {
                                    case .literal(let text):
                                        Text(text)
                                            .foregroundStyle(.secondary)
                                            .background(Color.gray.opacity(0.2))
                                    case .field(let idx):
                                        Text("⟨Field \(idx)⟩")
                                            .foregroundStyle(.blue)
                                            .bold()
                                    }
                                }
                            }
                            .padding(6)
                            .background(RoundedRectangle(cornerRadius: 4).stroke(.separator))
                            
                            Divider()
                            
                            // Display list of fields found
                            Text("Fields Found:").font(.headline)
                            ForEach(result.fieldProfiles) { profile in
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text("Field \(profile.index)")
                                            .bold()
                                        if let pattern = profile.inferredPattern {
                                            Text(pattern)
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundStyle(.green)
                                        }
                                        if profile.fixedWidth {
                                            Text("fixed-width: \(profile.widthRange.lowerBound)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        } else {
                                            Text("width: \(profile.widthRange.lowerBound)–\(profile.widthRange.upperBound)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    // Show up to 3 sample values
                                    Text(profile.samples.prefix(3).joined(separator: " · "))
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                .padding(.leading, 8)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("Paste text above, then click Analyze Pattern.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    Divider()
                    
                    // Template name and save button
                    HStack {
                        TextField("Template name", text: $templateName)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 250)
                        
                        Button("Save Template") {
                            saveTemplate()
                        }
                        .disabled(templateName.isEmpty || analysisResult == nil)
                        
                        Spacer()
                    }
                }
                
            }
            .frame(minWidth: 500, maxWidth: 1000, minHeight: 600, maxHeight: 1200, alignment: .topLeading)
        
     }
    
    // MARK: - Save
    
    private func saveTemplate() {
        guard let result = analysisResult else { return }
        
        var saved = loadSavedTemplates()
        let entry = SavedTemplate(name: templateName, result: result)
        saved.append(entry)
        
        if let encoded = try? JSONEncoder().encode(saved) {
            savedTemplatesData = encoded
        }
        
        templateName = ""
    }
    
    private func loadSavedTemplates() -> [SavedTemplate] {
        guard !savedTemplatesData.isEmpty,
              let decoded = try? JSONDecoder().decode([SavedTemplate].self, from: savedTemplatesData)
        else { return [] }
        return decoded
    }
}

// MARK: - Saved Template Model

struct SavedTemplate: Codable, Identifiable {
    let id: UUID
    let name: String
    let result: AnalysisResult
    
    init(name: String, result: AnalysisResult) {
        self.id = UUID()
        self.name = name
        self.result = result
    }
}


 */*/*/
