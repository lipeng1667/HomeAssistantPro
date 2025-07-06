//
//  SettingsStoreTests.swift
//  HomeAssistantProTests
//
//  Purpose: Unit tests for SettingsStore secure storage functionality
//  Author: Michael
//  Created: 2025-07-06
//  Modified: 2025-07-06
//
//  Modification Log:
//  - 2025-07-06: Initial creation with Keychain and UserDefaults tests
//
//  Functions:
//  - testStoreAndRetrieveUserId(): Tests user ID storage and retrieval
//  - testRemoveUserId(): Tests user ID removal from Keychain
//  - testStoreAndRetrieveDeviceId(): Tests device ID storage in UserDefaults
//  - testFirstLaunchFlag(): Tests first launch flag functionality
//  - testSelectedTheme(): Tests theme preference storage
//  - testClearAllAuthenticationData(): Tests authentication data cleanup
//  - testClearAllData(): Tests complete data cleanup
//

import XCTest
@testable import HomeAssistantPro

/// Unit tests for SettingsStore secure storage functionality
final class SettingsStoreTests: XCTestCase {
    
    var settingsStore: SettingsStore!
    
    override func setUp() {
        super.setUp()
        settingsStore = SettingsStore()
        
        // Clean up any existing test data
        try? settingsStore.clearAllData()
    }
    
    override func tearDown() {
        // Clean up after each test
        try? settingsStore.clearAllData()
        settingsStore = nil
        super.tearDown()
    }
    
    // MARK: - User ID Tests (Keychain)
    
    /// Tests storing and retrieving user ID from Keychain
    func testStoreAndRetrieveUserId() throws {
        let testUserId = "12345"
        
        // Store user ID
        try settingsStore.storeUserId(testUserId)
        
        // Retrieve user ID
        let retrievedUserId = try settingsStore.retrieveUserId()
        
        XCTAssertEqual(retrievedUserId, testUserId, "Retrieved user ID should match stored value")
    }
    
    /// Tests user ID removal from Keychain
    func testRemoveUserId() throws {
        let testUserId = "12345"
        
        // Store user ID first
        try settingsStore.storeUserId(testUserId)
        
        // Verify it was stored
        let storedUserId = try settingsStore.retrieveUserId()
        XCTAssertEqual(storedUserId, testUserId)
        
        // Remove user ID
        try settingsStore.removeUserId()
        
        // Verify it was removed
        let removedUserId = try settingsStore.retrieveUserId()
        XCTAssertNil(removedUserId, "User ID should be nil after removal")
    }
    
    /// Tests retrieving non-existent user ID returns nil
    func testRetrieveNonExistentUserId() throws {
        let userId = try settingsStore.retrieveUserId()
        XCTAssertNil(userId, "Non-existent user ID should return nil")
    }
    
    /// Tests overwriting existing user ID
    func testOverwriteUserId() throws {
        let firstUserId = "12345"
        let secondUserId = "67890"
        
        // Store first user ID
        try settingsStore.storeUserId(firstUserId)
        
        // Store second user ID (should overwrite)
        try settingsStore.storeUserId(secondUserId)
        
        // Retrieve user ID
        let retrievedUserId = try settingsStore.retrieveUserId()
        
        XCTAssertEqual(retrievedUserId, secondUserId, "Second user ID should overwrite first")
    }
    
    // MARK: - Device ID Tests (Keychain)
    
    /// Tests storing and retrieving device ID from Keychain
    func testStoreAndRetrieveDeviceId() throws {
        let testDeviceId = "iPhone_15_ABC123"
        
        // Store device ID
        try settingsStore.storeDeviceId(testDeviceId)
        
        // Retrieve device ID
        let retrievedDeviceId = try settingsStore.retrieveDeviceId()
        
        XCTAssertEqual(retrievedDeviceId, testDeviceId, "Retrieved device ID should match stored value")
    }
    
    /// Tests retrieving non-existent device ID returns nil
    func testRetrieveNonExistentDeviceId() throws {
        let deviceId = try settingsStore.retrieveDeviceId()
        XCTAssertNil(deviceId, "Non-existent device ID should return nil")
    }
    
    // MARK: - App Settings Tests (UserDefaults)
    
    /// Tests first launch flag functionality
    func testFirstLaunchFlag() {
        // Should default to true
        XCTAssertTrue(settingsStore.isFirstLaunch, "Should default to true for first launch")
        
        // Set to false
        settingsStore.storeFirstLaunchFlag(false)
        XCTAssertFalse(settingsStore.isFirstLaunch, "Should return false after being set")
        
        // Set back to true
        settingsStore.storeFirstLaunchFlag(true)
        XCTAssertTrue(settingsStore.isFirstLaunch, "Should return true after being set")
    }
    
    /// Tests selected theme storage and retrieval
    func testSelectedTheme() {
        // Should default to "system"
        XCTAssertEqual(settingsStore.selectedTheme, "system", "Should default to system theme")
        
        // Store custom theme
        let testTheme = "dark"
        settingsStore.storeSelectedTheme(testTheme)
        
        // Retrieve theme
        XCTAssertEqual(settingsStore.selectedTheme, testTheme, "Retrieved theme should match stored value")
    }
    
    // MARK: - Cleanup Tests
    
    /// Tests clearing authentication session (user_id and device_id should persist)
    func testClearAuthenticationSession() throws {
        let testUserId = "12345"
        let testDeviceId = "iPhone_15_ABC123"
        let testTheme = "dark"
        
        // Store test data
        try settingsStore.storeUserId(testUserId)
        try settingsStore.storeDeviceId(testDeviceId)
        settingsStore.storeSelectedTheme(testTheme)
        settingsStore.storeFirstLaunchFlag(false)
        
        // Clear authentication session only
        settingsStore.clearAuthenticationSession()
        
        // Verify user ID was preserved
        let userId = try settingsStore.retrieveUserId()
        XCTAssertEqual(userId, testUserId, "User ID should be preserved")
        
        // Verify device ID was preserved
        let deviceId = try settingsStore.retrieveDeviceId()
        XCTAssertEqual(deviceId, testDeviceId, "Device ID should be preserved")
        
        // Verify other settings were preserved
        XCTAssertEqual(settingsStore.selectedTheme, testTheme, "Theme should be preserved")
        XCTAssertFalse(settingsStore.isFirstLaunch, "First launch flag should be preserved")
    }
    
    /// Tests clearing all data including device ID
    func testClearAllData() throws {
        let testUserId = "12345"
        let testDeviceId = "iPhone_15_ABC123"
        let testTheme = "dark"
        
        // Store test data
        try settingsStore.storeUserId(testUserId)
        try settingsStore.storeDeviceId(testDeviceId)
        settingsStore.storeSelectedTheme(testTheme)
        settingsStore.storeFirstLaunchFlag(false)
        
        // Clear all data
        try settingsStore.clearAllData()
        
        // Verify all data was cleared
        let userId = try settingsStore.retrieveUserId()
        XCTAssertNil(userId, "User ID should be cleared")
        
        let deviceId = try settingsStore.retrieveDeviceId()
        XCTAssertNil(deviceId, "Device ID should be cleared")
        
        XCTAssertEqual(settingsStore.selectedTheme, "system", "Theme should reset to default")
        XCTAssertTrue(settingsStore.isFirstLaunch, "First launch flag should reset to default")
    }
    
    // MARK: - Error Handling Tests
    
    /// Tests that storage operations work independently
    func testIndependentStorageOperations() throws {
        let testUserId = "12345"
        let testDeviceId = "iPhone_15_ABC123"
        
        // Store user ID in Keychain
        try settingsStore.storeUserId(testUserId)
        
        // Store device ID in Keychain
        try settingsStore.storeDeviceId(testDeviceId)
        
        // Verify both are stored independently
        let retrievedUserId = try settingsStore.retrieveUserId()
        let retrievedDeviceId = try settingsStore.retrieveDeviceId()
        
        XCTAssertEqual(retrievedUserId, testUserId, "User ID should be stored in Keychain")
        XCTAssertEqual(retrievedDeviceId, testDeviceId, "Device ID should be stored in Keychain")
        
        // Remove user ID, device ID should remain
        try settingsStore.removeUserId()
        
        let userIdAfterRemoval = try settingsStore.retrieveUserId()
        let deviceIdAfterRemoval = try settingsStore.retrieveDeviceId()
        
        XCTAssertNil(userIdAfterRemoval, "User ID should be removed")
        XCTAssertEqual(deviceIdAfterRemoval, testDeviceId, "Device ID should remain")
    }
    
    /// Tests handling of empty strings
    func testEmptyStringHandling() throws {
        // Test empty user ID
        try settingsStore.storeUserId("")
        let retrievedUserId = try settingsStore.retrieveUserId()
        XCTAssertEqual(retrievedUserId, "", "Empty user ID should be stored and retrieved")
        
        // Test empty device ID
        try settingsStore.storeDeviceId("")
        let retrievedDeviceId = try settingsStore.retrieveDeviceId()
        XCTAssertEqual(retrievedDeviceId, "", "Empty device ID should be stored and retrieved")
        
        // Test empty theme
        settingsStore.storeSelectedTheme("")
        XCTAssertEqual(settingsStore.selectedTheme, "", "Empty theme should be stored and retrieved")
    }
}