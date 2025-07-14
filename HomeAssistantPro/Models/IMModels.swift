//
//  IMModels.swift
//  HomeAssistantPro
//
//  Purpose: Data models for instant messaging API requests and responses
//  Author: Michael
//  Created: 2025-07-14
//  Modified: 2025-07-14
//
//  Modification Log:
//  - 2025-07-14: Initial creation with chat message and WebSocket event models
//
//  Functions:
//  - Codable models for IM API communication
//  - ChatMessage: Message data with sender role and content
//  - WebSocket event models for real-time communication
//  - Request/Response models for API calls
//

import Foundation

// MARK: - Core IM Models

/// Chat message model matching API response structure
struct ChatMessage: Codable, Identifiable, Equatable {
    let id: Int
    let conversationId: Int
    let userId: Int?
    let adminId: Int?
    let senderRole: SenderRole
    let messageType: MessageType
    let content: String
    let fileId: String?
    let fileUrl: String?
    let metadata: String?
    let isRead: Int
    let timestamp: String
    let senderIdentifier: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case userId = "user_id"
        case adminId = "admin_id"
        case senderRole = "sender_role"
        case messageType = "message_type"
        case content
        case fileId = "file_id"
        case fileUrl = "file_url"
        case metadata
        case isRead = "is_read"
        case timestamp
        case senderIdentifier = "sender_identifier"
    }
    
    /// Computed property for formatted time ago
    var timeAgo: String {
        // Debug: print the timestamp for debugging
        print("DEBUG: Processing timestamp: '\(timestamp)'")
        
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        
        // Try ISO8601 format first
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: timestamp) {
            let result = formatter.localizedString(for: date, relativeTo: Date())
            print("DEBUG: ISO8601 parsed successfully, result: '\(result)'")
            return result
        }
        
        // Fallback to RFC3339 format
        let rfc3339Formatter = DateFormatter()
        rfc3339Formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        rfc3339Formatter.locale = Locale(identifier: "en_US_POSIX")
        rfc3339Formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let date = rfc3339Formatter.date(from: timestamp) {
            let result = formatter.localizedString(for: date, relativeTo: Date())
            print("DEBUG: RFC3339 parsed successfully, result: '\(result)'")
            return result
        }
        
        // Additional fallback for format with fractional seconds
        rfc3339Formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = rfc3339Formatter.date(from: timestamp) {
            let result = formatter.localizedString(for: date, relativeTo: Date())
            print("DEBUG: RFC3339 with fractional seconds parsed successfully, result: '\(result)'")
            return result
        }
        
        // Additional fallback for format without Z
        rfc3339Formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = rfc3339Formatter.date(from: timestamp) {
            let result = formatter.localizedString(for: date, relativeTo: Date())
            print("DEBUG: RFC3339 without Z parsed successfully, result: '\(result)'")
            return result
        }
        
        print("DEBUG: All timestamp parsing failed for: '\(timestamp)'")
        return "Unknown"
    }
    
    /// Computed property to check if message is from current user
    var isFromCurrentUser: Bool {
        return senderRole == .user
    }
}

/// Sender role enumeration
enum SenderRole: String, Codable, CaseIterable, Equatable {
    case user = "user"
    case admin = "admin"
    
    var displayName: String {
        switch self {
        case .user: return "You"
        case .admin: return "Support"
        }
    }
}

// MARK: - API Request Models

/// Request model for sending a message
struct SendMessageRequest: Codable {
    let userId: Int
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case message
    }
}

// Note: GET /api/chat/messages now uses URL parameters instead of request body

// MARK: - API Response Models

/// Response model for chat messages
struct ChatMessagesResponse: Codable {
    let status: String
    let data: ChatMessagesData
    
    struct ChatMessagesData: Codable {
        let conversationId: Int
        let messages: [ChatMessage]
        let pagination: ChatPagination
        
        enum CodingKeys: String, CodingKey {
            case conversationId = "conversation_id"
            case messages
            case pagination
        }
    }
}

/// Pagination model for chat messages
struct ChatPagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let pages: Int
}

/// Response model for sending a message
struct SendMessageResponse: Codable {
    let status: String
    let data: SendMessageData
    
    struct SendMessageData: Codable {
        let id: Int
        let conversationId: Int
        let content: String
        let senderRole: SenderRole
        let timestamp: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case conversationId = "conversation_id"
            case content = "message"
            case senderRole = "sender_role"
            case timestamp
        }
    }
}

// MARK: - WebSocket Event Models

/// Base WebSocket event structure
struct WebSocketEvent: Codable {
    let event: String
    let data: WebSocketEventData
}

/// WebSocket event data (can contain different types of data)
struct WebSocketEventData: Codable {
    // For new_message events
    let id: Int?
    let conversationId: Int?
    let senderRole: SenderRole?
    let messageType: MessageType?
    let content: String?
    let timestamp: String?
    let senderIdentifier: String?
    
    // For typing_indicator events
    let typing: Bool?
    
    // For message_read events
    let messageIds: [Int]?
    let readBy: String?
    
    // For conversation_status events
    let status: String?
    let changedBy: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderRole = "sender_role"
        case messageType = "message_type"
        case content
        case timestamp
        case senderIdentifier = "sender_identifier"
        case typing
        case messageIds = "message_ids"
        case readBy = "read_by"
        case status
        case changedBy = "changed_by"
    }
}

/// Message type enumeration
enum MessageType: String, Codable {
    case text = "text"
    case image = "image"
    case file = "file"
    case system = "system"
}

/// WebSocket event types
enum WebSocketEventType: String, CaseIterable {
    case newMessage = "new_message"
    case typingIndicator = "typing_indicator"
    case messageRead = "message_read"
    case conversationStatus = "conversation_status"
    case error = "error"
}

// MARK: - WebSocket Client Event Models

/// Join conversation event
struct JoinConversationEvent: Codable {
    let event: String = "join_conversation"
    let data: JoinConversationData
    
    struct JoinConversationData: Codable {
        let conversationId: Int
        
        enum CodingKeys: String, CodingKey {
            case conversationId = "conversation_id"
        }
    }
}

/// Send message via WebSocket event
struct SendMessageEvent: Codable {
    let event: String = "send_message"
    let data: SendMessageEventData
    
    struct SendMessageEventData: Codable {
        let conversationId: Int
        let messageType: MessageType
        let content: String
        let fileId: String?
        
        enum CodingKeys: String, CodingKey {
            case conversationId = "conversation_id"
            case messageType = "message_type"
            case content
            case fileId = "file_id"
        }
    }
}

/// Typing indicator event
struct TypingEvent: Codable {
    let event: String
    let data: TypingEventData
    
    struct TypingEventData: Codable {
        let conversationId: Int
        
        enum CodingKeys: String, CodingKey {
            case conversationId = "conversation_id"
        }
    }
    
    static func start(conversationId: Int) -> TypingEvent {
        return TypingEvent(
            event: "typing_start",
            data: TypingEventData(conversationId: conversationId)
        )
    }
    
    static func stop(conversationId: Int) -> TypingEvent {
        return TypingEvent(
            event: "typing_stop",
            data: TypingEventData(conversationId: conversationId)
        )
    }
}

// MARK: - Error Models

/// WebSocket error event
struct WebSocketError: Codable {
    let event: String = "error"
    let data: WebSocketErrorData
    
    struct WebSocketErrorData: Codable {
        let code: String
        let message: String
    }
}

/// IM Service errors
enum IMServiceError: Error, LocalizedError {
    case invalidUserId
    case emptyMessage
    case networkError(String)
    case jsonParsingError
    case socketNotConnected
    case authenticationFailed
    case conversationNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidUserId:
            return "Invalid user ID"
        case .emptyMessage:
            return "Message cannot be empty"
        case .networkError(let message):
            return "Network error: \(message)"
        case .jsonParsingError:
            return "Failed to parse server response"
        case .socketNotConnected:
            return "WebSocket connection not established"
        case .authenticationFailed:
            return "Authentication failed"
        case .conversationNotFound:
            return "Conversation not found"
        }
    }
}

// MARK: - Connection State

/// WebSocket connection state
enum ConnectionState: String, CaseIterable {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case connected = "connected"
    case reconnecting = "reconnecting"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .reconnecting: return "Reconnecting..."
        case .error: return "Connection Error"
        }
    }
    
    var isConnected: Bool {
        return self == .connected
    }
}