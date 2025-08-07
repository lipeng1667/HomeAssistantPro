//
//  AdminChatModels.swift
//  HomeAssistantPro
//
//  Purpose: Data models for admin chat management system
//  Author: Assistant
//  Create date: 2025-08-07
//  Latest modify date: 2025-08-07
//
//  Modification log:
//  - 2025-08-07: Initial creation with admin conversation and related models
//
//  Functions:
//  - AdminConversation: Main conversation model with user and admin info
//  - AdminUserInfo: User information for admin context
//  - AdminInfo: Admin user information
//  - LastMessage: Last message preview model
//

import Foundation

/// Admin conversation model with full management context
struct AdminConversation: Identifiable, Codable {
    /// Unique conversation identifier
    let id: Int
    
    /// User ID participating in conversation
    let userId: Int
    
    /// User information
    let userInfo: AdminUserInfo
    
    /// Assigned admin ID (nil if unassigned)
    let adminId: Int?
    
    /// Admin information (nil if unassigned)
    let adminInfo: AdminInfo?
    
    /// Conversation status ("active", "closed", "archived")
    let status: String
    
    /// Priority level ("low", "normal", "high", "urgent")
    let priority: String
    
    /// Conversation creation timestamp
    let createdAt: Date
    
    /// Last message timestamp
    let lastMessageAt: Date
    
    /// Number of unread messages
    let unreadCount: Int
    
    /// Total message count
    let totalMessages: Int
    
    /// Last message preview
    let lastMessage: LastMessage?
    
    /// Conversation tags
    let tags: [String]
    
    /// Resolution notes (if closed)
    let resolutionNotes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userInfo = "user_info"
        case adminId = "admin_id"
        case adminInfo = "admin_info"
        case status
        case priority
        case createdAt = "created_at"
        case lastMessageAt = "last_message_at"
        case unreadCount = "unread_count"
        case totalMessages = "total_messages"
        case lastMessage = "last_message"
        case tags
        case resolutionNotes = "resolution_notes"
    }
}

/// User information in admin context
struct AdminUserInfo: Codable {
    /// User ID
    let id: Int
    
    /// User's account name
    let accountName: String?
    
    /// User's phone number
    let phoneNumber: String?
    
    /// User status (1=anonymous, 2=registered, 87=admin)
    let status: Int
    
    /// User creation timestamp
    let createdAt: Date?
    
    /// User's last login timestamp
    let lastLogin: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case accountName = "account_name"
        case phoneNumber = "phone_number"
        case status
        case createdAt = "created_at"
        case lastLogin = "last_login"
    }
}

/// Admin user information
struct AdminInfo: Codable {
    /// Admin ID
    let id: Int
    
    /// Admin username
    let username: String
    
    /// Admin's account name
    let accountName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case accountName = "account_name"
    }
}

/// Last message preview model
struct LastMessage: Codable {
    /// Message ID
    let id: Int
    
    /// Message content
    let content: String
    
    /// Sender role ("user" or "admin")
    let senderRole: String
    
    /// Message timestamp
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case senderRole = "sender_role"
        case timestamp
    }
}

/// Admin chat dashboard statistics
struct AdminChatDashboard: Codable {
    /// Dashboard summary statistics
    let summary: DashboardSummary
    
    /// Recent activity list
    let recentActivity: [RecentActivity]
    
    /// Assignments for current admin
    let myAssignments: [MyAssignment]
    
    enum CodingKeys: String, CodingKey {
        case summary
        case recentActivity = "recent_activity"
        case myAssignments = "my_assignments"
    }
}

/// Dashboard summary statistics
struct DashboardSummary: Codable {
    /// Total conversations
    let totalConversations: Int
    
    /// Active conversations
    let activeConversations: Int
    
    /// Unread conversations
    let unreadConversations: Int
    
    /// Conversations assigned to current admin
    let assignedToMe: Int
    
    /// Unassigned conversations
    let unassigned: Int
    
    /// Conversations closed today
    let closedToday: Int
    
    /// Average response time
    let avgResponseTime: String
    
    enum CodingKeys: String, CodingKey {
        case totalConversations = "total_conversations"
        case activeConversations = "active_conversations"
        case unreadConversations = "unread_conversations"
        case assignedToMe = "assigned_to_me"
        case unassigned
        case closedToday = "closed_today"
        case avgResponseTime = "avg_response_time"
    }
}

/// Recent activity item
struct RecentActivity: Codable, Identifiable {
    /// Conversation ID
    let conversationId: Int
    
    /// User name
    let userName: String
    
    /// Last message content
    let lastMessage: String
    
    /// Activity timestamp
    let timestamp: Date
    
    /// Conversation status
    let status: String
    
    var id: Int { conversationId }
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case userName = "user_name"
        case lastMessage = "last_message"
        case timestamp
        case status
    }
}

/// Assignment item for current admin
struct MyAssignment: Codable, Identifiable {
    /// Conversation ID
    let conversationId: Int
    
    /// User name
    let userName: String
    
    /// Priority level
    let priority: String
    
    /// Unread message count
    let unreadCount: Int
    
    /// Last activity timestamp
    let lastActivity: Date
    
    var id: Int { conversationId }
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case userName = "user_name"
        case priority
        case unreadCount = "unread_count"
        case lastActivity = "last_activity"
    }
}

/// API response wrapper for admin conversations
struct AdminConversationsResponse: Codable {
    /// Response status
    let status: String
    
    /// Response data
    let data: ConversationsData
}

/// Conversations data container
struct ConversationsData: Codable {
    /// Array of conversations
    let conversations: [AdminConversation]
    
    /// Pagination information
    let pagination: Pagination
    
    /// Summary statistics
    let summary: ConversationsSummary
}


/// Conversations summary statistics
struct ConversationsSummary: Codable {
    /// Total active conversations
    let totalActive: Int
    
    /// Total unread conversations
    let totalUnread: Int
    
    /// Conversations assigned to me
    let assignedToMe: Int
    
    /// Unassigned conversations
    let unassigned: Int
    
    enum CodingKeys: String, CodingKey {
        case totalActive = "total_active"
        case totalUnread = "total_unread"
        case assignedToMe = "assigned_to_me"
        case unassigned
    }
}

/// Admin chat message model
struct AdminChatMessage: Codable, Identifiable {
    /// Message ID
    let id: Int
    
    /// Conversation ID
    let conversationId: Int
    
    /// Sender role ("user" or "admin")
    let senderRole: String
    
    /// Message content
    let message: String
    
    /// Message timestamp
    let timestamp: Date
    
    /// Sender identifier (user UUID or admin username)
    let senderIdentifier: String
    
    /// Internal admin note (not visible to user)
    let internalNote: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderRole = "sender_role"
        case message
        case timestamp
        case senderIdentifier = "sender_identifier"
        case internalNote = "internal_note"
    }
}
