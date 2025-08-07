//
//  AdminChatDetailView.swift
//  HomeAssistantPro
//
//  Purpose: Admin chat detail view for individual conversation management
//  Author: Assistant
//  Create date: 2025-08-07
//  Latest modify date: 2025-08-07
//
//  Modification log:
//  - 2025-08-07: Initial creation as placeholder for admin chat detail interface
//
//  Functions:
//  - body: Main admin chat detail view
//

import SwiftUI

/// Admin chat detail view for managing individual conversations
struct AdminChatDetailView: View {
    let conversation: AdminConversation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignTokens.ResponsiveSpacing.md) {
                // User info header
                HStack {
                    Circle()
                        .fill(DesignTokens.Colors.primaryCyan.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(conversation.userInfo.accountName?.prefix(1) ?? "U")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.primaryCyan)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(conversation.userInfo.accountName ?? "Unknown User")
                            .font(DesignTokens.ResponsiveTypography.headingMedium)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Text("Conversation #\(conversation.id)")
                            .font(DesignTokens.ResponsiveTypography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding()
                
                // Placeholder for chat messages
                VStack(spacing: DesignTokens.ResponsiveSpacing.lg) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(DesignTokens.Colors.primaryPurple.opacity(0.6))
                    
                    Text("Chat Detail View")
                        .font(DesignTokens.ResponsiveTypography.headingMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("This view will show the complete chat interface for admin-user conversations with message history, typing indicators, and admin management tools.")
                        .font(DesignTokens.ResponsiveTypography.bodyLarge)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
            }
            .background(DesignTokens.Colors.backgroundPrimary)
            .navigationTitle("Chat Detail")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DesignTokens.Colors.primaryPurple)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AdminChatDetailView(conversation: AdminConversation(
        id: 123,
        userId: 456,
        userInfo: AdminUserInfo(
            id: 456,
            accountName: "John Smith",
            phoneNumber: "+1234567890",
            status: 2,
            createdAt: Date(),
            lastLogin: Date()
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
    ))
}