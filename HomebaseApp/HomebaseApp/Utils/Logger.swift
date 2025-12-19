//
//  Logger.swift
//  HomebaseApp
//
//  Custom logging utility with timestamps
//

import Foundation
import OSLog

// MARK: - Custom Logger

/// Custom logger with timestamps and categories
struct AppLogger {
    /// Subsystem identifier for all app logs
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.homebase.app"
    
    // MARK: - Log Categories
    
    /// General app logs
    static let general = Logger(subsystem: subsystem, category: "general")
    
    /// Firebase/Network logs
    static let network = Logger(subsystem: subsystem, category: "network")
    
    /// UI/View logs
    static let ui = Logger(subsystem: subsystem, category: "ui")
    
    /// Data/Model logs
    static let data = Logger(subsystem: subsystem, category: "data")
    
    /// Error logs
    static let error = Logger(subsystem: subsystem, category: "error")
}

// MARK: - Convenience Functions

/// Log with timestamp and emoji
func logInfo(_ message: String, category: String = "general") {
    let timestamp = DateFormatter.logTimestamp.string(from: Date())
    print("ℹ️ [\(timestamp)] [\(category)] \(message)")
    
    // Also log to OSLog
    AppLogger.general.info("\(message)")
}

/// Log error with timestamp
func logError(_ message: String, error: Error? = nil, category: String = "error") {
    let timestamp = DateFormatter.logTimestamp.string(from: Date())
    if let error = error {
        print("❌ [\(timestamp)] [\(category)] \(message): \(error.localizedDescription)")
        AppLogger.error.error("\(message): \(error.localizedDescription)")
    } else {
        print("❌ [\(timestamp)] [\(category)] \(message)")
        AppLogger.error.error("\(message)")
    }
}

/// Log warning with timestamp
func logWarning(_ message: String, category: String = "warning") {
    let timestamp = DateFormatter.logTimestamp.string(from: Date())
    print("⚠️ [\(timestamp)] [\(category)] \(message)")
    AppLogger.general.warning("\(message)")
}

/// Log debug with timestamp (only in DEBUG builds)
func logDebug(_ message: String, category: String = "debug") {
    #if DEBUG
    let timestamp = DateFormatter.logTimestamp.string(from: Date())
    print("🐛 [\(timestamp)] [\(category)] \(message)")
    AppLogger.general.debug("\(message)")
    #endif
}

/// Log success with timestamp
func logSuccess(_ message: String, category: String = "success") {
    let timestamp = DateFormatter.logTimestamp.string(from: Date())
    print("✅ [\(timestamp)] [\(category)] \(message)")
    AppLogger.general.info("✅ \(message)")
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    static let logTimestampFull: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

