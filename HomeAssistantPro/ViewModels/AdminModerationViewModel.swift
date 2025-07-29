//
//  AdminModerationViewModel.swift
//  HomeAssistantPro
//
//  Purpose: Manages admin moderation actions for forum posts and replies
//  Author: Michael
//  Created: 2025-07-25
//  Modified: 2025-07-25
//
//  Modification Log:
//  - 2025-07-25: Initial creation with moderation action support
//  - 2025-07-25: Updated to use real AdminForumService API calls
//
//  Functions:
//  - moderatePost(_:action:reason:): Handles post approval/rejection
//  - moderateReply(_:action:reason:): Handles reply approval/rejection
//  - fetchReviewQueue(): Gets posts/replies pending review
//  - canModerate(userStatus:): Checks if user has admin privileges
//

import SwiftUI
import os.log

/// ViewModel for managing admin moderation actions in forum
@MainActor
class AdminModerationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Loading state for moderation actions
    @Published var isLoading = false
    
    /// Error message for moderation failures
    @Published var errorMessage: String?
    
    /// Success message for completed actions
    @Published var successMessage: String?
    
    /// Posts awaiting moderation review
    @Published var reviewQueue: [ForumTopic] = []
    
    /// Replies awaiting moderation review  
    @Published var pendingReplies: [ForumReply] = []
    
    /// Forum statistics for admin dashboard
    @Published var forumStats: ForumStats?
    
    /// Last refresh time for stats
    @Published var lastStatsRefresh: Date?
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "AdminModerationViewModel")
    private let adminForumService = AdminForumService.shared
    
    // MARK: - Moderation Actions
    
    /// Available moderation actions for posts/replies
    enum ModerationAction: String, CaseIterable {
        case approve = "approve"
        case reject = "reject"
        case delete = "delete"
        
        var displayName: String {
            switch self {
            case .approve: return "Approve"
            case .reject: return "Reject"
            case .delete: return "Delete"
            }
        }
        
        var iconName: String {
            switch self {
            case .approve: return "checkmark.circle.fill"
            case .reject: return "xmark.circle.fill"
            case .delete: return "trash.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .approve: return DesignTokens.Colors.primaryGreen
            case .reject: return DesignTokens.Colors.primaryRed
            case .delete: return DesignTokens.Colors.primaryRed
            }
        }
    }
    
    // MARK: - Post Moderation
    
    /// Moderates a forum post with specified action
    /// - Parameters:
    ///   - post: The forum topic to moderate
    ///   - action: Moderation action to perform
    ///   - reason: Optional reason for the action
    func moderatePost(_ post: ForumTopic, action: ModerationAction, reason: String? = nil) async {
        logger.info("Moderating post \(post.id) with action: \(action.rawValue)")
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            let result = try await adminForumService.moderatePost(
                postId: post.id,
                postType: "topic",
                action: action.rawValue,
                reason: reason
            )
            
            successMessage = "Post \(action.displayName.lowercased())d successfully"
            logger.info("Post moderation completed successfully: \(result.actionTaken)")
            
            // Remove from review queue if approved/rejected
            if action == .approve || action == .reject {
                reviewQueue.removeAll { $0.id == post.id }
            }
            
        } catch {
            errorMessage = "Failed to \(action.displayName.lowercased()) post: \(error.localizedDescription)"
            logger.error("Post moderation failed: \(error.localizedDescription)")
        }
    }
    
    /// Moderates a forum reply with specified action
    /// - Parameters:
    ///   - reply: The forum reply to moderate
    ///   - action: Moderation action to perform
    ///   - reason: Optional reason for the action
    func moderateReply(_ reply: ForumReply, action: ModerationAction, reason: String? = nil) async {
        logger.info("Moderating reply \(reply.id) with action: \(action.rawValue)")
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            let result = try await adminForumService.moderatePost(
                postId: reply.id,
                postType: "reply",
                action: action.rawValue,
                reason: reason
            )
            
            successMessage = "Reply \(action.displayName.lowercased())d successfully"
            logger.info("Reply moderation completed successfully: \(result.actionTaken)")
            
            // Remove from pending list if approved/rejected
            if action == .approve || action == .reject {
                pendingReplies.removeAll { $0.id == reply.id }
            }
            
        } catch {
            errorMessage = "Failed to \(action.displayName.lowercased()) reply: \(error.localizedDescription)"
            logger.error("Reply moderation failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Review Queue Management
    
    /// Fetches posts and replies awaiting moderation review
    func fetchReviewQueue() async {
        logger.info("Fetching moderation review queue")
        
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            let queue = try await adminForumService.fetchReviewQueue()
            
            // Separate topics and replies for easier management
            let topics = queue.pendingItems.compactMap { item -> ForumTopic? in
                guard item.type == "topic" else { return nil }
                
                return ForumTopic(
                    id: item.id,
                    title: item.title ?? "Untitled",
                    content: item.content,
                    category: item.category ?? "General",
                    author: ForumAuthor(
                        id: item.author.id,
                        name: item.author.name,
                        status: item.author.role == "admin" ? 87 : 2
                    ),
                    replyCount: 0,
                    likeCount: 0,
                    isLiked: false,
                    status: -1, // Under review
                    images: [],
                    createdAt: item.createdAt,
                    updatedAt: item.createdAt
                )
            }
            
            let replies = queue.pendingItems.compactMap { item -> ForumReply? in
                guard item.type == "reply", let topicId = item.topicId else { return nil }
                
                return ForumReply(
                    id: item.id,
                    content: item.content,
                    author: ForumAuthor(
                        id: item.author.id,
                        name: item.author.name,
                        status: item.author.role == "admin" ? 87 : 2
                    ),
                    parentReplyId: nil,
                    likeCount: 0,
                    isLiked: false,
                    status: -1, // Under review
                    images: [],
                    createdAt: item.createdAt,
                    updatedAt: item.createdAt
                )
            }
            
            reviewQueue = topics
            pendingReplies = replies
            
            logger.info("Review queue fetched successfully: \(topics.count) topics, \(replies.count) replies")
            
        } catch {
            errorMessage = "Failed to fetch review queue: \(error.localizedDescription)"
            logger.error("Review queue fetch failed: \(error.localizedDescription)")
        }
    }
    
    /// Fetches forum statistics for admin dashboard
    func fetchForumStats() async {
        logger.info("Fetching forum statistics")
        
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            let stats = try await adminForumService.fetchForumStats()
            forumStats = stats
            lastStatsRefresh = Date()
            
            logger.info("Forum stats fetched successfully")
            
        } catch {
            errorMessage = "Failed to fetch forum stats: \(error.localizedDescription)"
            logger.error("Forum stats fetch failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Permission Checking
    
    /// Checks if a user can perform moderation actions
    /// - Parameter userStatus: User's authentication status
    /// - Returns: True if user has admin privileges
    func canModerate(userStatus: UserStatus) -> Bool {
        return userStatus.canModerate
    }
    
    /// Checks if current user can moderate based on app view model
    /// - Parameter appViewModel: Current app view model
    /// - Returns: True if current user can moderate
    func canModerate(appViewModel: AppViewModel) -> Bool {
        guard let currentUser = appViewModel.currentUser else {
            return false
        }
        return canModerate(userStatus: currentUser.userStatus)
    }
    
    // MARK: - Helper Methods
    
    /// Clears any displayed messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    /// Gets the appropriate confirmation message for a moderation action
    /// - Parameters:
    ///   - action: The moderation action
    ///   - itemType: Type of item (post/reply)
    /// - Returns: Confirmation message string
    func getConfirmationMessage(for action: ModerationAction, itemType: String) -> String {
        switch action {
        case .approve:
            return "Are you sure you want to approve this \(itemType)? It will be visible to all users."
        case .reject:
            return "Are you sure you want to reject this \(itemType)? The author will be notified."
        case .delete:
            return "Are you sure you want to delete this \(itemType)? This action cannot be undone."
        }
    }
}