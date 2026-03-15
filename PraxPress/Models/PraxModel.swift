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

import SwiftData
//@Model
@Observable
final class PraxModel {
    
    // Non-optional reference to the document; attached after both are created.
    unowned private(set) var documment: MergedPDFDocument!

    init() {
        // Document will be attached immediately after both instances are created.
        // We keep it implicitly unwrapped to avoid unsafe placeholders while still
        // making it non-optional for consumers once attached.
    }

    func attach(document: MergedPDFDocument) {
        self.documment = document
    }

    enum PraxPressMode: String, CaseIterable {
        case data = "Data Mode"
        case merge = "Merge Mode"
        case prax = "Prax Mode"
        
        var color: Color {
            switch self {
            case .merge:
                return .pink
            case .data:
                return .blue
            case .prax:
                return .orange
            }
        }
        
        // And an icon, because why not?
        var icon: String {
            switch self {
            case .merge:
                return "apple.logo"
            case .data:
                return "swift"
            case .prax:
                return "gear"
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
    
    
    var selectedFiles = Set<PDFFile.ID>() {
        didSet {
            print ("PraxModel - MergedPDFDocument selectedFiles didSet: ", selectedFiles.count) //, selectedFiles.description)
            //         isLoadingPDF = true
            //            selectedPageItems = []
            //           clearWidthGuide()
            
            
/*            DispatchQueue.main.async {
                print ("Dispatch setEditingPDFDocumentFromSelectedFiles()")
                       self.setPageSectionsFromSelectedFiles()
                       self.refreshMergedDocument()
            }
    */    }
    }

    var selectedSections: Set<Int> = [] { didSet {
        print("PraxModel - electedSections didSet:  ", selectedSections)
    //    selectedSections.forEach {
    //        print("\($0)") }
    }}
    
    var selectedPageItems: Set<IndexPath> = [] { didSet {
        print("PraxModel - selectedPageItems didSet:  ", selectedPageItems)
    //    selectedPageItems.forEach {
    //        print("\($0)") }
    }}
    
    var selectedPages: Set<IndexPath> = [] { didSet {
        print("PraxModel - selectedPages didSet:  ", selectedPages)
    //          selectedPages.forEach {
    //              print("\($0)") }}
    }}

 
}

