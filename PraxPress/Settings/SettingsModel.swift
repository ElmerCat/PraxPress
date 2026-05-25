//
//  SettingsModel.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/25/26.
//


//  PraxModel.swift

import SwiftUI

@Observable

final class SettingsModel {
    
    unowned private(set) var undoManager: UndoManager!
    func attach(undoManager: UndoManager) {
        
        self.undoManager = undoManager
    }

    var optionKeyPressed = false
    var loadingPatterns = false
    
  //  var hasUnsavedChanges = false
  //  var showUnsavedChangesAlert = false
    
    var patternTypeToEdit: ImportPatternType?
    
     
    private var _importPatternTypes: [ImportPatternType] = []
    var importPatternTypes:  [ImportPatternType] {
        get { _importPatternTypes }
        set {
            if _importPatternTypes == newValue { return }
            
            let oldValue = importPatternTypes
            undoManager.registerUndo(withTarget: self, handler: {
                $0.importPatternTypes = oldValue
            })
            _importPatternTypes = newValue
            undoManager.setActionName("Set Pattern Types")
            

        }
    }

    
    
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

