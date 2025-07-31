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

/// Data structure for image viewer
struct ImageViewerData: Identifiable {
    let id = UUID()
    let images: [String]
    let selectedIndex: Int
}

/// Admin interface for reviewing pending forum posts and replies
struct AdminReviewQueueView: View {
    @StateObject private var moderationViewModel = AdminModerationViewModel()
    @EnvironmentObject private var appViewModel: AppViewModel
    
    @State private var selectedFilter: ReviewFilter = .all
    @State private var moderationItem: ReviewItem?
    @State private var moderationReason = ""
    @State private var imageViewerData: ImageViewerData?
    
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
        .onAppear {
            if moderationViewModel.canModerate(appViewModel: appViewModel) {
                Task {
                    await moderationViewModel.fetchReviewQueue()
                    await moderationViewModel.fetchForumStats()
                }
            }
        }
        .sheet(item: $moderationItem) { item in
            NavigationView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Moderate \(item.isReply ? "Reply" : "Topic")")
                            .font(.title2)
                            .foregroundColor(.primary)
                        
                        Text("by \(item.authorName)")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Content preview
                    VStack(alignment: .leading, spacing: 8) {
                        if let title = item.title {
                            Text(title)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        ScrollView {
                            Text(item.content)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Reason input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reason (Optional)")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        TextEditor(text: $moderationReason)
                            .frame(minHeight: 80, maxHeight: 120)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            Task {
                                await performModeration(item: item, action: .reject)
                            }
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Reject Post")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            moderationItem = nil
                            moderationReason = ""
                        }) {
                            Text("Cancel")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(24)
                .navigationTitle("Moderate Post")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            moderationItem = nil
                            moderationReason = ""
                        }
                        .foregroundColor(.secondary)
                    }
                }
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
    
    // MARK: - Filter Stats Section
    
    private var filterTabsSection: some View {
        VStack(spacing: 12) {
            // Interactive stats cards for filtering
            if let stats = moderationViewModel.forumStats {
                HStack(spacing: 12) {
                    // Total pending (All filter)
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = .all
                        }
                    }) {
                        InteractiveStatCard(
                            title: "Total Pending",
                            value: "\(stats.pendingReview.total)",
                            icon: "clock.fill",
                            color: DesignTokens.Colors.primaryAmber,
                            isSelected: selectedFilter == .all
                        )
                    }
                    .scaleButtonStyle()
                    
                    // Topics pending
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = .topics
                        }
                    }) {
                        InteractiveStatCard(
                            title: "Topics",
                            value: "\(stats.pendingReview.topics)",
                            icon: "bubble.left.and.bubble.right.fill",
                            color: DesignTokens.Colors.primaryCyan,
                            isSelected: selectedFilter == .topics
                        )
                    }
                    .scaleButtonStyle()
                    
                    // Replies pending
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = .replies
                        }
                    }) {
                        InteractiveStatCard(
                            title: "Replies",
                            value: "\(stats.pendingReview.replies)",
                            icon: "arrowshape.turn.up.left.fill",
                            color: DesignTokens.Colors.primaryGreen,
                            isSelected: selectedFilter == .replies
                        )
                    }
                    .scaleButtonStyle()
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
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                // Pending items
                let filteredItems = getFilteredItems()
                
                if filteredItems.isEmpty && !moderationViewModel.isLoading {
                    emptyStateView
                } else {
                    ForEach(filteredItems, id: \.id) { item in
                        PendingItemCard(
                            item: item,
                            onModerate: { action in
                                if action == .approve {
                                    // Auto-approve without reason
                                    Task {
                                        await performModeration(item: item, action: action)
                                    }
                                } else {
                                    // Show sheet for reject/delete actions
                                    logger.info("🔍 Setting moderationItem: \(item.id), showing sheet")
                                    moderationItem = item
                                    moderationReason = ""
                                }
                            },
                            onImageTap: { images, selectedIndex in
                                imageViewerData = ImageViewerData(
                                    images: images,
                                    selectedIndex: selectedIndex
                                )
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
    
    // MARK: - Interactive Stat Card Component
    
    private struct InteractiveStatCard: View {
        let title: String
        let value: String
        let icon: String
        let color: Color
        let isSelected: Bool
        
        var body: some View {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : color)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : DesignTokens.Colors.textPrimary)
                    
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : DesignTokens.Colors.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : DesignTokens.Colors.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? color.opacity(0.5) : DesignTokens.Colors.borderPrimary, lineWidth: isSelected ? 2 : 1)
                    )
                    .shadow(
                        color: isSelected ? color.opacity(0.3) : .clear,
                        radius: isSelected ? 8 : 0,
                        x: 0,
                        y: isSelected ? 4 : 0
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
        
        return items
        
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
        moderationItem = nil
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
    let onImageTap: ([String], Int) -> Void
    
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
                
                // Images
                if !item.images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(0..<item.images.count, id: \.self) { index in
                                let imageUrl = item.images[index]
                                
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(DesignTokens.Colors.backgroundSecondary)
                                        .overlay(
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.textSecondary))
                                        )
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onImageTap(item.images, index)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .frame(height: 80)
                }
                
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
    @State private var imageViewerData: ImageViewerData?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("Moderate \(item.isReply ? "Reply" : "Topic")")
                        .font(.title2)
                        .foregroundColor(.primary)
                    
                    Text("by \(item.authorName)")
                        .font(.body)
                        .foregroundColor(.secondary)
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
                
                // Images
                if !item.images.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Images (\(item.images.count))")
                            .font(DesignTokens.ResponsiveTypography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(0..<item.images.count, id: \.self) { index in
                                    let imageUrl = item.images[index]
                                    
                                    AsyncImage(url: URL(string: imageUrl)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(DesignTokens.Colors.backgroundSecondary)
                                            .overlay(
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.textSecondary))
                                            )
                                    }
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        imageViewerData = ImageViewerData(
                                            images: item.images,
                                            selectedIndex: index
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .frame(height: 100)
                    }
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
            .navigationTitle("Moderate Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
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
enum ReviewItem: Identifiable {
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
    
    var images: [String] {
        switch self {
        case .topic(let topic): return topic.images
        case .reply(let reply): return reply.images
        }
    }
}

// MARK: - Preview

#Preview {
    AdminReviewQueueView()
        .environmentObject(AppViewModel())
}
