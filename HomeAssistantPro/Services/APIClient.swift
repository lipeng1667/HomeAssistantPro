//
//  APIClient.swift
//  HomeAssistantPro
//
//  Purpose: Network service layer for API communication with authentication headers
//  Author: Michael
//  Created: 2025-07-04
//  Modified: 2025-07-25
//
//  Modification Log:
//  - 2025-07-04: Initial creation with HMAC-SHA256 signature generation
//  - 2025-07-06: Added SettingsStore integration for user ID storage
//  - 2025-07-25: Added session token support for enhanced admin security
//  - 2025-07-25: Refactored to use shared APIConfiguration for DRY principle
//
//  Functions:
//  - APIClient.shared: Singleton instance
//  - generateSignature(timestamp:): Generates HMAC-SHA256 signature for authentication
//  - performRequest(_:): Executes HTTP requests with authentication headers and detailed logging
//  - logRequest(_:): Logs complete request details including headers and body
//  - logResponse(_:data:): Logs response details including status and body
//  - authenticateAnonymously(deviceId:): Anonymous login API call
//  - register(accountName:phoneNumber:password:userId:): User registration API call
//  - login(userId:phoneNumber:password:): User login API call
//  - logout(userId:deviceId:): Logout API call
//

import Foundation
import CryptoKit
import os.log

/// Network service client for API communication with authentication
final class APIClient {
    static let shared = APIClient()
    
    private let apiConfig = APIConfiguration.shared
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "APIClient")
    private let settingsStore: SettingsStore
    
    /// Initialize APIClient with dependency injection
    /// - Parameter settingsStore: Settings storage service for user data persistence
    private init(settingsStore: SettingsStore = SettingsStore()) {
        self.settingsStore = settingsStore
    }
    
    
    /// Performs HTTP request with authentication headers
    /// - Parameter request: URLRequest to execute
    /// - Returns: Response data and HTTP status code
    /// - Throws: APIError for various failure cases
    private func performRequest(_ request: URLRequest) async throws -> (Data, Int) {
        // Log complete request details
        logRequest(request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Log response details
            logResponse(httpResponse, data: data)
            
            return (data, httpResponse.statusCode)
        } catch {
            logger.error("Network request failed: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }
    
    /// Logs complete request details including headers and body
    /// - Parameter request: URLRequest to log
    private func logRequest(_ request: URLRequest) {
        logger.info("📤 API REQUEST")
        logger.info("URL: \(request.url?.absoluteString ?? "Unknown")")
        logger.info("Method: \(request.httpMethod ?? "Unknown")")
        
        // Log headers
        logger.info("Headers:")
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                // Hide sensitive signature for security
                if key == "X-Signature" {
                    logger.info("  \(key): [HIDDEN]")
                } else {
                    logger.info("  \(key): \(value)")
                }
            }
        }
        
        // Log body
        if let body = request.httpBody {
            if let bodyString = String(data: body, encoding: .utf8) {
                logger.info("Body: \(bodyString)")
            } else {
                logger.info("Body: [Binary data, \(body.count) bytes]")
            }
        } else {
            logger.info("Body: [Empty]")
        }
        
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    /// Logs response details including status and body
    /// - Parameters:
    ///   - response: HTTPURLResponse received
    ///   - data: Response data
    private func logResponse(_ response: HTTPURLResponse, data: Data) {
        logger.info("📥 API RESPONSE")
        logger.info("Status: \(response.statusCode)")
        logger.info("URL: \(response.url?.absoluteString ?? "Unknown")")
        
        // Log response headers (optional, uncomment if needed)
        // logger.info("Response Headers:")
        // for (key, value) in response.allHeaderFields {
        //     logger.info("  \(key): \(value)")
        // }
        
        // Log response body
        if let responseString = String(data: data, encoding: .utf8) {
            logger.info("Response Body: \(responseString)")
        } else {
            logger.info("Response Body: [Binary data, \(data.count) bytes]")
        }
        
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    /// Creates authenticated URLRequest with required headers
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - method: HTTP method
    ///   - body: Request body data
    ///   - timestamp: Optional pre-generated timestamp (for password hashing consistency)
    /// - Returns: Configured URLRequest
    private func createAuthenticatedRequest(endpoint: String, method: String, body: Data?, timestamp: String? = nil) -> URLRequest {
        guard let url = URL(string: apiConfig.baseURL + endpoint) else {
            fatalError("Invalid URL: \(apiConfig.baseURL + endpoint)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add authentication headers using shared configuration
        let requestTimestamp = timestamp ?? String(Int(Date().timeIntervalSince1970 * 1000))
        let headers = apiConfig.createAuthHeaders()
        
        // Override timestamp if provided (for password hashing consistency)
        if let customTimestamp = timestamp {
            request.setValue(customTimestamp, forHTTPHeaderField: "X-Timestamp")
            request.setValue(apiConfig.generateSignature(timestamp: customTimestamp), forHTTPHeaderField: "X-Signature")
        } else {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    /// Performs anonymous login using secure device ID
    /// - Returns: LoginResponse with user information
    /// - Throws: APIError for authentication failures
    func authenticateAnonymously() async throws -> LoginResponse {
        let loginRequest = AnonymousLoginRequest()
        let body = try JSONEncoder().encode(loginRequest)
        
        let request = createAuthenticatedRequest(endpoint: "/api/auth/anonymous", method: "POST", body: body)
        
        let (data, statusCode) = try await performRequest(request)
        
        switch statusCode {
        case 200:
            let response = try JSONDecoder().decode(LoginResponse.self, from: data)
            logger.info("Anonymous login successful for device: \(loginRequest.deviceId)")
            
            // Store user ID securely in Keychain
            do {
                try settingsStore.storeUserId(String(response.data.user.id))
                // Store device ID for future use
                try settingsStore.storeDeviceId(loginRequest.deviceId)
                // Store session token if provided (usually not for anonymous users)
                if let sessionToken = response.data.user.sessionToken {
                    try settingsStore.storeSessionToken(sessionToken)
                }
                logger.info("User ID and device ID stored successfully")
            } catch {
                logger.error("Failed to store user credentials: \(error.localizedDescription)")
                // Note: We don't throw here as the login was successful
                // The caller should handle storage separately if needed
            }
            
            return response
        case 400:
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.badRequest(errorResponse.message)
        case 401:
            throw APIError.unauthorized
        case 500:
            throw APIError.serverError
        default:
            throw APIError.unknownError(statusCode)
        }
    }
    
    /// Registers a new user account
    /// - Parameters:
    ///   - accountName: User's full name
    ///   - phoneNumber: User's phone number
    ///   - password: Plain text password (will be hashed)
    ///   - userId: Optional user ID for existing anonymous users
    /// - Returns: LoginResponse with user information
    /// - Throws: APIError for registration failures
    func register(accountName: String, phoneNumber: String, password: String, userId: String? = nil) async throws -> LoginResponse {
        let registerRequest = RegisterRequest(
            accountName: accountName,
            phoneNumber: phoneNumber,
            password: password,
            userId: userId
        )
        let body = try JSONEncoder().encode(registerRequest)
        
        let request = createAuthenticatedRequest(endpoint: "/api/auth/register", method: "POST", body: body)
        
        let (data, statusCode) = try await performRequest(request)
        
        switch statusCode {
        case 200:
            let response = try JSONDecoder().decode(LoginResponse.self, from: data)
            logger.info("Registration successful for phone: \(phoneNumber)")
            
            // Store updated user ID and profile data
            do {
                try settingsStore.storeUserId(String(response.data.user.id))
                // Store session token if provided
                if let sessionToken = response.data.user.sessionToken {
                    try settingsStore.storeSessionToken(sessionToken)
                }
                // Store profile data with actual status from API (default to registered if missing)
                settingsStore.storeUserProfile(status: response.data.user.status ?? 2, accountName: accountName, phoneNumber: phoneNumber)
                logger.info("User ID and profile data stored successfully after registration")
            } catch {
                logger.error("Failed to store user credentials after registration: \(error.localizedDescription)")
            }
            
            return response
        case 400:
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.badRequest(errorResponse.message)
        case 500:
            throw APIError.serverError
        default:
            throw APIError.unknownError(statusCode)
        }
    }
    
    /// Logs in a user with phone number and password
    /// - Parameters:
    ///   - userId: User ID from previous session
    ///   - phoneNumber: User's phone number
    ///   - password: Plain text password (will be double-hashed)
    /// - Returns: LoginResponse with user information
    /// - Throws: APIError for login failures
    func login(userId: String?, phoneNumber: String, password: String) async throws -> LoginResponse {
        // Generate timestamp once for both password hashing and request headers
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        
        let loginRequest = LoginRequest(
            userId: userId,
            phoneNumber: phoneNumber,
            password: password,
            timestamp: timestamp
        )
        let body = try JSONEncoder().encode(loginRequest)
        
        // Pass the same timestamp to ensure consistency between password hash and headers
        let request = createAuthenticatedRequest(endpoint: "/api/auth/login", method: "POST", body: body, timestamp: timestamp)
        
        let (data, statusCode) = try await performRequest(request)
        
        switch statusCode {
        case 200:
            let response = try JSONDecoder().decode(LoginResponse.self, from: data)
            logger.info("Login successful for phone: \(phoneNumber), user_id: \(response.data.user.id)")
            
            // Store user ID and update status to registered (in case it changed)
            do {
                try settingsStore.storeUserId(String(response.data.user.id))
                // Store session token if provided
                if let sessionToken = response.data.user.sessionToken {
                    try settingsStore.storeSessionToken(sessionToken)
                }
                // Update status with actual API response and preserve existing profile data
                let existingAccountName = settingsStore.retrieveAccountName()
                let existingPhoneNumber = settingsStore.retrievePhoneNumber()
                settingsStore.storeUserProfile(status: response.data.user.status ?? 2, accountName: existingAccountName ?? response.data.user.name, phoneNumber: existingPhoneNumber ?? phoneNumber)
                logger.info("User ID confirmed and status updated after login")
            } catch {
                logger.error("Failed to store user credentials after login: \(error.localizedDescription)")
            }
            
            return response
        case 400:
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.badRequest(errorResponse.message)
        case 403:
            throw APIError.unauthorized // Wrong password
        case 500:
            throw APIError.serverError
        default:
            throw APIError.unknownError(statusCode)
        }
    }
    
    /// Logs out the authenticated user using secure device ID
    /// - Parameter userId: User ID from login response
    /// - Returns: Success message
    /// - Throws: APIError for logout failures
    func logout(userId: String) async throws -> String {
        let logoutRequest = LogoutRequest(userId: userId)
        let body = try JSONEncoder().encode(logoutRequest)
        
        let request = createAuthenticatedRequest(endpoint: "/api/auth/logout", method: "POST", body: body)
        
        let (data, statusCode) = try await performRequest(request)
        
        switch statusCode {
        case 200:
            let response = try JSONDecoder().decode(LogoutResponse.self, from: data)
            logger.info("Logout successful for user: \(userId)")
            
            // Clear login session (user_id and device_id remain for re-login)
            settingsStore.clearAuthenticationSession()
            logger.info("Login session cleared after logout")
            
            return response.message
        case 400, 401:
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.badRequest(errorResponse.message)
        case 500:
            throw APIError.serverError
        default:
            throw APIError.unknownError(statusCode)
        }
    }
}

/// API error types
enum APIError: LocalizedError {
    case invalidResponse
    case networkError(Error)
    case badRequest(String)
    case unauthorized
    case sessionExpired
    case serverError
    case unknownError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .badRequest(let message):
            return message
        case .unauthorized:
            return "Authentication failed"
        case .sessionExpired:
            return "Session expired. Please log in again."
        case .serverError:
            return "Server error occurred"
        case .unknownError(let code):
            return "Unknown error with status code: \(code)"
        }
    }
}