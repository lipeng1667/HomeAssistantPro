//
//  BackgroundDataPreloader.swift
//  HomeAssistantPro
//
//  Purpose: Background data preloading service for improving app performance
//  Author: Michael
//  Created: 2025-07-10
//  Modified: 2025-07-10
//
//  Modification Log:
//  - 2025-07-10: Initial creation with forum data preloading
//
//  Functions:
//  - startPreloading(): Initiates background data loading tasks
//  - preloadForumData(): Preloads forum topics and categories
//  - getCachedForumTopics(): Returns cached forum topics if available
//  - getCachedCategories(): Returns cached forum categories if available
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
        
        // Store tasks for potential cancellation
        preloadingTasks = [forumTask, categoriesTask]
        
        // Monitor completion
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await forumTask.value }
                group.addTask { await categoriesTask.value }
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
    
    /// Checks if forum data is available in cache
    /// - Returns: True if cached data exists and is valid
    func hasValidCachedData() -> Bool {
        return cacheManager.hasValidForumCache()
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
                self.preloadingProgress += 0.5
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
                self.preloadingProgress += 0.5
                self.logger.info("Categories preloaded and cached: \(response.data.categories.count) categories")
            }
            
        } catch {
            logger.error("Failed to preload categories: \(error.localizedDescription)")
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