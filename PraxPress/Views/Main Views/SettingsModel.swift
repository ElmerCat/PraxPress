//
//  SettingsModel.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/25/26.
//

//  PraxModel.swift

import SwiftUI

protocol ImportPatternTypeDelegate: AnyObject {
    func importPatternTypeDidChange(_ patternType: ImportPatternType, property: String, oldValue: Any?)
}
@Observable
final class SettingsModel: ImportPatternTypeDelegate {
    
    init() {
        _importFileCountLimit = Int(UserDefaults.standard.integer(forKey: "importFileCountLimit"))
        _savedTemplatesData = UserDefaults.standard.data(forKey: "savedTemplates") ?? Data()
    }
    
    private var _importFileCountLimit: Int
    var importFileCountLimit: Int {
        get { _importFileCountLimit }
        set {
            guard newValue != _importFileCountLimit else { return }
            _importFileCountLimit = newValue
            UserDefaults.standard.set(newValue, forKey: "importFileCountLimit") }
    }
    
    private var _savedTemplatesData: Data
    private var savedTemplatesData: Data {
        get {
            UserDefaults.standard.data(forKey: "savedTemplates") ?? Data()
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "savedTemplates")
        }
    }
    
    let undoManager = UndoManager()
    
    var optionKeyPressed = false
    var loadingPatterns = false

    var selected​Pattern​Type​ID: UUID?
     
    private var _importPatternTypes: [ImportPatternType] = []
    var importPatternTypes:  [ImportPatternType] {
        get { _importPatternTypes }
        set {
            guard newValue != _importPatternTypes else { return }
            
            
            if !loadingPatterns {
                let oldValue = importPatternTypes
                undoManager.registerUndo(withTarget: self, handler: {
                    $0.importPatternTypes = oldValue
                })
                undoManager.setActionName("Set Pattern Types")
            }
            _importPatternTypes = newValue
            newValue.forEach { $0.delegate = self }
        }
    }

    
    // Note: Changed selection from pattern object to selection by ID for clearer state management
    var selectedPatternType: ImportPatternType? {
        if let id = selected​Pattern​Type​ID {
            return importPatternTypes.first(where: { $0.id == id })
        }
        return nil
    }
    
    func deletePatternType(_ patternType: ImportPatternType) {
        if let index = importPatternTypes.firstIndex(where: { $0.id == patternType.id }) {
            importPatternTypes.remove(at: index)
            selected​Pattern​Type​ID = nil
        }
    }


    func savePatternTypes() {
        // Save the ImportPatternType records to AppStorage
        do {
            let data = try JSONEncoder().encode(importPatternTypes)
            savedTemplatesData = data
       } catch {
            print("Error saving pattern types: \(error)")
        }
    }


    
    func loadPatternTypes() {
        loadingPatterns = true
        // Load the ImportPatternType records from AppStorage
        do {
            let data = savedTemplatesData
            importPatternTypes = try JSONDecoder().decode([ImportPatternType].self, from: data)
            importPatternTypes.forEach { $0.delegate = self }
        } catch {
            print("Error loading pattern types: \(error)")
            importPatternTypes = []
        }
        loadingPatterns = false
       
    }
    
    func importPatternTypeDidChange(_ patternType: ImportPatternType, property: String, oldValue: Any?) {
        if !loadingPatterns {
            undoManager.registerUndo(withTarget: patternType) { target in
                switch property {
                case "name":
                    if let old = oldValue as? String { target.name = old }
                case "type":
                    if let old = oldValue as? ImportPatternType.FieldType { target.type = old }
                case "options":
                    if let old = oldValue as? String? { target.options = old }
                case "description":
                    if let old = oldValue as? String? { target.description = old }
                default:
                    break
                }
            }
            undoManager.setActionName("Edit Pattern Type")
            savePatternTypes()
            
        }
    }
}



@Observable
final class ImportPatternType: Identifiable {
    enum FieldType { case date, currency, fixed, variable }
    let id: UUID
    weak var delegate: ImportPatternTypeDelegate?

    var name: String { didSet { delegate?.importPatternTypeDidChange(self, property: "name", oldValue: oldValue) } }
    var type: FieldType { didSet { delegate?.importPatternTypeDidChange(self, property: "type", oldValue: oldValue) } }
    var options: String? { didSet { delegate?.importPatternTypeDidChange(self, property: "options", oldValue: oldValue) } }
    var description: String? { didSet { delegate?.importPatternTypeDidChange(self, property: "description", oldValue: oldValue) } }

    init(
        id: UUID = UUID(),
        name: String = "New Pattern Type",
        type: FieldType,
        options: String? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.options = options
        self.description = description
    }
    
    required init(from decoder: Decoder) throws {
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
        id = UUID() // Or decode if you store it
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

