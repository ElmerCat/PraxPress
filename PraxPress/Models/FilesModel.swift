//
//  FilesModel.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/26/26.
//

// Model objects: SourceFile & SourceFileGroup
//   and
// PersistenceController


import Foundation
import SwiftData
import SwiftUI
import PDFKit
import UniformTypeIdentifiers

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

enum SourceFileStatus: String, Codable {
    case okay
    case stale
    case bad
}

enum SourceFileType: String, Codable, Hashable, Comparable {
    static func < (lhs: SourceFileType, rhs: SourceFileType) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    
    case pdf = "pdf"
    case image = "image"
    case text = "text"
    case other = "other"
}



@Model
final class SourceFile {
    
    static let defaultFieldNames = ["Date", "PcardHolderName", "DocumentNumber", "Amount", "Vendor", "GLAccount", "CostObject", "Description"]
    
    static func dataFieldsFromPDFDocument(_ pdfDocument: PDFDocument) -> [String: FieldValue] {
        var dataFields: [String: FieldValue] = [:]
        let fieldNames = SourceFile.defaultFieldNames
        
        func value(from annot: PDFAnnotation) -> String? {
            if let v = annot.widgetStringValue, !v.isEmpty { return v }
            if let v = annot.contents, !v.isEmpty { return v }
            return nil
        }
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            print("Page #\(pageIndex + 1): annotations=\(page.annotations.count)")
            for annot in page.annotations {
                let key = annot.fieldName ?? ""
                if key.isEmpty { continue }
                let widgetType = String(describing: annot.widgetFieldType)
                let extracted = value(from: annot) ?? "(nil)"
                print("  Annotation field=\(key) type=\(widgetType) value=\(extracted)")
                
                if let v = value(from: annot), !(v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    if fieldNames.contains(key) {
                        dataFields[key] = .string(v)
                    }
                }
            }
        }
        return dataFields
    }
    
    var id: UUID
    var url: URL
    var bookmarkData: Data
    var fileName: String
    var pageCount: Int
    var fileType: SourceFileType
    var fileSize: Int
    var fileGroup: SourceFileGroup
    // Persisted as Data
    var imageOptionsData: Data?
    var dataFieldsData: Data?
    var status = SourceFileStatus.okay
    
    init(fileGroup: SourceFileGroup, url: URL, bookmarkData: Data, pageCount: Int, fileType: SourceFileType, fileSize: Int, imageOptions: ImageImportOptions? = nil, dataFields: [String: FieldValue]? = nil) {
        self.id = UUID()
        self.fileGroup = fileGroup
        self.url = url
        self.bookmarkData = bookmarkData
        self.fileName = url.lastPathComponent
        self.pageCount = pageCount
        self.fileType = fileType
        self.fileSize = fileSize
        if let dict = dataFields {
            self.dataFieldsData = encodeFlexibleFields(FlexibleFields(storage: dict)) } else {
            self.dataFieldsData = nil }
        
    }
    
    var imageOptions: ImageImportOptions? {
        get { guard let data = imageOptionsData else { return nil }; do {
            let options = try JSONDecoder().decode(ImageImportOptions.self, from: data)
            return options }
            catch { return nil } }
        set { if let options = newValue {
            if let data = try? JSONEncoder().encode(options) { imageOptionsData = data }
            else { imageOptionsData = nil } }
        }
    }
    
    var dataFields: [String: FieldValue]? {
        get {guard let data = dataFieldsData else { return nil }
            return decodeFlexibleFields(from: data)?.storage}
        set { if let dict = newValue {
            dataFieldsData = encodeFlexibleFields(FlexibleFields(storage: dict)) }
            else { dataFieldsData = nil } }
    }
    
    func testBookmark() {
        var isStale = false
        
        if let testURL = try? URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) {
            if testURL.absoluteString.contains("/.Trash/") || testURL.absoluteString.contains("/.Trashes/") {
                print(testURL, " - BookmarkData for URL: ", url, " - File is in Trash ***")
                status = .bad
            }
            else if isStale {
                print("BookmarkData for URL: ", url, " - File is Stale ***")
                
      //          refreshBookmark()
                status = .stale
            }
            else {
                print("Resolved BookmarkData for URL: ", url)
                status = .okay
            }
        }
  
        else {
            print("Unable to resolve bookmarkData for URL: ", url, " isStale: ", isStale)
            status = .bad

        }
        
    }
    
    func refreshBookmark() {
        let needsStop = url.startAccessingSecurityScopedResource()
        defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
        if let data = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
            bookmarkData = data
            status = .okay
        }
        else {
            status = .bad
        }
    }
}

struct SourceFileTransfer: Transferable, Identifiable, @unchecked Sendable {
    let id = UUID()
    let sourceFile: SourceFile
    
     struct Payload: Codable {
        let fileURL: URL
        let bookmarkData: Data
        let fileType: SourceFileType
        var fileSize: Int
        let imageOptions: ImageImportOptions?
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .sourceFileType) { item in
            // Encode a small payload containing the file's name and bookmark data
            
            let payload = Payload(
                fileURL: item.sourceFile.url,
                bookmarkData: item.sourceFile.bookmarkData,
                fileType: item.sourceFile.fileType,
                fileSize: item.sourceFile.fileSize,
                imageOptions: item.sourceFile.imageOptions
            )
            return try JSONEncoder().encode(payload)
        } importing: { data in
            // Decode the payload and reconstruct a minimal SourceFile via its bookmark
            let payload = try JSONDecoder().decode(Payload.self, from: data)
            // Resolve the URL from the bookmark to rebuild a SourceFile
   //         var isStale = false
   //         let url = try URL(resolvingBookmarkData: payload.bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
     //       var options: [String:FieldValue]?
            
            
            let fileGroup = SourceFileGroup(name: "Imported")
            let sourceFile = SourceFile(fileGroup: fileGroup, url: payload.fileURL, bookmarkData: payload.bookmarkData, pageCount: 0, fileType: payload.fileType, fileSize: payload.fileSize, imageOptions: payload.imageOptions)
            return SourceFileTransfer(sourceFile: sourceFile)
        }
    }
}



@Model
final class SourceFileGroup {
    @Attribute(.unique) var name: String
    @Relationship(deleteRule: .cascade, inverse: \SourceFile.fileGroup)
    var sourceFiles: [SourceFile] = []
    var fileTypes: [SourceFileType] = []
    
    init(name: String) {
        self.name = name
    }
}

