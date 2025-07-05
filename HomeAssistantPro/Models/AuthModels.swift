//
//  AuthModels.swift
//  HomeAssistantPro
//
//  Purpose: Data models for authentication API requests and responses
//  Author: Claude
//  Created: 2025-07-04
//  Modified: 2025-07-04
//
//  Modification Log:
//  - 2025-07-04: Initial creation with anonymous login and logout models
//  - 2025-07-05: Added register and login request/response models
//
//  Functions:
//  - Codable models for API communication
//  - AnonymousLoginRequest: Anonymous login request payload
//  - RegisterRequest: User registration request payload
//  - LoginRequest: User login request payload
//  - LogoutRequest: Logout request payload
//  - LoginResponse: Login success response
//  - LogoutResponse: Logout success response
//  - ErrorResponse: Error response format
//

import Foundation
import CryptoKit

// MARK: - Request Models

/// Request payload for anonymous login
struct AnonymousLoginRequest: Codable {
    let deviceId: String
    
    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
    }
    
    /// Creates anonymous login request with secure device ID
    init() {
        self.deviceId = DeviceIdentifier.shared.deviceId
    }
    
    /// Creates anonymous login request with custom device ID (for testing)
    init(deviceId: String) {
        self.deviceId = deviceId
    }
}

/// Request payload for user registration
struct RegisterRequest: Codable {
    let deviceId: String
    let accountName: String
    let phoneNumber: String
    let password: String
    let userId: String?
    
    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case accountName = "account_name"
        case phoneNumber = "phone_number"
        case password
        case userId = "user_id"
    }
    
    /// Creates registration request with hashed password
    /// - Parameters:
    ///   - accountName: User's full name
    ///   - phoneNumber: User's phone number
    ///   - password: Plain text password (will be hashed)
    ///   - userId: Optional user ID for existing anonymous users
    init(accountName: String, phoneNumber: String, password: String, userId: String? = nil) {
        self.deviceId = DeviceIdentifier.shared.deviceId
        self.accountName = accountName
        self.phoneNumber = phoneNumber
        self.password = Self.hashPassword(password)
        self.userId = userId
    }
    
    /// Hashes password using SHA-256
    /// - Parameter password: Plain text password
    /// - Returns: SHA-256 hashed password as hex string
    private static func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

/// Request payload for user login
struct LoginRequest: Codable {
    let userId: String
    let phoneNumber: String
    let password: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case phoneNumber = "phone_number"
        case password
    }
    
    /// Creates login request with double-hashed password
    /// - Parameters:
    ///   - userId: User ID from previous session
    ///   - phoneNumber: User's phone number
    ///   - password: Plain text password (will be double-hashed)
    ///   - timestamp: Current timestamp for password hashing
    init(userId: String, phoneNumber: String, password: String, timestamp: String) {
        self.userId = userId
        self.phoneNumber = phoneNumber
        self.password = Self.hashPasswordWithTimestamp(password, timestamp: timestamp)
    }
    
    /// Double-hashes password with timestamp: SHA-256(SHA-256(password) + timestamp)
    /// - Parameters:
    ///   - password: Plain text password
    ///   - timestamp: Current timestamp string
    /// - Returns: Double-hashed password as hex string
    private static func hashPasswordWithTimestamp(_ password: String, timestamp: String) -> String {
        // First hash: SHA-256(password)
        let firstHash = SHA256.hash(data: Data(password.utf8))
        let firstHashString = firstHash.compactMap { String(format: "%02x", $0) }.joined()
        
        // Second hash: SHA-256(firstHash + timestamp)
        let combinedData = Data((firstHashString + timestamp).utf8)
        let secondHash = SHA256.hash(data: combinedData)
        return secondHash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

/// Request payload for logout
struct LogoutRequest: Codable {
    let userId: String
    let deviceId: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case deviceId = "device_id"
    }
    
    /// Creates logout request with secure device ID
    init(userId: String) {
        self.userId = userId
        self.deviceId = DeviceIdentifier.shared.deviceId
    }
    
    /// Creates logout request with custom device ID (for testing)
    init(userId: String, deviceId: String) {
        self.userId = userId
        self.deviceId = deviceId
    }
}

// MARK: - Response Models

/// Response model for successful login
struct LoginResponse: Codable {
    let status: String
    let data: LoginData
    
    struct LoginData: Codable {
        let user: User
        
        struct User: Codable {
            let id: Int
        }
    }
}

/// Response model for successful logout
struct LogoutResponse: Codable {
    let status: String
    let message: String
}

/// Response model for API errors
struct ErrorResponse: Codable {
    let status: String
    let message: String
}

// MARK: - User Data Models

/// User information model
struct User: Codable {
    let id: Int
    let deviceId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case deviceId = "device_id"
    }
}