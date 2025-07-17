//
//  TopicDetailView.swift
//  HomeAssistantPro
//
//  Purpose: Forum topic detail view with replies and interactions
//  Author: Michael
//  Created: 2025-07-10
//  Modified: 2025-07-10
//
//  Modification Log:
//  - 2025-07-10: Initial creation with topic detail and replies
//
//  Functions:
//  - Topic display with full content and metadata
//  - Paginated replies list with author information
//  - Like/unlike functionality for topics and replies
//  - Reply creation and editing
//  - Pull-to-refresh and infinite scroll
//

import SwiftUI
import os.log

/// Topic detail view with replies and interactions
struct TopicDetailView: View {
    let topicId: Int
    var onUpdate: (() -> Void)?
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.optionalTabBarVisibility) private var tabBarVisibility
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var restrictionViewModel = AnonymousRestrictionViewModel()
    @State private var topic: ForumTopic?
    @State private var replies: [ForumReply] = []
    @State private var currentPage = 1
    @State private var hasMorePages = true
    @State private var isLoading = false
    @State private var isRefreshing = false
    @State private var errorMessage: String? = nil
    
    // Reply form state
    @State private var showReplyForm = false
    @State private var replyContent = ""
    @State private var isSubmittingReply = false
    @State private var replyingToReply: ForumReply? = nil
    
    // UI state for Reddit-inspired features
    @State private var isTopicHeaderCollapsed = false
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedSortOption: ForumSortOption = .newest
    
    // Cache current user ID to avoid repeated Keychain access
    @State private var currentUserId: String? = nil
    @State private var showSortOptions = false
    
    // Image viewer state
    @State private var showImageViewer = false
    @State private var imageViewerData: ImageViewerData? = nil
    
    // Edit/Delete state
    @State private var showEditTopic = false
    @State private var showEditReply = false
    @State private var editingReply: ForumReply? = nil
    @State private var showDeleteTopicConfirmation = false
    @State private var showDeleteReplyConfirmation = false
    @State private var deletingReply: ForumReply? = nil
    
    struct ImageViewerData: Identifiable {
        let id = UUID()
        let images: [String]
        let selectedIndex: Int
    }
    
    // Services
    private let forumService = ForumService.shared
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "TopicDetailView")
    
    /// Computed property that preserves hierarchical order from API response
    /// The backend now returns replies in correct hierarchical order, so we just use them as-is
    private var sortedReplies: [ForumReply] {
        // Return replies in the exact order provided by the API to preserve hierarchical structure
        return replies
    }
    
    // Computed header height based on device size
    private var headerHeight: CGFloat {
        let baseHeight: CGFloat = 40 // Button height
        let verticalPadding = DesignTokens.DeviceSize.current.spacing(32, 40, 48) // Top + bottom padding
        return baseHeight + verticalPadding
    }
    
    // Back swipe gesture for navigation
    private var backSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onEnded { value in
                // Check if this is a left-to-right swipe from the left edge
                let horizontalDistance = value.translation.width
                let verticalDistance = abs(value.translation.height)
                let startLocation = value.startLocation.x
                
                // Must be:
                // 1. Swipe from left edge (within 50px from left)
                // 2. Horizontal movement of at least 100px
                // 3. Predominantly horizontal (not vertical scroll)
                // 4. Left to right direction
                if startLocation < 50 && 
                   horizontalDistance > 100 && 
                   horizontalDistance > verticalDistance * 2 {
                    // Navigate back to ForumView
                    presentationMode.wrappedValue.dismiss()
                }
            }
    }
    
    var body: some View {
        ZStack {
            // Standardized background
            StandardTabBackground(configuration: .forum)
            
            // Main content with top padding for header
            VStack(spacing: 0) {
                // Spacer for header height
                Spacer()
                    .frame(height: headerHeight)
                
                // Content
                if let topic = topic {
                    contentSection(topic: topic)
                } else {
                    loadingSection
                }
            }
            
            // Fixed header overlay
            VStack {
                headerSection
                    .background(.ultraThinMaterial)
                Spacer()
            }
            .zIndex(2)
        }
        .navigationBarHidden(true)
        .gesture(backSwipeGesture)
        .onAppear {
            tabBarVisibility?.hideTabBar()
            loadCurrentUserId()
            loadTopicDetail()
        }
        .onDisappear {
            tabBarVisibility?.showTabBar()
        }
        .refreshable {
            await refreshTopic()
        }
        .fullScreenCover(item: $imageViewerData) { data in
            ImageViewerModal(
                images: data.images,
                selectedIndex: data.selectedIndex,
                isPresented: .init(
                    get: { imageViewerData != nil },
                    set: { if !$0 { imageViewerData = nil } }
                )
            )
        }
        .sheet(isPresented: $showReplyForm) {
            ReplyFormView(
                topicId: topicId,
                parentReply: replyingToReply,
                onReplySubmitted: {
                    Task {
                        await refreshTopic()
                    }
                }
            )
        }
        .sheet(isPresented: $showEditTopic) {
            if let currentTopic = topic {
                CreatePostView(
                    mode: .edit(currentTopic),
                    onCompletion: {
                        Task {
                            await refreshTopic()
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showEditReply) {
            if let editingReply = editingReply {
                EditReplyView(
                    reply: editingReply,
                    topicId: topicId,
                    onReplyUpdated: {
                        Task {
                            await refreshTopic()
                        }
                    }
                )
            }
        }
        .overlay {
            // Delete Topic Confirmation Modal
            if showDeleteTopicConfirmation {
                CustomConfirmationModal(
                    isPresented: $showDeleteTopicConfirmation,
                    config: ConfirmationConfig.destructive(
                        title: "Delete Topic",
                        message: "Are you sure you want to delete this topic? This action cannot be undone.",
                        icon: "trash",
                        confirmText: "Delete",
                        cancelText: "Cancel",
                        onConfirm: {
                            Task {
                                await deleteTopic()
                            }
                        }
                    )
                )
            }
        }
        .overlay {
            // Delete Reply Confirmation Modal
            if showDeleteReplyConfirmation {
                CustomConfirmationModal(
                    isPresented: $showDeleteReplyConfirmation,
                    config: ConfirmationConfig.destructive(
                        title: "Delete Reply",
                        message: "Are you sure you want to delete this reply? This action cannot be undone.",
                        icon: "trash",
                        confirmText: "Delete",
                        cancelText: "Cancel",
                        onConfirm: {
                            if let deletingReply = deletingReply {
                                Task {
                                    await deleteReply(deletingReply.id)
                                }
                            }
                        }
                    )
                )
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
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            // Back button
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    )
                    .standardShadowLight()
            }
            .scaleButtonStyle()
            
            Spacer()
            
            Text("Topic")
                .font(DesignTokens.ResponsiveTypography.headingMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Spacer()
            
            // Reply button
            Button(action: {
                // Check if user is anonymous
                if appViewModel.isAnonymousUser {
                    restrictionViewModel.showRestrictionModal(for: .replyToTopic)
                    return
                }
                
                replyingToReply = nil // Reply to main topic
                showReplyForm = true
            }) {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "plus.bubble")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.Forum.primary)
                    )
                    .standardShadowLight()
            }
            .scaleButtonStyle()
        }
        .responsiveHorizontalPadding(20, 24, 28)
        .responsiveVerticalPadding(16, 20, 24)
    }
    
    // MARK: - Content Section
    
    @ViewBuilder
    private func contentSection(topic: ForumTopic) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: DesignTokens.ResponsiveSpacing.lg) {
                // Collapsible topic header - Reddit inspired
                if !isTopicHeaderCollapsed {
                    topicCard(topic: topic)
                        .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .top)))
                } else {
                    // Collapsed topic context bar
                    collapsedTopicHeader(topic: topic)
                        .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .top)))
                }
                
                // Replies header
                if !replies.isEmpty {
                    repliesHeader
                }
                
                // Replies list
                ForEach(sortedReplies) { reply in
                    replyCard(reply: reply)
                        .onAppear {
                            // Load more replies when approaching the end
                            if reply.id == replies.last?.id && hasMorePages && !isLoading {
                                Task {
                                    await loadMoreReplies()
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
                
                // Empty replies state
                if replies.isEmpty && !isLoading {
                    emptyRepliesState
                }
                
                // Bottom padding
                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal, DesignTokens.ResponsiveSpacing.lg)
            .padding(.top, DesignTokens.ResponsiveSpacing.sm)
        }
    }
    
    // MARK: - Topic Card
    
    @ViewBuilder
    private func topicCard(topic: ForumTopic) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.ResponsiveSpacing.md) {
            // Author and metadata
            HStack {
                // Author avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DesignTokens.Colors.primaryCyan.opacity(0.2), DesignTokens.Colors.primaryGreen.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(DesignTokens.Colors.primaryCyan)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack() {
                        if let author = topic.author {
                            Text(author.name)
                                .font(DesignTokens.ResponsiveTypography.bodyLarge)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                        }
                        
                        Spacer()
                        
                        Text(topic.timeAgo)
                            .font(DesignTokens.ResponsiveTypography.caption)
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                       
                    }
                    
                    HStack(spacing: 8) {
                        Text(topic.category)
                            .font(DesignTokens.ResponsiveTypography.caption)
                            .foregroundColor(DesignTokens.Colors.primaryCyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(DesignTokens.Colors.primaryCyan.opacity(0.15))
                            )
                        
                        Spacer()
                        
                        // Edit/Delete menu for current user's topic
                        if isCurrentUserTopic() {
                            Menu {
                                Button(action: {
                                    showEditTopic = true
                                }) {
                                    Label("Edit Topic", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive, action: {
                                    showDeleteTopicConfirmation = true
                                }) {
                                    Label("Delete Topic", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .frame(width: 24, height: 24)
                            }
                        }
                        
                    }
                }
                
                if topic.isHot {
                    Circle()
                        .fill(DesignTokens.Colors.primaryAmber)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: DesignTokens.Colors.primaryAmber.opacity(0.4), radius: 4, x: 0, y: 2)
                }
            }
            
            // Title
            Text(topic.title)
                .font(DesignTokens.ResponsiveTypography.headingMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .multilineTextAlignment(.leading)
            
            // Content
            Text(topic.content)
                .font(DesignTokens.ResponsiveTypography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .lineSpacing(4)
            
            // Images
            if !topic.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(0..<topic.images.count, id: \.self) { index in
                            let imageUrl = topic.images[index]
                            
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(DesignTokens.Colors.backgroundSecondary)
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                    )
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                logger.info("🎯 Topic image tapped: index \(index), URL: \(imageUrl), total images: \(topic.images.count)")
                                imageViewerData = ImageViewerData(
                                    images: topic.images,
                                    selectedIndex: index
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Actions
            HStack(spacing: DesignTokens.ResponsiveSpacing.lg) {
                // Like button
                Button(action: {
                    // Check if user is anonymous
                    if appViewModel.isAnonymousUser {
                        restrictionViewModel.showRestrictionModal(for: .likeTopic)
                        return
                    }
                    
                    Task {
                        await toggleTopicLike()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: topic.isLiked == true ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(topic.isLiked == true ? DesignTokens.Colors.primaryAmber : DesignTokens.Colors.textSecondary)
                        
                        Text("\(topic.likeCount)")
                            .font(DesignTokens.ResponsiveTypography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                .scaleButtonStyle()
                
                // Reply count
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Text("\(topic.replyCount)")
                        .font(DesignTokens.ResponsiveTypography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
                
                // Collapse button - Reddit inspired
                Button(action: {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isTopicHeaderCollapsed = true
                    }
                }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.Forum.primary)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(DesignTokens.Colors.Forum.primary.opacity(0.1))
                        )
                }
                .scaleButtonStyle()
            }
        }
        .padding(DesignTokens.ResponsiveSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(DesignTokens.Colors.borderPrimary, lineWidth: 1)
                )
                .standardShadowMedium()
        )
    }
    
    // MARK: - Replies Section
    
    private var repliesHeader: some View {
        HStack {
            Text("Replies")
                .font(DesignTokens.ResponsiveTypography.headingMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text("\(replies.count)")
                .font(DesignTokens.ResponsiveTypography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(DesignTokens.Colors.backgroundSecondary)
                )
            
            Spacer()
            
            // Sort options button - Reddit inspired
            Button(action: {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                showSortOptions = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.Forum.primary)
                    
                    Text(selectedSortOption.displayName)
                        .font(DesignTokens.ResponsiveTypography.caption)
                        .foregroundColor(DesignTokens.Colors.Forum.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DesignTokens.Colors.Forum.primary.opacity(0.1))
                )
            }
            .actionSheet(isPresented: $showSortOptions) {
                ActionSheet(
                    title: Text("Sort Comments"),
                    buttons: ForumSortOption.allCases.map { option in
                        .default(Text(option.displayName)) {
                            selectedSortOption = option
                            Task {
                                await refreshWithSort(option)
                            }
                        }
                    } + [.cancel()]
                )
            }
        }
        .padding(.horizontal, DesignTokens.ResponsiveSpacing.sm)
    }
    
    // MARK: - Collapsed Topic Header
    
    @ViewBuilder
    private func collapsedTopicHeader(topic: ForumTopic) -> some View {
        HStack(spacing: DesignTokens.ResponsiveSpacing.sm) {
            // Expand button
            Button(action: {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isTopicHeaderCollapsed = false
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.Forum.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(topic.title)
                    .font(DesignTokens.ResponsiveTypography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(topic.category)
                        .font(DesignTokens.ResponsiveTypography.caption)
                        .foregroundColor(DesignTokens.Colors.Forum.primary)
                    
                    Text("•")
                        .font(DesignTokens.ResponsiveTypography.caption)
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                    
                    Text("\(topic.replyCount) replies")
                        .font(DesignTokens.ResponsiveTypography.caption)
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, DesignTokens.ResponsiveSpacing.md)
        .padding(.vertical, DesignTokens.ResponsiveSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.Forum.primary.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DesignTokens.Colors.Forum.primary.opacity(0.2), lineWidth: 1)
                )
        )
        .contentMargins()
    }
    
    // MARK: - Reply Card
    
    @ViewBuilder
    private func replyCard(reply: ForumReply) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Nested reply indentation with connection lines
            if reply.isNestedReply {
                // Threading line with connection
                VStack(spacing: 0) {
                    // Connection line to parent
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(DesignTokens.Colors.Forum.primary.opacity(0.4))
                            .frame(width: 2)
                        
                        // Horizontal connector
                        Rectangle()
                            .fill(DesignTokens.Colors.Forum.primary.opacity(0.4))
                            .frame(height: 2)
                            .frame(width: DesignTokens.ResponsiveSpacing.sm)
                    }
                    .frame(height: DesignTokens.ResponsiveSpacing.md)
                    
                    // Vertical connection line
                    Rectangle()
                        .fill(DesignTokens.Colors.Forum.primary.opacity(0.2))
                        .frame(width: 2)
                    
                    Spacer()
                }
                .frame(width: DesignTokens.ResponsiveSpacing.xl)
            }
            
            // Reply content
            VStack(alignment: .leading, spacing: DesignTokens.ResponsiveSpacing.md) {
                // Parent reply context (for nested replies) - Enhanced
                if let parentReply = reply.parentReply {
                    VStack(alignment: .leading, spacing: 6) {
                        // Parent author info
                        HStack(spacing: 8) {
                            Image(systemName: "arrowshape.turn.up.left")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.Forum.primary)
                            
                            Text("Replying to \(parentReply.author.name)")
                                .font(DesignTokens.ResponsiveTypography.caption)
                                .foregroundColor(DesignTokens.Colors.Forum.primary)
                                .fontWeight(.medium)
                            
                            Spacer()
                        }
                        
                        // Parent reply preview
                        Text(parentReply.contentPreview)
                            .font(DesignTokens.ResponsiveTypography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .lineLimit(2)
                            .padding(.leading, 20) // Indent to align with arrow
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignTokens.Colors.Forum.primary.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(DesignTokens.Colors.Forum.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                // Author and metadata
                HStack {
                    // Author avatar
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.Colors.primaryPurple.opacity(0.2), DesignTokens.Colors.primaryCyan.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: reply.isNestedReply ? 28 : 32, height: reply.isNestedReply ? 28 : 32)
                        .overlay(
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: reply.isNestedReply ? 14 : 16, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.primaryPurple)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(reply.author.name)
                                .font(reply.isNestedReply ? DesignTokens.ResponsiveTypography.bodySmall : DesignTokens.ResponsiveTypography.bodyMedium)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            
                            // Review status badge for user's under-review replies
                            if reply.isUnderReview && isCurrentUserReply(reply) {
                                ReviewStatusBadge(status: reply.status)
                            }
                        }
                        
                        Text(reply.timeAgo)
                            .font(DesignTokens.ResponsiveTypography.caption)
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                    }
                    
                    Spacer()
                }
                
                // Content
                Text(reply.content)
                    .font(DesignTokens.ResponsiveTypography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineSpacing(4)
                
                // Images
                if !reply.images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.ResponsiveSpacing.sm) {
                            ForEach(0..<reply.images.count, id: \.self) { index in
                                let imageUrl = reply.images[index]
                                
                                Button(action: {
                                    logger.info("Reply image tapped: index \(index), URL: \(imageUrl), total images: \(reply.images.count)")
                                    logger.info("All reply images: \(reply.images)")
                                    imageViewerData = ImageViewerData(
                                        images: reply.images,
                                        selectedIndex: index
                                    )
                                }) {
                                    AsyncImage(url: URL(string: imageUrl)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(DesignTokens.Colors.backgroundSecondary)
                                            .overlay(
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle())
                                            )
                                    }
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                // Actions
                HStack {
                    // Like button with haptic feedback
                    Button(action: {
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        // Check if user is anonymous
                        if appViewModel.isAnonymousUser {
                            restrictionViewModel.showRestrictionModal(for: .likeReply)
                            return
                        }
                        
                        Task {
                            await toggleReplyLike(replyId: reply.id)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: reply.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(reply.isLiked ? DesignTokens.Colors.primaryAmber : DesignTokens.Colors.textSecondary)
                            
                            Text("\(reply.likeCount)")
                                .font(DesignTokens.ResponsiveTypography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                    }
                    .scaleButtonStyle()
                    
                    Spacer()
                    
                    // Edit/Delete menu for current user's reply
                    if isCurrentUserReply(reply) {
                        Menu {
                            Button(action: {
                                editingReply = reply
                                showEditReply = true
                            }) {
                                Label("Edit Reply", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive, action: {
                                deletingReply = reply
                                showDeleteReplyConfirmation = true
                            }) {
                                Label("Delete Reply", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                        }
                    } else {
                        // Reply to this reply button with haptic feedback
                        Button(action: {
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            // Check if user is anonymous
                            if appViewModel.isAnonymousUser {
                                restrictionViewModel.showRestrictionModal(for: .replyToReply)
                                return
                            }
                            
                            replyingToReply = reply
                            showReplyForm = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrowshape.turn.up.left")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(DesignTokens.Colors.Forum.primary)
                                
                                Text("Reply")
                                    .font(DesignTokens.ResponsiveTypography.caption)
                                    .foregroundColor(DesignTokens.Colors.Forum.primary)
                            }
                        }
                        .scaleButtonStyle()
                    }
                }
            }
            .padding(DesignTokens.ResponsiveSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: reply.isNestedReply ? 12 : 16)
                    .fill(DesignTokens.Colors.backgroundSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: reply.isNestedReply ? 12 : 16)
                            .stroke(reply.isNestedReply ? DesignTokens.Colors.Forum.primary.opacity(0.2) : DesignTokens.Colors.borderSecondary, lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Loading and Empty States
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            
            Text("Loading topic...")
                .font(DesignTokens.ResponsiveTypography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyRepliesState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(DesignTokens.Colors.textTertiary)
            
            Text("No replies yet")
                .font(DesignTokens.ResponsiveTypography.headingMedium)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Text("Be the first to reply to this topic!")
                .font(DesignTokens.ResponsiveTypography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textTertiary)
                .multilineTextAlignment(.center)
            
            Button("Add Reply") {
                // Check if user is anonymous
                if appViewModel.isAnonymousUser {
                    restrictionViewModel.showRestrictionModal(for: .replyToTopic)
                    return
                }
                
                replyingToReply = nil // Reply to main topic
                showReplyForm = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
    
    // MARK: - Data Loading
    
    /// Loads topic detail and initial replies
    @MainActor
    private func loadTopicDetail() {
        guard !isLoading else { return }
        
        isLoading = true
        
        Task {
            do {
                let response = try await forumService.fetchTopicDetail(
                    topicId: topicId,
                    replyPage: currentPage,
                    replyLimit: 20
                )
                
                topic = response.data.topic
                
                var fetchedReplies = response.data.replies
                let replyMap = Dictionary(uniqueKeysWithValues: fetchedReplies.map { ($0.id, $0) })
                for i in 0..<fetchedReplies.count {
                    if let parentId = fetchedReplies[i].parentReplyId, let parentReply = replyMap[parentId] {
                        fetchedReplies[i].parentReply = ParentReplyInfo(
                            id: parentReply.id,
                            content: parentReply.content,
                            author: parentReply.author
                        )
                    }
                }
                self.replies = fetchedReplies
                
                hasMorePages = self.replies.count < response.data.totalReplies
                
                logger.info("Loaded topic \(topicId) with \(replies.count) replies")
                
            } catch {
                logger.error("Failed to load topic detail: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
    
    /// Refreshes topic and replies
    @MainActor
    private func refreshTopic() async {
        isRefreshing = true
        currentPage = 1
        hasMorePages = true
        
        do {
            let response = try await forumService.fetchTopicDetail(
                topicId: topicId,
                replyPage: 1,
                replyLimit: 20
            )
            
            topic = response.data.topic
            
            var fetchedReplies = response.data.replies
            let replyMap = Dictionary(uniqueKeysWithValues: fetchedReplies.map { ($0.id, $0) })
            for i in 0..<fetchedReplies.count {
                if let parentId = fetchedReplies[i].parentReplyId, let parentReply = replyMap[parentId] {
                    fetchedReplies[i].parentReply = ParentReplyInfo(
                        id: parentReply.id,
                        content: parentReply.content,
                        author: parentReply.author
                    )
                }
            }
            self.replies = fetchedReplies
            
            hasMorePages = self.replies.count < response.data.totalReplies
            
            logger.info("Refreshed topic \(topicId)")
            
        } catch {
            logger.error("Failed to refresh topic: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isRefreshing = false
    }
    
    /// Refreshes replies with specific sort option
    @MainActor
    private func refreshWithSort(_ sortOption: ForumSortOption) async {
        isRefreshing = true
        currentPage = 1
        hasMorePages = true
        
        do {
            let response = try await forumService.fetchReplies(
                topicId: topicId,
                page: 1,
                limit: 20,
                sort: sortOption
            )
            
            var fetchedReplies = response.data.replies
            let replyMap = Dictionary(uniqueKeysWithValues: fetchedReplies.map { ($0.id, $0) })
            for i in 0..<fetchedReplies.count {
                if let parentId = fetchedReplies[i].parentReplyId, let parentReply = replyMap[parentId] {
                    fetchedReplies[i].parentReply = ParentReplyInfo(
                        id: parentReply.id,
                        content: parentReply.content,
                        author: parentReply.author
                    )
                }
            }
            self.replies = fetchedReplies
            
            hasMorePages = response.data.pagination.hasNext
            
            logger.info("Refreshed replies with sort: \(sortOption.rawValue)")
            
        } catch {
            logger.error("Failed to refresh replies with sort: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isRefreshing = false
    }
    
    /// Loads more replies for pagination
    @MainActor
    private func loadMoreReplies() async {
        guard hasMorePages && !isLoading else { return }
        
        isLoading = true
        currentPage += 1
        
        do {
            let response = try await forumService.fetchReplies(
                topicId: topicId,
                page: currentPage,
                limit: 20
            )
            
            var newReplies = response.data.replies
            let combinedReplies = self.replies + newReplies
            
            var processedReplies = combinedReplies
            let replyMap = Dictionary(uniqueKeysWithValues: processedReplies.map { ($0.id, $0) })
            for i in 0..<processedReplies.count {
                if let parentId = processedReplies[i].parentReplyId, let parentReply = replyMap[parentId] {
                    processedReplies[i].parentReply = ParentReplyInfo(
                        id: parentReply.id,
                        content: parentReply.content,
                        author: parentReply.author
                    )
                }
            }
            self.replies = processedReplies
            
            self.hasMorePages = response.data.pagination.hasNext
            
            logger.info("Loaded \(newReplies.count) more replies")
            
        } catch {
            logger.error("Failed to load more replies: \(error.localizedDescription)")
            currentPage -= 1 // Revert page increment on error
        }
        
        isLoading = false
    }
    
    /// Toggles like status for the topic
    @MainActor
    private func toggleTopicLike() async {
        guard var currentTopic = topic else { return }
        
        // Optimistic update
        let wasLiked = currentTopic.isLiked ?? false
        let newLikeCount = wasLiked ? currentTopic.likeCount - 1 : currentTopic.likeCount + 1
        
        // Update UI immediately
        topic = ForumTopic(
            id: currentTopic.id,
            title: currentTopic.title,
            content: currentTopic.content,
            category: currentTopic.category,
            author: currentTopic.author,
            replyCount: currentTopic.replyCount,
            likeCount: newLikeCount,
            isLiked: !wasLiked,
            status: currentTopic.status,
            images: currentTopic.images,
            createdAt: currentTopic.createdAt,
            updatedAt: currentTopic.updatedAt
        )
        
        do {
            let response = try await forumService.likeTopic(topicId: topicId)
            
            // Update with server response
            topic = ForumTopic(
                id: currentTopic.id,
                title: currentTopic.title,
                content: currentTopic.content,
                category: currentTopic.category,
                author: currentTopic.author,
                replyCount: currentTopic.replyCount,
                likeCount: response.data.likeCount,
                isLiked: response.data.isLiked,
                status: currentTopic.status,
                images: currentTopic.images,
                createdAt: currentTopic.createdAt,
                updatedAt: currentTopic.updatedAt
            )
            
            logger.info("Toggled topic like: \(response.data.isLiked)")
            
        } catch {
            // Revert optimistic update on error
            topic = currentTopic
            logger.error("Failed to toggle topic like: \(error.localizedDescription)")
        }
    }
    
    /// Toggles like status for a reply
    @MainActor
    private func toggleReplyLike(replyId: Int) async {
        guard let replyIndex = replies.firstIndex(where: { $0.id == replyId }) else { return }
        
        let reply = replies[replyIndex]
        let wasLiked = reply.isLiked
        let newLikeCount = wasLiked ? reply.likeCount - 1 : reply.likeCount + 1
        
        // Optimistic update
        replies[replyIndex] = ForumReply(
            id: reply.id,
            content: reply.content,
            author: reply.author,
            parentReplyId: reply.parentReplyId,
            parentReply: reply.parentReply,
            likeCount: newLikeCount,
            isLiked: !wasLiked,
            status: reply.status,
            images: reply.images,
            createdAt: reply.createdAt,
            updatedAt: reply.updatedAt
        )
        
        do {
            let response = try await forumService.likeReply(replyId: replyId)
            
            // Update with server response
            replies[replyIndex] = ForumReply(
                id: reply.id,
                content: reply.content,
                author: reply.author,
                parentReplyId: reply.parentReplyId,
                parentReply: reply.parentReply,
                likeCount: response.data.likeCount,
                isLiked: response.data.isLiked,
                status: reply.status,
                images: reply.images,
                createdAt: reply.createdAt,
                updatedAt: reply.updatedAt
            )
            
            logger.info("Toggled reply like: \(response.data.isLiked)")
            
        } catch {
            // Revert optimistic update on error
            replies[replyIndex] = reply
            logger.error("Failed to toggle reply like: \(error.localizedDescription)")
        }
    }
    
    /// Checks if a reply belongs to the current user
    /// - Parameter reply: The reply to check
    /// - Returns: True if the reply belongs to the current user (only for authenticated users)
    private func isCurrentUserReply(_ reply: ForumReply) -> Bool {
        // Only check for authenticated users (not anonymous)
        guard !appViewModel.isAnonymousUser,
              let userId = currentUserId else {
            return false
        }
        return String(reply.author.id) == userId
    }
    
    /// Checks if the current topic belongs to the current user
    /// - Returns: True if the topic belongs to the current user (only for authenticated users)
    private func isCurrentUserTopic() -> Bool {
        guard !appViewModel.isAnonymousUser,
              let currentTopic = topic,
              let author = currentTopic.author,
              let userId = currentUserId else {
            return false
        }
        return String(author.id) == userId
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
            logger.info("🔑 TOPIC_DETAIL: Loading user ID from Keychain (first time)")
            currentUserId = try? forumService.getCurrentUserId()
        } else {
            logger.info("🔑 TOPIC_DETAIL: Using cached user ID: \(currentUserId ?? "nil")")
        }
    }
    
    /// Deletes the current topic
    @MainActor
    private func deleteTopic() async {
        guard let currentTopic = topic else { return }
        
        do {
            let _ = try await forumService.deleteTopic(topicId: currentTopic.id)
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            logger.info("Topic \(currentTopic.id) deleted successfully")
            
            // Navigate back to forum view
            onUpdate?()
            presentationMode.wrappedValue.dismiss()
            
        } catch {
            logger.error("Failed to delete topic: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    /// Deletes a specific reply
    @MainActor
    private func deleteReply(_ replyId: Int) async {
        do {
            let _ = try await forumService.deleteReply(replyId: replyId)
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            logger.info("Reply \(replyId) deleted successfully")
            
            // Refresh the topic to show updated replies
            await refreshTopic()
            
            // Clear the deleting reply reference
            deletingReply = nil
            
        } catch {
            logger.error("Failed to delete reply: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            deletingReply = nil
        }
    }
}

// MARK: - Reply Form View

/// Reply form sheet view
struct ReplyFormView: View {
    let topicId: Int
    let parentReply: ForumReply?
    let onReplySubmitted: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var replyContent = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    
    private let forumService = ForumService.shared
    private let maxContentLength = 1000
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                    Spacer()
                    
                    Text(parentReply != nil ? "Reply to \(parentReply!.author.name)" : "Add Reply")
                        .font(DesignTokens.ResponsiveTypography.headingMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Spacer()
                    
                    Button("Post") {
                        Task {
                            await submitReply()
                        }
                    }
                    .disabled(isFormInvalid || isSubmitting)
                    .opacity(isFormInvalid ? 0.6 : 1.0)
                }
                .padding()
                
                Divider()
                
                // Content
                VStack(alignment: .leading, spacing: 16) {
                    // Parent reply context (if replying to a reply)
                    if let parentReply = parentReply {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Replying to:")
                                .font(DesignTokens.ResponsiveTypography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(DesignTokens.Colors.primaryPurple.opacity(0.2))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(DesignTokens.Colors.primaryPurple)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(parentReply.author.name)
                                        .font(DesignTokens.ResponsiveTypography.bodyMedium)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    
                                    Text(String(parentReply.content.prefix(100)) + (parentReply.content.count > 100 ? "..." : ""))
                                        .font(DesignTokens.ResponsiveTypography.caption)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(DesignTokens.Colors.primaryPurple.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(DesignTokens.Colors.primaryPurple.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    
                    HStack {
                        Text("Your Reply")
                            .font(DesignTokens.ResponsiveTypography.bodyLarge)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Spacer()
                        
                        Text("\(replyContent.count)/\(maxContentLength)")
                            .font(DesignTokens.ResponsiveTypography.caption)
                            .foregroundColor(contentLengthColor)
                    }
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $replyContent)
                            .font(DesignTokens.ResponsiveTypography.bodyMedium)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(DesignTokens.Colors.backgroundSurface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(DesignTokens.Colors.borderPrimary, lineWidth: 1)
                                    )
                            )
                            .onChange(of: replyContent) { newValue in
                                if newValue.count > maxContentLength {
                                    replyContent = String(newValue.prefix(maxContentLength))
                                }
                            }
                        
                        if replyContent.isEmpty {
                            Text("Write your reply...")
                                .font(DesignTokens.ResponsiveTypography.bodyMedium)
                                .foregroundColor(DesignTokens.Colors.textSecondary.opacity(0.6))
                                .padding(16)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationBarHidden(true)
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
    }
    
    private var isFormInvalid: Bool {
        let trimmedContent = replyContent.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedContent.isEmpty || trimmedContent.count < 1 || replyContent.count > maxContentLength
    }
    
    private var contentLengthColor: Color {
        if replyContent.count > maxContentLength * 9 / 10 {
            return DesignTokens.Colors.primaryRed
        } else if replyContent.count > maxContentLength * 7 / 10 {
            return DesignTokens.Colors.primaryAmber
        } else {
            return DesignTokens.Colors.textSecondary
        }
    }
    
    @MainActor
    private func submitReply() async {
        guard !isFormInvalid else { return }
        
        isSubmitting = true
        
        do {
            let _ = try await forumService.createReply(
                topicId: topicId,
                content: replyContent.trimmingCharacters(in: .whitespacesAndNewlines),
                parentReplyId: parentReply?.id
            )
            
            presentationMode.wrappedValue.dismiss()
            onReplySubmitted()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSubmitting = false
    }
}

// MARK: - Preview

#Preview {
    TopicDetailView(topicId: 1)
        .environmentObject(AppViewModel())
}
