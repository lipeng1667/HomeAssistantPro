//
//  CacheManager.swift
//  HomeAssistantPro
//
//  Purpose: Cache management service for storing and retrieving preloaded data
//  Author: Michael
//  Created: 2025-07-10
//  Modified: 2025-07-10
//
//  Modification Log:
//  - 2025-07-10: Initial creation with forum data caching
//
//  Functions:
//  - cacheForumTopics(_:): Stores forum topics in cache
//  - getCachedForumTopics(): Retrieves cached forum topics
//  - cacheCategories(_:): Stores forum categories in cache
//  - getCachedCategories(): Retrieves cached forum categories
//  - hasValidForumCache(): Checks if cached forum data is still valid
//  - clearCache(): Clears all cached data
//

import Foundation
import os.log

/// Cache management service for storing and retrieving preloaded application data
class CacheManager {
    
    // MARK: - Singleton
    static let shared = CacheManager()
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "CacheManager")
    
    // Cache keys
    private enum CacheKeys {
        static let forumTopics = "cached_forum_topics"
        static let forumCategories = "cached_forum_categories"
        static let forumTopicsTimestamp = "cached_forum_topics_timestamp"
        static let categoriesTimestamp = "cached_categories_timestamp"
    }
    
    // Cache expiration time (30 minutes)
    private let cacheExpirationInterval: TimeInterval = 30 * 60
    
    // MARK: - Initialization
    private init() {
        logger.info("CacheManager initialized")
    }
    
    // MARK: - Forum Topics Cache
    
    /// Stores forum topics in cache with timestamp
    /// - Parameter topics: Array of ForumTopic objects to cache
    func cacheForumTopics(_ topics: [ForumTopic]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            let data = try encoder.encode(topics)
            userDefaults.set(data, forKey: CacheKeys.forumTopics)
            userDefaults.set(Date(), forKey: CacheKeys.forumTopicsTimestamp)
            
            logger.info("Cached \(topics.count) forum topics")
            
        } catch {
            logger.error("Failed to cache forum topics: \(error.localizedDescription)")
        }
    }
    
    /// Retrieves cached forum topics if available and valid
    /// - Returns: Array of cached ForumTopic objects, or empty array if none/expired
    func getCachedForumTopics() -> [ForumTopic] {
        guard isForumTopicsCacheValid() else {
            logger.info("Forum topics cache is invalid or expired")
            return []
        }
        
        guard let data = userDefaults.data(forKey: CacheKeys.forumTopics) else {
            logger.info("No cached forum topics found")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let topics = try decoder.decode([ForumTopic].self, from: data)
            logger.info("Retrieved \(topics.count) cached forum topics")
            return topics
            
        } catch {
            logger.error("Failed to decode cached forum topics: \(error.localizedDescription)")
            // Clear corrupted cache
            clearForumTopicsCache()
            return []
        }
    }
    
    /// Checks if forum topics cache is valid (not expired)
    /// - Returns: True if cache exists and is within expiration time
    private func isForumTopicsCacheValid() -> Bool {
        guard let timestamp = userDefaults.object(forKey: CacheKeys.forumTopicsTimestamp) as? Date else {
            return false
        }
        
        let timeSinceCache = Date().timeIntervalSince(timestamp)
        return timeSinceCache < cacheExpirationInterval
    }
    
    /// Clears forum topics cache
    private func clearForumTopicsCache() {
        userDefaults.removeObject(forKey: CacheKeys.forumTopics)
        userDefaults.removeObject(forKey: CacheKeys.forumTopicsTimestamp)
        logger.info("Cleared forum topics cache")
    }
    
    // MARK: - Categories Cache
    
    /// Stores forum categories in cache with timestamp
    /// - Parameter categories: Array of ForumCategory objects to cache
    func cacheCategories(_ categories: [ForumCategory]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(categories)
            userDefaults.set(data, forKey: CacheKeys.forumCategories)
            userDefaults.set(Date(), forKey: CacheKeys.categoriesTimestamp)
            
            logger.info("Cached \(categories.count) forum categories")
            
        } catch {
            logger.error("Failed to cache categories: \(error.localizedDescription)")
        }
    }
    
    /// Retrieves cached forum categories if available and valid
    /// - Returns: Array of cached ForumCategory objects, or empty array if none/expired
    func getCachedCategories() -> [ForumCategory] {
        guard isCategoriesCacheValid() else {
            logger.info("Categories cache is invalid or expired")
            return []
        }
        
        guard let data = userDefaults.data(forKey: CacheKeys.forumCategories) else {
            logger.info("No cached categories found")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let categories = try decoder.decode([ForumCategory].self, from: data)
            logger.info("Retrieved \(categories.count) cached categories")
            return categories
            
        } catch {
            logger.error("Failed to decode cached categories: \(error.localizedDescription)")
            // Clear corrupted cache
            clearCategoriesCache()
            return []
        }
    }
    
    /// Checks if categories cache is valid (not expired)
    /// - Returns: True if cache exists and is within expiration time
    private func isCategoriesCacheValid() -> Bool {
        guard let timestamp = userDefaults.object(forKey: CacheKeys.categoriesTimestamp) as? Date else {
            return false
        }
        
        let timeSinceCache = Date().timeIntervalSince(timestamp)
        return timeSinceCache < cacheExpirationInterval
    }
    
    /// Clears categories cache
    private func clearCategoriesCache() {
        userDefaults.removeObject(forKey: CacheKeys.forumCategories)
        userDefaults.removeObject(forKey: CacheKeys.categoriesTimestamp)
        logger.info("Cleared categories cache")
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
        let hasTopics = userDefaults.data(forKey: CacheKeys.forumTopics) != nil
        let hasCategories = userDefaults.data(forKey: CacheKeys.forumCategories) != nil
        return hasTopics || hasCategories
    }
    
    // MARK: - Cache Management
    
    /// Clears all cached data
    func clearAllCache() {
        clearForumTopicsCache()
        clearCategoriesCache()
        logger.info("Cleared all cache data")
    }
    
    /// Gets cache statistics for debugging
    /// - Returns: Dictionary with cache information
    func getCacheInfo() -> [String: Any] {
        var info: [String: Any] = [:]
        
        // Forum topics info
        if let timestamp = userDefaults.object(forKey: CacheKeys.forumTopicsTimestamp) as? Date {
            info["topics_cached_at"] = timestamp
            info["topics_age_minutes"] = Int(Date().timeIntervalSince(timestamp) / 60)
            info["topics_valid"] = isForumTopicsCacheValid()
        }
        
        // Categories info
        if let timestamp = userDefaults.object(forKey: CacheKeys.categoriesTimestamp) as? Date {
            info["categories_cached_at"] = timestamp
            info["categories_age_minutes"] = Int(Date().timeIntervalSince(timestamp) / 60)
            info["categories_valid"] = isCategoriesCacheValid()
        }
        
        info["cache_expiration_minutes"] = Int(cacheExpirationInterval / 60)
        
        return info
    }
}