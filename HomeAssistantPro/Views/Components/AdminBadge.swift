//
//  AdminBadge.swift
//  HomeAssistantPro
//
//  Purpose: Reusable admin badge component for identifying admin users in forum and chat
//  Author: Michael
//  Created: 2025-07-25
//  Modified: 2025-07-25
//
//  Modification Log:
//  - 2025-07-25: Initial creation with responsive admin badge design
//
//  Functions:
//  - AdminBadge: SwiftUI view component showing admin status
//

import SwiftUI

/// Admin badge component for displaying admin user status
struct AdminBadge: View {
    
    /// Style variants for the admin badge
    enum Style {
        case compact    // Small badge for forum posts
        case standard   // Regular size for profile views
        case large      // Larger size for emphasis
        
        var iconSize: CGFloat {
            switch self {
            case .compact: return DesignTokens.DeviceSize.current.fontSize(10, 11, 12)
            case .standard: return DesignTokens.DeviceSize.current.fontSize(12, 13, 14)
            case .large: return DesignTokens.DeviceSize.current.fontSize(14, 15, 16)
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .compact: return DesignTokens.DeviceSize.current.fontSize(8, 9, 10)
            case .standard: return DesignTokens.DeviceSize.current.fontSize(10, 11, 12)
            case .large: return DesignTokens.DeviceSize.current.fontSize(12, 13, 14)
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .compact: return DesignTokens.DeviceSize.current.spacing(3, 3.5, 4)
            case .standard: return DesignTokens.DeviceSize.current.spacing(4, 5, 6)
            case .large: return DesignTokens.DeviceSize.current.spacing(6, 7, 8)
            }
        }
    }
    
    // MARK: - Properties
    
    let style: Style
    let showText: Bool
    
    // MARK: - Initialization
    
    /// Creates an admin badge with specified style
    /// - Parameters:
    ///   - style: Visual style of the badge
    ///   - showText: Whether to show "Admin" text alongside the icon
    init(style: Style = .standard, showText: Bool = true) {
        self.style = style
        self.showText = showText
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: DesignTokens.DeviceSize.current.spacing(2, 2.5, 3)) {
            // Crown icon
            Image(systemName: "crown.fill")
                .font(.system(size: style.iconSize, weight: .semibold))
                .foregroundColor(.white)
            
            // Admin text (optional)
            if showText {
                Text("Admin")
                    .font(.system(size: style.fontSize, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, style.padding + 2)
        .padding(.vertical, style.padding)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.84, blue: 0.0), // Gold
                            Color(red: 0.85, green: 0.65, blue: 0.0)  // Darker gold
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3),
                    radius: DesignTokens.DeviceSize.current.spacing(2, 2.5, 3),
                    x: 0,
                    y: DesignTokens.DeviceSize.current.spacing(1, 1.5, 2)
                )
        )
    }
}

// MARK: - Convenience Extensions

extension AdminBadge {
    /// Creates a compact admin badge for forum posts
    static var compact: AdminBadge {
        AdminBadge(style: .compact, showText: false)
    }
    
    /// Creates a standard admin badge with text
    static var standard: AdminBadge {
        AdminBadge(style: .standard, showText: true)
    }
    
    /// Creates a large admin badge for emphasis
    static var large: AdminBadge {
        AdminBadge(style: .large, showText: true)
    }
}

// MARK: - Helper View Extensions

extension View {
    /// Conditionally shows an admin badge if the user is an admin
    /// - Parameters:
    ///   - isAdmin: Whether the user is an admin
    ///   - style: Style of the admin badge
    ///   - showText: Whether to show admin text
    /// - Returns: View with optional admin badge
    func adminBadge(
        if isAdmin: Bool, 
        style: AdminBadge.Style = .standard, 
        showText: Bool = true
    ) -> some View {
        HStack(spacing: DesignTokens.DeviceSize.current.spacing(4, 5, 6)) {
            self
            
            if isAdmin {
                AdminBadge(style: style, showText: showText)
            }
        }
    }
}

// MARK: - Preview

#Preview("Admin Badge Styles") {
    VStack(spacing: 20) {
        HStack(spacing: 15) {
            AdminBadge.compact
            AdminBadge(style: .compact, showText: true)
        }
        
        HStack(spacing: 15) {
            AdminBadge.standard
            AdminBadge(style: .standard, showText: false)
        }
        
        HStack(spacing: 15) {
            AdminBadge.large
            AdminBadge(style: .large, showText: false)
        }
        
        // Usage examples
        Text("John Doe")
            .adminBadge(if: true, style: .compact, showText: false)
        
        Text("Admin User")
            .adminBadge(if: true, style: .standard, showText: true)
    }
    .padding()
}