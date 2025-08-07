//
//  AdminChatService.swift
//  HomeAssistantPro
//
//  Purpose: Service for admin chat management API endpoints
//  Author: Assistant
//  Create date: 2025-08-07
//  Latest modify date: 2025-08-07
//
//  Modification log:
//  - 2025-08-07: Initial creation with admin chat management endpoints
//
//  Functions:
//  - fetchDashboard(): Get admin chat dashboard statistics
//  - fetchConversations(page:limit:status:assignedAdmin:userId:unreadOnly:sort:): List all conversations with filters
//  - fetchConversationDetails(conversationId:): Get specific conversation details
//  - assignConversation(_:to:notes:): Assign conversation to admin
//  - updateConversationStatus(_:status:priority:tags:resolutionNotes:): Update conversation metadata
//  - sendMessage(conversationId:message:messageType:internalNote:): Send admin message
//

import Foundation
import os.log

/// Service for admin chat management operations
final class AdminChatService: ObservableObject {
    static let shared = AdminChatService()
    
    private let apiConfig = APIConfiguration.shared
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "AdminChatService")
    private let settingsStore: SettingsStore
    
    /// Initialize AdminChatService with dependency injection
    /// - Parameter settingsStore: Settings storage service for authentication data
    private init(settingsStore: SettingsStore = SettingsStore()) {
        self.settingsStore = settingsStore
    }
    
    /// Creates authenticated URLRequest with admin headers
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - method: HTTP method
    ///   - body: Request body data
    /// - Returns: Configured URLRequest
    /// - Throws: AdminChatError for authentication setup failures
    private func createAdminRequest(endpoint: String, method: String, body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: apiConfig.baseURL + endpoint) else {
            throw AdminChatError.invalidEndpoint
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        
        // Use shared authentication headers from APIConfiguration
        let sessionToken = try? settingsStore.retrieveSessionToken()
        let headers = apiConfig.createAuthHeaders(sessionToken: sessionToken)
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add admin authorization header if session token exists
        if let sessionToken = sessionToken {
            request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    /// Performs HTTP request and handles admin-specific errors
    /// - Parameter request: URLRequest to execute
    /// - Returns: Response data
    /// - Throws: AdminChatError for various failure cases
    private func performRequest(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AdminChatError.invalidResponse
            }
            
            logger.info("Admin Chat API Response: \(httpResponse.statusCode) for \(request.url?.absoluteString ?? "unknown")")
            
            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 401:
                throw AdminChatError.unauthorized
            case 403:
                throw AdminChatError.adminRequired
            case 404:
                throw AdminChatError.conversationNotFound
            case 429:
                throw AdminChatError.rateLimited
            case 500...599:
                throw AdminChatError.serverError
            default:
                throw AdminChatError.unknownError(httpResponse.statusCode)
            }
        } catch let error as AdminChatError {
            throw error
        } catch {
            logger.error("Network error in admin chat request: \(error.localizedDescription)")
            throw AdminChatError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Public API Methods
    
    /// Fetches admin chat dashboard statistics and overview
    /// - Parameter adminId: Optional specific admin ID for personalized data
    /// - Returns: AdminChatDashboard with statistics and recent activity
    /// - Throws: AdminChatError for various failure cases
    func fetchDashboard(adminId: Int? = nil) async throws -> AdminChatDashboard {
        var endpoint = "/admin/chat/dashboard"
        if let adminId = adminId {
            endpoint += "?admin_id=\(adminId)"
        }
        
        let request = try createAdminRequest(endpoint: endpoint, method: "GET")
        let data = try await performRequest(request)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        struct DashboardResponse: Codable {
            let status: String
            let data: AdminChatDashboard
        }
        
        let response = try decoder.decode(DashboardResponse.self, from: data)
        
        guard response.status == "success" else {
            throw AdminChatError.invalidResponse
        }
        
        return response.data
    }
    
    /// Fetches conversations list with advanced filtering options
    /// - Parameters:
    ///   - page: Page number (1-based, default: 1)
    ///   - limit: Items per page (1-100, default: 20)
    ///   - status: Filter by status (optional)
    ///   - assignedAdmin: Filter by assigned admin ID (optional)
    ///   - userId: Filter by specific user ID (optional)
    ///   - unreadOnly: Show only conversations with unread messages (default: false)
    ///   - sort: Sort order - "newest", "oldest", "last_activity" (default: "newest")
    /// - Returns: AdminConversationsResponse with conversations and pagination
    /// - Throws: AdminChatError for various failure cases
    func fetchConversations(
        page: Int = 1,
        limit: Int = 20,
        status: String? = nil,
        assignedAdmin: Int? = nil,
        userId: Int? = nil,
        unreadOnly: Bool = false,
        sort: String = "newest"
    ) async throws -> AdminConversationsResponse {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "unread_only", value: String(unreadOnly)),
            URLQueryItem(name: "sort", value: sort)
        ]
        
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        
        if let assignedAdmin = assignedAdmin {
            queryItems.append(URLQueryItem(name: "assigned_admin", value: String(assignedAdmin)))
        }
        
        if let userId = userId {
            queryItems.append(URLQueryItem(name: "user_id", value: String(userId)))
        }
        
        var urlComponents = URLComponents(string: apiConfig.baseURL + "/admin/chat/conversations")!
        urlComponents.queryItems = queryItems
        
        guard let finalEndpoint = urlComponents.url?.absoluteString.replacingOccurrences(of: apiConfig.baseURL, with: "") else {
            throw AdminChatError.invalidEndpoint
        }
        
        let request = try createAdminRequest(endpoint: finalEndpoint, method: "GET")
        
        let data = try await performRequest(request)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let response = try decoder.decode(AdminConversationsResponse.self, from: data)
        
        guard response.status == "success" else {
            throw AdminChatError.invalidResponse
        }
        
        return response
    }
    
    /// Fetches detailed information about a specific conversation
    /// - Parameter conversationId: Conversation ID to retrieve
    /// - Returns: AdminConversation with complete details
    /// - Throws: AdminChatError for various failure cases
    func fetchConversationDetails(conversationId: Int) async throws -> AdminConversation {
        let endpoint = "/admin/chat/conversations/\(conversationId)"
        let request = try createAdminRequest(endpoint: endpoint, method: "GET")
        let data = try await performRequest(request)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        struct ConversationDetailResponse: Codable {
            let status: String
            let data: ConversationWrapper
        }
        
        struct ConversationWrapper: Codable {
            let conversation: AdminConversation
        }
        
        let response = try decoder.decode(ConversationDetailResponse.self, from: data)
        
        guard response.status == "success" else {
            throw AdminChatError.invalidResponse
        }
        
        return response.data.conversation
    }
    
    /// Assigns a conversation to a specific admin
    /// - Parameters:
    ///   - conversationId: Conversation ID to assign
    ///   - adminId: Admin ID to assign conversation to
    ///   - notes: Optional assignment notes
    /// - Returns: Assignment confirmation data
    /// - Throws: AdminChatError for various failure cases
    func assignConversation(_ conversationId: Int, to adminId: Int, notes: String? = nil) async throws -> AssignmentResponse {
        let endpoint = "/admin/chat/conversations/\(conversationId)/assign"
        
        var requestBody: [String: Any] = ["admin_id": adminId]
        if let notes = notes {
            requestBody["notes"] = notes
        }
        
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)
        let request = try createAdminRequest(endpoint: endpoint, method: "PUT", body: bodyData)
        let data = try await performRequest(request)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        struct AssignmentResponseWrapper: Codable {
            let status: String
            let data: AssignmentResponse
        }
        
        let response = try decoder.decode(AssignmentResponseWrapper.self, from: data)
        
        guard response.status == "success" else {
            throw AdminChatError.invalidResponse
        }
        
        return response.data
    }
    
    /// Updates conversation status, priority, and management tags
    /// - Parameters:
    ///   - conversationId: Conversation ID to update
    ///   - status: New status (optional)
    ///   - priority: Priority level (optional)
    ///   - tags: Array of tag strings (optional)
    ///   - resolutionNotes: Notes when closing conversation (optional)
    /// - Returns: Updated conversation metadata
    /// - Throws: AdminChatError for various failure cases
    func updateConversationStatus(
        _ conversationId: Int,
        status: String? = nil,
        priority: String? = nil,
        tags: [String]? = nil,
        resolutionNotes: String? = nil
    ) async throws -> ConversationStatusResponse {
        let endpoint = "/admin/chat/conversations/\(conversationId)/status"
        
        var requestBody: [String: Any] = [:]
        if let status = status { requestBody["status"] = status }
        if let priority = priority { requestBody["priority"] = priority }
        if let tags = tags { requestBody["tags"] = tags }
        if let resolutionNotes = resolutionNotes { requestBody["resolution_notes"] = resolutionNotes }
        
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)
        let request = try createAdminRequest(endpoint: endpoint, method: "PUT", body: bodyData)
        let data = try await performRequest(request)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        struct StatusResponseWrapper: Codable {
            let status: String
            let data: ConversationStatusResponse
        }
        
        let response = try decoder.decode(StatusResponseWrapper.self, from: data)
        
        guard response.status == "success" else {
            throw AdminChatError.invalidResponse
        }
        
        return response.data
    }
    
    /// Sends a message as an admin to a specific conversation
    /// - Parameters:
    ///   - conversationId: Conversation ID to send message to
    ///   - message: Message content
    ///   - messageType: Type of message (default: "text")
    ///   - internalNote: Private admin note (optional)
    /// - Returns: Sent message details
    /// - Throws: AdminChatError for various failure cases
    func sendMessage(
        conversationId: Int,
        message: String,
        messageType: String = "text",
        internalNote: String? = nil
    ) async throws -> AdminChatMessage {
        let endpoint = "/admin/chat/conversations/\(conversationId)/messages"
        
        var requestBody: [String: Any] = [
            "message": message,
            "message_type": messageType
        ]
        if let internalNote = internalNote {
            requestBody["internal_note"] = internalNote
        }
        
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)
        let request = try createAdminRequest(endpoint: endpoint, method: "POST", body: bodyData)
        let data = try await performRequest(request)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        struct MessageResponse: Codable {
            let status: String
            let data: AdminChatMessage
        }
        
        let response = try decoder.decode(MessageResponse.self, from: data)
        
        guard response.status == "success" else {
            throw AdminChatError.invalidResponse
        }
        
        return response.data
    }
}

// MARK: - Response Models

/// Assignment response model
struct AssignmentResponse: Codable {
    let conversationId: Int
    let assignedAdmin: AdminInfo
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case assignedAdmin = "assigned_admin"
        case notes
    }
}

/// Conversation status update response
struct ConversationStatusResponse: Codable {
    let conversationId: Int
    let status: String
    let priority: String
    let tags: [String]
    let resolutionNotes: String?
    let updatedBy: String
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case status
        case priority
        case tags
        case resolutionNotes = "resolution_notes"
        case updatedBy = "updated_by"
        case updatedAt = "updated_at"
    }
}

// MARK: - Error Types

/// Errors specific to admin chat operations
enum AdminChatError: Error, LocalizedError {
    case invalidEndpoint
    case unauthorized
    case adminRequired
    case conversationNotFound
    case rateLimited
    case serverError
    case networkError(String)
    case invalidResponse
    case unknownError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "Invalid API endpoint"
        case .unauthorized:
            return "Authentication failed"
        case .adminRequired:
            return "Admin access required"
        case .conversationNotFound:
            return "Conversation not found"
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        case .serverError:
            return "Server error occurred"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid server response"
        case .unknownError(let code):
            return "Unknown error occurred (Code: \(code))"
        }
    }
}