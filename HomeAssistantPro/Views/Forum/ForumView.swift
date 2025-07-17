//
//  ForumView.swift
//  HomeAssistantPro
//
//  Purpose: Modern forum community with 2025 iOS design aesthetics
//  Author: Michael
//  Updated: 2025-07-17
//
//  Features: Glassmorphism search, floating cards, smooth animations,
//  dynamic interactions, contemporary visual hierarchy, and optimized
//  data loading using splash screen preloaded cache to avoid redundant API calls.
//

import SwiftUI
import os.log

/// Modern forum view with contemporary design aesthetics
struct ForumView: View {
    @State private var searchText = ""
    @State private var selectedTopic: ForumTopic? = nil
    @State private var animateCards = false
    @State private var searchFocused = false
    @State private var showCreatePost = false
    @State private var showCreateMenu = false
    @StateObject private var draftManager = DraftManager.shared
    @StateObject private var restrictionViewModel = AnonymousRestrictionViewModel()
    @EnvironmentObject private var appViewModel: AppViewModel
    
    // Forum data state
    @State private var topics: [ForumTopic] = []
    @State private var categories: [ForumCategory] = []
    @State private var selectedCategory: String? = nil
    @State private var sortOption: ForumSortOption = .newest
    @State private var currentPage = 1
    @State private var hasMorePages = true
    @State private var isLoading = false
    @State private var isRefreshing = false
    @State private var errorMessage: String? = nil
    @State private var isSearching = false
    @State private var searchResults: [ForumTopic] = []
    
    // Cache current user ID to avoid repeated Keychain access
    @State private var currentUserId: String? = nil
    
    // Services
    private let forumService = ForumService.shared
    @Environment(\.backgroundDataPreloader) private var backgroundDataPreloader
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "ForumView")
    
    var filteredTopics: [ForumTopic] {
        let baseTopics: [ForumTopic]
        
        if searchText.isEmpty {
            baseTopics = topics
        } else if isSearching {
            baseTopics = searchResults
        } else {
            // Local filtering as fallback
            baseTopics = topics.filter { 
                $0.title.lowercased().contains(searchText.lowercased()) || 
                $0.category.lowercased().contains(searchText.lowercased()) ||
                $0.content.lowercased().contains(searchText.lowercased())
            }
        }
        
        // Sort topics with under-review topics for current user at the top
        return baseTopics.sorted { topic1, topic2 in
            // Check if either topic is under review for the current user
            let topic1IsUserReview = topic1.isUnderReview && isCurrentUserTopic(topic1)
            let topic2IsUserReview = topic2.isUnderReview && isCurrentUserTopic(topic2)
            
            // Under-review topics for current user come first
            if topic1IsUserReview && !topic2IsUserReview {
                return true
            } else if !topic1IsUserReview && topic2IsUserReview {
                return false
            } else {
                // For topics with same review status, maintain original order
                return false
            }
        }
    }
    
    /// Checks if a topic belongs to the current user
    /// - Parameter topic: The topic to check
    /// - Returns: True if the topic belongs to the current user (only for authenticated users)
    private func isCurrentUserTopic(_ topic: ForumTopic) -> Bool {
        // Only check for authenticated users (not anonymous)
        guard !appViewModel.isAnonymousUser,
              let userId = currentUserId,
              let topicAuthorId = topic.author?.id else {
            return false
        }
        return String(topicAuthorId) == userId
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Standardized background
                StandardTabBackground(configuration: .forum)
                
                VStack(spacing: 0) {
                    // Enhanced header with contextual menu
                    enhancedHeader
                    
                    // Search bar
                    searchSection
                        .padding(.horizontal, DesignTokens.ResponsiveSpacing.lg)
                        .padding(.bottom, 16)
                    
                    // Topics list
                    topicsListSection
                }
            }
            .navigationBarHidden(true)
        }
        .dismissKeyboardOnSwipeDown()
        .onAppear {
            startAnimations()
            loadCurrentUserId()
            loadInitialData()
        }
        .refreshable {
            await refreshTopics()
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView(mode: .create) {
                Task {
                    await refreshTopics()
                }
            }
        }
        .confirmationDialog("Create Post", isPresented: $showCreateMenu, titleVisibility: .visible) {
            Button("New Topic") {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showCreatePost = true
                }
            }
            
            if draftManager.currentDraft != nil {
                Button("Continue Draft") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showCreatePost = true
                    }
                }
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            if let draft = draftManager.currentDraft {
                Text("You have an unfinished draft from \(formatDraftDate(draft.lastModified))")
            } else {
                Text("Choose how you'd like to contribute to the community")
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .overlay {
            if restrictionViewModel.showModal {
                CustomConfirmationModal(
                    isPresented: $restrictionViewModel.showModal,
                    config: ConfirmationConfig.primary(
                        title: restrictionViewModel.restrictedAction.title,
                        message: restrictionViewModel.restrictedAction.message,
                        icon: "person.badge.plus",
                        confirmText: restrictionViewModel.restrictedAction.primaryButtonText,
                        cancelText: restrictionViewModel.restrictedAction.secondaryButtonText,
                        onConfirm: {
                            restrictionViewModel.navigateToRegistration()
                        },
                        onCancel: {
                            restrictionViewModel.navigateToLogin()
                        }
                    )
                )
            }
        }
    }
    
    
    // MARK: - Enhanced Header
    
    /// Forum-specific header component with specialized business logic
    /// 
    /// ARCHITECTURE NOTE: This header is intentionally separate from StandardTabHeader
    /// due to Forum's complex requirements:
    /// - Anonymous user restriction handling (READ-ONLY indicators, restriction modals)
    /// - Draft management integration (DraftManager state, draft indicators, context menus)
    /// - Complex dependencies (DraftManager, AnonymousRestrictionViewModel, AppViewModel)
    /// - Domain-specific UI patterns (draft status badges, contextual action menus)
    /// - Heavy business logic that would bloat the generic StandardTabHeader component
    ///
    /// This specialized approach maintains clean separation of concerns while sharing
    /// responsive design patterns and DesignTokens with StandardTabHeader.
    private var enhancedHeader: some View {
        HStack(alignment: .center) {
            // Left section
            VStack(alignment: .leading, spacing: DesignTokens.ResponsiveSpacing.xs) {
                HStack(spacing: 8) {
                    Text("COMMUNITY")
                        .font(DesignTokens.ResponsiveTypography.caption)
                        .foregroundColor(DesignTokens.Colors.Forum.primary)
                        .tracking(1.5)
                    
                    // Read-only indicator for anonymous users
                    if appViewModel.isAnonymousUser {
                        Text("READ-ONLY")
                            .font(.system(size: DesignTokens.DeviceSize.current.fontSize(10, 11, 12), weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(DesignTokens.Colors.textSecondary.opacity(0.15))
                            )
                    }
                }
                
                Text("Forum")
                    .font(DesignTokens.ResponsiveTypography.headingLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            
            Spacer()
            
            // Right action button with contextual menu
            Button(action: {
                HapticManager.buttonTap()
                
                // Check if user is anonymous
                if appViewModel.isAnonymousUser {
                    restrictionViewModel.showRestrictionModal(for: .createTopic)
                    return
                }
                
                if draftManager.currentDraft != nil {
                    showCreateMenu = true
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showCreatePost = true
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(
                            width: DesignTokens.DeviceSize.current.spacing(44, 48, 52),
                            height: DesignTokens.DeviceSize.current.spacing(44, 48, 52)
                        )
                        .overlay(
                            Circle()
                                .stroke(DesignTokens.Colors.Forum.primary.opacity(0.3), lineWidth: 1)
                        )
                        .standardShadowLight()
                    
                    // Show draft indicator if available
                    if draftManager.currentDraft != nil {
                        VStack(spacing: 2) {
                            Image(systemName: "doc.text")
                                .font(.system(size: DesignTokens.DeviceSize.current.fontSize(12, 14, 16), weight: .semibold))
                                .foregroundColor(DesignTokens.Colors.Forum.primary)
                            
                            Circle()
                                .fill(DesignTokens.Colors.primaryAmber)
                                .frame(width: 6, height: 6)
                        }
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: DesignTokens.DeviceSize.current.fontSize(16, 18, 20), weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.Forum.primary)
                    }
                }
            }
            .scaleButtonStyle()
            .contextMenu {
                if !appViewModel.isAnonymousUser {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showCreatePost = true
                        }
                    } label: {
                        Label("New Topic", systemImage: "plus.bubble")
                    }
                    
                    if draftManager.currentDraft != nil {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showCreatePost = true
                            }
                        } label: {
                            Label("Continue Draft", systemImage: "doc.text")
                        }
                        
                        Button(role: .destructive) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                draftManager.clearDraft()
                            }
                            HapticManager.buttonTap()
                        } label: {
                            Label("Delete Draft", systemImage: "trash")
                        }
                    }
                } else {
                    Button {
                        restrictionViewModel.showRestrictionModal(for: .createTopic)
                    } label: {
                        Label("New Topic", systemImage: "plus.bubble")
                    }
                }
            }
        }
        .responsiveHorizontalPadding(20, 24, 28)
        .responsiveVerticalPadding(16, 20, 24)
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        HStack(spacing: 16) {
            // Search bar
            HStack(spacing: 12) {
                Group {
                    if isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                .foregroundColor(searchFocused ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textSecondary)
                
                TextField("Search topics, categories...", text: $searchText)
                    .font(.system(size: 16, weight: .medium))
                    .textFieldStyle(PlainTextFieldStyle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            searchFocused = true
                        }
                    }
                    .onChange(of: searchText) { newValue in
                        Task {
                            await performSearch(query: newValue)
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            searchText = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary.opacity(0.4))
                    }
                    .scaleButtonStyle()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(searchFocused ? DesignTokens.Colors.primaryCyan.opacity(0.5) : DesignTokens.Colors.borderPrimary, lineWidth: searchFocused ? 2 : 1)
                    )
                    .shadow(color: DesignTokens.Shadow.light.color, radius: DesignTokens.Shadow.light.radius, x: DesignTokens.Shadow.light.x, y: DesignTokens.Shadow.light.y)
            )
            .scaleEffect(searchFocused ? 1.02 : 1.0)
            
            // Filter button
            Button(action: {
                showFilterOptions()
            }) {
                VStack(spacing: 2) {
                    Image(systemName: selectedCategory != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(selectedCategory != nil ? DesignTokens.Colors.Forum.primary : DesignTokens.Colors.textSecondary)
                    
                    if let selectedCategory = selectedCategory {
                        Text(selectedCategory)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(DesignTokens.Colors.Forum.primary)
                            .lineLimit(1)
                    }
                }
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                    )
            }
            .scaleButtonStyle()
        }
    }
    
    // MARK: - Topics List Section
    
    private var topicsListSection: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(Array(filteredTopics.enumerated()), id: \.element.id) { index, topic in
                    topicCard(topic: topic, index: index)
                        .scaleEffect(animateCards ? 1.0 : 0.95)
                        .opacity(animateCards ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateCards)
                        .onAppear {
                            // Load more topics when approaching the end
                            if index == filteredTopics.count - 3 && hasMorePages && !isLoading {
                                Task {
                                    await loadMoreTopics()
                                }
                            }
                        }
                }
                
                // Loading indicator
                if isLoading && !isRefreshing {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                        
                        Text("Loading more...")
                            .font(DesignTokens.ResponsiveTypography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    .padding()
                }
                
                // Empty state
                if topics.isEmpty && !isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                        
                        Text("No topics yet")
                            .font(DesignTokens.ResponsiveTypography.headingMedium)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Text("Be the first to start a conversation!")
                            .font(DesignTokens.ResponsiveTypography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                            .multilineTextAlignment(.center)
                        
                        Button("Create Topic") {
                            showCreatePost = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()
                }
                
                // Bottom padding for tab bar
                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Topic Card
    
    @ViewBuilder
    private func topicCard(topic: ForumTopic, index: Int) -> some View {
        NavigationLink(destination: TopicDetailView(topicId: topic.id, onUpdate: { 
            Task {
                await refreshTopics()
            }
        })) {
            HStack(spacing: 16) {
                // Avatar with status indicator
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.Colors.primaryCyan.opacity(0.2), DesignTokens.Colors.primaryGreen.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.primaryCyan)
                        )
                    
                    if topic.isHot {
                        Circle()
                            .fill(DesignTokens.Colors.primaryAmber)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: DesignTokens.Colors.primaryAmber.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Category, review status, and time
                    HStack {
                        // Review status badge for user's under-review content
                        if topic.isUnderReview && isCurrentUserTopic(topic) {
                            ReviewStatusBadge(status: topic.status)
                        }
                        
                        Text(topic.category)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.primaryCyan)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(DesignTokens.Colors.primaryCyan.opacity(0.15))
                            )
                        
                        Spacer()
                        
                        Text(topic.timeAgo)
                            .font(DesignTokens.Typography.captionSmall)
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                    }
                    
                    // Title
                    Text(topic.title)
                        .font(DesignTokens.ResponsiveTypography.bodyLarge)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    // Stats
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary.opacity(0.6))
                            
                            Text("\(topic.replyCount)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.primaryAmber)
                            
                            Text("\(topic.likeCount)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary.opacity(0.4))
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(DesignTokens.Colors.borderPrimary, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Actions & Animations
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
            animateCards = true
        }
    }
    
    /// Loads and caches current user ID to avoid repeated Keychain access
    private func loadCurrentUserId() {
        // Only load for authenticated users (not anonymous)
        guard !appViewModel.isAnonymousUser else {
            currentUserId = nil
            return
        }
        
        // Only load if not already cached
        if currentUserId == nil {
            logger.info("🔑 FORUM: Loading user ID from Keychain (first time)")
            currentUserId = try? forumService.getCurrentUserId()
        } else {
            logger.info("🔑 FORUM: Using cached user ID: \(currentUserId ?? "nil")")
        }
    }
    
    /// Format draft date for display in confirmation dialog
    /// - Parameter date: Draft creation/modification date
    /// - Returns: Formatted relative date string
    private func formatDraftDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Data Loading
    
    /// Loads initial forum data (topics and categories)
    /// Uses preloaded data from splash screen and only loads fresh data if cache is invalid
    private func loadInitialData() {
        // Check cache first for instant display
        loadCachedDataIfAvailable()
        
        // Only load fresh data from API if cache is invalid or expired
        if !backgroundDataPreloader.hasValidCachedData() {
            Task {
                await loadTopics()
                await loadCategories()
            }
        } else {
            logger.info("Using valid cached data, skipping API calls")
        }
    }
    
    /// Loads cached data if available for instant display
    private func loadCachedDataIfAvailable() {
        let cachedTopics = backgroundDataPreloader.getCachedForumTopics()
        let cachedCategories = backgroundDataPreloader.getCachedCategories()
        
        if !cachedTopics.isEmpty {
            topics = cachedTopics
            logger.info("Loaded \(cachedTopics.count) topics from cache")
        }
        
        if !cachedCategories.isEmpty {
            categories = cachedCategories
            logger.info("Loaded \(cachedCategories.count) categories from cache")
        }
        
        // If we have cached data, don't show loading state
        if !cachedTopics.isEmpty || !cachedCategories.isEmpty {
            isLoading = false
        }
    }
    
    /// Loads topics from API
    /// - Parameter refresh: Whether this is a refresh operation
    @MainActor
    private func loadTopics(refresh: Bool = false) async {
        // Only show loading if we don't have cached data
        let hasCachedData = !topics.isEmpty
        
        if refresh {
            isRefreshing = true
            currentPage = 1
            hasMorePages = true
        } else if !hasCachedData {
            isLoading = true
        }
        
        do {
            let response = try await forumService.fetchTopics(
                page: currentPage,
                limit: 20,
                category: selectedCategory,
                sort: sortOption,
                search: searchText.isEmpty ? nil : searchText
            )
            
            if refresh {
                topics = response.data.topics
            } else if currentPage == 1 {
                // First page load - replace cached data with fresh data
                topics = response.data.topics
            } else {
                // Pagination - append to existing data
                topics.append(contentsOf: response.data.topics)
            }
            
            hasMorePages = response.data.pagination.hasNext
            logger.info("Loaded \(response.data.topics.count) topics from API")
            
            // Cache fresh data for future use (only for first page)
            if currentPage == 1 && selectedCategory == nil && searchText.isEmpty {
                // Cache the fresh data we just loaded
                let cacheManager = CacheManager.shared
                cacheManager.cacheForumTopics(response.data.topics)
            }
            
        } catch {
            logger.error("Failed to load topics: \(error.localizedDescription)")
            
            // Only show error if we don't have cached data to fall back on
            if !hasCachedData {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
        isRefreshing = false
    }
    
    /// Loads categories from API
    @MainActor
    private func loadCategories() async {
        do {
            let response = try await forumService.fetchCategories()
            categories = response.data.categories
            logger.info("Loaded \(categories.count) categories from API")
            
        } catch {
            logger.error("Failed to load categories: \(error.localizedDescription)")
            
            // Keep cached categories if API fails and we don't have current data
            if categories.isEmpty {
                let cachedCategories = backgroundDataPreloader.getCachedCategories()
                if !cachedCategories.isEmpty {
                    categories = cachedCategories
                    logger.info("Using cached categories as fallback")
                }
            }
        }
    }
    
    /// Refreshes topics list
    @MainActor
    private func refreshTopics() async {
        await loadTopics(refresh: true)
    }
    
    /// Loads more topics for pagination
    @MainActor
    private func loadMoreTopics() async {
        guard hasMorePages && !isLoading else { return }
        
        currentPage += 1
        await loadTopics()
    }
    
    /// Performs search with API
    @MainActor
    private func performSearch(query: String) async {
        // Cancel previous search if query is empty
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            isSearching = false
            searchResults.removeAll()
            return
        }
        
        // Only search if query is at least 2 characters
        guard query.count >= 2 else { return }
        
        isSearching = true
        
        do {
            let response = try await forumService.searchForum(
                query: query,
                type: .topics,
                category: selectedCategory,
                page: 1,
                limit: 20
            )
            
            // Convert search results to ForumTopic objects
            searchResults = response.data.results.compactMap { result in
                guard result.type == "topic" else { return nil }
                
                return ForumTopic(
                    id: result.id,
                    title: result.title ?? "Untitled",
                    content: result.content,
                    category: result.category,
                    author: result.author,
                    replyCount: result.replyCount ?? 0,
                    likeCount: result.likeCount,
                    isLiked: false, // Search results don't include like status
                    status: 0, // Assume published
                    images: [],
                    createdAt: result.createdAt,
                    updatedAt: result.updatedAt
                )
            }
            
            logger.info("Search returned \(searchResults.count) results for query: \(query)")
            
        } catch {
            logger.error("Search failed: \(error.localizedDescription)")
            isSearching = false
            searchResults.removeAll()
        }
    }
    
    /// Shows filter options (category and sort)
    private func showFilterOptions() {
        // For now, cycle through categories
        let allCategories = ["All"] + categories.map { $0.name }
        
        if let currentIndex = allCategories.firstIndex(of: selectedCategory ?? "All") {
            let nextIndex = (currentIndex + 1) % allCategories.count
            let newCategory = allCategories[nextIndex]
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = newCategory == "All" ? nil : newCategory
            }
            
            // Reload topics with new filter
            Task {
                await loadTopics(refresh: true)
            }
        }
    }
}

// Note: Topic model is now replaced by ForumTopic in ForumModels.swift


// MARK: - Preview

#Preview {
    ForumView()
        .environmentObject(AppViewModel())
        .environmentObject(TabBarVisibilityManager())
}

