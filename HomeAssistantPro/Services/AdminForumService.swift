//
//  AdminForumService.swift
//  HomeAssistantPro
//
//  Purpose: Service for admin forum moderation API endpoints
//  Author: Michael
//  Created: 2025-07-25
//  Modified: 2025-07-25
//
//  Modification Log:
//  - 2025-07-25: Initial creation with admin moderation endpoints
//  - 2025-07-25: Refactored to use shared APIConfiguration to avoid code duplication
//
//  Functions:
//  - moderatePost(_:action:reason:): Moderate a single forum post
//  - fetchReviewQueue(page:limit:type:): Get posts awaiting moderation
//  - fetchForumStats(): Get forum statistics for admin dashboard
//

import Foundation
import CryptoKit
import os.log

/// Service for admin forum moderation operations
final class AdminForumService {
    static let shared = AdminForumService()
    
    private let apiConfig = APIConfiguration.shared
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "AdminForumService")
    private let settingsStore: SettingsStore
    
    /// Initialize AdminForumService with dependency injection
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
    /// - Throws: AdminForumError for authentication setup failures
    private func createAdminRequest(endpoint: String, method: String, body: Data?) throws -> URLRequest {
        guard let url = URL(string: apiConfig.baseURL + endpoint) else {
            throw AdminForumError.invalidEndpoint
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Get session token for enhanced admin security
        let sessionToken = try? settingsStore.retrieveSessionToken()
        
        // Add authentication headers using shared configuration
        let headers = apiConfig.createAuthHeaders(sessionToken: sessionToken)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    /// Performs HTTP request with error handling
    /// - Parameter request: URLRequest to execute
    /// - Returns: Response data and HTTP status code
    /// - Throws: AdminForumError for various failure cases
    private func performRequest(_ request: URLRequest) async throws -> (Data, Int) {
        // Log request details
        logger.info("📤 ADMIN API REQUEST: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "Unknown")")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AdminForumError.invalidResponse
            }

            // Log response body
            if let responseString = String(data: data, encoding: .utf8) {
                logger.info("📄 Response Body: \(responseString)")
            } else {
                logger.info("📄 Response Body: [Binary data, \(data.count) bytes]")
            }

            return (data, httpResponse.statusCode)
        } catch {
            logger.error("Admin API request failed: \(error.localizedDescription)")
            throw AdminForumError.networkError(error)
        }
    }
    
    // MARK: - Admin Moderation Methods
    
    /// Moderates a single forum post with approve/reject action
    /// - Parameters:
    ///   - postId: ID of the post to moderate
    ///   - postType: Type of post ("topic" or "reply")
    ///   - action: Moderation action ("approve" or "reject")
    ///   - reason: Optional reason for the moderation action
    /// - Returns: Moderation result with new post status
    /// - Throws: AdminForumError for moderation failures
    func moderatePost(postId: Int, postType: String, action: String, reason: String? = nil) async throws -> ModerationResult {
        // Get current user ID for authentication
        guard let userIdString = try? settingsStore.retrieveUserId(),
              let userId = Int(userIdString) else {
            throw AdminForumError.notAuthenticated
        }
        
        let moderationRequest = ModerationRequest(
            userId: userId,
            postId: postId,
            postType: postType,
            action: action,
            reason: reason
        )
        
        let body = try JSONEncoder().encode(moderationRequest)
        let request = try createAdminRequest(endpoint: "/admin/forum/moderate", method: "POST", body: body)
        
        let (data, statusCode) = try await performRequest(request)
        
        switch statusCode {
        case 200:
            let response = try JSONDecoder().decode(ModerationResponse.self, from: data)
            logger.info("Moderation successful: \(action) post \(postId)")
            return ModerationResult(
                postId: response.data.postId,
                newStatus: response.data.newStatus,
                actionTaken: response.data.actionTaken
            )
        case 400:
            let errorResponse = try JSONDecoder().decode(AdminErrorResponse.self, from: data)
            throw AdminForumError.badRequest(errorResponse.message)
        case 401:
            throw AdminForumError.sessionExpired
        case 403:
            throw AdminForumError.accessDenied
        case 404:
            throw AdminForumError.postNotFound
        case 409:
            throw AdminForumError.postAlreadyModerated
        case 500:
            throw AdminForumError.serverError
        default:
            throw AdminForumError.unknownError(statusCode)
        }
    }
    
    /// Fetches posts awaiting moderation review
    /// - Parameters:
    ///   - page: Page number (1-based)
    ///   - limit: Number of items per page
    ///   - type: Filter by type ("topic", "reply", or "all")
    ///   - sort: Sort order ("newest", "oldest", "priority")
    ///   - category: Filter by forum category (optional)
    /// - Returns: Review queue with pending items and pagination info
    /// - Throws: AdminForumError for fetch failures
    func fetchReviewQueue(page: Int = 1, limit: Int = 20, type: String = "all", sort: String = "oldest", category: String? = nil) async throws -> ReviewQueue {
        logger.info("🔍 Fetching review queue: page=\(page), limit=\(limit), type=\(type), sort=\(sort)")
        
        // Get current user ID for authentication
        guard let userIdString = try? settingsStore.retrieveUserId(),
              let userId = Int(userIdString) else {
            logger.error("❌ fetchReviewQueue failed: user not authenticated")
            throw AdminForumError.notAuthenticated
        }
        
        logger.info("✅ User authenticated: userId=\(userId)")
        
        var queryItems = [
            URLQueryItem(name: "user_id", value: String(userId)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "sort", value: sort)
        ]
        
        // Add optional category filter
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        
        var urlComponents = URLComponents(string: apiConfig.baseURL + "/admin/forum/review-queue")
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            throw AdminForumError.invalidEndpoint
        }
        
        // GET request with no body - user_id is now in query parameters
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication headers using shared configuration
        let sessionToken = try? settingsStore.retrieveSessionToken()
        let headers = apiConfig.createAuthHeaders(sessionToken: sessionToken)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, statusCode) = try await performRequest(request)
        
        switch statusCode {
        case 200:
            let response = try JSONDecoder().decode(ReviewQueueResponse.self, from: data)
            logger.info("Review queue fetched: \(response.data.pendingItems.count) items")
            return ReviewQueue(
                pendingItems: response.data.pendingItems,
                pagination: response.data.pagination,
                stats: response.data.stats
            )
        case 400:
            let errorResponse = try JSONDecoder().decode(AdminErrorResponse.self, from: data)
            throw AdminForumError.badRequest(errorResponse.message)
        case 401:
            throw AdminForumError.sessionExpired
        case 403:
            throw AdminForumError.accessDenied
        case 500:
            throw AdminForumError.serverError
        default:
            throw AdminForumError.unknownError(statusCode)
        }
    }
    
    /// Fetches forum statistics for admin dashboard
    /// - Returns: Forum statistics including moderation metrics
    /// - Throws: AdminForumError for fetch failures
    func fetchForumStats() async throws -> ForumStats {
        // Get current user ID for authentication
        guard let userIdString = try? settingsStore.retrieveUserId(),
              let userId = Int(userIdString) else {
            throw AdminForumError.notAuthenticated
        }
        
        // Add user_id as query parameter for GET requests
        let queryItems = [URLQueryItem(name: "user_id", value: String(userId))]
        var urlComponents = URLComponents(string: apiConfig.baseURL + "/admin/forum/stats")
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            throw AdminForumError.invalidEndpoint
        }
        
        // GET request with no body - user_id is now in query parameters
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication headers using shared configuration
        let sessionToken = try? settingsStore.retrieveSessionToken()
        let headers = apiConfig.createAuthHeaders(sessionToken: sessionToken)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, statusCode) = try await performRequest(request)
        
        switch statusCode {
        case 200:
            let response = try JSONDecoder().decode(ForumStatsResponse.self, from: data)
            logger.info("Forum stats fetched successfully")
            return response.data
        case 400:
            let errorResponse = try JSONDecoder().decode(AdminErrorResponse.self, from: data)
            throw AdminForumError.badRequest(errorResponse.message)
        case 401:
            throw AdminForumError.sessionExpired
        case 403:
            throw AdminForumError.accessDenied
        case 500:
            throw AdminForumError.serverError
        default:
            throw AdminForumError.unknownError(statusCode)
        }
    }
}

// MARK: - Request Models

/// Request model for moderation actions
struct ModerationRequest: Codable {
    let userId: Int
    let postId: Int
    let postType: String
    let action: String
    let reason: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case postId = "post_id"
        case postType = "post_type"
        case action, reason
    }
}

/// Request model for admin endpoints requiring user ID
struct AdminUserRequest: Codable {
    let userId: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

// MARK: - Response Models

/// Response model for moderation actions
struct ModerationResponse: Codable {
    let status: String
    let data: ModerationData
    
    struct ModerationData: Codable {
        let postId: Int
        let newStatus: Int
        let actionTaken: String
        
        enum CodingKeys: String, CodingKey {
            case postId = "post_id"
            case newStatus = "new_status"
            case actionTaken = "action_taken"
        }
    }
}

/// Response model for review queue
struct ReviewQueueResponse: Codable {
    let status: String
    let data: ReviewQueueData
    
    struct ReviewQueueData: Codable {
        let pendingItems: [PendingItem]
        let pagination: Pagination
        let stats: QueueStats
        
        enum CodingKeys: String, CodingKey {
            case pendingItems = "posts"
            case pagination
            case stats = "queue_stats"
        }
    }
}

/// Response model for forum statistics
struct ForumStatsResponse: Codable {
    let status: String
    let data: ForumStats
}

/// Error response model for admin endpoints
struct AdminErrorResponse: Codable {
    let status: String
    let message: String
}

// MARK: - Data Models

/// Result of a moderation action
struct ModerationResult {
    let postId: Int
    let newStatus: Int
    let actionTaken: String
}

/// Review queue with pending items
struct ReviewQueue {
    let pendingItems: [PendingItem]
    let pagination: Pagination
    let stats: QueueStats
}

/// Item awaiting moderation
struct PendingItem: Codable, Identifiable {
    let id: Int
    let type: String
    let title: String?
    let content: String
    let userId: Int
    let authorName: String
    let category: String?
    let topicId: String?
    let parentReplyId: String?
    let createdAt: String
    let updatedAt: String
    let priority: String? // Optional since API doesn't always provide it
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, content, category
        case userId = "user_id"
        case authorName = "author_name"
        case topicId = "topic_id"
        case parentReplyId = "parent_reply_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case priority
    }
}


/// Pagination information
struct Pagination: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalItems: Int
    let hasNext: Bool
    let hasPrevious: Bool
    
    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case totalPages = "total_pages"
        case totalItems = "total_items"
        case hasNext = "has_next"
        case hasPrevious = "has_previous"
    }
}

/// Queue statistics
struct QueueStats: Codable {
    let totalPending: Int
    let topicsPending: Int?
    let repliesPending: Int?
    let averageWaitTimeHours: Double?
    let typeFilter: String?
    
    enum CodingKeys: String, CodingKey {
        case totalPending = "total_pending"
        case topicsPending = "topics_pending"
        case repliesPending = "replies_pending"
        case averageWaitTimeHours = "average_wait_time_hours"
        case typeFilter = "type_filter"
    }
}

/// Forum statistics for admin dashboard
struct ForumStats: Codable {
    let pendingReview: PendingReviewStats
    let recentActivity: RecentActivityStats
    let queueHealth: QueueHealthStats
    let lastUpdated: String
    
    enum CodingKeys: String, CodingKey {
        case pendingReview = "pending_review"
        case recentActivity = "recent_activity"
        case queueHealth = "queue_health"
        case lastUpdated = "last_updated"
    }
}

/// Pending review statistics
struct PendingReviewStats: Codable {
    let total: Int
    let topics: Int
    let replies: Int
    let urgent: Int
}

/// Recent activity statistics
struct RecentActivityStats: Codable {
    let last24h: DailyStats
    
    enum CodingKeys: String, CodingKey {
        case last24h = "last_24h"
    }
}

/// Daily activity statistics
struct DailyStats: Codable {
    let newPosts: Int
    let moderated: Int
    let userSignups: Int
    
    enum CodingKeys: String, CodingKey {
        case newPosts = "new_posts"
        case moderated = "moderated"
        case userSignups = "user_signups"
    }
}

/// Queue health statistics
struct QueueHealthStats: Codable {
    let averageWaitTimeHours: Double
    let oldestPendingHours: Double
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case averageWaitTimeHours = "average_wait_time_hours"
        case oldestPendingHours = "oldest_pending_hours"
        case status
    }
}

// MARK: - Error Types

/// Admin forum service error types
enum AdminForumError: LocalizedError {
    case invalidEndpoint
    case invalidResponse
    case networkError(Error)
    case notAuthenticated
    case sessionExpired
    case accessDenied
    case badRequest(String)
    case postNotFound
    case postAlreadyModerated
    case serverError
    case unknownError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "Invalid API endpoint"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .notAuthenticated:
            return "User not authenticated"
        case .sessionExpired:
            return "Session expired. Please log in again."
        case .accessDenied:
            return "Admin access required"
        case .badRequest(let message):
            return message
        case .postNotFound:
            return "Post not found"
        case .postAlreadyModerated:
            return "Post has already been moderated"
        case .serverError:
            return "Server error occurred"
        case .unknownError(let code):
            return "Unknown error with status code: \(code)"
        }
    }
}
