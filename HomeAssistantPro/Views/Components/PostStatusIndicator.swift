//
//  PostStatusIndicator.swift
//  HomeAssistantPro
//
//  Purpose: Visual indicators for forum post status (published, under review, deleted)
//  Author: Michael
//  Created: 2025-07-25
//  Modified: 2025-07-25
//
//  Modification Log:
//  - 2025-07-25: Initial creation with status indicator designs
//
//  Functions:
//  - PostStatusIndicator: Main status indicator component
//  - StatusBadge: Reusable status badge
//  - ReviewStatusBadge: Specialized badge for review status
//

import SwiftUI

/// Visual indicator for forum post status
struct PostStatusIndicator: View {
    let status: PostStatus
    let style: Style
    
    /// Style variants for the status indicator
    enum Style {
        case badge      // Small badge for topic cards
        case banner     // Full-width banner for detail views
        case inline     // Inline text indicator
        
        var fontSize: CGFloat {
            switch self {
            case .badge: return DesignTokens.DeviceSize.current.fontSize(10, 11, 12)
            case .banner: return DesignTokens.DeviceSize.current.fontSize(14, 15, 16)
            case .inline: return DesignTokens.DeviceSize.current.fontSize(12, 13, 14)
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .badge: return EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8)
            case .banner: return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
            case .inline: return EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
            }
        }
    }
    
    /// Post status types with visual properties
    enum PostStatus: Int {
        case underReview = -1
        case published = 0
        case deleted = 1
        case rejected = 2
        
        var displayName: String {
            switch self {
            case .underReview: return "Under Review"
            case .published: return "Published"
            case .deleted: return "Deleted"
            case .rejected: return "Rejected"
            }
        }
        
        var iconName: String {
            switch self {
            case .underReview: return "clock.fill"
            case .published: return "checkmark.circle.fill"
            case .deleted: return "trash.fill"
            case .rejected: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .underReview: return DesignTokens.Colors.primaryAmber
            case .published: return DesignTokens.Colors.primaryGreen
            case .deleted: return DesignTokens.Colors.primaryRed
            case .rejected: return DesignTokens.Colors.primaryRed
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .underReview: return DesignTokens.Colors.primaryAmber.opacity(0.15)
            case .published: return DesignTokens.Colors.primaryGreen.opacity(0.15)
            case .deleted: return DesignTokens.Colors.primaryRed.opacity(0.15)
            case .rejected: return DesignTokens.Colors.primaryRed.opacity(0.2)
            }
        }
        
        var description: String {
            switch self {
            case .underReview: return "This post is awaiting admin approval before it becomes visible to other users."
            case .published: return "This post is visible to all community members."
            case .deleted: return "This post has been removed by an administrator."
            case .rejected: return "This post was not approved and is only visible to you. You can edit and resubmit it."
            }
        }
        
        var isVisible: Bool {
            return self != .deleted
        }
    }
    
    init(status: Int, style: Style = .badge) {
        self.status = PostStatus(rawValue: status) ?? .published
        self.style = style
    }
    
    init(status: PostStatus, style: Style = .badge) {
        self.status = status
        self.style = style
    }
    
    var body: some View {
        switch style {
        case .badge:
            badgeView
        case .banner:
            bannerView
        case .inline:
            inlineView
        }
    }
    
    // MARK: - Badge Style
    
    private var badgeView: some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .font(.system(size: style.fontSize - 2, weight: .semibold))
            
            Text(status.displayName)
                .font(.system(size: style.fontSize, weight: .semibold))
        }
        .foregroundColor(status.color)
        .padding(style.padding)
        .background(
            Capsule()
                .fill(status.backgroundColor)
        )
    }
    
    // MARK: - Banner Style
    
    private var bannerView: some View {
        HStack(spacing: 12) {
            Image(systemName: status.iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(status.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(status.displayName)
                    .font(.system(size: style.fontSize, weight: .semibold))
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text(status.description)
                    .font(.system(size: style.fontSize - 2, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(style.padding)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(status.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(status.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Inline Style
    
    private var inlineView: some View {
        HStack(spacing: 6) {
            Image(systemName: status.iconName)
                .font(.system(size: style.fontSize, weight: .medium))
            
            Text(status.displayName)
                .font(.system(size: style.fontSize, weight: .semibold))
        }
        .foregroundColor(status.color)
        .padding(style.padding)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(status.backgroundColor)
        )
    }
}


// MARK: - Convenience Extensions

extension View {
    /// Adds a post status indicator to the view
    /// - Parameters:
    ///   - status: Post status integer
    ///   - style: Visual style of the indicator
    /// - Returns: View with status indicator overlay
    func postStatusIndicator(
        status: Int,
        style: PostStatusIndicator.Style = .badge
    ) -> some View {
        overlay(alignment: .topTrailing) {
            PostStatusIndicator(status: status, style: style)
                .padding(.top, 8)
                .padding(.trailing, 8)
        }
    }
    
    /// Shows a status banner at the top of the view
    /// - Parameter status: Post status integer
    /// - Returns: View with status banner
    func statusBanner(status: Int) -> some View {
        VStack(spacing: 0) {
            if status != 0 { // Only show banner for non-published posts
                PostStatusIndicator(status: status, style: .banner)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
            
            self
        }
    }
}

// MARK: - Helper Extensions

extension ForumTopic {
    /// Convenience computed property for status indicator
    var statusIndicator: PostStatusIndicator.PostStatus {
        return PostStatusIndicator.PostStatus(rawValue: status) ?? .published
    }
}

extension ForumReply {
    /// Convenience computed property for status indicator
    var statusIndicator: PostStatusIndicator.PostStatus {
        return PostStatusIndicator.PostStatus(rawValue: status) ?? .published
    }
}

// MARK: - Preview

#Preview("Status Indicators") {
    VStack(spacing: 20) {
        // Badge styles
        VStack(spacing: 12) {
            Text("Badge Style")
                .font(.headline)
            
            HStack(spacing: 12) {
                PostStatusIndicator(status: .underReview, style: .badge)
                PostStatusIndicator(status: .published, style: .badge)
                PostStatusIndicator(status: .rejected, style: .badge)
                PostStatusIndicator(status: .deleted, style: .badge)
            }
        }
        
        // Inline styles
        VStack(spacing: 12) {
            Text("Inline Style")
                .font(.headline)
            
            HStack(spacing: 12) {
                PostStatusIndicator(status: .underReview, style: .inline)
                PostStatusIndicator(status: .published, style: .inline)
                PostStatusIndicator(status: .rejected, style: .inline)
                PostStatusIndicator(status: .deleted, style: .inline)
            }
        }
        
        // Banner styles
        VStack(spacing: 12) {
            Text("Banner Style")
                .font(.headline)
            
            VStack(spacing: 8) {
                PostStatusIndicator(status: .underReview, style: .banner)
                PostStatusIndicator(status: .published, style: .banner)
                PostStatusIndicator(status: .rejected, style: .banner)
                PostStatusIndicator(status: .deleted, style: .banner)
            }
        }
    }
    .padding()
}