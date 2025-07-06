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
    private let settingsStore = SettingsStore()
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "AppViewModel")
    
    /// Initialize AppViewModel and restore previous login state
    init() {
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
    private var isUserLoggedIn: Bool {
        get { UserDefaults.standard.bool(forKey: "is_logged_in") }
        set { UserDefaults.standard.set(newValue, forKey: "is_logged_in") }
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
            currentUser = User(id: response.data.user.id, deviceId: DeviceIdentifier.shared.deviceId)
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
            isLoading = false
            return false
        } catch {
            errorMessage = "Unexpected error occurred"
            logger.error("Logout failed with unexpected error: \(error.localizedDescription)")
            
            // Even if logout fails, clear local state
            currentUser = nil
            isLoggedIn = false
            isUserLoggedIn = false // Clear from UserDefaults
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
        if isUserLoggedIn, let userId = currentUserId {
            // Restore user session from stored data
            currentUser = User(id: Int(userId) ?? 0, deviceId: DeviceIdentifier.shared.deviceId)
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
