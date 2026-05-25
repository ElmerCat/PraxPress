//
//  SetttingsModel.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/25/26.
//


//  PraxModel.swift

import SwiftUI

@Observable

final class SetttingsModel {
    
    var undoManager = UndoManager()
    var optionKeyPressed = false
    var hasUnsavedChanges = false
    var showUnsavedChangesAlert = false
    
    var patternTypeToEdit: ImportPatternType?
    
    var importPatternTypes: [ImportPatternType] = []
    var selectedPatternType: ImportPatternType?
    var selected​Pattern​Type​ID: UUID?
}



struct ImportPatternType: Identifiable {
    enum FieldType { case date, currency, fixed, variable }
    let id = UUID()
    var name = "New Pattern Type"
    var type: FieldType
    var options: String?
    var description: String?
}

