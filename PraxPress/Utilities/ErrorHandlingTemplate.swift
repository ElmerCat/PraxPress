//
//  ErrorHandlingTemplate.swift
//  PraxPress
//
//  Template patterns for error handling across the app.
//  Copy and adapt these patterns when implementing error handling in new features.
//
//  Created by Elmer Cat on 5/17/26.
//

import Foundation
import OSLog

// MARK: - ErrorHandlingTemplate

/*
 ============================================================================
 GENERAL ERROR HANDLING PATTERN FOR PraxPress
 ============================================================================
 
 This file demonstrates the recommended error handling patterns.
 Use these as templates when adding error handling to new features.
 
 */

// MARK: - Pattern 1: Async Task with User Feedback (Recommended for user-initiated actions)

/*
 Use this when:
 - User initiates an action (import, save, etc.)
 - Operation is async (network, file I/O, database)
 - User needs feedback if it fails
 
 Example: PDF import
 */

/*
 func handleImportAction(urls: [URL]) {
     Task {
         do {
             PraxLogger.shared.logInfo(
                 "Starting import of \(urls.count) file(s)",
                 category: .import
             )
             
             // Perform operation
             for url in urls {
                 try await performImport(url: url)
             }
             
             // Success - log and update UI
             PraxLogger.shared.logInfo(
                 "Import completed successfully",
                 category: .import
             )
             
             DispatchQueue.main.async { [self] in
                 // Update state - show success toast, refresh UI, etc.
             }
             
         } catch {
             // Create user-facing error
             let praxError = PraxError.pdfImportFailed(
                 fileName: "file",
                 underlyingError: error
             )
             
             // Present to user
             self.presentError(praxError)
         }
     }
 }
 */

// MARK: - Pattern 2: Sync Operation with Graceful Fallback (No UI error)

/*
 Use this when:
 - Operation is synchronous
 - Non-critical (app functions fine without result)
 - Has automatic fallback
 
 Example: Loading cached preferences
 */

/*
 func loadUserPreferences() -> [String: String] {
     do {
         PraxLogger.shared.logDebug(
             "Loading preferences from UserDefaults",
             category: .general
         )
         
         let prefs = UserDefaults.standard.dictionary(forKey: "userPrefs") as? [String: String] ?? [:]
         return prefs
         
     } catch {
         // Log but don't present error UI
         PraxLogger.shared.logWarning(
             "Failed to load preferences: \(error.localizedDescription)",
             category: .general
         )
         
         return [:]  // Return default/empty value
     }
 }
 */

// MARK: - Pattern 3: Security-Scoped Resource Access (Always use defer)

/*
 Use this when:
 - Accessing security-scoped URLs
 - Working with bookmarks
 - Any resource that needs cleanup
 
 Key: Use 'defer' to GUARANTEE cleanup even on error
 */

/*
 func readSecurityScopedFile(url: URL) -> String? {
     let needsStop = url.startAccessingSecurityScopedResource()
     defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
     
     do {
         PraxLogger.shared.logInfo(
             "Reading security-scoped resource: \(url.lastPathComponent)",
             category: .bookmarks
         )
         
         let content = try String(contentsOf: url, encoding: .utf8)
         
         PraxLogger.shared.logDebug(
             "Successfully read \(content.count) bytes",
             category: .bookmarks
         )
         
         return content
         
     } catch {
         PraxLogger.shared.logError(
             "Failed to read security-scoped resource",
             error: error,
             category: .bookmarks
         )
         
         return nil
     }
     // defer ALWAYS fires here, even if exception thrown above
 }
 */

// MARK: - Pattern 4: Input Validation with User Error

/*
 Use this when:
 - User provides input that needs validation
 - Validation can fail with structured error
 - User should see clear reason why
 
 Example: Validating image format
 */

/*
 func validateImage(url: URL) throws {
     do {
         // Validate file extension
         guard url.pathExtension.lowercased() == "png" else {
             throw PraxError.imageProcessingFailed(
                 fileName: url.lastPathComponent,
                 reason: "Only PNG files are supported. Received: .\(url.pathExtension)"
             )
         }
         
         // Validate file exists and is readable
         guard FileManager.default.fileExists(atPath: url.path) else {
             throw PraxError.fileAccessDenied(filePath: url.path)
         }
         
         // Validate can load image
         guard let image = NSImage(contentsOf: url) else {
             throw PraxError.imageProcessingFailed(
                 fileName: url.lastPathComponent,
                 reason: "Could not load image data. File may be corrupted."
             )
         }
         
         PraxLogger.shared.logInfo(
             "Image validation passed: \(url.lastPathComponent)",
             category: .import
         )
         
     } catch let error as PraxError {
         // Re-throw structured error
         throw error
     } catch {
         // Wrap unexpected error
         throw PraxError.generic(
             title: "Validation Error",
             message: error.localizedDescription
         )
     }
 }
 */

// MARK: - Pattern 5: Batch Processing with Partial Failure

/*
 Use this when:
 - Processing multiple items
 - Some may fail while others succeed
 - Need to report overall status
 
 Example: Importing multiple PDFs
 */

/*
 func importMultiplePDFs(urls: [URL]) {
     Task {
         var successCount = 0
         var failedItems: [(url: URL, error: Error)] = []
         
         for url in urls {
             do {
                 PraxLogger.shared.logDebug(
                     "Processing: \(url.lastPathComponent)",
                     category: .import
                 )
                 
                 try await processPDF(url: url)
                 successCount += 1
                 
             } catch {
                 PraxLogger.shared.logWarning(
                     "Failed to process \(url.lastPathComponent): \(error.localizedDescription)",
                     category: .import
                 )
                 failedItems.append((url, error))
             }
         }
         
         // Report results on main thread
         DispatchQueue.main.async { [self] in
             if failedItems.isEmpty {
                 PraxLogger.shared.logInfo(
                     "Batch import complete: \(successCount)/\(urls.count) items processed successfully",
                     category: .import
                 )
                 // Show success toast
             } else {
                 let failureList = failedItems
                     .map { $0.url.lastPathComponent }
                     .joined(separator: ", ")
                 
                 let error = PraxError.generic(
                     title: "Batch Import - Partial Failure",
                     message: "Successfully imported \(successCount) of \(urls.count) file(s).\n\nFailed:\n\(failureList)"
                 )
                 self.presentError(error)
             }
         }
     }
 }
 */

// MARK: - Pattern 6: Wrap Throwing Function Without Try-Catch

/*
 Use this when:
 - Calling a throwing function
 - Want to propagate error up (don't catch it)
 - Or want to transform error before propagating
 */

/*
 func processFile(url: URL) throws {
     // Just call it - error propagates automatically
     let content = try String(contentsOf: url, encoding: .utf8)
     
     // Or transform error:
     do {
         let content = try String(contentsOf: url, encoding: .utf8)
         return content
     } catch {
         // Transform generic error to structured error
         throw PraxError.fileAccessDenied(filePath: url.path)
     }
 }
 */

// MARK: - SUMMARY: When to use each pattern

/*
 ============================================================================
 DECISION TREE: Which pattern to use?
 ============================================================================
 
 1. Is this user-initiated action?
    YES → Pattern 1: Show error alert + recovery suggestions
    NO  → Go to 2
 
 2. Does operation need resource cleanup (files, connections)?
    YES → Pattern 3: Use defer block
    NO  → Go to 3
 
 3. Is failure non-critical?
    YES → Pattern 2: Log warning, return nil/default
    NO  → Go to 4
 
 4. Does this validate user input?
    YES → Pattern 4: Throw structured PraxError
    NO  → Go to 5
 
 5. Processing multiple items?
    YES → Pattern 5: Batch processing with partial failure
    NO  → Pattern 1: Standard async + user feedback
 
 ============================================================================
 */
