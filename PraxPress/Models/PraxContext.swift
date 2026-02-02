//
//  PraxContext.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/24/26.
//


import SwiftUI
import Combine
import PDFKit

@Observable
class PraxContext {
    
//    @AppStorage("selectedSettingsTab") var selectedSettingsTab: SettingsTab = .general
//    @ObservationIgnored @AppStorage("export.filename.prefix") var appStorageExportFilenamePrefix = ""


    var selectedAnimalCategoryName: String?
    var columnVisibility: NavigationSplitViewVisibility
    
    var sidebarTitle = "Categories"
    
    var contentListTitle: String {
        if let selectedAnimalCategoryName {
            selectedAnimalCategoryName
        } else {
            ""
        }
    }
    
    init(selectedAnimalCategoryName: String? = nil,
         columnVisibility: NavigationSplitViewVisibility = .automatic) {
        self.selectedAnimalCategoryName = selectedAnimalCategoryName
        self.columnVisibility = columnVisibility
    }
    
    var optionKeyPressed = false
}

