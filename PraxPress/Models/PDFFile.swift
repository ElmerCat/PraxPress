//
//  PDFFile.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/26/26.
//

/*
 See the LICENSE.txt file for this sample’s licensing information.
 
 Abstract:
 A model class that defines the properties of an animal.
 */

import Foundation
import SwiftData
import SwiftUI

struct PDFDataFields: Codable {
    var pcardHolderName: String?
    var documentNumber: String?
    var date: String?
    var amount: String?
    var vendor: String?
    var glAccount: String?
    var costObject: String?
    var justification: String?
}

@Model
final class PDFFile {
    var id: UUID
    var url: URL
    var bookmarkData: Data
    var fileName: String
    var pageCount: Int
    var fileGroup: PDFFileGroup
    var dataFields: PDFDataFields?
    
    init(fileGroup: PDFFileGroup, url: URL, bookmarkData: Data, pageCount: Int, dataFields: PDFDataFields? = nil) {
        self.id = UUID()
        self.fileGroup = fileGroup
        self.url = url
        self.bookmarkData = bookmarkData
        self.fileName = url.lastPathComponent
        self.pageCount = pageCount
        self.dataFields = dataFields
    }
    
    func dataFieldsFromEntry(_ entry: PDFEntry) -> PDFDataFields? {
        var dataFields = PDFDataFields()
        dataFields.pcardHolderName = entry.pcardHolderName
        dataFields.documentNumber = entry.documentNumber
        dataFields.date = entry.date
        dataFields.amount = entry.amount
        dataFields.vendor = entry.vendor
        dataFields.glAccount = entry.glAccount
        dataFields.costObject = entry.costObject
        dataFields.justification = entry.description
        return dataFields
    }
    

    
}



@Model
final class PDFFileGroup {
    @Attribute(.unique) var name: String
    @Relationship(deleteRule: .cascade, inverse: \PDFFile.fileGroup)
    
    
    var pdfFiles: [PDFFile] = []
    
    init(name: String) {
        self.name = name
    }
}

