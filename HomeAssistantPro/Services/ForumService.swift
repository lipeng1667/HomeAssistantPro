//
//  ForumService.swift
//  HomeAssistantPro
//
//  Purpose: Forum API service layer with URLSession and structured concurrency
//  Author: Michael
//  Created: 2025-07-10
//  Modified: 2025-07-25
//
//  Modification Log:
//  - 2025-07-10: Initial creation with forum API methods
//  - 2025-07-25: Refactored to use shared APIConfiguration to eliminate code duplication
//
//  Functions:
//  - ForumService.shared: Singleton instance
//  - fetchTopics: Get paginated topics list with filtering
//  - fetchTopicDetail: Get topic with replies
//  - createTopic: Create new forum topic
//  - updateTopic: Update existing topic
//  - deleteTopic: Delete topic by ID
//  - createReply: Add reply to topic
//  - updateReply: Update existing reply
//  - deleteReply: Delete reply by ID
//  - likeTopic: Toggle like on topic
//  - likeReply: Toggle like on reply
//  - searchForum: Search topics and replies
//  - fetchCategories: Get forum categories
//  - fetchDrafts: Get user's drafts
//  - saveDraft: Save/update draft
//  - deleteDraft: Delete draft
//

import Foundation
import os.log

/// Forum API service with URLSession and structured concurrency
final class ForumService {
    static let shared = ForumService()
    
    private let apiClient: APIClient
    private let apiConfig = APIConfiguration.shared
    private let settingsStore: SettingsStore
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "ForumService")
    
    /// Initialize ForumService with dependency injection
    /// - Parameters:
    ///   - apiClient: API client for network requests
    ///   - settingsStore: Settings storage for user data
    private init(apiClient: APIClient = APIClient.shared, settingsStore: SettingsStore = SettingsStore()) {
        self.apiClient = apiClient
        self.settingsStore = settingsStore
    }
    
    /// Gets current user ID from settings store
    /// - Returns: User ID string or throws error if not found
    /// - Throws: ForumError.userNotAuthenticated if no user ID found
    func getCurrentUserId() throws -> String {
        guard let userId = try? settingsStore.retrieveUserId() else {
            logger.error("❌ No user ID found in settings store")
            throw ForumError.userNotAuthenticated
        }
        logger.info("👤 Current user ID: \(userId)")
        return userId
    }
    
    /// Checks if current user is authenticated (not anonymous)
    /// - Returns: True if user is authenticated, false if anonymous or not logged in
    private func isUserAuthenticated() -> Bool {
        let userStatus = settingsStore.retrieveUserStatus()
        logger.info("🔐 User status check: \(userStatus) (2=registered, 87=admin, 1=anonymous, 0=not logged in)")
        
        // Also check if we have a valid user ID as fallback for status inconsistencies
        let hasValidUserId = (try? getCurrentUserId()) != nil
        logger.info("🔐 Has valid user ID: \(hasValidUserId)")
        
        // User is authenticated if they have proper status OR have a valid user ID
        let isAuthenticated = (userStatus == 2 || userStatus == 87) || hasValidUserId
        logger.info("🔐 Final authentication result: \(isAuthenticated)")
        
        return isAuthenticated
    }
    
    /// Creates authenticated URLRequest for forum endpoints
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - method: HTTP method
    ///   - body: Request body data
    /// - Returns: Configured URLRequest
    private func createForumRequest(endpoint: String, method: String, body: Data? = nil) -> URLRequest {
        guard let url = URL(string: apiConfig.baseURL + endpoint) else {
            fatalError("Invalid URL: \(apiConfig.baseURL + endpoint)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add authentication headers using shared configuration
        let headers = apiConfig.createAuthHeaders()
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        logger.info("🔐 Auth Headers added for endpoint: \(endpoint)")
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    
    /// Performs authenticated request and handles response
    /// - Parameter request: URLRequest to execute
    /// - Returns: Response data
    /// - Throws: ForumError for various failure cases
    private func performRequest(_ request: URLRequest) async throws -> Data {
        // Log request details
        logger.info("🚀 API Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "Unknown URL")")
        
        // Log request headers
        if let headers = request.allHTTPHeaderFields {
            logger.info("📋 Request Headers:")
            for (key, value) in headers {
                // Don't log sensitive data like signatures
                if key.lowercased().contains("signature") {
                    logger.info("  \(key): [REDACTED]")
                } else {
                    logger.info("  \(key): \(value)")
                }
            }
        }
        
        // Log request body if present
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            logger.info("📝 Request Body: \(bodyString)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("❌ Invalid response type")
                throw ForumError.invalidResponse
            }
            
            // Log response details
            logger.info("📥 Response Status: \(httpResponse.statusCode)")
            logger.info("📋 Response Headers:")
            for (key, value) in httpResponse.allHeaderFields {
                logger.info("  \(String(describing: key)): \(String(describing: value))")
            }
            
            // Log response body
            if let responseString = String(data: data, encoding: .utf8) {
                logger.info("📄 Response Body: \(responseString)")
            } else {
                logger.info("📄 Response Body: [Binary data, \(data.count) bytes]")
            }
            
            // Check for API errors - 200 (OK) and 201 (Created) are success codes
            if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
                logger.error("❌ API Error - Status: \(httpResponse.statusCode)")
                
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    logger.error("❌ Error Response: status=\(errorResponse.status), message=\(errorResponse.message)")
                    switch httpResponse.statusCode {
                    case 400:
                        throw ForumError.badRequest(errorResponse.message)
                    case 401:
                        throw ForumError.unauthorized
                    case 403:
                        throw ForumError.forbidden
                    case 404:
                        throw ForumError.notFound
                    case 429:
                        throw ForumError.rateLimited
                    case 500:
                        throw ForumError.serverError
                    default:
                        throw ForumError.unknownError(httpResponse.statusCode)
                    }
                } else {
                    logger.error("❌ Unknown error format")
                    throw ForumError.unknownError(httpResponse.statusCode)
                }
            }
            
            logger.info("✅ Request completed successfully")
            return data
            
        } catch {
            if error is ForumError {
                logger.error("❌ Forum Error: \(error.localizedDescription)")
                throw error
            }
            logger.error("❌ Network request failed: \(error.localizedDescription)")
            throw ForumError.networkError(error)
        }
    }
    
    // MARK: - Topics API
    
    /// Fetches paginated list of forum topics
    /// - Parameters:
    ///   - page: Page number (1-based)
    ///   - limit: Items per page (1-50)
    ///   - category: Optional category filter
    ///   - sort: Sort order (newest, oldest, popular, trending)
    ///   - search: Optional search query
    ///   - includeUserReviews: Include current user's under-review content
    /// - Returns: ForumTopicsResponse with topics and pagination
    /// - Throws: ForumError for API failures
    func fetchTopics(page: Int = 1, limit: Int = 20, category: String? = nil, sort: ForumSortOption = .newest, search: String? = nil, includeUserReviews: Bool = true) async throws -> ForumTopicsResponse {
        logger.info("🔍 fetchTopics called - page: \(page), limit: \(limit), category: \(category ?? "nil"), sort: \(sort.rawValue), search: \(search ?? "nil"), includeUserReviews: \(includeUserReviews)")
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "sort", value: sort.rawValue)
        ]
        
        if let category = category {
            components.queryItems?.append(URLQueryItem(name: "category", value: category))
        }
        
        if let search = search {
            components.queryItems?.append(URLQueryItem(name: "search", value: search))
        }
        
        // Include user_id to get under-review topics for current user (only for authenticated users)
        logger.info("🔍 Debug fetchTopics: includeUserReviews=\(includeUserReviews), isUserAuthenticated=\(self.isUserAuthenticated())")
        
        if includeUserReviews && self.isUserAuthenticated() {
            do {
                let userId = try self.getCurrentUserId()
                components.queryItems?.append(URLQueryItem(name: "user_id", value: userId))
                logger.info("👤 Including user_id \(userId) for under-review content")
            } catch {
                logger.error("❌ Failed to get current user ID in fetchTopics: \(error)")
            }
        } else {
            logger.info("⚠️ Not including user_id in fetchTopics - includeUserReviews: \(includeUserReviews), authenticated: \(self.isUserAuthenticated())")
        }
        
        let queryString = components.query ?? ""
        let endpoint = "/api/forum/topics" + (queryString.isEmpty ? "" : "?\(queryString)")
        
        let request = createForumRequest(endpoint: endpoint, method: "GET")
        let data = try await performRequest(request)
        
        let response = try JSONDecoder().decode(ForumTopicsResponse.self, from: data)
        logger.info("Fetched \(response.data.topics.count) topics for page \(page)")
        
        return response
    }
    
    /// Fetches detailed topic with replies
    /// - Parameters:
    ///   - topicId: Topic ID
    ///   - replyPage: Reply page number
    ///   - replyLimit: Replies per page
    ///   - includeUserReviews: Include current user's under-review replies
    /// - Returns: ForumTopicDetailResponse with topic and replies
    /// - Throws: ForumError for API failures
    func fetchTopicDetail(topicId: Int, replyPage: Int = 1, replyLimit: Int = 20, includeUserReviews: Bool = true) async throws -> ForumTopicDetailResponse {
        logger.info("📖 fetchTopicDetail called - topicId: \(topicId), replyPage: \(replyPage), replyLimit: \(replyLimit), includeUserReviews: \(includeUserReviews)")
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "reply_page", value: String(replyPage)),
            URLQueryItem(name: "reply_limit", value: String(replyLimit))
        ]
        
        // Include user_id to get under-review replies for current user (only for authenticated users)
        logger.info("🔍 Debug: includeUserReviews=\(includeUserReviews), isUserAuthenticated=\(self.isUserAuthenticated())")
        
        if includeUserReviews && self.isUserAuthenticated() {
            do {
                let userId = try self.getCurrentUserId()
                components.queryItems?.append(URLQueryItem(name: "user_id", value: userId))
                logger.info("👤 Including user_id \(userId) for under-review replies")
            } catch {
                logger.error("❌ Failed to get current user ID: \(error)")
            }
        } else {
            logger.info("⚠️ Not including user_id - includeUserReviews: \(includeUserReviews), authenticated: \(self.isUserAuthenticated())")
        }
        
        let queryString = components.query ?? ""
        let endpoint = "/api/forum/topics/\(topicId)?\(queryString)"
        
        let request = createForumRequest(endpoint: endpoint, method: "GET")
        let data = try await performRequest(request)
        
        let response = try JSONDecoder().decode(ForumTopicDetailResponse.self, from: data)
        logger.info("Fetched topic \(topicId) with \(response.data.replies.count) replies")
        
        return response
    }
    
    /// Creates a new forum topic
    /// - Parameters:
    ///   - title: Topic title (3-100 characters)
    ///   - content: Topic content (10-2000 characters)
    ///   - category: Topic category
    ///   - images: Array of image URLs (max 3) - DEPRECATED, use imageFiles instead
    ///   - imageFiles: Array of image file data to upload
    /// - Returns: CreateTopicResponse with topic ID
    /// - Throws: ForumError for API failures
    func createTopic(title: String, content: String, category: String, images: [String] = [], imageFiles: [FileUploadRequest] = []) async throws -> CreateTopicResponse {
        logger.info("📝 createTopic called - title: \(title), category: \(category), imageFiles: \(imageFiles.count)")
        
        let userId = try getCurrentUserId()
        var finalImageUrls = images // Start with provided URLs
        
        // Upload image files first if provided
        if !imageFiles.isEmpty {
            logger.info("📤 Uploading \(imageFiles.count) image files before creating topic...")
            
            for imageFile in imageFiles {
                let uploadResponse = try await uploadFile(imageFile)
                
                if let fileUrl = uploadResponse.data.fileUrl {
                    finalImageUrls.append(fileUrl)
                    logger.info("✅ Image uploaded successfully: \(fileUrl)")
                } else {
                    logger.error("❌ Failed to get file URL from upload response")
                    throw ForumError.serverError
                }
            }
        }
        
        let requestData = CreateTopicRequest(
            userId: Int(userId) ?? 0,
            title: title,
            content: content,
            category: category,
            images: finalImageUrls
        )
        
        let body = try JSONEncoder().encode(requestData)
        let request = createForumRequest(endpoint: "/api/forum/topics", method: "POST", body: body)
        let data = try await performRequest(request)
        
        let response = try JSONDecoder().decode(CreateTopicResponse.self, from: data)
        logger.info("✅ Created topic with ID: \(response.data.topic.id), images: \(finalImageUrls.count)")
        
        return response
    }
    
    /// Updates an existing topic (author only)
    /// - Parameters:
    ///   - topicId: Topic ID
    ///   - title: Optional new title
    ///   - content: Optional new content
    ///   - category: Optional new category
    ///   - images: Optional new images array
    /// - Returns: UpdateTopicResponse with updated topic
    /// - Throws: ForumError for API failures
    func updateTopic(topicId: Int, title: String? = nil, content: String? = nil, category: String? = nil, images: [String]? = nil) async throws -> UpdateTopicResponse {
        let userId = try getCurrentUserId()
        
        let requestData = UpdateTopicRequest(
            userId: Int(userId) ?? 0,
            title: title,
            content: content,
            category: category,
            images: images
        )
        
        let body = try JSONEncoder().encode(requestData)
        let request = createForumRequest(endpoint: "/api/forum/topics/\(topicId)", method: "PUT", body: body)
        let data = try await performRequest(request)
        
        let response = try JSONDecoder().decode(UpdateTopicResponse.self, from: data)
        logger.info("Updated topic \(topicId)")
        
        return response
    }
    
    /// Deletes a topic (author only)
    /// - Parameter topicId: Topic ID
    /// - Returns: Success message
    /// - Throws: ForumError for API failures
    func deleteTopic(topicId: Int) async throws -> String {
        let userId = try getCurrentUserId()
        
        let requestData = DeleteTopicRequest(userId: Int(userId) ?? 0)
        let body = try JSONEncoder().encode(requestData)
        let request = createForumRequest(endpoint: "/api/forum/topics/\(topicId)", method: "DELETE", body: body)
        let data = try await performRequest(request)
        
        let response = try JSONDecoder().decode(DeleteResponse.self, from: data)
        logger.info("Deleted topic \(topicId)")
        
        return response.message
    }
    
    // MARK: - Replies API
    
    /// Fetches replies for a specific topic
    /// - Parameters:
    ///   - topicId: Topic ID
    ///   - page: Page number
    ///   - limit: Replies per page
    ///   - sort: Sort order
    ///   - includeUserReviews: Include current user's under-review replies
    /// - Returns: ForumRepliesResponse with replies and pagination
    /// - Throws: ForumError for API failures
    func fetchReplies(topicId: Int, page: Int = 1, limit: Int = 20, sort: ForumSortOption = .newest, includeUserReviews: Bool = true) async throws -> ForumRepliesResponse {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "sort", value: sort.rawValue)
        ]
        
        // Include user_id to get under-review replies for current user (only for authenticated users)
        if includeUserReviews && isUserAuthenticated() {
            if let userId = try? getCurrentUserId() {
                components.queryItems?.append(URLQueryItem(name: "user_id", value: userId))
                logger.info("👤 Including user_id \(userId) for under-review replies")
            }
        }
        
        let queryString = components.query ?? ""
        let endpoint = "/api/forum/topics/\(topicId)/replies?\(queryString)"
        
        let request = createForumRequest(endpoint: endpoint, method: "GET")
        let data = try await performRequest(request)
        
        let response = try JSONDecoder().decode(ForumRepliesResponse.self, from: data)
        logger.info("Fetched \(response.data.replies.count) replies for topic \(topicId)")
        
        return response
    }
    
    /// Creates a reply to a topic or nested reply to another reply
    /// - Parameters:
    ///   - topicId: Topic ID
    ///   - content: Reply content (1-1000 characters)
    ///   - parentReplyId: Parent reply ID for nested replies (optional)
    ///   - images: Array of image URLs (max 2) - DEPRECATED, use imageFiles instead
    ///   - imageFiles: Array of image file data to upload
    /// - Returns: CreateReplyResponse with reply ID
    /// - Throws: ForumError for API failures
    func createReply(topicId: Int, content: String, parentReplyId: Int? = nil, images: [String] = [], imageFiles: [FileUploadRequest] = []) async throws -> CreateReplyResponse {
        logger.info("💬 createReply called - topicId: \(topicId), parentReplyId: \(parentReplyId?.description ?? "nil"), content length: \(content.count), imageFiles: \(imageFiles.count)")
        
        let userId = try getCurrentUserId()
        var finalImageUrls = images // Start with provided URLs
        
        // Upload image files first if provided
        if !imageFiles.isEmpty {
            logger.info("📤 Uploading \(imageFiles.count) image files before creating reply...")
            
            for imageFile in imageFiles {
                let uploadResponse = try await uploadFile(imageFile)
                
                if let fileUrl = uploadResponse.data.fileUrl {
                    finalImageUrls.append(fileUrl)
                    logger.info("✅ Image uploaded successfully: \(fileUrl)")
                } else {
                    logger.error("❌ Failed to get file URL from upload response")
                    throw ForumError.serverError
                }
            }
        }
        
        let requestData = CreateReplyRequest(
            userId: Int(userId) ?? 0,
            content: content,
            parentReplyId: parentReplyId,
            images: finalImageUrls
        )
        
        let body = try JSONEncoder().encode(requestData)
        let request = createForumRequest(endpoint: "/api/forum/topics/\(topicId)/replies", method: "POST", body: body)
        let data = try await performRequest(request)
        
        let response = try JSONDecoder().decode(CreateReplyResponse.self, from: data)
        let replyType = parentReplyId != nil ? "nested reply" : "reply"
        logger.info("✅ Created \(replyType) with ID: \(response.data.reply.id), images: \(finalImageUrls.count)")
        
        return response
    }
    
    /// Updates a reply (author only)
    /// - Parameters:
    ///   - replyId: Reply ID
    ///   - content: New reply content
    ///   - images: New images array
    /// - Returns: UpdateReplyResponse with updated reply
    /// - Throws: ForumError for API failures
    func updateReply(replyId: Int, content: String, images: [String] = []) async throws -> UpdateReplyResponse {
        let userId = try getCurrentUserId()
        
        let requestData = UpdateReplyRequest(
            userId: Int(userId) ?? 0,
            content: content,
            images: images
        )
        
        let body = try JSONEncoder().encode(requestData)
        let request = createForumRequest(endpoint: "/api/forum/replies/\(replyId)", method: "PUT", body: body)
        let data = try await performRequest(request)
        
        let response = try JSONDecoder().decode(UpdateReplyResponse.self, from: data)
        logger.info("Updated reply \(replyId)")
        
        return response
    }
    
    /// Deletes a reply (author only)
    /// - Parameter replyId: Reply ID
    /// - Returns: Success message
    /// - Throws: ForumError for API failures
    func deleteReply(replyId: Int) async throws -> String {
        let userId = try getCurrentUserId()
        
        let requestData = DeleteReplyRequest(userId: Int(userId) ?? 0)
        let body = try JSONEncoder().encode(requestData)
        let request = createForumRequest(endpoint: "/api/forum/replies/\(replyId)", method: "DELETE", body: body)
        let data = try await performRequest(request)
        
        let response = try JSONDecoder().decode(DeleteResponse.self, from: data)
        logger.info("Deleted reply \(replyId)")
        
        return response.message
    }
    
    // MARK: - Like API
    
    /// Toggles like status for a topic
    /// - Parameter topicId: Topic ID
    /// - Returns: LikeResponse with updated like status
    /// - Throws: ForumError for API failures
    func likeTopic(topicId: Int) async throws -> LikeResponse {
        let userId = try getCurrentUserId()
        
        let requestData = LikeRequest(userId: Int(userId) ?? 0)
        let body = try JSONEncoder().encode(requestData)
        let request = createForumRequest(endpoint: "/api/forum/topics/\(topicId)/like", method: "POST", body: body)
        let data = try await performRequest(request)
        
        let response = try JSONDecoder().decode(LikeResponse.self, from: data)
        logger.info("Toggled like for topic \(topicId): \(response.data.isLiked)")
        
        return response
    }
    
    /// Toggles like status for a reply
    /// - Parameter replyId: Reply ID
    /// - Returns: LikeResponse with updated like status
    /// - Throws: ForumError for API failures
    func likeReply(replyId: Int) async throws -> LikeResponse {
        let userId = try getCurrentUserId()
        
        let requestData = LikeRequest(userId: Int(userId) ?? 0)
        let body = try JSONEncoder().encode(requestData)
        let request = createForumRequest(endpoint: "/api/forum/replies/\(replyId)/like", method: "POST", body: body)
        let data = try await performRequest(request)
        
        let response = try JSONDecoder().decode(LikeResponse.self, from: data)
        logger.info("Toggled like for reply \(replyId): \(response.data.isLiked)")
        
        return response
    }
    
    // MARK: - Search API
    
    /// Searches forum topics and replies
    /// - Parameters:
    ///   - query: Search query (min 2 characters)
    ///   - type: Search type (all, topics, replies)
    ///   - category: Optional category filter
    ///   - page: Page number
    ///   - limit: Results per page
    /// - Returns: ForumSearchResponse with results
    /// - Throws: ForumError for API failures
    func searchForum(query: String, type: ForumSearchType = .all, category: String? = nil, page: Int = 1, limit: Int = 20) async throws -> ForumSearchResponse {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: type.rawValue),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        if let category = category {
            components.queryItems?.append(URLQueryItem(name: "category", value: category))
        }
        
        let queryString = components.query ?? ""
        let endpoint = "/api/forum/search?\(queryString)"
        
        let request = createForumRequest(endpoint: endpoint, method: "GET")
        let data = try await performRequest(request)
        
        let response = try JSONDecoder().decode(ForumSearchResponse.self, from: data)
        logger.info("Found \(response.data.results.count) results for query: \(query)")
        
        return response
    }
    
    // MARK: - Categories API
    
    /// Fetches available forum categories
    /// - Returns: ForumCategoriesResponse with categories list
    /// - Throws: ForumError for API failures
    func fetchCategories() async throws -> ForumCategoriesResponse {
        let request = createForumRequest(endpoint: "/api/forum/categories", method: "GET")
        let data = try await performRequest(request)
        
        let response = try JSONDecoder().decode(ForumCategoriesResponse.self, from: data)
        logger.info("Fetched \(response.data.categories.count) categories")
        
        return response
    }
    
    // MARK: - Drafts API
    
    /// Fetches user's saved drafts
    /// - Parameters:
    ///   - type: Optional draft type filter (topic, reply)
    ///   - page: Page number
    ///   - limit: Drafts per page
    /// - Returns: ForumDraftsResponse with drafts
    /// - Throws: ForumError for API failures
    func fetchDrafts(type: String? = nil, page: Int = 1, limit: Int = 10) async throws -> ForumDraftsResponse {
        let userId = try getCurrentUserId()
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "user_id", value: userId),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        if let type = type {
            components.queryItems?.append(URLQueryItem(name: "type", value: type))
        }
        
        let queryString = components.query ?? ""
        let endpoint = "/api/forum/drafts?\(queryString)"
        
        let request = createForumRequest(endpoint: endpoint, method: "GET")
        let data = try await performRequest(request)
        
        let response = try JSONDecoder().decode(ForumDraftsResponse.self, from: data)
        logger.info("Fetched user drafts")
        
        return response
    }
    
    /// Saves or updates a draft
    /// - Parameters:
    ///   - title: Draft title (for topic drafts)
    ///   - content: Draft content
    ///   - category: Draft category (for topic drafts)
    ///   - type: Draft type (topic, reply)
    ///   - topicId: Parent topic ID (for reply drafts)
    /// - Returns: SaveDraftResponse with draft info
    /// - Throws: ForumError for API failures
    func saveDraft(title: String? = nil, content: String? = nil, category: String? = nil, type: String, topicId: Int? = nil) async throws -> SaveDraftResponse {
        let userId = try getCurrentUserId()
        
        let requestData = SaveDraftRequest(
            userId: Int(userId) ?? 0,
            title: title,
            content: content,
            category: category,
            type: type,
            topicId: topicId
        )
        
        let body = try JSONEncoder().encode(requestData)
        let request = createForumRequest(endpoint: "/api/forum/drafts", method: "POST", body: body)
        let data = try await performRequest(request)
        
        let response = try JSONDecoder().decode(SaveDraftResponse.self, from: data)
        logger.info("Saved draft with ID: \(response.data.draft.id)")
        
        return response
    }
    
    /// Deletes a saved draft
    /// - Parameter draftId: Draft ID
    /// - Returns: Success message
    /// - Throws: ForumError for API failures
    func deleteDraft(draftId: Int) async throws -> String {
        let userId = try getCurrentUserId()
        
        let requestData = DeleteDraftRequest(userId: Int(userId) ?? 0)
        let body = try JSONEncoder().encode(requestData)
        let request = createForumRequest(endpoint: "/api/forum/drafts/\(draftId)", method: "DELETE", body: body)
        let data = try await performRequest(request)
        
        let response = try JSONDecoder().decode(DeleteResponse.self, from: data)
        logger.info("Deleted draft \(draftId)")
        
        return response.message
    }
    
    // MARK: - Upload API
    
    /// Uploads a file for forum use (topic or reply)
    /// - Parameters:
    ///   - uploadRequest: File upload request with data and metadata
    /// - Returns: UploadResponse with file URL
    /// - Throws: ForumError for API failures
    func uploadFile(_ uploadRequest: FileUploadRequest) async throws -> UploadResponse {
        logger.info("📤 uploadFile called - fileName: \(uploadRequest.fileName), type: \(uploadRequest.type), fileSize: \(uploadRequest.file.count) bytes")
        
        let userId = try getCurrentUserId()
        
        guard let url = URL(string: apiConfig.baseURL + "/api/forum/uploads") else {
            throw ForumError.invalidResponse
        }
        
        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Add authentication headers using shared configuration
        let headers = apiConfig.createAuthHeaders()
        for (key, value) in headers {
            // Skip Content-Type as it's set by multipart form
            if key != "Content-Type" {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        logger.info("🔐 Upload Auth Headers added")
        
        // Build multipart form data
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(uploadRequest.fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(uploadRequest.mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(uploadRequest.file)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add user_id
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(uploadRequest.userId)".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add type
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"type\"\r\n\r\n".data(using: .utf8)!)
        body.append(uploadRequest.type.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add post_id if provided
        if let postId = uploadRequest.postId {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"post_id\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(postId)".data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let data = try await performRequest(request)
        
        let response = try JSONDecoder().decode(UploadResponse.self, from: data)
        logger.info("✅ File uploaded successfully - fileUrl: \(response.data.fileUrl ?? "nil")")
        
        return response
    }
}

// MARK: - Forum Errors

/// Forum service error types
enum ForumError: LocalizedError {
    case userNotAuthenticated
    case invalidResponse
    case networkError(Error)
    case badRequest(String)
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case serverError
    case unknownError(Int)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated. Please log in."
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .badRequest(let message):
            return message
        case .unauthorized:
            return "Authentication failed"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .serverError:
            return "Server error occurred"
        case .unknownError(let code):
            return "Unknown error with status code: \(code)"
        }
    }
}

// MARK: - Import CryptoKit

import CryptoKit
