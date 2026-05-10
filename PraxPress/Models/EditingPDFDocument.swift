//
//  EditingPDFDocument.swift
//  PraxPress
//
//  Created by Elmer Cat on 4/26/26.
//

import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers
import Foundation



@Observable @MainActor class EditingPDFDocument: PDFDocument {
    
    
    unowned let prax: PraxModel
    
    init(prax: PraxModel) {
        self.prax = prax
        super.init()
    }
    
    private var _mergedPage: MergedPage?
    var mergedPage: MergedPage? {
        get { _mergedPage }
        set {
            if _mergedPage != newValue {
                _mergedPage = newValue
            }
            
        }
    }
    var pageItems: [PageItem] {
        get {
            var items: [PageItem] = []
            if let mergedPage {
                for pageItem in mergedPage.pageItems {
                    if !pageItem.skipped {
                        items.append(pageItem)
                    }
                }

            }
            return items
        }
    }
    
    func pageItem(for pdfPage: PDFPage) -> PageItem? {
        
        return nil
    }
    
    
}
