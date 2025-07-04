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
//
//  Functions:
//  - Codable models for API communication
//  - AnonymousLoginRequest: Anonymous login request payload
//  - LogoutRequest: Logout request payload
//  - LoginResponse: Login success response
//  - LogoutResponse: Logout success response
//  - ErrorResponse: Error response format
//

import Foundation

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