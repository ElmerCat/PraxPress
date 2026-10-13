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




@Model
final class SourceFile {
    var bookmarkData: Data
    var addedDate: Date = Date()
    var lastModificationDate: Date = Date()
    var pageCount: Int
    var fileType: SourceFileType
    var fileGroup: SourceFileGroup
    var imageOptionsData: Data?
    var dataFieldsData: Data?
    var status: SourceFileStatus = SourceFileStatus.okay
    var isLibraryFile: Bool = false
    var exported: Bool = false
    
    @Attribute(.ephemeral) private var _URL: URL? = nil
    
    
    init(fileGroup: SourceFileGroup, bookmarkData: Data, pageCount: Int, fileType: SourceFileType, imageOptions: ImageImportOptions? = nil, dataFields: [String: FieldValue]? = nil) {
        self.fileGroup = fileGroup
        self.bookmarkData = bookmarkData
        self.pageCount = pageCount
        self.fileType = fileType
        if let dict = dataFields {
            self.dataFieldsData = encodeFlexibleFields(FlexibleFields(storage: dict)) } else {
                self.dataFieldsData = nil }
    }
    @Transient var fileAttributes: [FileAttributeKey: Any] = [:] { didSet {
        if lastModificationDate != modificationDate {
            PraxLogger.shared.logInfo("SourceFile was updated: \(url.lastPathComponent)", category: .general)
            lastModificationDate = modificationDate
        }
        
    }}
    @Attribute(.ephemeral) var transientPropertiesLoaded = false
}

extension SourceFile {
    
    var url: URL {
        get { if _URL == nil {
            var isStale = false
            guard let url = try? URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) else { _URL = URL(filePath: ""); status = .bad; return _URL! }
            
            if url.absoluteString.contains("/.Trash/") || url.absoluteString.contains("/.Trashes/") {
                PraxLogger.shared.logWarning("File is in the trash: \(url.lastPathComponent)", category: .bookmarks)
                status = .trashed }
            else if isStale  {
                PraxLogger.shared.logInfo("Stale file has been moved to: \(url.absoluteString)", category: .bookmarks)

                status = .okay }
            else { status = .okay }
            Task { do {
                fileAttributes = try await fileAttributesForBookmark(self.bookmarkData)
             //   print("fileAttributes:  ", fileAttributes)
                self.transientPropertiesLoaded = true
                await PraxLogger.shared.logInfo("Transient properties loaded for SourceFile: \(self.url.lastPathComponent)", category: .general)
            } catch { await PraxLogger.shared.logError("Unable to load file attributes", category: .import) } }
            
            
            _URL = url }
            
            
            return _URL! }
        set{  _URL = newValue } }
    
  
    var creationDate: Date { fileAttributes[.creationDate] as? Date ?? .distantPast }
    var modificationDate: Date { fileAttributes[.modificationDate] as? Date ?? .distantPast }
    
    var fileSize: Int { fileAttributes[.size] as? Int ?? 0 }
    
    
/*    func testBookmark() {
        var isStale = false
        if let testURL = try? URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) {
            if testURL.absoluteString.contains("/.Trash/") || testURL.absoluteString.contains("/.Trashes/") {
                PraxLogger.shared.logWarning("File is in the trash: \(url.lastPathComponent)", category: .bookmarks)
                status = .trashed }
            else if (testURL != url) || isStale  {
                PraxLogger.shared.logInfo("File: \(url.lastPathComponent) - was moved to: \(testURL.absoluteString)", category: .bookmarks)
                status = .okay }
            else {
                PraxLogger.shared.logInfo("File bookmark tested okay for: \(url.lastPathComponent)",category: .bookmarks)
                status = .okay } }
        else {
            PraxLogger.shared.logError("File cannot be found: \(url.lastPathComponent)", category: .bookmarks)
            status = .bad }
    }  */
    
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
    
    var fileName: String { url.lastPathComponent }
    
    
    
    
    
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
    let id: PersistentIdentifier
    let fileURL: URL
    let bookmarkData: Data
    let fileType: SourceFileType
    //  var fileSize: Int
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
            //      fileSize: sourceFile.fileSize,
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
                //            fileSize: item.payload.fileSize,
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




