//
//  PhoneNumberUtils.swift
//  HomeAssistantPro
//
//  Purpose: Utility functions for phone number formatting and validation
//  Author: Michael
//  Created: 2025-07-06
//  Modified: 2025-07-06
//
//  Modification Log:
//  - 2025-07-06: Initial creation with China mobile phone number utilities
//
//  Functions:
//  - formatPhoneNumber(_:): Formats phone number to China mobile format (XXX XXXX XXXX)
//  - validatePhoneNumber(_:): Validates China mobile phone number format
//  - isValidChinaMobile(_:): Checks if phone number is valid China mobile format
//

import Foundation

/// Utility class for phone number formatting and validation
struct PhoneNumberUtils {
    
    /// Formats phone number with China mobile format (3-4-4 spacing)
    /// - Parameter phoneNumber: Raw phone number string
    /// - Returns: Formatted phone number string in China format
    static func formatPhoneNumber(_ phoneNumber: String) -> String {
        // Remove all non-numeric characters
        let digits = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // Limit to 11 digits (China mobile standard)
        let limitedDigits = String(digits.prefix(11))
        
        // Format based on length - China format: XXX XXXX XXXX
        switch limitedDigits.count {
        case 0:
            return ""
        case 1...3:
            return limitedDigits
        case 4...7:
            let firstPart = String(limitedDigits.prefix(3))
            let secondPart = String(limitedDigits.dropFirst(3))
            return "\(firstPart) \(secondPart)"
        case 8...11:
            let firstPart = String(limitedDigits.prefix(3))
            let secondPart = String(limitedDigits.dropFirst(3).prefix(4))
            let thirdPart = String(limitedDigits.dropFirst(7))
            return "\(firstPart) \(secondPart) \(thirdPart)"
        default:
            return limitedDigits
        }
    }
    
    /// Validates China mobile phone number format
    /// - Parameter phoneNumber: Phone number string to validate
    /// - Returns: True if valid China mobile number, false otherwise
    static func validatePhoneNumber(_ phoneNumber: String) -> Bool {
        // Extract digits only for validation
        let digits = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // China mobile numbers: 11 digits starting with 1 and valid second digit
        if phoneNumber.isEmpty {
            return true
        } else if digits.count == 11 && digits.hasPrefix("1") {
            // Valid China mobile prefixes: 13X, 14X, 15X, 16X, 17X, 18X, 19X
            let secondDigit = String(digits.dropFirst(1).prefix(1))
            return ["3", "4", "5", "6", "7", "8", "9"].contains(secondDigit)
        } else {
            return false
        }
    }
    
    /// Checks if phone number is valid China mobile format
    /// - Parameter phoneNumber: Phone number string to check
    /// - Returns: True if valid and complete China mobile number, false otherwise
    static func isValidChinaMobile(_ phoneNumber: String) -> Bool {
        let digits = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return digits.count == 11 && validatePhoneNumber(phoneNumber)
    }
    
    /// Removes all formatting from phone number, returning only digits
    /// - Parameter phoneNumber: Formatted phone number string
    /// - Returns: Clean phone number with only digits
    static func cleanPhoneNumber(_ phoneNumber: String) -> String {
        return phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
    }
}