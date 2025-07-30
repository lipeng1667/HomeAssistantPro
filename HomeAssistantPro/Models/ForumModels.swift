//
//  ForumModels.swift
//  HomeAssistantPro
//
//  Purpose: Data models for forum API requests and responses
//  Author: Michael
//  Created: 2025-07-10
//  Modified: 2025-07-25
//
//  Modification Log:
//  - 2025-07-10: Initial creation with forum topic and reply models
//  - 2025-07-25: Added admin detection helpers and author display properties
//
//  Functions:
//  - Codable models for forum API communication
//  - ForumTopic: Topic data with replies, likes, and metadata
//  - ForumReply: Reply data with author and like information
//  - ForumCategory: Category information with counts
//  - ForumDraft: Draft management models
//  - ForumUpload: File upload models
//  - Pagination models for list responses
//

import Foundation

// MARK: - Core Forum Models

/// Forum topic model matching API response structure
struct ForumTopic: Codable, Identifiable {
    let id: Int
    let title: String
    let content: String
    let category: String
    let author: ForumAuthor?
    let replyCount: Int
    let likeCount: Int
    let isLiked: Bool?
    let status: Int
    let images: [String]
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case category
        case author
        case replyCount = "reply_count"
        case likeCount = "like_count"
        case isLiked = "is_liked"
        case status
        case images
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Computed property to check if topic is published
    var isPublished: Bool {
        return status == 0
    }
    
    /// Computed property to check if topic is under review
    var isUnderReview: Bool {
        return status == -1
    }
    
    /// Computed property to check if topic is rejected
    var isRejected: Bool {
        return status == 2
    }
    
    /// Computed property to check if topic is deleted
    var isDeleted: Bool {
        return status == 1
    }
    
    /// Computed property to check if topic is hot (trending)
    var isHot: Bool {
        return likeCount > 50 || replyCount > 20
    }
    
    /// Computed property for formatted time ago
    var timeAgo: String {
        return DateUtils.formatTimeAgo(from: createdAt)
    }
    
    /// Author display name with fallback
    var authorDisplayName: String {
        return author?.name ?? "Anonymous"
    }
    
    /// Whether the author is an admin user
    var isAuthorAdmin: Bool {
        return author?.isAdmin ?? false
    }
}

/// Forum reply model matching API response structure
struct ForumReply: Codable, Identifiable {
    let id: Int
    let content: String
    let author: ForumAuthor
    let parentReplyId: Int?
    var parentReply: ParentReplyInfo?
    let likeCount: Int
    let isLiked: Bool
    let status: Int
    let images: [String]
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case author
        case parentReplyId = "parent_reply_id"
        case likeCount = "like_count"
        case isLiked = "is_liked"
        case status
        case images
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Computed property to check if reply is published
    var isPublished: Bool {
        return status == 0
    }
    
    /// Computed property to check if reply is under review
    var isUnderReview: Bool {
        return status == -1
    }
    
    /// Computed property to check if reply is rejected
    var isRejected: Bool {
        return status == 2
    }
    
    /// Computed property to check if reply is deleted
    var isDeleted: Bool {
        return status == 1
    }
    
    /// Computed property for formatted time ago
    var timeAgo: String {
        return DateUtils.formatTimeAgo(from: createdAt)
    }
    
    /// Computed property to check if this is a nested reply
    var isNestedReply: Bool {
        return parentReplyId != nil
    }
}

/// Parent reply information for nested replies
struct ParentReplyInfo {
    let id: Int
    let content: String
    let author: ForumAuthor
    
    /// Computed property for shortened content preview
    var contentPreview: String {
        return String(content.prefix(100)) + (content.count > 100 ? "..." : "")
    }
}

/// Forum author information
struct ForumAuthor: Codable {
    let id: Int
    let name: String
    let status: Int? // User status (87 = admin, 2 = registered, etc.)
    
    /// Computed property to check if author is admin
    var isAdmin: Bool {
        return status == 87
    }
    
    /// Gets user status enum from raw value
    var userStatus: UserStatus {
        guard let status = status else { return .normal }
        return UserStatus(rawValue: status) ?? .normal
    }
}

/// Forum category model
struct ForumCategory: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let topicCount: Int
    let icon: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case topicCount = "topic_count"
        case icon
    }
}

// MARK: - API Response Models

/// Response model for topics list
struct ForumTopicsResponse: Codable {
    let status: String
    let data: ForumTopicsData
    
    struct ForumTopicsData: Codable {
        let topics: [ForumTopic]
        let pagination: ForumPagination
    }
}

/// Response model for topic detail
struct ForumTopicDetailResponse: Codable {
    let status: String
    let data: ForumTopicDetailData
    
    struct ForumTopicDetailData: Codable {
        let topic: ForumTopic
        let replies: [ForumReply]
        let totalReplies: Int
        
        enum CodingKeys: String, CodingKey {
            case topic
            case replies
            case totalReplies = "total_replies"
        }
    }
}

/// Response model for replies list
struct ForumRepliesResponse: Codable {
    let status: String
    let data: ForumRepliesData
    
    struct ForumRepliesData: Codable {
        let replies: [ForumReply]
        let pagination: ForumPagination
    }
}

/// Response model for categories list
struct ForumCategoriesResponse: Codable {
    let status: String
    let data: ForumCategoriesData
    
    struct ForumCategoriesData: Codable {
        let categories: [ForumCategory]
    }
}

/// Response model for search results
struct ForumSearchResponse: Codable {
    let status: String
    let data: ForumSearchData
    
    struct ForumSearchData: Codable {
        let results: [ForumSearchResult]
        let pagination: ForumPagination
        let searchInfo: ForumSearchInfo
        
        enum CodingKeys: String, CodingKey {
            case results
            case pagination
            case searchInfo = "search_info"
        }
    }
}

/// Search result model
struct ForumSearchResult: Codable, Identifiable {
    let id: Int
    let type: String
    let title: String?
    let content: String
    let category: String
    let author: ForumAuthor
    let topicId: Int?
    let likeCount: Int
    let replyCount: Int?
    let relevanceScore: Double
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case content
        case category
        case author
        case topicId = "topic_id"
        case likeCount = "like_count"
        case replyCount = "reply_count"
        case relevanceScore = "relevance_score"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Search metadata information
struct ForumSearchInfo: Codable {
    let query: String
    let totalResults: Int
    let searchTime: Double
    let filtersApplied: ForumSearchFilters
    
    enum CodingKeys: String, CodingKey {
        case query
        case totalResults = "total_results"
        case searchTime = "search_time"
        case filtersApplied = "filters_applied"
    }
}

/// Search filters information
struct ForumSearchFilters: Codable {
    let category: String?
    let type: String?
}

/// Pagination model for API responses
struct ForumPagination: Codable {
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

// MARK: - Request Models

/// Request model for creating a new topic
struct CreateTopicRequest: Codable {
    let userId: Int
    let title: String
    let content: String
    let category: String
    let images: [String]
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case title
        case content
        case category
        case images
    }
}

/// Request model for updating a topic
struct UpdateTopicRequest: Codable {
    let userId: Int
    let title: String?
    let content: String?
    let category: String?
    let images: [String]?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case title
        case content
        case category
        case images
    }
}

/// Request model for deleting a topic
struct DeleteTopicRequest: Codable {
    let userId: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

/// Request model for creating a reply
struct CreateReplyRequest: Codable {
    let userId: Int
    let content: String
    let parentReplyId: Int?
    let images: [String]
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case content
        case parentReplyId = "parent_reply_id"
        case images
    }
}

/// Request model for updating a reply
struct UpdateReplyRequest: Codable {
    let userId: Int
    let content: String
    let images: [String]
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case content
        case images
    }
}

/// Request model for deleting a reply
struct DeleteReplyRequest: Codable {
    let userId: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

/// Request model for like/unlike actions
struct LikeRequest: Codable {
    let userId: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

// MARK: - Response Models for Actions

/// Response model for topic creation
struct CreateTopicResponse: Codable {
    let status: String
    let data: CreateTopicData
    
    struct CreateTopicData: Codable {
        let topic: TopicCreationInfo
        
        struct TopicCreationInfo: Codable {
            let id: Int
            let createdAt: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case createdAt = "created_at"
            }
        }
    }
}

/// Response model for reply creation
struct CreateReplyResponse: Codable {
    let status: String
    let data: CreateReplyData
    
    struct CreateReplyData: Codable {
        let reply: ReplyCreationInfo
        
        struct ReplyCreationInfo: Codable {
            let id: Int
            let createdAt: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case createdAt = "created_at"
            }
        }
    }
}

/// Response model for like/unlike actions
struct LikeResponse: Codable {
    let status: String
    let data: LikeData
    
    struct LikeData: Codable {
        let isLiked: Bool
        let likeCount: Int
        
        enum CodingKeys: String, CodingKey {
            case isLiked = "is_liked"
            case likeCount = "like_count"
        }
    }
}

/// Response model for topic/reply updates
struct UpdateTopicResponse: Codable {
    let status: String
    let data: UpdateTopicData
    
    struct UpdateTopicData: Codable {
        let topic: ForumTopic
    }
}

/// Response model for reply updates
struct UpdateReplyResponse: Codable {
    let status: String
    let data: UpdateReplyData
    
    struct UpdateReplyData: Codable {
        let reply: ForumReply
    }
}

/// Response model for deletions
struct DeleteResponse: Codable {
    let status: String
    let message: String
}

// MARK: - Draft Models

/// Draft topic model
struct ForumTopicDraft: Codable, Identifiable {
    let id: Int
    let userId: Int
    let title: String
    let content: String
    let category: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case content
        case category
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Draft reply model
struct ForumReplyDraft: Codable, Identifiable {
    let id: Int
    let userId: Int
    let content: String
    let topicId: Int
    let topicTitle: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case content
        case topicId = "topic_id"
        case topicTitle = "topic_title"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Response model for drafts
struct ForumDraftsResponse: Codable {
    let status: String
    let data: ForumDraftsData
    
    struct ForumDraftsData: Codable {
        let topicDraft: ForumTopicDraft?
        let replyDrafts: [ForumReplyDraft]
        
        enum CodingKeys: String, CodingKey {
            case topicDraft = "topic_draft"
            case replyDrafts = "reply_drafts"
        }
    }
}

/// Request model for saving drafts
struct SaveDraftRequest: Codable {
    let userId: Int
    let title: String?
    let content: String?
    let category: String?
    let type: String
    let topicId: Int?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case title
        case content
        case category
        case type
        case topicId = "topic_id"
    }
}

/// Response model for draft creation
struct SaveDraftResponse: Codable {
    let status: String
    let data: SaveDraftData
    
    struct SaveDraftData: Codable {
        let draft: DraftInfo
        
        struct DraftInfo: Codable {
            let id: Int
            let userId: Int
            let title: String?
            let content: String?
            let category: String?
            let type: String
            let createdAt: String
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case userId = "user_id"
                case title
                case content
                case category
                case type
                case createdAt = "created_at"
                case updatedAt = "updated_at"
            }
        }
    }
}

/// Request model for deleting drafts
struct DeleteDraftRequest: Codable {
    let userId: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

// MARK: - Upload Models

/// Upload progress model
struct UploadProgress: Codable {
    let uploadId: String
    let chunkIndex: Int
    let totalChunks: Int
    let uploadedChunks: Int
    let progressPercentage: Int
    let fileUrl: String?
    let fileId: Int?
    let complete: Bool
    
    enum CodingKeys: String, CodingKey {
        case uploadId = "upload_id"
        case chunkIndex = "chunk_index"
        case totalChunks = "total_chunks"
        case uploadedChunks = "uploaded_chunks"
        case progressPercentage = "progress_percentage"
        case fileUrl = "file_url"
        case fileId = "file_id"
        case complete
    }
}

/// Upload response model
struct UploadResponse: Codable {
    let status: String
    let data: UploadProgress
}

/// Request model for file upload
struct FileUploadRequest {
    let file: Data
    let fileName: String
    let mimeType: String
    let userId: Int
    let type: String // "topic" or "reply"
    let postId: Int?
}

// MARK: - Enums

/// Forum topic status
enum ForumTopicStatus: Int, CaseIterable {
    case waitingForReview = -1
    case published = 0
    case deleted = 1
    
    var description: String {
        switch self {
        case .waitingForReview: return "Waiting for Review"
        case .published: return "Published"
        case .deleted: return "Deleted"
        }
    }
}

/// Forum sort options
enum ForumSortOption: String, CaseIterable {
    case newest = "newest"
    case oldest = "oldest"
    case popular = "popular"
    case trending = "trending"
    
    var displayName: String {
        switch self {
        case .newest: return "Newest"
        case .oldest: return "Oldest"
        case .popular: return "Popular"
        case .trending: return "Trending"
        }
    }
}

/// Forum search type
enum ForumSearchType: String, CaseIterable {
    case all = "all"
    case topics = "topics"
    case replies = "replies"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .topics: return "Topics"
        case .replies: return "Replies"
        }
    }
}
