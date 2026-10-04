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

enum SourceFileStatus: String, Codable, Hashable, Comparable {
    static func < (lhs: SourceFileStatus, rhs: SourceFileStatus) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    
    case okay = "Source Files"
    case trashed = "Files in the Trash"
    case bad = "Files that can't be found"
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
    
    var id: UUID
    var url: URL
    var bookmarkData: Data
    var fileName: String
    var pageCount: Int
    var fileType: SourceFileType
    var fileSize: Int
    var fileGroup: SourceFileGroup
    var imageOptionsData: Data?
    var dataFieldsData: Data?
    var status: SourceFileStatus = SourceFileStatus.okay
    var isLibraryFile: Bool = false
    
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
            //     print("Page #\(pageIndex + 1): annotations=\(page.annotations.count)")
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
    
    
    
    func testBookmark() {
        var isStale = false
        
        if let testURL = try? URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) {
            if testURL.absoluteString.contains("/.Trash/") || testURL.absoluteString.contains("/.Trashes/") {
                print(testURL, " - BookmarkData for URL: ", url, " - File is in Trash ***")
                status = .trashed
            }
            else if isStale {
                print("BookmarkData for URL: ", url, " - File is Stale *** \n", testURL, "\n")
                
                refreshBookmark(testURL)
               
            }
            else {
            //    print("Resolved BookmarkData for URL: ", url)
                status = .okay
            }
        }
  
        else {
            print("Unable to resolve bookmarkData for URL: ", url, " isStale: ", isStale)
            status = .bad

        }
        
    }
    
    func refreshBookmark(_ url: URL) {
        let needsStop = url.startAccessingSecurityScopedResource()
        defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
        if let data = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
            self.url = url
            bookmarkData = data
            status = .okay
        }
        else {
            status = .bad
        }
    }
    
    func displayValue(for key: String) -> String {
        guard let fields = dataFields else {return "No Data Fields"}
        guard let field = fields[key] else { return "No Field: " + key }
        
        //    print (field)
        
        if let s = field.stringValue { return s }
        if let i = field.intValue { return String(i) }
        if let d = field.doubleValue { return String(d) }
        if let b = field.boolValue { return String(b) }
        if let date = field.dateValue {
            return ISO8601DateFormatter().string(from: date)
        }
        return "No Data: " + key
    }

    
}

extension NSPasteboard.PasteboardType {
    static let pageItemType = NSPasteboard.PasteboardType("com.praxpress.page-item")
    static let mergedPageType = NSPasteboard.PasteboardType("com.praxpress.pdf-page-section")
    static let sourceFileType = NSPasteboard.PasteboardType("com.praxpress.source-file-item")
}

extension UTType {
    static let pageItemType = UTType(exportedAs: "com.praxpress.page-item")
    static let mergedPageType = UTType(exportedAs: "com.praxpress.pdf-page-section")
    static let sourceFileType = UTType(exportedAs: "com.praxpress.source-file-item")
}

extension UUID: @retroactive Transferable, @retroactive Identifiable {
    public var id: UUID { self }
    
    public static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.uuidString)
    }
}



nonisolated struct SourceFilePayload: Codable {
    let id: UUID
    let fileURL: URL
    let bookmarkData: Data
    let fileType: SourceFileType
    var fileSize: Int
    var isLibraryFile: Bool
    let imageOptions: ImageImportOptions?
}

struct SourceFileTransfer: Transferable, Identifiable, @unchecked Sendable {
    let id = UUID()
    var sourceFile: SourceFile?
    var payload: SourceFilePayload
    
    init(payload: SourceFilePayload) {
        self.payload = payload
    }
    
    init(sourceFile: SourceFile) {
        self.payload = SourceFilePayload(
            id: sourceFile.id,
            fileURL: sourceFile.url,
            bookmarkData: sourceFile.bookmarkData,
            fileType: sourceFile.fileType,
            fileSize: sourceFile.fileSize,
            isLibraryFile: sourceFile.isLibraryFile,
            imageOptions: sourceFile.imageOptions
        )
    }

    static var transferRepresentation: some TransferRepresentation {
        
        DataRepresentation(contentType: .sourceFileType) { item in
            let payload = SourceFilePayload(
                id: item.payload.id,
                fileURL: item.payload.fileURL,
                bookmarkData: item.payload.bookmarkData,
                fileType: item.payload.fileType,
                fileSize: item.payload.fileSize,
                isLibraryFile: item.payload.isLibraryFile,
                imageOptions: item.payload.imageOptions)
            return try JSONEncoder().encode(payload) }
        importing: { data in
            let payload = try JSONDecoder().decode(SourceFilePayload.self, from: data)
            return SourceFileTransfer(payload: payload)
        }
        
        ProxyRepresentation(exporting: \.payload.fileURL.absoluteString)
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

