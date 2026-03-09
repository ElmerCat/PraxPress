//  PraxModel.swift
//  PraxPress - Prax=0104-1
//

import Foundation
import CoreGraphics
import PDFKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

//import Combine

extension PDFDisplayMode {
    var color: Color {
        switch self {
            
        case .singlePage: return .pink
        case .singlePageContinuous: return .blue
        case .twoUp: return .orange
        case .twoUpContinuous: return .yellow
        default: return .black
        }
    }
    
    var icon: String {
        switch self {
        case .singlePage: return "inset.filled.center.rectangle.portrait"
        case .singlePageContinuous: return "inset.filled.center.rectangle.portrait"
        case .twoUp: return "inset.filled.center.rectangle.portrait"
        case .twoUpContinuous: return "inset.filled.center.rectangle.portrait"
        default: return "inset.filled.center.rectangle.portrait"
         }
    }
    
}

//@Model
@Observable
final class PraxModel {
    var documment: MergedPDFDocument?

    enum PraxPressMode: String, CaseIterable {
        case data = "Data Mode"
        case merge = "Merge Mode"
        
        var color: Color {
            switch self {
            case .merge:
                return .pink
            case .data:
                return .blue
            }
        }
        
        // And an icon, because why not?
        var icon: String {
            switch self {
            case .merge:
                return "apple.logo"
            case .data:
                return "swift"
             }
        }
    }
    var praxPressMode: PraxPressMode = .merge
    
    var dropTargeted = false
    var optionKeyPressed = false
    
    var saveError: String?

    var isOn = false
    var isLarge: Bool = false
    var showFilesPanel = true
    var showingFileImportOptions: Bool = false
    var showingFileExportOptions: Bool = false
    var showingMergedDocumentInspector = false
    var showingPDFPageItemInspector = false
    var showingImporter: Bool = false
    var showingFileImporter: Bool = false
    var showingExportFolderSelector: Bool = false
    var isShowingInspector: Bool = false
    var showSavePanel: Bool = false
    var columnVisibility: NavigationSplitViewVisibility = .all
 
}

