//
//  BackgroundDataPreloader.swift
//  HomeAssistantPro
//
//  Purpose: Background data preloading service for improving app performance
//  Author: Michael
//  Created: 2025-07-10
//  Modified: 2025-07-17
//
//  Modification Log:
//  - 2025-07-10: Initial creation with forum data preloading
//  - 2025-07-17: Added chat history preloading during splash screen for instant view loading
//
//  Functions:
//  - startPreloading(): Initiates background data loading tasks (forum + chat)
//  - preloadForumData(): Preloads forum topics and categories
//  - preloadChatHistory(): Preloads chat history messages
//  - getCachedForumTopics(): Returns cached forum topics if available
//  - getCachedCategories(): Returns cached forum categories if available
//  - getCachedChatHistory(): Returns cached chat history if available
//  - hasValidCachedData(): Checks if forum cache is valid
//  - hasValidCachedChatData(): Checks if chat cache is valid
//

import Foundation
import SwiftUI
import os.log

/// Background data preloader service for improving app startup performance
@MainActor
class BackgroundDataPreloader: ObservableObject {
    
    // MARK: - Singleton
    static let shared = BackgroundDataPreloader()
    
    // MARK: - Published Properties
    @Published var isPreloadingComplete = false
    @Published var preloadingProgress: Double = 0.0
    
    // MARK: - Private Properties
    private let forumService = ForumService.shared
    private let imService = IMService.shared
    private let cacheManager = CacheManager.shared
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "BackgroundDataPreloader")
    
    private var preloadingTasks: [Task<Void, Never>] = []
    
    // MARK: - Initialization
    private init() {
        logger.info("BackgroundDataPreloader initialized")
    }
    
    // MARK: - Public Methods
    
    /// Starts background preloading of essential app data
    /// - Note: This method is non-blocking and runs in background
    func startPreloading() {
        logger.info("Starting background data preloading")
        
        // Cancel any existing preloading tasks
        stopPreloading()
        
        // Start preloading tasks concurrently
        let forumTask = Task {
            await preloadForumData()
        }
        
        let categoriesTask = Task {
            await preloadCategories()
        }
        
        let chatTask = Task {
            await preloadChatHistory()
        }
        
        // Store tasks for potential cancellation
        preloadingTasks = [forumTask, categoriesTask, chatTask]
        
        // Monitor completion
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await forumTask.value }
                group.addTask { await categoriesTask.value }
                group.addTask { await chatTask.value }
            }
            
            await MainActor.run {
                self.isPreloadingComplete = true
                self.preloadingProgress = 1.0
                self.logger.info("Background preloading completed")
            }
        }
    }
    
    /// Stops all ongoing preloading tasks
    func stopPreloading() {
        preloadingTasks.forEach { $0.cancel() }
        preloadingTasks.removeAll()
        logger.info("Background preloading stopped")
    }
    
    /// Returns cached forum topics if available
    /// - Returns: Array of cached ForumTopic objects, or empty array if none cached
    func getCachedForumTopics() -> [ForumTopic] {
        return cacheManager.getCachedForumTopics()
    }
    
    /// Returns cached forum categories if available
    /// - Returns: Array of cached ForumCategory objects, or empty array if none cached
    func getCachedCategories() -> [ForumCategory] {
        return cacheManager.getCachedCategories()
    }
    
    /// Returns cached chat history if available
    /// - Returns: Array of cached ChatMessage objects, or empty array if none cached
    func getCachedChatHistory() -> [ChatMessage] {
        return cacheManager.getCachedChatHistory()
    }
    
    /// Checks if forum data is available in cache
    /// - Returns: True if cached data exists and is valid
    func hasValidCachedData() -> Bool {
        return cacheManager.hasValidForumCache()
    }
    
    /// Checks if chat history is available in cache
    /// - Returns: True if cached chat data exists and is valid
    func hasValidCachedChatData() -> Bool {
        return cacheManager.hasValidChatCache()
    }
    
    // MARK: - Private Methods
    
    /// Preloads forum topics data in background
    private func preloadForumData() async {
        logger.info("Starting forum topics preload")
        
        do {
            let response = try await forumService.fetchTopics(
                page: 1,
                limit: 20,
                category: nil,
                sort: .newest,
                search: nil
            )
            
            // Cache the preloaded data
            await MainActor.run {
                cacheManager.cacheForumTopics(response.data.topics)
                self.preloadingProgress += 0.33
                self.logger.info("Forum topics preloaded and cached: \(response.data.topics.count) topics")
            }
            
        } catch {
            logger.error("Failed to preload forum topics: \(error.localizedDescription)")
        }
    }
    
    /// Preloads forum categories data in background
    private func preloadCategories() async {
        logger.info("Starting categories preload")
        
        do {
            let response = try await forumService.fetchCategories()
            
            // Cache the preloaded data
            await MainActor.run {
                cacheManager.cacheCategories(response.data.categories)
                self.preloadingProgress += 0.33
                self.logger.info("Categories preloaded and cached: \(response.data.categories.count) categories")
            }
            
        } catch {
            logger.error("Failed to preload categories: \(error.localizedDescription)")
        }
    }
    
    /// Preloads chat history data in background
    private func preloadChatHistory() async {
        logger.info("Starting chat history preload")
        
        // Get user ID for chat history (placeholder - you'll need to implement proper user ID retrieval)
        let userId = 53 // TODO: Replace with actual user ID from authentication
        
        do {
            let messages = try await imService.fetchMessages(userId: userId, page: 1, limit: 20)
            
            // Cache the preloaded data
            await MainActor.run {
                cacheManager.cacheChatHistory(messages)
                self.preloadingProgress += 0.34
                self.logger.info("Chat history preloaded and cached: \(messages.count) messages")
            }
            
        } catch {
            logger.error("Failed to preload chat history: \(error.localizedDescription)")
        }
    }
}

// MARK: - Environment Key
struct BackgroundDataPreloaderKey: EnvironmentKey {
    static let defaultValue: BackgroundDataPreloader = BackgroundDataPreloader.shared
}

extension EnvironmentValues {
    var backgroundDataPreloader: BackgroundDataPreloader {
        get { self[BackgroundDataPreloaderKey.self] }
        set { self[BackgroundDataPreloaderKey.self] = newValue }
    }
}