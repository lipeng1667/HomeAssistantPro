//
//  IMService.swift
//  HomeAssistantPro
//
//  Purpose: Service for instant messaging API integration
//  Author: Michael
//  Created: 2025-07-14
//  Modified: 2025-07-14
//
//  Modification Log:
//  - 2025-07-14: Initial creation with chat message API integration
//
//  Functions:
//  - fetchMessages: Get chat history from API
//  - sendMessage: Send message to admin
//  - HMAC-SHA256 authentication with user_id
//  - Error handling and response parsing
//

import Foundation
import CryptoKit
import os.log

/// Service for instant messaging API operations
class IMService: ObservableObject {
    
    // MARK: - Properties
    
    /// Shared instance
    static let shared = IMService()
    
    /// Base URL for API requests
    private let baseURL = "http://47.94.108.189:10000"
    
    /// App secret for HMAC authentication
    private let appSecret = "EJFIDNFNGIUHq32923HDFHIHsdf866HU"
    
    /// URL session for network requests with custom configuration
    private let urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()
    
    /// Logger for debugging
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "IMService")
    
    /// Current user ID
    @Published var currentUserId: Int?
    
    /// Loading state
    @Published var isLoading = false
    
    /// Error message
    @Published var errorMessage: String?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Fetch chat messages from API
    /// - Parameters:
    ///   - userId: User ID to fetch messages for
    ///   - page: Page number (default: 1 = newest messages)
    ///   - limit: Number of messages per page (default: 20)
    /// - Returns: Array of chat messages ordered chronologically (oldest first)
    /// - Note: Server returns newest messages first, this function reverses them for proper chat display
    func fetchMessages(userId: Int, page: Int = 1, limit: Int = 20) async throws -> [ChatMessage] {
        logger.info("Fetching chat messages for user: \(userId), page: \(page), limit: \(limit)")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // Create URL with query parameters
        var components = URLComponents(string: "\(baseURL)/api/chat/messages")
        components?.queryItems = [
            URLQueryItem(name: "user_id", value: String(userId)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components?.url else {
            throw IMServiceError.networkError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication headers
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let signature = generateSignature(timestamp: timestamp)
        
        request.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
        request.setValue(signature, forHTTPHeaderField: "X-Signature")
        
        // Log request details
        logger.debug("Request URL: \(request.url?.absoluteString ?? "unknown")")
        logger.debug("Request method: \(request.httpMethod ?? "unknown")")
        logger.debug("Request headers: \(String(describing: request.allHTTPHeaderFields))")
        logger.debug("Request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "empty")")
        
        // Perform request
        let (data, response) = try await urlSession.data(for: request)
        
        // Log response details
        if let httpResponse = response as? HTTPURLResponse {
            logger.debug("Response status: \(httpResponse.statusCode)")
            logger.debug("Response headers: \(String(describing: httpResponse.allHeaderFields))")
        }
        logger.debug("Response data: \(String(data: data, encoding: .utf8) ?? "empty")")
        
        // Check HTTP status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IMServiceError.networkError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = "HTTP \(httpResponse.statusCode)"
            logger.error("HTTP error: \(errorMessage)")
            throw IMServiceError.networkError(errorMessage)
        }
        
        // Parse response
        do {
            let decoder = JSONDecoder()
            let chatResponse = try decoder.decode(ChatMessagesResponse.self, from: data)
            
            if chatResponse.status == "success" {
                await MainActor.run {
                    currentUserId = userId
                }
                logger.info("Successfully fetched \(chatResponse.data.messages.count) messages")
                
                // Server returns newest messages first, but chat UI needs oldest first
                // So we reverse the array to show messages in chronological order
                let orderedMessages = chatResponse.data.messages.reversed()
                return Array(orderedMessages)
            } else {
                throw IMServiceError.networkError("API returned error status")
            }
        } catch {
            logger.error("Failed to decode response: \(error.localizedDescription)")
            throw IMServiceError.jsonParsingError
        }
    }
    
    /// Send message to admin
    /// - Parameters:
    ///   - message: Message content
    ///   - userId: User ID sending the message
    /// - Returns: Sent message details
    func sendMessage(message: String, userId: Int) async throws -> ChatMessage {
        logger.info("Sending message from user: \(userId)")
        
        // Validate input
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw IMServiceError.emptyMessage
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // Create request
        guard let url = URL(string: "\(baseURL)/api/chat/messages") else {
            throw IMServiceError.networkError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add authentication headers
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let signature = generateSignature(timestamp: timestamp)
        
        request.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
        request.setValue(signature, forHTTPHeaderField: "X-Signature")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add request body with user_id and message
        let requestBody = SendMessageRequest(userId: userId, message: message)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // Log request details
        logger.debug("Request URL: \(request.url?.absoluteString ?? "unknown")")
        logger.debug("Request method: \(request.httpMethod ?? "unknown")")
        logger.debug("Request headers: \(String(describing: request.allHTTPHeaderFields))")
        logger.debug("Request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "empty")")
        
        // Perform request
        let (data, response) = try await urlSession.data(for: request)
        
        // Log response details
        if let httpResponse = response as? HTTPURLResponse {
            logger.debug("Response status: \(httpResponse.statusCode)")
            logger.debug("Response headers: \(String(describing: httpResponse.allHeaderFields))")
        }
        logger.debug("Response data: \(String(data: data, encoding: .utf8) ?? "empty")")
        
        // Check HTTP status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IMServiceError.networkError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let errorMessage = "HTTP \(httpResponse.statusCode)"
            logger.error("HTTP error: \(errorMessage)")
            throw IMServiceError.networkError(errorMessage)
        }
        
        // Parse response
        do {
            let decoder = JSONDecoder()
            let sendResponse = try decoder.decode(SendMessageResponse.self, from: data)
            
            if sendResponse.status == "success" {
                // Convert SendMessageData to ChatMessage
                let chatMessage = ChatMessage(
                    id: sendResponse.data.id,
                    conversationId: sendResponse.data.conversationId,
                    userId: userId,
                    adminId: nil,
                    senderRole: sendResponse.data.senderRole,
                    messageType: .text,
                    content: sendResponse.data.content,
                    fileId: nil,
                    fileUrl: nil,
                    metadata: nil,
                    isRead: 0,
                    timestamp: sendResponse.data.timestamp,
                    senderIdentifier: "user_\(userId)"
                )
                
                logger.info("Successfully sent message with ID: \(chatMessage.id)")
                return chatMessage
            } else {
                throw IMServiceError.networkError("API returned error status")
            }
        } catch {
            logger.error("Failed to decode response: \(error.localizedDescription)")
            throw IMServiceError.jsonParsingError
        }
    }
    
    // MARK: - Helper Methods
    
    /// Generate HMAC-SHA256 signature for authentication
    /// - Parameter timestamp: Current timestamp
    /// - Returns: Hex-encoded signature
    private func generateSignature(timestamp: String) -> String {
        let key = SymmetricKey(data: appSecret.data(using: .utf8)!)
        let signature = HMAC<SHA256>.authenticationCode(for: timestamp.data(using: .utf8)!, using: key)
        return Data(signature).map { String(format: "%02hhx", $0) }.joined()
    }
    
    /// Get current user ID from service
    /// - Returns: User ID string
    func getCurrentUserId() throws -> String {
        guard let userId = currentUserId else {
            throw IMServiceError.invalidUserId
        }
        return String(userId)
    }
    
    /// Clear current user session
    func clearSession() {
        currentUserId = nil
        errorMessage = nil
    }
    
    /// Set current user ID
    /// - Parameter userId: User ID to set (or nil to clear)
    func setCurrentUserId(_ userId: Int?) {
        currentUserId = userId
    }
    
    // MARK: - Error Handling
    
    /// Handle network errors with user-friendly messages
    /// - Parameter error: Error to handle
    /// - Returns: User-friendly error message
    func handleError(_ error: Error) -> String {
        let errorMessage: String
        
        if let imError = error as? IMServiceError {
            errorMessage = imError.localizedDescription
        } else if error.localizedDescription.contains("cancelled") {
            // Don't show cancelled errors to user
            return ""
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .cancelled:
                return "" // Don't show cancelled errors
            case .timedOut:
                errorMessage = "Request timed out. Please try again."
            case .notConnectedToInternet:
                errorMessage = "No internet connection. Please check your network."
            case .networkConnectionLost:
                errorMessage = "Network connection lost. Please try again."
            default:
                errorMessage = "Network error: \(urlError.localizedDescription)"
            }
        } else {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        
        logger.error("IM Service error: \(errorMessage)")
        
        Task { @MainActor in
            self.errorMessage = errorMessage
        }
        
        return errorMessage
    }
}