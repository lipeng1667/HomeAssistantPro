//
//  CacheManager.swift
//  HomeAssistantPro
//
//  Purpose: In-memory cache management service for storing and retrieving preloaded data
//  Author: Michael
//  Created: 2025-07-10
//  Modified: 2025-07-17
//
//  Modification Log:
//  - 2025-07-10: Initial creation with forum data caching using UserDefaults
//  - 2025-07-17: Added chat history caching support for splash screen preloading optimization
//  - 2025-07-17: Refactored from UserDefaults to in-memory cache for better performance
//
//  Functions:
//  - cacheForumTopics(_:): Stores forum topics in memory cache
//  - getCachedForumTopics(): Retrieves cached forum topics from memory
//  - cacheCategories(_:): Stores forum categories in memory cache
//  - getCachedCategories(): Retrieves cached forum categories from memory
//  - cacheChatHistory(_:): Stores chat history in memory cache
//  - getCachedChatHistory(): Retrieves cached chat history from memory
//  - hasValidForumCache(): Checks if cached forum data is still valid
//  - hasValidChatCache(): Checks if cached chat data is still valid
//  - clearCache(): Clears all cached data from memory
//

import Foundation
import os.log

/// Cache management service for storing and retrieving preloaded application data in memory
class CacheManager {
    
    // MARK: - Singleton
    static let shared = CacheManager()
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "CacheManager")
    
    // In-memory cache storage
    private var cachedForumTopics: [ForumTopic] = []
    private var cachedForumCategories: [ForumCategory] = []
    private var cachedChatHistory: [ChatMessage] = []
    
    // Cache timestamps
    private var forumTopicsTimestamp: Date?
    private var categoriesTimestamp: Date?
    private var chatHistoryTimestamp: Date?
    
    // Cache expiration time (30 minutes)
    private let cacheExpirationInterval: TimeInterval = 30 * 60
    
    // MARK: - Initialization
    private init() {
        logger.info("CacheManager initialized")
    }
    
    // MARK: - Forum Topics Cache
    
    /// Stores forum topics in memory cache with timestamp
    /// - Parameter topics: Array of ForumTopic objects to cache
    func cacheForumTopics(_ topics: [ForumTopic]) {
        cachedForumTopics = topics
        forumTopicsTimestamp = Date()
        logger.info("Cached \(topics.count) forum topics in memory")
    }
    
    /// Retrieves cached forum topics if available and valid
    /// - Returns: Array of cached ForumTopic objects, or empty array if none/expired
    func getCachedForumTopics() -> [ForumTopic] {
        guard isForumTopicsCacheValid() else {
            logger.info("Forum topics cache is invalid or expired")
            clearForumTopicsCache()
            return []
        }
        
        logger.info("Retrieved \(self.cachedForumTopics.count) cached forum topics from memory")
        return cachedForumTopics
    }
    
    /// Checks if forum topics cache is valid (not expired)
    /// - Returns: True if cache exists and is within expiration time
    private func isForumTopicsCacheValid() -> Bool {
        guard let timestamp = forumTopicsTimestamp else {
            return false
        }
        
        let timeSinceCache = Date().timeIntervalSince(timestamp)
        return timeSinceCache < cacheExpirationInterval && !cachedForumTopics.isEmpty
    }
    
    /// Clears forum topics cache
    private func clearForumTopicsCache() {
        cachedForumTopics = []
        forumTopicsTimestamp = nil
        logger.info("Cleared forum topics cache from memory")
    }
    
    // MARK: - Categories Cache
    
    /// Stores forum categories in memory cache with timestamp
    /// - Parameter categories: Array of ForumCategory objects to cache
    func cacheCategories(_ categories: [ForumCategory]) {
        cachedForumCategories = categories
        categoriesTimestamp = Date()
        logger.info("Cached \(categories.count) forum categories in memory")
    }
    
    /// Retrieves cached forum categories if available and valid
    /// - Returns: Array of cached ForumCategory objects, or empty array if none/expired
    func getCachedCategories() -> [ForumCategory] {
        guard isCategoriesCacheValid() else {
            logger.info("Categories cache is invalid or expired")
            clearCategoriesCache()
            return []
        }
        
        logger.info("Retrieved \(self.cachedForumCategories.count) cached categories from memory")
        return cachedForumCategories
    }
    
    /// Checks if categories cache is valid (not expired)
    /// - Returns: True if cache exists and is within expiration time
    private func isCategoriesCacheValid() -> Bool {
        guard let timestamp = categoriesTimestamp else {
            return false
        }
        
        let timeSinceCache = Date().timeIntervalSince(timestamp)
        return timeSinceCache < cacheExpirationInterval && !cachedForumCategories.isEmpty
    }
    
    /// Clears categories cache
    private func clearCategoriesCache() {
        cachedForumCategories = []
        categoriesTimestamp = nil
        logger.info("Cleared categories cache from memory")
    }
    
    // MARK: - Cache Validation
    
    /// Checks if there's valid cached forum data available
    /// - Returns: True if both topics and categories have valid cache
    func hasValidForumCache() -> Bool {
        return isForumTopicsCacheValid() && isCategoriesCacheValid()
    }
    
    /// Checks if there's any cached forum data (valid or not)
    /// - Returns: True if any forum data exists in cache
    func hasCachedForumData() -> Bool {
        return !cachedForumTopics.isEmpty || !cachedForumCategories.isEmpty
    }
    
    /// Checks if there's valid cached chat history available
    /// - Returns: True if chat history cache exists and is valid
    func hasValidChatCache() -> Bool {
        return isChatHistoryCacheValid()
    }
    
    /// Checks if there's any cached chat data (valid or not)
    /// - Returns: True if any chat history exists in cache
    func hasCachedChatData() -> Bool {
        return !cachedChatHistory.isEmpty
    }
    
    // MARK: - Cache Management
    
    // MARK: - Chat History Cache
    
    /// Stores chat history in memory cache with timestamp
    /// - Parameter messages: Array of ChatMessage objects to cache
    func cacheChatHistory(_ messages: [ChatMessage]) {
        cachedChatHistory = messages
        chatHistoryTimestamp = Date()
        logger.info("Cached \(messages.count) chat messages in memory")
    }
    
    /// Retrieves cached chat history if available and valid
    /// - Returns: Array of cached ChatMessage objects, or empty array if none/expired
    func getCachedChatHistory() -> [ChatMessage] {
        guard isChatHistoryCacheValid() else {
            logger.info("Chat history cache is invalid or expired")
            clearChatHistoryCache()
            return []
        }
        
        logger.info("Retrieved \(self.cachedChatHistory.count) cached chat messages from memory")
        return cachedChatHistory
    }
    
    /// Checks if chat history cache is valid (not expired)
    /// - Returns: True if cache exists and is within expiration time
    private func isChatHistoryCacheValid() -> Bool {
        guard let timestamp = chatHistoryTimestamp else {
            return false
        }
        
        let timeSinceCache = Date().timeIntervalSince(timestamp)
        return timeSinceCache < cacheExpirationInterval && !cachedChatHistory.isEmpty
    }
    
    /// Clears chat history cache
    private func clearChatHistoryCache() {
        cachedChatHistory = []
        chatHistoryTimestamp = nil
        logger.info("Cleared chat history cache from memory")
    }
    
    /// Clears all cached data
    func clearAllCache() {
        clearForumTopicsCache()
        clearCategoriesCache()
        clearChatHistoryCache()
        logger.info("Cleared all cache data")
    }
    
    /// Gets cache statistics for debugging
    /// - Returns: Dictionary with cache information
    func getCacheInfo() -> [String: Any] {
        var info: [String: Any] = [:]
        
        // Forum topics info
        if let timestamp = forumTopicsTimestamp {
            info["topics_cached_at"] = timestamp
            info["topics_age_minutes"] = Int(Date().timeIntervalSince(timestamp) / 60)
            info["topics_valid"] = isForumTopicsCacheValid()
            info["topics_count"] = cachedForumTopics.count
        }
        
        // Categories info
        if let timestamp = categoriesTimestamp {
            info["categories_cached_at"] = timestamp
            info["categories_age_minutes"] = Int(Date().timeIntervalSince(timestamp) / 60)
            info["categories_valid"] = isCategoriesCacheValid()
            info["categories_count"] = cachedForumCategories.count
        }
        
        // Chat history info
        if let timestamp = chatHistoryTimestamp {
            info["chat_cached_at"] = timestamp
            info["chat_age_minutes"] = Int(Date().timeIntervalSince(timestamp) / 60)
            info["chat_valid"] = isChatHistoryCacheValid()
            info["chat_count"] = cachedChatHistory.count
        }
        
        info["cache_expiration_minutes"] = Int(cacheExpirationInterval / 60)
        info["storage_type"] = "memory"
        
        return info
    }
}
