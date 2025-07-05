//
//  APIClient.swift
//  HomeAssistantPro
//
//  Purpose: Network service layer for API communication with authentication headers
//  Author: Claude
//  Created: 2025-07-04
//  Modified: 2025-07-04
//
//  Modification Log:
//  - 2025-07-04: Initial creation with HMAC-SHA256 signature generation
//
//  Functions:
//  - APIClient.shared: Singleton instance
//  - generateSignature(timestamp:): Generates HMAC-SHA256 signature for authentication
//  - performRequest(_:): Executes HTTP requests with authentication headers
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
    
    private let baseURL = "http://47.94.108.189:10000"
    private let appSecret = "EJFIDNFNGIUHq32923HDFHIHsdf866HU"
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "APIClient")
    
    private init() {}
    
    /// Generates HMAC-SHA256 signature for app-level authentication
    /// - Parameter timestamp: Current timestamp in milliseconds
    /// - Returns: Hex-encoded signature string
    private func generateSignature(timestamp: String) -> String {
        let key = SymmetricKey(data: appSecret.data(using: .utf8)!)
        let signature = HMAC<SHA256>.authenticationCode(for: timestamp.data(using: .utf8)!, using: key)
        return signature.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Performs HTTP request with authentication headers
    /// - Parameter request: URLRequest to execute
    /// - Returns: Response data and HTTP status code
    /// - Throws: APIError for various failure cases
    private func performRequest(_ request: URLRequest) async throws -> (Data, Int) {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            logger.info("API Response: \(httpResponse.statusCode) for \(request.url?.absoluteString ?? "unknown")")
            
            return (data, httpResponse.statusCode)
        } catch {
            logger.error("Network request failed: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }
    
    /// Creates authenticated URLRequest with required headers
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - method: HTTP method
    ///   - body: Request body data
    /// - Returns: Configured URLRequest
    private func createAuthenticatedRequest(endpoint: String, method: String, body: Data?) -> URLRequest {
        guard let url = URL(string: baseURL + endpoint) else {
            fatalError("Invalid URL: \(baseURL + endpoint)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication headers
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let signature = generateSignature(timestamp: timestamp)
        
        request.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
        request.setValue(signature, forHTTPHeaderField: "X-Signature")
        
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
    func login(userId: String, phoneNumber: String, password: String) async throws -> LoginResponse {
        // Get timestamp for password hashing (same as used in headers)
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        
        let loginRequest = LoginRequest(
            userId: userId,
            phoneNumber: phoneNumber,
            password: password,
            timestamp: timestamp
        )
        let body = try JSONEncoder().encode(loginRequest)
        
        let request = createAuthenticatedRequest(endpoint: "/api/auth/login", method: "POST", body: body)
        
        let (data, statusCode) = try await performRequest(request)
        
        switch statusCode {
        case 200:
            let response = try JSONDecoder().decode(LoginResponse.self, from: data)
            logger.info("Login successful for user: \(userId)")
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