//
//  PraxError.swift
//  PraxPress
//
//  Structured error types for user-facing error presentation
//  Each case includes title, user-friendly message, recovery suggestions, and underlying error
//
//  Created by Elmer Cat on 5/17/26.
//

import Foundation

/// User-facing error type with structured information for display and recovery
///
/// Usage:
/// ```
/// let error = PraxError.pdfImportFailed(fileName: "doc.pdf", underlyingError: someError)
/// prax.presentError(error)
/// ```
enum PraxError: Error, Identifiable {
    case pdfImportFailed(fileName: String, underlyingError: Error)
    case imageProcessingFailed(fileName: String, reason: String)
    case persistenceFailed(operation: String, underlyingError: Error)
    case bookmarkResolutionFailed(underlyingError: Error)
    case fileAccessDenied(filePath: String)
    case saveFailed(reason: String, underlyingError: Error?)
    case generic(title: String, message: String)
    
    // MARK: - Identifiable Conformance
    
    var id: String {
        switch self {
        case .pdfImportFailed: return "pdfImportFailed"
        case .imageProcessingFailed: return "imageProcessingFailed"
        case .persistenceFailed: return "persistenceFailed"
        case .bookmarkResolutionFailed: return "bookmarkResolutionFailed"
        case .fileAccessDenied: return "fileAccessDenied"
        case .saveFailed: return "saveFailed"
        case .generic: return "generic"
        }
    }
    
    // MARK: - User-Facing Title (shown in alert header)
    
    var title: String {
        switch self {
        case .pdfImportFailed:
            return "PDF Import Failed"
        case .imageProcessingFailed:
            return "Image Processing Failed"
        case .persistenceFailed:
            return "Storage Error"
        case .bookmarkResolutionFailed:
            return "File Access Error"
        case .fileAccessDenied:
            return "Access Denied"
        case .saveFailed:
            return "Save Failed"
        case .generic(let title, _):
            return title
        }
    }
    
    // MARK: - User-Facing Message (shown in alert body)
    
    var userMessage: String {
        switch self {
        case .pdfImportFailed(let fileName, let error):
            return "Could not import PDF '\(fileName)':\n\n\(error.localizedDescription)"
        
        case .imageProcessingFailed(let fileName, let reason):
            return "Could not process image '\(fileName)':\n\n\(reason)"
        
        case .persistenceFailed(let operation, let error):
            return "Storage operation '\(operation)' failed:\n\n\(error.localizedDescription)"
        
        case .bookmarkResolutionFailed(let error):
            return "Could not access file:\n\n\(error.localizedDescription)\n\nThe file may have been moved or deleted."
        
        case .fileAccessDenied(let filePath):
            return "Access denied to file:\n\n\(filePath)\n\nCheck file permissions or try copying to Documents."
        
        case .saveFailed(let reason, let error):
            let errorDetails = error.map { "\n\n\(($0 as NSError).localizedDescription)" } ?? ""
            return "Could not save PDF:\n\n\(reason)\(errorDetails)"
        
        case .generic(_, let message):
            return message
        }
    }
    
    // MARK: - Recovery Suggestions (shown to user as bulleted list)
    
    var recoverySuggestions: [String] {
        switch self {
        case .pdfImportFailed:
            return [
                "Ensure the file is a valid PDF",
                "Try copying the file to a local folder first",
                "Check that the file is not corrupted by opening it in Preview",
                "For remote files, ensure your network connection is stable"
            ]
        
        case .imageProcessingFailed:
            return [
                "Ensure the file is a valid image (PNG, JPEG, GIF, HEIC)",
                "Try using smaller image files or lower resolutions",
                "Check your Mac's available memory and disk space",
                "Try resaving the image in a different format"
            ]
        
        case .persistenceFailed:
            return [
                "Check available disk space on your Mac",
                "Try restarting PraxPress",
                "Check file and folder permissions",
                "Try saving to a different location"
            ]
        
        case .bookmarkResolutionFailed:
            return [
                "Ensure the file still exists at its original location",
                "Re-import the file if it was moved or renamed",
                "Check network connectivity for remote files",
                "Try re-adding the file using file browser"
            ]
        
        case .fileAccessDenied:
            return [
                "Copy the file to a location you have access to (e.g., Documents)",
                "Use Finder's 'Get Info' to verify read permissions",
                "Contact your system administrator if file is restricted",
                "Try copying to Desktop and importing from there"
            ]
        
        case .saveFailed:
            return [
                "Check available disk space on your Mac",
                "Verify the destination folder exists and is writable",
                "Try saving to a different location (e.g., Desktop or Documents)",
                "Ensure you have write permissions to the destination"
            ]
        
        case .generic:
            return ["Try again or contact support if the problem persists"]
        }
    }
    
    // MARK: - Underlying Error (for logging to Console.app)
    
    var underlyingError: Error? {
        switch self {
        case .pdfImportFailed(_, let error): return error
        case .persistenceFailed(_, let error): return error
        case .bookmarkResolutionFailed(let error): return error
        case .saveFailed(_, let error): return error
        default: return nil
        }
    }
}
