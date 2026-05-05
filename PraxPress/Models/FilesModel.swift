//
//  FilesModel.swift
//  PraxPress
//
//  Created by Elmer Cat on 1/26/26.
//

// Model objects: PDFFile & PDFFileGroup
//   and
// FilesPersistenceController


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

struct PDFFilePayload: Codable {
    let fileURL: URL
    let bookmarkData: Data
}

enum PDFFileStatus: String, Codable {
    case okay
    case stale
    case bad
}


struct PDFFileTransfer: Transferable, Identifiable, @unchecked Sendable {
    let id = UUID()
    let pdfFile: PDFFile

    struct Payload: Codable {
        let fileURL: URL
        let bookmarkData: Data
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .pdfFileType) { item in
            // Encode a small payload containing the file's name and bookmark data
            let payload = Payload(fileURL: item.pdfFile.url, bookmarkData: item.pdfFile.bookmarkData)
            return try JSONEncoder().encode(payload)
        } importing: { data in
            // Decode the payload and reconstruct a minimal PDFFile via its bookmark
            let payload = try JSONDecoder().decode(Payload.self, from: data)
            // Resolve the URL from the bookmark to rebuild a PDFFile
            var isStale = false
            let url = try URL(resolvingBookmarkData: payload.bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            // Create a placeholder PDFFile; callers can insert into model context as needed
            let fileGroup = PDFFileGroup(name: "Imported")
            let pdfFile = PDFFile(fileGroup: fileGroup, url: url, bookmarkData: payload.bookmarkData, pageCount: 0)
            return PDFFileTransfer(pdfFile: pdfFile)
        }
        
        // Add a standard file URL representation for maximum compatibility
        DataRepresentation(contentType: .fileURL) { item in
            item.pdfFile.url.absoluteString.data(using: .utf8)!
        } importing: { data in
            guard let urlString = String(data: data, encoding: .utf8),
                  let url = URL(string: urlString) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            // You may need to resolve the URL with a default bookmark data here, if desired.
            let fileGroup = PDFFileGroup(name: "Imported")
            let pdfFile = PDFFile(fileGroup: fileGroup, url: url, bookmarkData: Data(), pageCount: 0)
            return PDFFileTransfer(pdfFile: pdfFile)
        }
    }
}


@Model
final class PDFFile {
    
    static let defaultFieldNames = ["Date", "PcardHolderName", "DocumentNumber", "Amount", "Vendor", "GLAccount", "CostObject", "Description"]
    
    var id: UUID
    var url: URL
    var bookmarkData: Data
    var fileName: String
    var pageCount: Int
    var fileGroup: PDFFileGroup
    // Persisted as Data
    var dataFieldsData: Data?
    var status = PDFFileStatus.bad
    
    init(fileGroup: PDFFileGroup, url: URL, bookmarkData: Data, pageCount: Int, dataFields: [String: FieldValue]? = nil) {
        self.id = UUID()
        self.fileGroup = fileGroup
        self.url = url
        self.bookmarkData = bookmarkData
        self.fileName = url.lastPathComponent
        self.pageCount = pageCount
        if let dict = dataFields {
            self.dataFieldsData = encodeFlexibleFields(FlexibleFields(storage: dict))
        } else {
            self.dataFieldsData = nil
        }
        
    }
    
    // A convenient computed property that callers can work with
    var dataFields: [String: FieldValue]? {
        get {
            guard let data = dataFieldsData else { return nil }
            return decodeFlexibleFields(from: data)?.storage
        }
        set {
            if let dict = newValue {
                dataFieldsData = encodeFlexibleFields(FlexibleFields(storage: dict))
            } else {
                dataFieldsData = nil
            }
        }
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



@Model
final class PDFFileGroup {
    @Attribute(.unique) var name: String
    @Relationship(deleteRule: .cascade, inverse: \PDFFile.fileGroup)
     var pdfFiles: [PDFFile] = []
    
    init(name: String) {
        self.name = name
    }
}


@ModelActor
actor FilesPersistenceController: Observable {
    private let DEBUG_LOGS = true
    
    func pdfFiles() -> [PDFFile] {
        do {
            return try modelContext.fetch(FetchDescriptor<PDFFile>())
        } catch {
            print("Failed to load pdfFiles: \(error)")
            return []
        }
    }

    
    func processImportedURLs(_ urls: [URL]) async throws {
        
        var pdfFiles: [PDFFile] = []
        do {
            pdfFiles = try modelContext.fetch(FetchDescriptor<PDFFile>())
        } catch {
            print("Failed to load pdfFiles: \(error)")
            throw (error)
        }
        

        var expanded: [(url: URL, bookmark: Data)] = []
        
        for url in urls {
            let needsStop = url.startAccessingSecurityScopedResource()
            defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
            
            do {
                let values = try url.resourceValues(forKeys: [.isDirectoryKey])
                if values.isDirectory == true {
                    let discovered = filesRecursively(in: url)
                    for fileURL in discovered {
                        guard isPDF(fileURL) else { continue }
                        if let data = try? fileURL.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
                            expanded.append((url: fileURL, bookmark: data))
                        }
                    }
                } else {
                    if isPDF(url), let data = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
                        expanded.append((url: url, bookmark: data))
                    }
                }
            } catch {
                if isPDF(url), let data = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
                    expanded.append((url: url, bookmark: data))
                }
            }
        }
        var seen = Set<URL>(pdfFiles.map { $0.url })
        
        
        let uniquePairs: [(url: URL, bookmark: Data)] = expanded.filter { pair in
            seen.insert(pair.url).inserted
        }
        
        do {
            for urlBookmark in uniquePairs {
                
                
                guard let pdfFile = try await newPDFFileFromURLBookmark(url: urlBookmark.url, bookmarkData: urlBookmark.bookmark) else {
                    print("Failed newPDFFileFromURLBookmark(url: ", urlBookmark.url)
                    continue
                }
                
              
                
                
                
        //        pdfFile.dataFields = pdfFile.dataFieldsFromEntry(entry)
                modelContext.insert(pdfFile)
                
                try modelContext.save()
            }
            
        }
        catch {
            print("Error adding newPDFFileFromURLBookmark urls: ", urls)
        }
 
        
        
        
        func filesRecursively(in folderURL: URL) -> [URL] {
            var collected: [URL] = []
            let fm = FileManager.default
            if let enumerator = fm.enumerator(at: folderURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                for case let item as URL in enumerator {
                    do {
                        let resourceValues = try item.resourceValues(forKeys: [.isDirectoryKey])
                        if resourceValues.isDirectory == true {
                            continue
                        } else {
                            if DEBUG_LOGS { print("Discovered file in folder: \(item.path)") }
                            collected.append(item)
                        }
                    } catch {
                        continue
                    }
                }
            }
            return collected
        }
        
    }

    func newPDFFileFromURLBookmark(url: URL, bookmarkData: Data) async throws -> PDFFile? {
        
    var isStale = false
    guard let resolvedURL = try? URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) else {
        print("newPDFFileFromURLBookmark - Failed to resolve bookmark for url: ", url)
        return nil
    }
    
    let needsStop = resolvedURL.startAccessingSecurityScopedResource()
    defer { if needsStop { resolvedURL.stopAccessingSecurityScopedResource() } }
    
    print("\n--- Parsing PDF: \(resolvedURL.absoluteString) ---")
    guard let pdfDocument = PDFDocument(url: resolvedURL) else {
        print("Failed to open PDF: \(resolvedURL.path)")
        return nil
    }
    print("Opened PDF. Page count: \(pdfDocument.pageCount)")
    
        let predicate = #Predicate<PDFFile> { $0.url == url }
        var descriptor = FetchDescriptor<PDFFile>(predicate: predicate)
        descriptor.fetchLimit = 1
        do {
            let existing = try modelContext.fetch(descriptor)
                if !existing.isEmpty {
                    print("newPDFFileFromURLBookmark - PDFFile already exists with same url: ", url)
                    return nil
                }
        }
        catch {
            print("newPDFFileFromURLBookmark - failed fetch for existing url: ", url)
            return nil
        }
        
        do {
            let mainFileGroup = try await pdfFileGroup("Main File Group")
            
            
           let pdfFile = PDFFile(fileGroup: mainFileGroup, url: url, bookmarkData: bookmarkData, pageCount: pdfDocument.pageCount)
            
            var dataFields: [String: FieldValue] = [:]
            let fieldNames = PDFFile.defaultFieldNames
            
            func value(from annot: PDFAnnotation) -> String? {
                if let v = annot.widgetStringValue, !v.isEmpty { return v }
                if let v = annot.contents, !v.isEmpty { return v }
                return nil
            }
            
            for pageIndex in 0..<pdfDocument.pageCount {
                guard let page = pdfDocument.page(at: pageIndex) else { continue }
                if DEBUG_LOGS { print("Page #\(pageIndex + 1): annotations=\(page.annotations.count)") }
                for annot in page.annotations {
                    let key = annot.fieldName ?? ""
                    if key.isEmpty { continue }
                    let widgetType = String(describing: annot.widgetFieldType)
                    let extracted = value(from: annot) ?? "(nil)"
                    if DEBUG_LOGS { print("  Annotation field=\(key) type=\(widgetType) value=\(extracted)") }
                    
                    if let v = value(from: annot), !(v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                        if fieldNames.contains(key) {
                            dataFields[key] = .string(v)
                        }
                    }
                }
            }
            pdfFile.dataFields = dataFields
            return pdfFile
        }
        catch {
            print("newPDFFileFromURLBookmark - failed pdfFileGroup(\"Main File Group\")")
            return nil
        }

}

    func pdfFileGroup(_ name: String) async throws -> PDFFileGroup {
        // Try fetch by name
        let predicate = #Predicate<PDFFileGroup> { $0.name == name }
        var descriptor = FetchDescriptor<PDFFileGroup>(predicate: predicate)
        descriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        // Create if missing
        let group = PDFFileGroup(name: name)
        modelContext.insert(group)
        try modelContext.save()
        return group
    }
    
    func deletePDFFiles(_ ids: Set<UUID>) throws {
        print("deletePDFFiles(_ ids: ", ids)
        guard !ids.isEmpty else { return }
        // Build a predicate that matches any of the provided IDs
        let predicate = #Predicate<PDFFile> { pdfFile in
            ids.contains(pdfFile.id)
        }
        var descriptor = FetchDescriptor<PDFFile>(predicate: predicate)
        descriptor.fetchLimit = nil // fetch all matches
        
        let pdfFiles = try modelContext.fetch(descriptor)
        for pdfFile in pdfFiles {
            modelContext.delete(pdfFile)
        }
        try modelContext.save()
    }
    


    func praxTest() {
        
        print("Actor modelContext:", ObjectIdentifier(modelContext))
        
        let fetchDescriptor = FetchDescriptor<PDFFile>()

        do {
            let pdfFiles = try modelContext.fetch(fetchDescriptor)

            for pdfFile in pdfFiles {
                print("Found \(pdfFile.fileName)")
            }
        } catch {
            print("Failed to load model.")
        }
 
    }
        
   
    func isPDF(_ url: URL) -> Bool {
        if let type = UTType(filenameExtension: url.pathExtension) {
            return type.conforms(to: .pdf)
        }
        return url.pathExtension.lowercased() == "pdf"
    }

    
}
