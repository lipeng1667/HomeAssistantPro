//
//  DateUtils.swift
//  HomeAssistantPro
//
//  Purpose: Utility functions for date formatting and time calculations
//  Author: Michael
//  Created: 2025-07-16
//  Modified: 2025-07-16
//
//  Modification Log:
//  - 2025-07-16: Initial creation with timeAgo functionality
//
//  Functions:
//  - formatTimeAgo: Convert timestamp string to relative time display
//  - parseTimestamp: Parse various timestamp formats to Date
//  - Supports ISO8601, RFC3339, and custom formats
//

import Foundation

/// Utility class for date formatting and time calculations
struct DateUtils {
    
    // MARK: - Time Ago Formatting
    
    /// Convert timestamp string to relative time display (e.g., "2 hours ago", "just now")
    /// - Parameter timestamp: ISO8601 or RFC3339 formatted timestamp string
    /// - Returns: Localized relative time string
    static func formatTimeAgo(from timestamp: String) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        
        // Try ISO8601 format first
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: timestamp) {
            return formatter.localizedString(for: date, relativeTo: Date())
        }
        
        // Fallback to RFC3339 format
        let rfc3339Formatter = DateFormatter()
        rfc3339Formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        rfc3339Formatter.locale = Locale(identifier: "en_US_POSIX")
        rfc3339Formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let date = rfc3339Formatter.date(from: timestamp) {
            return formatter.localizedString(for: date, relativeTo: Date())
        }
        
        // Additional fallback for format with fractional seconds
        rfc3339Formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = rfc3339Formatter.date(from: timestamp) {
            return formatter.localizedString(for: date, relativeTo: Date())
        }
        
        // Additional fallback for format without Z
        rfc3339Formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = rfc3339Formatter.date(from: timestamp) {
            return formatter.localizedString(for: date, relativeTo: Date())
        }
        
        // Final fallback for other common formats
        rfc3339Formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = rfc3339Formatter.date(from: timestamp) {
            return formatter.localizedString(for: date, relativeTo: Date())
        }
        
        print("DEBUG: All timestamp parsing failed for: '\(timestamp)'")
        return "Unknown"
    }
    
    // MARK: - Date Parsing
    
    /// Parse timestamp string to Date object
    /// - Parameter timestamp: Timestamp string in various formats
    /// - Returns: Date object or nil if parsing fails
    static func parseTimestamp(_ timestamp: String) -> Date? {
        // Try ISO8601 format first
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: timestamp) {
            return date
        }
        
        // Try RFC3339 formats
        let rfc3339Formatter = DateFormatter()
        rfc3339Formatter.locale = Locale(identifier: "en_US_POSIX")
        rfc3339Formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for format in formats {
            rfc3339Formatter.dateFormat = format
            if let date = rfc3339Formatter.date(from: timestamp) {
                return date
            }
        }
        
        return nil
    }
    
    // MARK: - Formatting Utilities
    
    /// Format date to display string
    /// - Parameters:
    ///   - date: Date to format
    ///   - style: DateFormatter style
    /// - Returns: Formatted date string
    static func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Format date to display string with time
    /// - Parameters:
    ///   - date: Date to format
    ///   - dateStyle: Date formatting style
    ///   - timeStyle: Time formatting style
    /// - Returns: Formatted date and time string
    static func formatDateTime(_ date: Date, dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: date)
    }
    
    /// Check if date is today
    /// - Parameter date: Date to check
    /// - Returns: True if date is today
    static func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
    
    /// Check if date is yesterday
    /// - Parameter date: Date to check
    /// - Returns: True if date is yesterday
    static func isYesterday(_ date: Date) -> Bool {
        return Calendar.current.isDateInYesterday(date)
    }
    
    /// Get time difference in seconds
    /// - Parameters:
    ///   - from: Start date
    ///   - to: End date (default: current date)
    /// - Returns: Time difference in seconds
    static func timeDifference(from: Date, to: Date = Date()) -> TimeInterval {
        return to.timeIntervalSince(from)
    }
}