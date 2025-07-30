//
//  AdminReviewQueueView.swift
//  HomeAssistantPro
//
//  Purpose: Admin interface for reviewing and moderating pending forum posts
//  Author: Michael
//  Created: 2025-07-25
//  Modified: 2025-07-25
//
//  Modification Log:
//  - 2025-07-25: Initial creation with review queue interface
//
//  Functions:
//  - AdminReviewQueueView: Main review queue interface
//  - PendingItemCard: Card component for pending items
//  - ModerationActionSheet: Action sheet for moderation decisions
//

import SwiftUI
import os.log

/// Admin interface for reviewing pending forum posts and replies
struct AdminReviewQueueView: View {
    @StateObject private var moderationViewModel = AdminModerationViewModel()
    @EnvironmentObject private var appViewModel: AppViewModel
    
    @State private var selectedFilter: ReviewFilter = .all
    @State private var showingModerationSheet = false
    @State private var selectedItem: ReviewItem?
    @State private var moderationReason = ""
    
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "AdminReviewQueueView")
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                StandardTabBackground(configuration: .forum)
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Filter tabs
                    filterTabsSection
                    
                    // Content
                    contentSection
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            if moderationViewModel.canModerate(appViewModel: appViewModel) {
                Task {
                    await moderationViewModel.fetchReviewQueue()
                    await moderationViewModel.fetchForumStats()
                }
            }
        }
        .sheet(isPresented: $showingModerationSheet) {
            if let item = selectedItem {
                ModerationActionSheet(
                    item: item,
                    reason: $moderationReason,
                    onModerate: { action in
                        Task {
                            await performModeration(item: item, action: action)
                        }
                    }
                )
            }
        }
        .alert("Moderation Success", isPresented: .constant(moderationViewModel.successMessage != nil)) {
            Button("OK") {
                moderationViewModel.clearMessages()
            }
        } message: {
            if let successMessage = moderationViewModel.successMessage {
                Text(successMessage)
            }
        }
        .alert("Moderation Error", isPresented: .constant(moderationViewModel.errorMessage != nil)) {
            Button("OK") {
                moderationViewModel.clearMessages()
            }
        } message: {
            if let errorMessage = moderationViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: DesignTokens.ResponsiveSpacing.xs) {
                HStack(spacing: 8) {
                    Text("ADMIN")
                        .font(DesignTokens.ResponsiveTypography.caption)
                        .foregroundColor(DesignTokens.Colors.primaryPurple)
                        .tracking(1.5)
                    
                    AdminBadge(style: .compact, showText: false)
                }
                
                Text("Review Queue")
                    .font(DesignTokens.ResponsiveTypography.headingLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            
            Spacer()
            
            // Refresh button
            Button(action: {
                Task {
                    await moderationViewModel.fetchReviewQueue()
                    await moderationViewModel.fetchForumStats()
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
                                .stroke(DesignTokens.Colors.primaryPurple.opacity(0.3), lineWidth: 1)
                        )
                        .standardShadowLight()
                    
                    if moderationViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: DesignTokens.DeviceSize.current.fontSize(16, 18, 20), weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.primaryPurple)
                    }
                }
            }
            .scaleButtonStyle()
            .disabled(moderationViewModel.isLoading)
        }
        .responsiveHorizontalPadding(20, 24, 28)
        .responsiveVerticalPadding(16, 20, 24)
    }
    
    // MARK: - Filter Tabs Section
    
    private var filterTabsSection: some View {
        HStack(spacing: 12) {
            ForEach(ReviewFilter.allCases, id: \.self) { filter in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFilter = filter
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: filter.iconName)
                            .font(.system(size: 14, weight: .medium))
                        
                        Text(filter.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .fixedSize()
                        
                        // Count badge
                        let count = getFilterCount(for: filter)
                        if count > 0 {
                            Text("\(count)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(DesignTokens.Colors.primaryRed)
                                )
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundColor(selectedFilter == filter ? .white : DesignTokens.Colors.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(selectedFilter == filter ? DesignTokens.Colors.primaryPurple : .clear)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedFilter)
                    )
                }
                .scaleButtonStyle()
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                // Statistics cards
                if let stats = moderationViewModel.forumStats {
                    statsSection(stats: stats)
                }
                
                // Pending items
                let filteredItems = getFilteredItems()
                
                if filteredItems.isEmpty && !moderationViewModel.isLoading {
                    emptyStateView
                } else {
                    ForEach(filteredItems, id: \.id) { item in
                        PendingItemCard(
                            item: item,
                            onModerate: { action in
                                selectedItem = item
                                moderationReason = ""
                                if action == .approve {
                                    // Auto-approve without reason
                                    Task {
                                        await performModeration(item: item, action: action)
                                    }
                                } else {
                                    // Show sheet for reject/delete actions
                                    showingModerationSheet = true
                                }
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                    }
                }
                
                // Bottom padding
                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Statistics Section
    
    private func statsSection(stats: ForumStats) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Total pending
                StatCard(
                    title: "Total Pending",
                    value: "\(stats.pendingReview.total)",
                    icon: "clock.fill",
                    color: DesignTokens.Colors.primaryAmber
                )
                
                // Topics pending
                StatCard(
                    title: "Topics",
                    value: "\(stats.pendingReview.topics)",
                    icon: "bubble.left.and.bubble.right.fill",
                    color: DesignTokens.Colors.primaryCyan
                )
                
                // Replies pending
                StatCard(
                    title: "Replies",
                    value: "\(stats.pendingReview.replies)",
                    icon: "arrowshape.turn.up.left.fill",
                    color: DesignTokens.Colors.primaryGreen
                )
            }
            
            // Queue health indicator
            HStack {
                Image(systemName: stats.queueHealth.status == "healthy" ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(stats.queueHealth.status == "healthy" ? DesignTokens.Colors.primaryGreen : DesignTokens.Colors.primaryAmber)
                
                Text("Queue Health: \(stats.queueHealth.status.capitalized)")
                    .font(DesignTokens.ResponsiveTypography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                Spacer()
                
                Text("Avg Wait: \(String(format: "%.1f", stats.queueHealth.averageWaitTimeHours))h")
                    .font(DesignTokens.ResponsiveTypography.bodySmall)
                    .foregroundColor(DesignTokens.Colors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(DesignTokens.Colors.borderPrimary, lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(DesignTokens.Colors.primaryGreen)
            
            VStack(spacing: 12) {
                Text("All Clear!")
                    .font(DesignTokens.ResponsiveTypography.headingMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text("No posts awaiting moderation. Great job keeping the community safe!")
                    .font(DesignTokens.ResponsiveTypography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.top, 60)
    }
    
    // MARK: - Helper Methods
    
    private func getFilterCount(for filter: ReviewFilter) -> Int {
        switch filter {
        case .all:
            return moderationViewModel.reviewQueue.count + moderationViewModel.pendingReplies.count
        case .topics:
            return moderationViewModel.reviewQueue.count
        case .replies:
            return moderationViewModel.pendingReplies.count
        }
    }
    
    private func getFilteredItems() -> [ReviewItem] {
        var items: [ReviewItem] = []
        
        switch selectedFilter {
        case .all:
            items.append(contentsOf: moderationViewModel.reviewQueue.map { ReviewItem.topic($0) })
            items.append(contentsOf: moderationViewModel.pendingReplies.map { ReviewItem.reply($0) })
        case .topics:
            items.append(contentsOf: moderationViewModel.reviewQueue.map { ReviewItem.topic($0) })
        case .replies:
            items.append(contentsOf: moderationViewModel.pendingReplies.map { ReviewItem.reply($0) })
        }
        
        return items.sorted { item1, item2 in
            // Sort by creation date, newest first
            let date1 = DateUtils.parseTimestamp(item1.createdAt) ?? Date.distantPast
            let date2 = DateUtils.parseTimestamp(item2.createdAt) ?? Date.distantPast
            return date1 > date2
        }
    }
    
    private func performModeration(item: ReviewItem, action: AdminModerationViewModel.ModerationAction) async {
        let reason = moderationReason.isEmpty ? nil : moderationReason
        
        switch item {
        case .topic(let topic):
            await moderationViewModel.moderatePost(topic, action: action, reason: reason)
        case .reply(let reply):
            await moderationViewModel.moderateReply(reply, action: action, reason: reason)
        }
        
        // Refresh stats after successful moderation
        await moderationViewModel.fetchForumStats()
        
        // Close sheet and clear state
        showingModerationSheet = false
        selectedItem = nil
        moderationReason = ""
    }
}

// MARK: - Supporting Views

/// Statistics card component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DesignTokens.Colors.borderPrimary, lineWidth: 1)
                )
                .standardShadowLight()
        )
    }
}

/// Card component for pending items
struct PendingItemCard: View {
    let item: ReviewItem
    let onModerate: (AdminModerationViewModel.ModerationAction) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Item type indicator
            VStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: item.isReply ? 
                                [DesignTokens.Colors.primaryGreen.opacity(0.2), DesignTokens.Colors.primaryGreen.opacity(0.1)] :
                                [DesignTokens.Colors.primaryCyan.opacity(0.2), DesignTokens.Colors.primaryCyan.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: item.isReply ? "arrowshape.turn.up.left.fill" : "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(item.isReply ? DesignTokens.Colors.primaryGreen : DesignTokens.Colors.primaryCyan)
                    )
                
                Spacer()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Type and author
                HStack {
                    Text(item.isReply ? "REPLY" : "TOPIC")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(item.isReply ? DesignTokens.Colors.primaryGreen : DesignTokens.Colors.primaryCyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill((item.isReply ? DesignTokens.Colors.primaryGreen : DesignTokens.Colors.primaryCyan).opacity(0.15))
                        )
                    
                    Text("by \(item.authorName)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text(item.timeAgo)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                }
                
                // Title (for topics) or parent info (for replies)
                if let title = item.title {
                    Text(title)
                        .font(DesignTokens.ResponsiveTypography.bodyLarge)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .lineLimit(2)
                }
                
                // Content preview
                Text(item.content)
                    .font(DesignTokens.ResponsiveTypography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(3)
                
                // Action buttons
                HStack(spacing: 12) {
                    // Approve button
                    Button(action: {
                        HapticManager.buttonTap()
                        onModerate(.approve)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Approve")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(DesignTokens.Colors.primaryGreen)
                        )
                    }
                    .scaleButtonStyle()
                    
                    // Reject button
                    Button(action: {
                        HapticManager.buttonTap()
                        onModerate(.reject)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Reject")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(DesignTokens.Colors.primaryRed)
                        )
                    }
                    .scaleButtonStyle()
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
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
}

/// Action sheet for moderation decisions
struct ModerationActionSheet: View {
    let item: ReviewItem
    @Binding var reason: String
    let onModerate: (AdminModerationViewModel.ModerationAction) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("Moderate \(item.isReply ? "Reply" : "Topic")")
                        .font(DesignTokens.ResponsiveTypography.headingLarge)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("by \(item.authorName)")
                        .font(DesignTokens.ResponsiveTypography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                // Content preview
                VStack(alignment: .leading, spacing: 8) {
                    if let title = item.title {
                        Text(title)
                            .font(DesignTokens.ResponsiveTypography.bodyLarge)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    
                    ScrollView {
                        Text(item.content)
                            .font(DesignTokens.ResponsiveTypography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 200)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(DesignTokens.Colors.borderPrimary, lineWidth: 1)
                            )
                    )
                }
                
                // Reason input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reason (Optional)")
                        .font(DesignTokens.ResponsiveTypography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    TextEditor(text: $reason)
                        .frame(minHeight: 80, maxHeight: 120)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        )
                        .overlay(
                            // Placeholder text
                            Group {
                                if reason.isEmpty {
                                    HStack {
                                        VStack {
                                            HStack {
                                                Text("Enter moderation reason...")
                                                    .foregroundColor(.secondary)
                                                    .padding(.leading, 12)
                                                    .padding(.top, 16)
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        )
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onModerate(.reject)
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Reject Post")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.Colors.primaryRed)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        onModerate(.delete)
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Post")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.Colors.primaryRed.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Done") {
//                        dismiss()
//                    }
//                }
//            }
        }
    }
}

// MARK: - Supporting Types

/// Filter options for review queue
enum ReviewFilter: String, CaseIterable {
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
    
    var iconName: String {
        switch self {
        case .all: return "list.bullet"
        case .topics: return "bubble.left.and.bubble.right"
        case .replies: return "arrowshape.turn.up.left"
        }
    }
}

/// Unified review item type
enum ReviewItem {
    case topic(ForumTopic)
    case reply(ForumReply)
    
    var id: Int {
        switch self {
        case .topic(let topic): return topic.id
        case .reply(let reply): return reply.id
        }
    }
    
    var title: String? {
        switch self {
        case .topic(let topic): return topic.title
        case .reply: return nil
        }
    }
    
    var content: String {
        switch self {
        case .topic(let topic): return topic.content
        case .reply(let reply): return reply.content
        }
    }
    
    var authorName: String {
        switch self {
        case .topic(let topic): return topic.authorDisplayName
        case .reply(let reply): return reply.author.name
        }
    }
    
    var createdAt: String {
        switch self {
        case .topic(let topic): return topic.createdAt
        case .reply(let reply): return reply.createdAt
        }
    }
    
    var timeAgo: String {
        switch self {
        case .topic(let topic): return topic.timeAgo
        case .reply(let reply): return reply.timeAgo
        }
    }
    
    var isReply: Bool {
        switch self {
        case .topic: return false
        case .reply: return true
        }
    }
}

// MARK: - Preview

#Preview {
    AdminReviewQueueView()
        .environmentObject(AppViewModel())
}
