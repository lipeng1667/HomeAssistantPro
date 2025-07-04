//
//  DeviceIdentifier.swift
//  HomeAssistantPro
//
//  Purpose: Manages secure device identification using Keychain storage
//  Author: Claude
//  Created: 2025-07-04
//  Modified: 2025-07-04
//
//  Modification Log:
//  - 2025-07-04: Initial creation with Keychain-based device ID storage
//
//  Functions:
//  - deviceId: Computed property to get/create device identifier
//  - generateDeviceId(): Creates new UUID-based device identifier
//  - saveToKeychain(_:): Stores device ID in Keychain
//  - loadFromKeychain(): Retrieves device ID from Keychain
//

import Foundation
import Security
import os.log

/// Manages secure device identification using Keychain storage
final class DeviceIdentifier {
    static let shared = DeviceIdentifier()
    
    private let service = "com.vincenx.HomeAssistantPro"
    private let account = "device_identifier"
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "DeviceIdentifier")
    
    private init() {}
    
    /// Gets or creates a persistent device identifier
    /// - Returns: Unique device identifier string
    var deviceId: String {
        if let existingId = loadFromKeychain() {
            return existingId
        } else {
            let newId = generateDeviceId()
            saveToKeychain(newId)
            return newId
        }
    }
    
    /// Generates a new UUID-based device identifier
    /// - Returns: Device ID in format "iOS_UUID"
    private func generateDeviceId() -> String {
        let uuid = UUID().uuidString
        return "iOS_\(uuid)"
    }
    
    /// Saves device ID to Keychain
    /// - Parameter deviceId: Device identifier to store
    private func saveToKeychain(_ deviceId: String) {
        let data = deviceId.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            logger.info("Device ID saved to Keychain successfully")
        } else {
            logger.error("Failed to save device ID to Keychain: \(status)")
        }
    }
    
    /// Loads device ID from Keychain
    /// - Returns: Device identifier if found, nil otherwise
    private func loadFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            if status != errSecItemNotFound {
                logger.error("Failed to load device ID from Keychain: \(status)")
            }
            return nil
        }
        
        guard let data = item as? Data,
              let deviceId = String(data: data, encoding: .utf8) else {
            logger.error("Failed to decode device ID from Keychain data")
            return nil
        }
        
        logger.info("Device ID loaded from Keychain successfully")
        return deviceId
    }
    
    /// Removes device ID from Keychain (for testing/reset purposes)
    func clearDeviceId() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            logger.info("Device ID cleared from Keychain")
        } else {
            logger.error("Failed to clear device ID from Keychain: \(status)")
        }
    }
}