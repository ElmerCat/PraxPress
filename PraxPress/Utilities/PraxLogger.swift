//
//  PraxLogger.swift
//  PraxPress
//
//  Centralized logging with both OSLog (Console.app) and persistent .log file
//

import Foundation
import OSLog
import AppKit

/// Unified logger for PraxPress that writes to both Console.app and persistent .log files
final class PraxLogger {
    static let shared = PraxLogger()
    
    private let logSubsystem = "com.praxpress.app"
    
    // Category-specific loggers
    private lazy var generalLogger = Logger(subsystem: logSubsystem, category: "General")
    private lazy var importLogger = Logger(subsystem: logSubsystem, category: "Import")
    private lazy var persistenceLogger = Logger(subsystem: logSubsystem, category: "Persistence")
    private lazy var uiLogger = Logger(subsystem: logSubsystem, category: "UI")
    private lazy var pdfLogger = Logger(subsystem: logSubsystem, category: "PDF")
    private lazy var bookmarkLogger = Logger(subsystem: logSubsystem, category: "Bookmarks")
    private lazy var performanceLogger = Logger(subsystem: logSubsystem, category: "Performance")
    
    // File logging
    private var logFileURL: URL?
    private let fileQueue = DispatchQueue(label: "com.praxpress.logging.file")
    
    private init() {
        setupFileLogging()
        logInfo("🚀 PraxLogger initialized", category: .general)
    }
    
    // MARK: - File Logging Setup
    
    private func setupFileLogging() {
        // Create logs directory in Application Support
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("⚠️ Could not access Application Support directory")
            return
        }
        
        let logsDirectory = appSupportURL.appendingPathComponent("PraxPress/Logs", isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("⚠️ Could not create logs directory: \(error)")
            return
        }
        
        // Create timestamped log file
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let logFileName = "PraxPress_\(timestamp).log"
        logFileURL = logsDirectory.appendingPathComponent(logFileName)
        
        // Write header
        let header = """
        ================================================================================
        PraxPress Log File
        Started: \(Date())
        ================================================================================
        
        """
        
        if let fileURL = logFileURL {
            do {
                try header.write(to: fileURL, atomically: true, encoding: .utf8)
                print("📝 Log file created at: \(fileURL.path)")
            } catch {
                print("⚠️ Failed to initialize log file: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - File Writing (Synchronous)
    
    private func writeToFile(_ message: String, level: String, category: String) {
        guard let fileURL = logFileURL else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        
        let logEntry = "[\(timestamp)] [\(level)] [\(category)] \(message)\n"
        
        fileQueue.async {
            do {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()
                if let data = logEntry.data(using: .utf8) {
                    fileHandle.write(data)
                }
                try fileHandle.close()
            } catch {
                // Silently fail if file can't be written
            }
        }
    }
    
    // MARK: - Log Category
    
    enum Category {
        case general
        case `import`
        case persistence
        case ui
        case pdf
        case bookmarks
        case performance
        
        fileprivate func logger(from praxLogger: PraxLogger) -> Logger {
            switch self {
            case .general: return praxLogger.generalLogger
            case .`import`: return praxLogger.importLogger
            case .persistence: return praxLogger.persistenceLogger
            case .ui: return praxLogger.uiLogger
            case .pdf: return praxLogger.pdfLogger
            case .bookmarks: return praxLogger.bookmarkLogger
            case .performance: return praxLogger.performanceLogger
            }
        }
        
        fileprivate var categoryName: String {
            switch self {
            case .general: return "General"
            case .`import`: return "Import"
            case .persistence: return "Persistence"
            case .ui: return "UI"
            case .pdf: return "PDF"
            case .bookmarks: return "Bookmarks"
            case .performance: return "Performance"
            }
        }
    }
    
    // MARK: - Public API (All Synchronous)
    
    func logInfo(_ message: String, category: Category = .general) {
        let logger = category.logger(from: self)
        logger.info("\(message)")
        writeToFile(message, level: "INFO", category: category.categoryName)
    }
    
    func logDebug(_ message: String, category: Category = .general) {
        let logger = category.logger(from: self)
        logger.debug("\(message)")
        writeToFile(message, level: "DEBUG", category: category.categoryName)
    }
    
    func logWarning(_ message: String, category: Category = .general) {
        let logger = category.logger(from: self)
        logger.warning("⚠️ \(message)")
        writeToFile(message, level: "WARNING", category: category.categoryName)
    }
    
    func logError(_ message: String, error: Error? = nil, category: Category = .general) {
        let logger = category.logger(from: self)
        let fullMessage: String
        if let error = error {
            fullMessage = "❌ \(message) - Error: \(error.localizedDescription)"
        } else {
            fullMessage = "❌ \(message)"
        }
        logger.error("\(fullMessage)")
        writeToFile(fullMessage, level: "ERROR", category: category.categoryName)
    }
    
    func logFault(_ message: String, error: Error? = nil, category: Category = .general) {
        let logger = category.logger(from: self)
        let fullMessage: String
        if let error = error {
            fullMessage = "🔥 FAULT: \(message) - \(error.localizedDescription)"
        } else {
            fullMessage = "🔥 FAULT: \(message)"
        }
        logger.fault("\(fullMessage)")
        writeToFile(fullMessage, level: "FAULT", category: category.categoryName)
    }
    
    func logPerformance(name: String, duration: TimeInterval) {
        let message = "⏱️ \(name): \(String(format: "%.3f", duration))s"
        performanceLogger.info("\(message)")
        writeToFile(message, level: "PERF", category: "Performance")
    }
    
    // MARK: - Utility: Get Log File URL
    
    func getLogFileURL() -> URL? {
        return logFileURL
    }
    
    func openLogFile() {
        guard let url = getLogFileURL(),
              FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        NSWorkspace.shared.open(url)
    }
    
    /// Get directory containing all log files
    func getLogsDirectoryURL() -> URL? {
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return appSupportURL.appendingPathComponent("PraxPress/Logs", isDirectory: true)
    }
}

// MARK: - Convenience Extension

extension OSLog {
    static let praxpress = OSLog(subsystem: "com.praxpress.app", category: "General")
}
