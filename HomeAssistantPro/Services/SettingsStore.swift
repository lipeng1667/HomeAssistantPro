//
//  SettingsStore.swift
//  HomeAssistantPro
//
//  Purpose: Secure storage service for user settings and authentication data
//  In KeyChain:
//      - device id:    created at the first time app launched
//      - user id:      server will return when user login(or anonymous login)
//  In UserDefaults:
//      - isFirstLaunch:    if it's first launch to show the intro views
//      - theme:
//      - language:
//
//  Author: Michael
//  Created: 2025-07-06
//  Modified: 2025-07-06
//
//  Modification Log:
//  - 2025-07-06: Initial creation with Keychain and UserDefaults wrappers
//
//  Functions:
//  - init(): Initialize with default service configuration
//  - storeUserId(_:): Securely store user ID in Keychain
//  - retrieveUserId(): Retrieve stored user ID from Keychain
//  - removeUserId(): Remove user ID from Keychain
//  - storeDeviceId(_:): Store device ID in Keychain
//  - retrieveDeviceId(): Retrieve device ID from Keychain
//  - setIntroShown(): Marks intro as completed (legacy compatibility)
//  - clearAllSettings(): Clear all stored data for logout
//

import Foundation
import Security
import SwiftUI
import os.log

/// Service for managing secure storage of user settings and authentication data
final class SettingsStore: ObservableObject {
    
    // MARK: - Properties
    
    /// Published theme preference for SwiftUI observation
    @Published var selectedTheme: String = "system"
    
    /// Published first launch state for SwiftUI observation
    @Published var isFirstLaunch: Bool = true
    
    private let keychainService = "com.homeassistant.ios.keychain"
    private let userDefaults = UserDefaults.standard
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "SettingsStore")
    
    // MARK: - Keys
    
    private enum KeychainKeys {
        static let userId = "user_id"
        static let deviceId = "device_id"
    }
    
    private enum UserDefaultsKeys {
        static let isFirstLaunch = "is_first_launch"
        static let selectedTheme = "selected_theme"
    }
    
    // MARK: - Initialization
    
    /// Initialize SettingsStore with default configuration
    init() {
        // Load published properties from storage
        self.selectedTheme = userDefaults.string(forKey: UserDefaultsKeys.selectedTheme) ?? "system"
        self.isFirstLaunch = userDefaults.object(forKey: UserDefaultsKeys.isFirstLaunch) == nil ? true : userDefaults.bool(forKey: UserDefaultsKeys.isFirstLaunch)
        
        logger.info("SettingsStore initialized")
    }
    
    // MARK: - User ID Management (Keychain)
    
    /// Securely stores user ID in Keychain
    /// - Parameter userId: User ID string to store
    /// - Throws: SettingsStoreError for storage failures
    func storeUserId(_ userId: String) throws {
        let data = Data(userId.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: KeychainKeys.userId,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            logger.error("Failed to store user ID in Keychain: \(status)")
            throw SettingsStoreError.keychainStorageError(status)
        }
        
        logger.info("User ID stored successfully in Keychain")
    }
    
    /// Retrieves user ID from Keychain
    /// - Returns: User ID string if found, nil otherwise
    /// - Throws: SettingsStoreError for retrieval failures
    func retrieveUserId() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: KeychainKeys.userId,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        switch status {
        case errSecSuccess:
            guard let data = dataTypeRef as? Data,
                  let userId = String(data: data, encoding: .utf8) else {
                logger.error("Failed to decode user ID from Keychain data")
                throw SettingsStoreError.dataDecodingError
            }
            logger.info("User ID retrieved successfully from Keychain")
            return userId
            
        case errSecItemNotFound:
            logger.info("No user ID found in Keychain")
            return nil
            
        default:
            logger.error("Failed to retrieve user ID from Keychain: \(status)")
            throw SettingsStoreError.keychainRetrievalError(status)
        }
    }
    
    /// Removes user ID from Keychain
    /// - Throws: SettingsStoreError for removal failures
    func removeUserId() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: KeychainKeys.userId
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            logger.error("Failed to remove user ID from Keychain: \(status)")
            throw SettingsStoreError.keychainDeletionError(status)
        }
        
        logger.info("User ID removed from Keychain")
    }
    
    // MARK: - Device ID Management (Keychain)
    
    /// Securely stores device ID in Keychain
    /// - Parameter deviceId: Device ID string to store
    /// - Throws: SettingsStoreError for storage failures
    func storeDeviceId(_ deviceId: String) throws {
        let data = Data(deviceId.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: KeychainKeys.deviceId,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            logger.error("Failed to store device ID in Keychain: \(status)")
            throw SettingsStoreError.keychainStorageError(status)
        }
        
        logger.info("Device ID stored successfully in Keychain")
    }
    
    /// Retrieves device ID from Keychain
    /// - Returns: Device ID string if found, nil otherwise
    /// - Throws: SettingsStoreError for retrieval failures
    func retrieveDeviceId() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: KeychainKeys.deviceId,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        switch status {
        case errSecSuccess:
            guard let data = dataTypeRef as? Data,
                  let deviceId = String(data: data, encoding: .utf8) else {
                logger.error("Failed to decode device ID from Keychain data")
                throw SettingsStoreError.dataDecodingError
            }
            logger.info("Device ID retrieved successfully from Keychain")
            return deviceId
            
        case errSecItemNotFound:
            logger.info("No device ID found in Keychain")
            return nil
            
        default:
            logger.error("Failed to retrieve device ID from Keychain: \(status)")
            throw SettingsStoreError.keychainRetrievalError(status)
        }
    }
    
    // MARK: - App Settings (UserDefaults)
    
    /// Stores first launch flag
    /// - Parameter isFirstLaunch: Boolean indicating if this is first app launch
    func storeFirstLaunchFlag(_ isFirstLaunch: Bool) {
        userDefaults.set(isFirstLaunch, forKey: UserDefaultsKeys.isFirstLaunch)
        self.isFirstLaunch = isFirstLaunch
        logger.info("First launch flag stored: \(isFirstLaunch)")
    }
    
    /// Marks intro as shown (sets first launch to false)
    /// Legacy method for compatibility with IntroView
    func setIntroShown() {
        storeFirstLaunchFlag(false)
        logger.info("Intro marked as shown")
    }
    
    /// Stores selected theme preference
    /// - Parameter theme: Theme name string
    func storeSelectedTheme(_ theme: String) {
        userDefaults.set(theme, forKey: UserDefaultsKeys.selectedTheme)
        self.selectedTheme = theme
        logger.info("Selected theme stored: \(theme)")
    }
    
    // MARK: - Cleanup
    
    /// Clears login session state (does NOT clear user_id or device_id - they persist across logout)
    /// This method is intentionally minimal as user_id and device_id should persist
    func clearAuthenticationSession() {
        // User ID and Device ID are NOT cleared on logout - they persist for re-login
        // Only the login session state in AppViewModel is cleared
        logger.info("Authentication session cleared (user_id and device_id preserved)")
    }
    
    /// Clears all app data including user_id and device_id (for complete app reset)
    /// - Throws: SettingsStoreError for cleanup failures
    func clearAllData() throws {
        // Clear user ID from Keychain
        do {
            try removeUserId()
        } catch {
            logger.error("Failed to clear user ID during complete reset")
            throw error
        }
        
        // Clear device ID from Keychain  
        let deviceQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: KeychainKeys.deviceId
        ]
        
        let deviceStatus = SecItemDelete(deviceQuery as CFDictionary)
        if deviceStatus != errSecSuccess && deviceStatus != errSecItemNotFound {
            logger.error("Failed to remove device ID from Keychain: \(deviceStatus)")
            throw SettingsStoreError.keychainDeletionError(deviceStatus)
        }
        
        // Clear UserDefaults
        userDefaults.removeObject(forKey: UserDefaultsKeys.isFirstLaunch)
        userDefaults.removeObject(forKey: UserDefaultsKeys.selectedTheme)
        
        // Reset published properties to defaults
        self.isFirstLaunch = true
        self.selectedTheme = "system"
        
        logger.info("All app data cleared successfully (including user_id and device_id)")
    }
}

// MARK: - Error Types

/// Errors that can occur during settings storage operations
enum SettingsStoreError: LocalizedError {
    case keychainStorageError(OSStatus)
    case keychainRetrievalError(OSStatus)
    case keychainDeletionError(OSStatus)
    case dataDecodingError
    
    var errorDescription: String? {
        switch self {
        case .keychainStorageError(let status):
            return "Failed to store data in Keychain (status: \(status))"
        case .keychainRetrievalError(let status):
            return "Failed to retrieve data from Keychain (status: \(status))"
        case .keychainDeletionError(let status):
            return "Failed to delete data from Keychain (status: \(status))"
        case .dataDecodingError:
            return "Failed to decode data from storage"
        }
    }
}
