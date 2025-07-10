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
    
    @Environment(\.presentationMode) var presentationMode
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
    
    // Services
    private let forumService = ForumService.shared
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "TopicDetailView")
    
    var body: some View {
        NavigationView {
            ZStack {
                // Standardized background
                StandardTabBackground(configuration: .forum)
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Content
                    if let topic = topic {
                        contentSection(topic: topic)
                    } else {
                        loadingSection
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadTopicDetail()
        }
        .refreshable {
            await refreshTopic()
        }
        .sheet(isPresented: $showReplyForm) {
            ReplyFormView(
                topicId: topicId,
                onReplySubmitted: {
                    Task {
                        await refreshTopic()
                    }
                }
            )
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
                // Topic content
                topicCard(topic: topic)
                
                // Replies header
                if !replies.isEmpty {
                    repliesHeader
                }
                
                // Replies list
                ForEach(replies) { reply in
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
                    if let author = topic.author {
                        Text(author.name)
                            .font(DesignTokens.ResponsiveTypography.bodyLarge)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
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
                        
                        Text(topic.timeAgo)
                            .font(DesignTokens.ResponsiveTypography.caption)
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                    }
                }
                
                Spacer()
                
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
                    HStack(spacing: DesignTokens.ResponsiveSpacing.sm) {
                        ForEach(topic.images, id: \.self) { imageUrl in
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
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Actions
            HStack(spacing: DesignTokens.ResponsiveSpacing.lg) {
                // Like button
                Button(action: {
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
        }
        .padding(.horizontal, DesignTokens.ResponsiveSpacing.sm)
    }
    
    // MARK: - Reply Card
    
    @ViewBuilder
    private func replyCard(reply: ForumReply) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.ResponsiveSpacing.md) {
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
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(DesignTokens.Colors.primaryPurple)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(reply.author.name)
                        .font(DesignTokens.ResponsiveTypography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
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
                        ForEach(reply.images, id: \.self) { imageUrl in
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
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Actions
            HStack {
                // Like button
                Button(action: {
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
            }
        }
        .padding(DesignTokens.ResponsiveSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignTokens.Colors.backgroundSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DesignTokens.Colors.borderSecondary, lineWidth: 1)
                )
        )
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
                replies = response.data.replies
                hasMorePages = response.data.replyPagination.hasNext
                
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
            replies = response.data.replies
            hasMorePages = response.data.replyPagination.hasNext
            
            logger.info("Refreshed topic \(topicId)")
            
        } catch {
            logger.error("Failed to refresh topic: \(error.localizedDescription)")
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
            
            replies.append(contentsOf: response.data.replies)
            hasMorePages = response.data.pagination.hasNext
            
            logger.info("Loaded \(response.data.replies.count) more replies")
            
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
            likeCount: newLikeCount,
            isLiked: !wasLiked,
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
                likeCount: response.data.likeCount,
                isLiked: response.data.isLiked,
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
}

// MARK: - Reply Form View

/// Reply form sheet view
struct ReplyFormView: View {
    let topicId: Int
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
                    
                    Text("Add Reply")
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
                content: replyContent.trimmingCharacters(in: .whitespacesAndNewlines)
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