//
//  PraxModel+FileManager.swift
//  PraxPress
//
//  Created by Elmer Cat on 5/30/26.
//
import Foundation
import SwiftData
import SwiftUI
import PDFKit
import UniformTypeIdentifiers

extension PraxModel {
 
    var importFileCountLimit: Int {
        get { Int(UserDefaults.standard.integer(forKey: "importFileCountLimit")) }
        set { UserDefaults.standard.set(newValue, forKey: "importFileCountLimit") }
    }

    
    func processImportedURLs(_ urls: [URL], at indexPath: IndexPath? = nil) async throws {
        let fileTypes = ["pdf", "png", "jpeg", "jpg", "gif", "heic"]

        
        var urlBookmarks: [(url: URL, bookmark: Data, size: Int)] = []
        
        for url in urls {
            let needsStop = url.startAccessingSecurityScopedResource()
            defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
            
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileType = fileAttributes[.type] as! FileAttributeType
                guard fileType == .typeDirectory || fileType == .typeRegular else {
                    PraxLogger.shared.logError("Import Source Alert", category: .import)
                    let error = NSError(domain: "FileImporting", code: -1, userInfo: [ NSLocalizedDescriptionKey: "File type is not supported" ])
                    let praxError = PraxError.fileImportFailed(fileName: url.absoluteString, underlyingError: error)
                    presentError(praxError)
                    return
                }
                
                if fileType == .typeDirectory {
                    urlBookmarks.append(contentsOf: expandFolderRecursively(url, for: fileTypes))
                    
                }
                else {
                    guard let data = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) else {
                        PraxLogger.shared.logError("Import Source Error", category: .import)
                        let error = NSError(domain: "FileImporting", code: -1, userInfo: [ NSLocalizedDescriptionKey: "Error reading file bookmark data" ])
                        let praxError = PraxError.fileImportFailed(fileName: url.absoluteString, underlyingError: error)
                        presentError(praxError)
                        return
                    }
                    let fileSize = fileAttributes[.size]
                    urlBookmarks.append((url: url, bookmark: data, size: fileSize) as! (url: URL, bookmark: Data, size: Int))
                } }
            catch {let praxError = PraxError.fileImportFailed( fileName: url.lastPathComponent, underlyingError: error )
                presentError(praxError)
            }
        }

        
        
        if urlBookmarks.count > importFileCountLimit {
            let message = "Found \(urlBookmarks.count) files -- but that exceeds Settings -> Import Files Count Limit: \(importFileCountLimit)"
            PraxLogger.shared.logError(message, category: .import)
            let error = PraxError.generic(title: "Import Error", message: message)
            presentError(error)
            return
        }
        
        
        importDropIndexPath = indexPath
        urlBookmarksToImport = urlBookmarks.filter { $0.url.pathExtension.lowercased() != "pdf" }
        for urlBookmark in urlBookmarksToImport { PraxLogger.shared.logInfo("Import Source URL: \(urlBookmark.url.path)  -  Size: \(urlBookmark.size)", category: .import) }
        
        var pdfURLBookmarks = urlBookmarks.filter { $0.url.pathExtension.lowercased() == "pdf" }
        for urlBookmark in pdfURLBookmarks {  PraxLogger.shared.logInfo("Import PDF URL: \(urlBookmark.url.path)  -  Size: \(urlBookmark.size)", category: .import) }
        
        let pdfFiles = await document.persistence.pdfFiles()
        var existingPDFFileURLs = Set<URL>(pdfFiles.map { $0.url })
        pdfURLBookmarks = pdfURLBookmarks.filter { urlBookmark in existingPDFFileURLs.insert(urlBookmark.url).inserted }
        for urlBookmark in pdfURLBookmarks {  PraxLogger.shared.logInfo("Adding new PDFFile for: \(urlBookmark.url.path)  -  Size: \(urlBookmark.size)", category: .import) }
        
        
        do {
            for urlBookmark in pdfURLBookmarks {
                let url = urlBookmark.url
                
                switch url.pathExtension.lowercased() {
                    
                case "pdf":
                    guard let _ = try await document.persistence.newPDFFileFromURLBookmark(url: urlBookmark.url, bookmarkData: urlBookmark.bookmark) else {
                        print("Failed newPDFFileFromURLBookmark(url: ", urlBookmark.url)
                        continue
                    }
                    
                case "png", "jpeg", "jpg", "gif", "heic":
                    
                    
              //      PraxLogger.shared.logInfo("Importing Image File: \(url.lastPathComponent) - size: \(prax.importSourceAttributes[.size] ?? 0) - type: \(sourceAttributes[.type] ?? "unknown")", category: .import)
                    
                    
                    
                    if inspectNextImageDrop {
                        
                        let praxError = PraxError.generic(
                            title: "Operation Failed",
                            message: "inspectNextImageDrop - Something unexpected happened. Please try again."
                        )
                        presentError(praxError)
                        
                        //            showingImageDropInspector = true
                    } else {
                        
                        showingImportEditor = true
                        
                        // IMPORTANT: default size limit is applied inside addPageFromImageURL
                        //          DispatchQueue.main.async { [self] in addPageFromImageURL(url, at: indexPath, options: .neutral) }
                    }
                    
                default:
                    break
                    
                }
                
            }
            
        }
        catch {
            print("Error adding newPDFFileFromURLBookmark urls: ", urls)
        }
        

        
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
                        PraxLogger.shared.logInfo("Discovered file in folder: \(url.path)", category: .import)
                        collected.append((url: url, size: resourceValues.fileSize ?? 0))
                    }
                } catch {
                    continue
                }
            }
        }
        return collected
    }
    
    func expandFolderRecursively(_ url: URL, for types:[String]) -> [(url: URL, bookmark: Data, size: Int)] {
        var urlBookmarks: [(url: URL, bookmark: Data, size: Int)] = []
        let needsStop = url.startAccessingSecurityScopedResource()
        defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
        let folderFiles = filesRecursively(in: url)
        for file in folderFiles {
            guard types.contains(file.url.pathExtension.lowercased()) else { continue }
            if let data = try? file.url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
                urlBookmarks.append((url: file.url, bookmark: data, size: file.size)) } }
        return urlBookmarks
    }

    
}

