//
//  ReviewStatusBadge.swift
//  HomeAssistantPro
//
//  Purpose: Reusable badge component to display review status for forum content
//  Author: Michael
//  Created: 2025-07-13
//  Modified: 2025-07-13
//
//  Modification Log:
//  - 2025-07-13: Initial creation with under-review status badge
//
//  Functions:
//  - ReviewStatusBadge: Main badge component
//  - init(status:): Initialize with forum status
//  - isVisible: Computed property to show/hide badge
//  - badgeText: Computed property for status text
//  - badgeColor: Computed property for status color
//

import SwiftUI

/// Badge component to display forum content review status
struct ReviewStatusBadge: View {
    let status: Int
    
    /// Initialize badge with forum status
    /// - Parameter status: Forum status (-1=under review, 0=published, 1=deleted)
    init(status: Int) {
        self.status = status
    }
    
    /// Computed property to determine badge visibility
    var isVisible: Bool {
        return status == -1 // Only show for under-review content
    }
    
    /// Computed property for status text
    var badgeText: String {
        switch status {
        case -1:
            return "Reviewing"
        case 0:
            return "Published"
        case 1:
            return "Deleted"
        default:
            return "Unknown"
        }
    }
    
    /// Computed property for status color
    var badgeColor: Color {
        switch status {
        case -1:
            return DesignTokens.Colors.primaryAmber
        case 0:
            return DesignTokens.Colors.primaryGreen
        case 1:
            return Color.red
        default:
            return Color.gray
        }
    }
    
    var body: some View {
        if isVisible {
            Text(badgeText)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(badgeColor)
                )
        }
    }
}

/// Extension to add review status badge to any view
extension View {
    /// Adds a review status badge overlay to the view
    /// - Parameters:
    ///   - status: Forum content status
    ///   - alignment: Badge alignment (default: topTrailing)
    /// - Returns: View with badge overlay
    func reviewStatusBadge(status: Int, alignment: Alignment = .topTrailing) -> some View {
        self.overlay(
            ReviewStatusBadge(status: status),
            alignment: alignment
        )
    }
}

#Preview {
    VStack(spacing: DesignTokens.ResponsiveSpacing.md) {
        ReviewStatusBadge(status: -1) // Under Review
        ReviewStatusBadge(status: 0)  // Published (not visible)
        ReviewStatusBadge(status: 1)  // Deleted (not visible)
        
        // Example with overlay
        RoundedRectangle(cornerRadius: 12)
            .fill(DesignTokens.Colors.backgroundSecondary)
            .frame(width: 200, height: 100)
            .reviewStatusBadge(status: -1)
    }
    .background(DesignTokens.Colors.backgroundPrimary)
}
