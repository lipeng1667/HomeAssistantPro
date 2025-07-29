//
//  APIConfiguration.swift
//  HomeAssistantPro
//
//  Purpose: Shared API configuration for all network services
//  Author: Michael
//  Created: 2025-07-25
//  Modified: 2025-07-25
//
//  Modification Log:
//  - 2025-07-25: Initial creation to centralize API configuration
//
//  Functions:
//  - APIConfiguration.shared: Singleton instance with shared config
//  - generateSignature(timestamp:): Shared HMAC-SHA256 signature generation
//

import Foundation
import CryptoKit

/// Centralized API configuration shared across all network services
final class APIConfiguration {
    static let shared = APIConfiguration()
    
    /// Base URL for all API endpoints
    let baseURL = "http://47.94.108.189:10000"
    
    /// App secret for HMAC-SHA256 signature generation
    private let appSecret = "EJFIDNFNGIUHq32923HDFHIHsdf866HU"
    
    private init() {}
    
    /// Generates HMAC-SHA256 signature for app-level authentication
    /// - Parameter timestamp: Current timestamp in milliseconds
    /// - Returns: Hex-encoded signature string
    func generateSignature(timestamp: String) -> String {
        let key = SymmetricKey(data: appSecret.data(using: .utf8)!)
        let signature = HMAC<SHA256>.authenticationCode(for: timestamp.data(using: .utf8)!, using: key)
        return signature.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Creates standard authentication headers for API requests
    /// - Parameter sessionToken: Optional session token for enhanced security
    /// - Returns: Dictionary of authentication headers
    func createAuthHeaders(sessionToken: String? = nil) -> [String: String] {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let signature = generateSignature(timestamp: timestamp)
        
        var headers = [
            "Content-Type": "application/json",
            "X-Timestamp": timestamp,
            "X-Signature": signature
        ]
        
        if let token = sessionToken {
            headers["X-Session-Token"] = token
        }
        
        return headers
    }
}