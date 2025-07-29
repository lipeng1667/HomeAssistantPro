//
//  AppViewModel.swift
//  HomeAssistantPro
//
//  Purpose: Manages global app state, including login status.
//  Author: Michael
//  Created: 2025-06-24
//  Modified: 2025-07-06
//
//  Modification Log:
//  - 2025-07-04: Added real API authentication with anonymous login and logout
//  - 2025-07-04: Integrated secure DeviceIdentifier for device identification
//  - 2025-07-06: Integrated SettingsStore for secure user ID storage
//
//  Functions:
//  - loginAnonymously(): Performs anonymous login via API
//  - logout(): Logs out user via API
//

import SwiftUI
import os.log

/// View model for managing global app state, including login status.
final class AppViewModel: ObservableObject {
    /// Indicates whether the user is logged in.
    @Published var isLoggedIn: Bool = false
    
    /// Current logged-in user information
    @Published var currentUser: User?
    
    /// Error message for login failures
    @Published var errorMessage: String?
    
    /// Loading state for authentication operations
    @Published var isLoading: Bool = false
    
    private let apiClient = APIClient.shared
    private var settingsStore: SettingsStore
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "AppViewModel")
    
    /// Initialize AppViewModel with optional SettingsStore injection
    init(settingsStore: SettingsStore = SettingsStore()) {
        self.settingsStore = settingsStore
        restoreLoginState()
    }
    
    /// Public accessor for current user ID stored securely in Keychain
    var currentUserId: String? {
        get {
            do {
                return try settingsStore.retrieveUserId()
            } catch {
                logger.error("Failed to retrieve user ID: \(error.localizedDescription)")
                return nil
            }
        }
        set {
            if let newValue = newValue {
                do {
                    try settingsStore.storeUserId(newValue)
                } catch {
                    logger.error("Failed to store user ID: \(error.localizedDescription)")
                }
            } else {
                do {
                    try settingsStore.removeUserId()
                } catch {
                    logger.error("Failed to remove user ID: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Login state stored in UserDefaults
    var isUserLoggedIn: Bool {
        get { UserDefaults.standard.bool(forKey: "is_logged_in") }
        set { UserDefaults.standard.set(newValue, forKey: "is_logged_in") }
    }
    
    /// Computed property to check if current user is anonymous (view-only access)
    /// Returns true if user status is 1 (anonymous), false otherwise
    var isAnonymousUser: Bool {
        return settingsStore.retrieveUserStatus() == 1
    }
    
    /// Performs anonymous login via API
    /// - Returns: Success/failure status
    @MainActor
    func loginAnonymously() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.authenticateAnonymously()
            
            // Store user information (user ID is now stored securely by APIClient)
            let deviceId = try settingsStore.getOrCreateDeviceId()
            // Create user with anonymous status (1)
            currentUser = User(id: response.data.user.id, deviceId: deviceId, status: 1)
            // Store user status for persistence
            settingsStore.storeUserStatus(1)
            isLoggedIn = true
            isUserLoggedIn = true // Persist to UserDefaults
            
            logger.info("Anonymous login successful for user ID: \(response.data.user.id)")
            isLoading = false
            return true
            
        } catch let error as APIError {
            if case .sessionExpired = error {
                forceLogout()
            } else {
                errorMessage = error.localizedDescription
            }
            logger.error("Anonymous login failed: \(error.localizedDescription)")
            isLoading = false
            return false
        } catch {
            errorMessage = "Unexpected error occurred"
            logger.error("Anonymous login failed with unexpected error: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }
    
    /// Logs out the current user via API
    /// - Returns: Success/failure status
    @MainActor
    func logout() async -> Bool {
        guard let userId = currentUserId else {
            isLoggedIn = false
            currentUser = nil
            return true
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await apiClient.logout(userId: userId)
            
            // Clear user session (user ID persists for re-login)
            currentUser = nil
            isLoggedIn = false
            isUserLoggedIn = false // Clear from UserDefaults
            
            // Clear chat cache to prevent data leakage between users
            CacheManager.shared.clearChatCache()
            
            logger.info("Logout successful")
            isLoading = false
            return true
            
        } catch let error as APIError {
            if case .sessionExpired = error {
                // Session already expired, just clear local state
                logger.info("Session was already expired during logout")
            } else {
                errorMessage = error.localizedDescription
                logger.error("Logout failed: \(error.localizedDescription)")
            }
            
            // Even if logout fails, clear local state
            currentUser = nil
            isLoggedIn = false
            isUserLoggedIn = false // Clear from UserDefaults
            
            // Clear chat cache to prevent data leakage between users
            CacheManager.shared.clearChatCache()
            
            isLoading = false
            return false
        } catch {
            errorMessage = "Unexpected error occurred"
            logger.error("Logout failed with unexpected error: \(error.localizedDescription)")
            
            // Even if logout fails, clear local state
            currentUser = nil
            isLoggedIn = false
            isUserLoggedIn = false // Clear from UserDefaults
            
            // Clear chat cache to prevent data leakage between users
            CacheManager.shared.clearChatCache()
            
            isLoading = false
            return false
        }
    }
    
    /// Synchronous login method for legacy compatibility
    func login() {
        Task {
            await loginAnonymously()
        }
    }
    
    /// Restores login state from secure storage on app launch
    private func restoreLoginState() {
        logger.info("DEBUG RESTORE: Restoring login state - isUserLoggedIn: \(self.isUserLoggedIn), currentUserId: \(self.currentUserId ?? "nil")")
        if isUserLoggedIn, let userId = currentUserId {
            // Restore user session from stored data
            do {
                let deviceId = try settingsStore.getOrCreateDeviceId()
                let userStatus = settingsStore.retrieveUserStatus()
                let accountName = settingsStore.retrieveAccountName()
                let phoneNumber = settingsStore.retrievePhoneNumber()
                
                logger.info("DEBUG RESTORE: Retrieved data - userId: \(userId), userStatus: \(userStatus), accountName: \(accountName ?? "nil")")
                
                let restoredUser = User(
                    id: Int(userId) ?? 0,
                    deviceId: deviceId,
                    status: userStatus,
                    accountName: accountName,
                    phoneNumber: phoneNumber
                )
                currentUser = restoredUser
            } catch {
                logger.error("DEBUG RESTORE: Failed to restore device ID: \(error.localizedDescription)")
                // Fallback to logged out state if device ID cannot be retrieved
                isLoggedIn = false
                return
            }
            isLoggedIn = true
            logger.info("Login state restored for user ID: \(userId)")
        } else {
            // No valid session found
            isLoggedIn = false
            logger.info("No previous login state found")
        }
    }
    
    /// Forces logout when session expires (called from API errors)
    @MainActor
    func forceLogout() {
        // Don't clear user_id - it persists for re-login
        currentUser = nil
        isLoggedIn = false
        isUserLoggedIn = false
        errorMessage = "Your session has expired. Please log in again."
        logger.info("User session expired, forced logout")
    }
} 
