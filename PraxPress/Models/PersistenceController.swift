//
//  PersistenceController.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/30/26.
//
import Foundation
import SwiftData
import SwiftUI
import PDFKit
import UniformTypeIdentifiers


@ModelActor
actor PersistenceController: Observable {
    
    var praxModel: PraxModel?
    var prax: PraxModel { praxModel! }
    func attach(prax: PraxModel) { self.praxModel = prax }
    
    func sourceFiles() -> [SourceFile] {
        do { return try modelContext.fetch(FetchDescriptor<SourceFile>()) }
        catch { print("Failed to load sourceFiles: \(error)"); return [] }
    }
    
    func sourceFileGroup(_ name: String) async throws -> SourceFileGroup {  // Try fetch by name
        let predicate = #Predicate<SourceFileGroup> { $0.name == name }
        var descriptor = FetchDescriptor<SourceFileGroup>(predicate: predicate)
        descriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(descriptor).first { return existing }
        // Create if missing
        let group = SourceFileGroup(name: name)
        modelContext.insert(group)
        try modelContext.save()
        return group
    }
    
    func deleteSourceFiles(_ ids: Set<UUID>) throws {
        print("deleteSourceFiles(_ ids: ", ids)
        guard !ids.isEmpty else { return }
        // Build a predicate that matches any of the provided IDs
        let predicate = #Predicate<SourceFile> { sourceFile in  ids.contains(sourceFile.id) }
        var descriptor = FetchDescriptor<SourceFile>(predicate: predicate)
        descriptor.fetchLimit = nil // fetch all matches
        
        let sourceFiles = try modelContext.fetch(descriptor)
        for sourceFile in sourceFiles {
            modelContext.delete(sourceFile)
        }
        try modelContext.save()
    }
    
 
 
    var importFileCountLimit: Int {
        get { Int(UserDefaults.standard.integer(forKey: "importFileCountLimit")) }
        set { UserDefaults.standard.set(newValue, forKey: "importFileCountLimit") }
    }

    struct ImportInfo {
        let url: URL
        let bookmark: Data
        let size: Int
    }
    
    func importURLs(_ urls: [URL]) async throws {
        let importFileCountLimit = Int(UserDefaults.standard.integer(forKey: "importFileCountLimit"))
        
        var urlBookmarks: [ImportInfo] = []
        
        for url in urls {
            let needsStop = url.startAccessingSecurityScopedResource()
            defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
            
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileType = fileAttributes[.type] as! FileAttributeType
                guard fileType == .typeDirectory || fileType == .typeRegular else {
                    await PraxLogger.shared.logError("Import Source Alert", category: .import)
                    let error = NSError(domain: "FileImporting", code: -1, userInfo: [ NSLocalizedDescriptionKey: "File type is not supported" ])
                    let praxError = PraxError.fileImportFailed(fileName: url.absoluteString, underlyingError: error)
                    await prax.presentError(praxError)
                    return
                }
                
                if fileType == .typeDirectory {
                    urlBookmarks.append(contentsOf: expandFolderRecursively(url, for: await Prax.fileTypes))
                    
                }
                else {
                    guard let data = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) else {
                        await PraxLogger.shared.logError("Import Source Error", category: .import)
                        let error = NSError(domain: "FileImporting", code: -1, userInfo: [ NSLocalizedDescriptionKey: "Error reading file bookmark data" ])
                        let praxError = PraxError.fileImportFailed(fileName: url.absoluteString, underlyingError: error)
                        await prax.presentError(praxError)
                        return
                    }
                  
                    
                    urlBookmarks.append(ImportInfo(url: url, bookmark: data, size: fileAttributes[.size] as! Int))
                } }
            catch {let praxError = PraxError.fileImportFailed( fileName: url.lastPathComponent, underlyingError: error )
                await prax.presentError(praxError)
            }
        }

        
        
        if urlBookmarks.count > importFileCountLimit {
            let message = "Found \(urlBookmarks.count) files -- but that exceeds Settings -> Import Files Count Limit: \(importFileCountLimit)"
            await PraxLogger.shared.logError(message, category: .import)
            let error = PraxError.generic(title: "Import Error", message: message)
            await prax.presentError(error)
            return
        }
              
        let existingSourceFiles = sourceFiles()
        let existingSourceFileURLs = Set<URL>(existingSourceFiles.map { $0.url })
        
        let duplicateURLs = urlBookmarks.filter { existingSourceFileURLs.contains($0.url) }
        for duplicateURL in duplicateURLs { await PraxLogger.shared.logInfo("Duplicate URL: \(duplicateURL.url.path)", category: .import) }
        
        urlBookmarks = urlBookmarks.filter { !existingSourceFileURLs.contains($0.url) }
        
        await addSourceFilesForURLBookmarks(urlBookmarks)

     }
    
    
    func addSourceFilesForURLBookmarks(_ urlBookmarks: [ImportInfo]) async {
        
        
        do {
            for importInfo in urlBookmarks {
                await PraxLogger.shared.logInfo("Adding new SourceFile for: \(importInfo.url.path)  -  Size: \(importInfo.size)", category: .import)
                let url = importInfo.url
                var sourceFile: SourceFile?
                switch url.pathExtension.lowercased() {
                    
                case "pdf":
                    
                    guard let pdfDocument = PDFDocument(url: url) else {
                        await PraxLogger.shared.logError("Failed to open PDF: \(url.path)", category: .pdf)
                        throw PraxError.fileImportFailed( fileName: url.lastPathComponent, underlyingError: NSError(domain: "PDFDocument", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not load PDF file. File may be corrupted or an unsupported PDF format." ]))}
                    
                    print("Opened PDF. Page count: \(pdfDocument.pageCount)")
                    
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
                    
                    let mainFileGroup = try await sourceFileGroup("Main File Group")
                    
                    sourceFile = SourceFile(fileGroup: mainFileGroup, url: url, bookmarkData: importInfo.bookmark, pageCount: pdfDocument.pageCount, fileType: .pdf, fileSize: importInfo.size)
                    
                    sourceFile?.dataFields = dataFields
                    
                    
                    
                    
                    
                case "png", "jpeg", "jpg", "gif", "heic":
                    
                    let mainFileGroup = try await sourceFileGroup("Main File Group")
                    
                    sourceFile = SourceFile(fileGroup: mainFileGroup, url: url, bookmarkData: importInfo.bookmark, pageCount: 0, fileType: .image, fileSize: importInfo.size)
                    
                    
                    
                    
                default:
                    break
                    
                }
                
                guard let sourceFile else {
                    let message = "Could not create Source File for \(url.path)"
                    await PraxLogger.shared.logError(message, category: .import)
                    let error = PraxError.generic(title: "Import Error", message: message)
                    await prax.presentError(error)
                    return
                }
                modelContext.insert(sourceFile)
                try modelContext.save()
                
                
                
            }
            
        }
        catch {
            let message = "Error Importing URLs: \(urlBookmarks)"
            await PraxLogger.shared.logError(message, category: .import)
            let error = PraxError.generic(title: "Import Error", message: message)
            await prax.presentError(error) }
        
    }
    
    
    
    
    func filesRecursively(in folderURL: URL) -> [(url: URL, size: Int)] {
        var collected: [(url: URL, size: Int)] = []
        let fm = FileManager.default
        if let enumerator = fm.enumerator(at: folderURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let url as URL in enumerator {
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
                    if resourceValues.isDirectory == true {
                        continue
                    } else {
       //                 PraxLogger.shared.logInfo("Discovered file in folder: \(url.path)", category: .import)
                        collected.append((url: url, size: resourceValues.fileSize ?? 0))
                    }
                } catch {
                    continue
                }
            }
        }
        return collected
    }
    
    func expandFolderRecursively(_ url: URL, for types:[String]) -> [ImportInfo] {
        var urlBookmarks: [ImportInfo] = []
        let needsStop = url.startAccessingSecurityScopedResource()
        defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
        let folderFiles = filesRecursively(in: url)
        for file in folderFiles {
            guard types.contains(file.url.pathExtension.lowercased()) else { continue }
            if let data = try? file.url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
                urlBookmarks.append(ImportInfo(url: file.url, bookmark: data, size: file.size)) } }
        return urlBookmarks
    }


    
    func praxTest() {
        
        print("Actor modelContext:", ObjectIdentifier(modelContext))
        
        let fetchDescriptor = FetchDescriptor<SourceFile>()
        
        do {
            let sourceFiles = try modelContext.fetch(fetchDescriptor)
            
            for sourceFile in sourceFiles {
                print("Found \(sourceFile.fileName)")
            }
        } catch {
            print("Failed to load model.")
        }
        
    }
    
    
    
}











/*


 
 func isPDF(_ url: URL) -> Bool {
 if let type = UTType(filenameExtension: url.pathExtension) {
 return type.conforms(to: .pdf)
 }
 return url.pathExtension.lowercased() == "pdf"
 }
 
 

 
func newSourceFileFromURLBookmark(url: URL, bookmarkData: Data) async throws -> SourceFile? {
    
    var isStale = false
    
    
    guard let resolvedURL = try? URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) else {
        await PraxLogger.shared.logError(
            "Failed to resolve bookmark for url: \(url.lastPathComponent)",
            category: .bookmarks
        )
        throw PraxError.bookmarkResolutionFailed(
            underlyingError: NSError(domain: "BookmarkResolution", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Could not resolve bookmark data. File may have been moved or deleted."
            ])
        )
    }
    
    let needsStop = resolvedURL.startAccessingSecurityScopedResource()
    defer { if needsStop { resolvedURL.stopAccessingSecurityScopedResource() } }
    
    
    
    
    print("\n--- Parsing PDF: \(resolvedURL.absoluteString) ---")
    guard let pdfDocument = PDFDocument(url: resolvedURL) else {
        await PraxLogger.shared.logError(
            "Failed to open PDF: \(resolvedURL.path)",
            category: .pdf
        )
        throw PraxError.fileImportFailed(
            fileName: url.lastPathComponent,
            underlyingError: NSError(domain: "PDFDocument", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "Could not load PDF file. File may be corrupted or an unsupported PDF format."
            ])
        )
    }
    print("Opened PDF. Page count: \(pdfDocument.pageCount)")
    
    let predicate = #Predicate<SourceFile> { $0.url == url }
    var descriptor = FetchDescriptor<SourceFile>(predicate: predicate)
    descriptor.fetchLimit = 1
    do {
        let existing = try modelContext.fetch(descriptor)
        if !existing.isEmpty {
            print("newSourceFileFromURLBookmark - SourceFile already exists with same url: ", url)
            return nil
        }
    }
    catch {
        await PraxLogger.shared.logError(
            "Failed to check for existing PDF file",
            error: error,
            category: .persistence
        )
        throw PraxError.persistenceFailed(
            operation: "Check existing PDF file",
            underlyingError: error
        )
    }
    do {
        let mainFileGroup = try await sourceFileGroup("Main File Group")
        
        
        let sourceFile = SourceFile(fileGroup: mainFileGroup, url: url, bookmarkData: bookmarkData, pageCount: pdfDocument.pageCount)
        
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
        sourceFile.dataFields = dataFields
        
        modelContext.insert(sourceFile)
        try modelContext.save()
        
        return sourceFile
    }
    catch {
        await PraxLogger.shared.logError(
            "Failed to create PDF file entry",
            error: error,
            category: .persistence
        )
        throw PraxError.persistenceFailed(
            operation: "Create PDF file entry",
            underlyingError: error
        )
    }
    
}

*/



