//
//  AdminChatConversationListView.swift
//  HomeAssistantPro
//
//  Purpose: Admin chat conversation list interface for managing user conversations
//  Author: Assistant  
//  Create date: 2025-08-07
//  Latest modify date: 2025-08-07
//
//  Modification log:
//  - 2025-08-07: Initial creation with conversation list, filters, search, and assignment features
//
//  Functions:
//  - conversationListView: Main conversation list with cards
//  - filterHeaderView: Filter chips for status and assignment
//  - searchBarView: Search functionality for conversations
//  - loadConversations(): Load conversations from API with filters
//  - assignConversation(_:to:): Assign conversation to admin
//  - updateConversationStatus(_:status:): Update conversation status
//

import SwiftUI

/// Admin conversation list view with filtering, search, and management capabilities
struct AdminChatConversationListView: View {
    @State private var conversations: [AdminConversation] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var selectedStatusFilter = "all"
    @State private var selectedAssignmentFilter = "all"
    @State private var showingAssignmentSheet = false
    @State private var selectedConversation: AdminConversation?
    @State private var errorMessage: String?
    
    // Environment
    @EnvironmentObject private var settingsStore: SettingsStore
    
    // Filter options
    private let statusFilters = [
        ("all", "All"),
        ("active", "Active"), 
        ("closed", "Closed"),
        ("archived", "Archived")
    ]
    
    private let assignmentFilters = [
        ("all", "All"),
        ("assigned_to_me", "Mine"),
        ("unassigned", "Unassigned")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and stats
            headerView
            
            // Search bar
            searchBarView
                .padding(.horizontal, DesignTokens.ResponsiveSpacing.md)
            
            // Filter chips
            filterHeaderView
                .padding(.horizontal, DesignTokens.ResponsiveSpacing.md)
            
            // Conversation list
            conversationListView
        }
        .background(DesignTokens.Colors.backgroundPrimary)
        .onAppear {
            loadConversations()
        }
        .refreshable {
            await refreshConversations()
        }
        .sheet(item: $selectedConversation) { conversation in
            AdminChatDetailView(conversation: conversation)
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: DesignTokens.ResponsiveSpacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chat Management")
                        .font(DesignTokens.ResponsiveTypography.headingLarge)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("\(conversations.count) conversations")
                        .font(DesignTokens.ResponsiveTypography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
                
                // Stats badges
                HStack(spacing: DesignTokens.ResponsiveSpacing.xs) {
                    StatsBadge(
                        title: "Unread", 
                        count: conversations.filter { $0.unreadCount > 0 }.count,
                        color: DesignTokens.Colors.primaryAmber
                    )
                    
                    StatsBadge(
                        title: "Unassigned",
                        count: conversations.filter { $0.adminId == nil }.count,
                        color: DesignTokens.Colors.primaryPurple
                    )
                }
            }
            .padding(.horizontal, DesignTokens.ResponsiveSpacing.md)
            .padding(.top, DesignTokens.ResponsiveSpacing.sm)
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBarView: some View {
        HStack(spacing: DesignTokens.ResponsiveSpacing.xs) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                TextField("Search conversations...", text: $searchText)
                    .font(DesignTokens.ResponsiveTypography.bodyMedium)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.ResponsiveSpacing.sm)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(DesignTokens.Colors.borderPrimary, lineWidth: 1)
                    )
            )
        }
        .padding(.vertical, DesignTokens.ResponsiveSpacing.xs)
    }
    
    // MARK: - Filter Header
    
    private var filterHeaderView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.ResponsiveSpacing.xs) {
                // Status filters
                ForEach(statusFilters, id: \.0) { filter in
                    FilterChip(
                        title: filter.1,
                        isSelected: selectedStatusFilter == filter.0,
                        action: { selectedStatusFilter = filter.0 }
                    )
                }
                
                Divider()
                    .frame(height: 24)
                
                // Assignment filters
                ForEach(assignmentFilters, id: \.0) { filter in
                    FilterChip(
                        title: filter.1,
                        isSelected: selectedAssignmentFilter == filter.0,
                        action: { selectedAssignmentFilter = filter.0 }
                    )
                }
            }
            .padding(.horizontal, DesignTokens.ResponsiveSpacing.md)
        }
        .padding(.vertical, DesignTokens.ResponsiveSpacing.xs)
    }
    
    // MARK: - Conversation List
    
    private var conversationListView: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.ResponsiveSpacing.sm) {
                if isLoading && conversations.isEmpty {
                    ProgressView("Loading conversations...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                } else if filteredConversations.isEmpty {
                    emptyStateView
                        .padding(.top, 100)
                } else {
                    ForEach(filteredConversations) { conversation in
                        ConversationCard(
                            conversation: conversation,
                            onTap: { selectedConversation = conversation },
                            onAssign: { assignConversation(conversation, to: nil) }
                        )
                        .contentMargins()
                    }
                }
            }
            .padding(.horizontal, DesignTokens.ResponsiveSpacing.md)
            .padding(.vertical, DesignTokens.ResponsiveSpacing.sm)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignTokens.ResponsiveSpacing.lg) {
            Image(systemName: "message.badge")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(DesignTokens.Colors.primaryPurple.opacity(0.6))
            
            VStack(spacing: DesignTokens.ResponsiveSpacing.xs) {
                Text("No Conversations")
                    .font(DesignTokens.ResponsiveTypography.headingMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text("No conversations match your current filters")
                    .font(DesignTokens.ResponsiveTypography.bodyLarge)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredConversations: [AdminConversation] {
        var filtered = conversations
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { conversation in
                conversation.userInfo.accountName?.lowercased().contains(searchText.lowercased()) == true ||
                conversation.lastMessage?.content.lowercased().contains(searchText.lowercased()) == true
            }
        }
        
        // Filter by status
        if selectedStatusFilter != "all" {
            filtered = filtered.filter { $0.status == selectedStatusFilter }
        }
        
        // Filter by assignment
        if selectedAssignmentFilter != "all" {
            switch selectedAssignmentFilter {
            case "assigned_to_me":
                // TODO: Get current admin ID and filter
                break
            case "unassigned":
                filtered = filtered.filter { $0.adminId == nil }
            default:
                break
            }
        }
        
        return filtered.sorted { $0.lastMessageAt > $1.lastMessageAt }
    }
    
    // MARK: - Actions
    
    private func loadConversations() {
        isLoading = true
        
        // Mock data for now - replace with AdminChatAPIService
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            conversations = mockConversations
            isLoading = false
        }
    }
    
    private func refreshConversations() async {
        await loadConversations()
    }
    
    private func assignConversation(_ conversation: AdminConversation, to adminId: Int?) {
        // TODO: Implement assignment via AdminChatAPIService
        showingAssignmentSheet = true
    }
    
    private func updateConversationStatus(_ conversation: AdminConversation, status: String) {
        // TODO: Implement status update via AdminChatAPIService
    }
}

// MARK: - Supporting Views

private struct StatsBadge: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : DesignTokens.Colors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? DesignTokens.Colors.primaryPurple : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(DesignTokens.Colors.borderSecondary, lineWidth: 1)
                        .opacity(isSelected ? 0 : 1)
                )
        )
        .scaleButtonStyle()
    }
}

private struct ConversationCard: View {
    let conversation: AdminConversation
    let onTap: () -> Void
    let onAssign: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DesignTokens.ResponsiveSpacing.sm) {
                // User info and status
                HStack {
                    // User avatar
                    Circle()
                        .fill(DesignTokens.Colors.primaryCyan.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(conversation.userInfo.accountName?.prefix(1) ?? "U")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.primaryCyan)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(conversation.userInfo.accountName ?? "Unknown User")
                                .font(DesignTokens.ResponsiveTypography.bodyLarge)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            // Status badge
                            StatusBadge(status: conversation.status)
                        }
                        
                        HStack {
                            // Priority indicator
                            if conversation.priority == "high" || conversation.priority == "urgent" {
                                Circle()
                                    .fill(conversation.priority == "urgent" ? DesignTokens.Colors.primaryCyan : DesignTokens.Colors.primaryAmber)
                                    .frame(width: 6, height: 6)
                            }
                            
                            Text("ID: \(conversation.id)")
                                .font(.system(size: 12))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            if let adminInfo = conversation.adminInfo {
                                Text("• Assigned to \(adminInfo.accountName)")
                                    .font(.system(size: 12))
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            } else {
                                Text("• Unassigned")
                                    .font(.system(size: 12))
                                    .foregroundColor(DesignTokens.Colors.primaryAmber)
                            }
                            
                            Spacer()
                            
                            Text(conversation.lastMessageAt.timeAgoString)
                                .font(.system(size: 12))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                    }
                    
                    // Unread count
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(DesignTokens.Colors.primaryPurple)
                            .clipShape(Circle())
                    }
                }
                
                // Last message preview
                if let lastMessage = conversation.lastMessage {
                    HStack {
                        Text(lastMessage.content)
                            .font(DesignTokens.ResponsiveTypography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
                
                // Tags
                if !conversation.tags.isEmpty {
                    HStack {
                        ForEach(conversation.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.primaryPurple)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(DesignTokens.Colors.primaryPurple.opacity(0.1))
                                )
                        }
                        
                        if conversation.tags.count > 3 {
                            Text("+\(conversation.tags.count - 3)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(DesignTokens.ResponsiveSpacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DesignTokens.Colors.borderPrimary, lineWidth: 1)
                )
        )
        .scaleButtonStyle()
    }
}

private struct StatusBadge: View {
    let status: String
    
    var body: some View {
        let config = statusConfig(for: status)
        
        Text(config.title)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(config.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(config.color.opacity(0.2))
            )
    }
    
    private func statusConfig(for status: String) -> (title: String, color: Color) {
        switch status {
        case "active":
            return ("ACTIVE", DesignTokens.Colors.primaryGreen)
        case "closed":
            return ("CLOSED", DesignTokens.Colors.textSecondary)
        case "archived":
            return ("ARCHIVED", DesignTokens.Colors.textTertiary)
        default:
            return ("UNKNOWN", DesignTokens.Colors.textSecondary)
        }
    }
}

// MARK: - Mock Data

private let mockConversations: [AdminConversation] = [
    AdminConversation(
        id: 123,
        userId: 456,
        userInfo: AdminUserInfo(
            id: 456,
            accountName: "John Smith",
            phoneNumber: "+1234567890",
            status: 2,
            createdAt: Date().addingTimeInterval(-86400 * 30),
            lastLogin: Date().addingTimeInterval(-7200)
        ),
        adminId: 789,
        adminInfo: AdminInfo(
            id: 789,
            username: "admin_sarah",
            accountName: "Sarah Wilson"
        ),
        status: "active",
        priority: "normal",
        createdAt: Date().addingTimeInterval(-86400 * 2),
        lastMessageAt: Date().addingTimeInterval(-3600),
        unreadCount: 3,
        totalMessages: 12,
        lastMessage: LastMessage(
            id: 25,
            content: "Thank you for your help with the billing issue!",
            senderRole: "user",
            timestamp: Date().addingTimeInterval(-3600)
        ),
        tags: ["billing", "resolved"],
        resolutionNotes: nil
    ),
    AdminConversation(
        id: 124,
        userId: 457,
        userInfo: AdminUserInfo(
            id: 457,
            accountName: "Jane Doe",
            phoneNumber: "+1987654321",
            status: 2,
            createdAt: Date().addingTimeInterval(-86400 * 15),
            lastLogin: Date().addingTimeInterval(-1200)
        ),
        adminId: nil,
        adminInfo: nil,
        status: "active",
        priority: "high",
        createdAt: Date().addingTimeInterval(-3600),
        lastMessageAt: Date().addingTimeInterval(-1800),
        unreadCount: 1,
        totalMessages: 5,
        lastMessage: LastMessage(
            id: 30,
            content: "I'm having trouble accessing my account after the recent update.",
            senderRole: "user",
            timestamp: Date().addingTimeInterval(-1800)
        ),
        tags: ["account", "urgent"],
        resolutionNotes: nil
    )
]

// MARK: - Extensions

extension Date {
    var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    AdminChatConversationListView()
        .environmentObject(SettingsStore())
}
