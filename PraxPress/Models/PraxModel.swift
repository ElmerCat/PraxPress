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

@ModelActor
actor PersistenceController: Observable {
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
            
            var dataFields = await PDFDataFields()
            
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
                        switch key {
                        case "PcardHolderName":
                            dataFields.pcardHolderName = v
                        case "DocumentNumber":
                            dataFields.documentNumber = v
                        case "Date":
                            dataFields.date = v
                        case "Amount":
                            dataFields.amount = v
                        case "Vendor":
                            dataFields.vendor = v
                        case "GLAccount":
                            dataFields.glAccount = v
                        case "CostObject":
                            dataFields.costObject = v
                        case "Description":
                            dataFields.justification = v
                        default:
                            break
                        }
                    }
                }
            }
            
        //    pdfFile.dataFields = dataFields
            
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

