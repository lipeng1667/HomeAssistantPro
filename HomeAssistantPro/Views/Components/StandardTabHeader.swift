//
//  StandardTabHeader.swift
//  HomeAssistantPro
//
//  Purpose: Modern responsive header component for all tab views
//  Author: Michael
//  Created: 2025-06-25
//  Modified: 2025-07-17
//
//  Modification Log:
//  - 2025-06-25: Initial creation with flexible configuration system
//  - 2025-06-26: Removed duplicate StandardButtonStyle declaration
//  - 2025-07-17: Major responsive design system integration
//    * Updated to use DesignTokens.ResponsiveTypography for all text
//    * Replaced fixed padding with responsive methods matching ForumView
//    * Added glassmorphism effects and modern shadow system
//    * Implemented device-adaptive button sizing
//    * Streamlined configuration by removing obsolete padding parameters
//    * Enhanced button styles with proper borders and responsive dimensions
//
//  Functions:
//  - StatusIndicator: Animated status displays for real-time feedback
//  - ActionButton: Responsive button styles (circular, capsule, glass)
//  - HeaderConfiguration: Flexible configuration system for different tabs
//  - Preset configurations: Pre-built setups for Home, Chat, and Settings tabs
//
//  Features:
//  - Full responsive design system integration using DesignTokens
//  - Device-adaptive spacing, typography, and button sizing
//  - Modern glassmorphism effects with ultraThinMaterial backgrounds
//  - Animated status indicators for dynamic content
//  - Consistent styling across all tab implementations
//  - Streamlined API with responsive defaults
//

import SwiftUI
import Foundation

/// Standardized header component for tab views with consistent styling
/// 
/// ARCHITECTURE NOTE: This component is designed for generic tab headers (Home, Chat, Settings)
/// that require basic configuration and styling. For specialized headers with complex business
/// logic (like ForumView), separate dedicated header components should be used.
///
/// ForumView Header Separation Rationale:
/// - Forum requires specialized features: draft management, anonymous restrictions, context menus
/// - Complex dependencies: DraftManager, AnonymousRestrictionViewModel, AppViewModel
/// - Domain-specific UI patterns: READ-ONLY indicators, draft status, restriction modals
/// - Heavy business logic that would bloat this generic component
///
/// Usage Guidelines:
/// - Use StandardTabHeader for: Simple headers with titles, status indicators, basic actions
/// - Use dedicated headers for: Complex domain logic, multiple dependencies, specialized workflows
/// - Both should share: DesignTokens, responsive patterns, common styling utilities
struct StandardTabHeader: View {
    let configuration: HeaderConfiguration
    
    var body: some View {
        VStack(spacing: 16) {
            // Main header content
            HStack(alignment: .center) {
                // Left side content (category label and main title)
                VStack(alignment: .leading, spacing: configuration.titleSpacing) {
                    // Category label (optional)
                    if let categoryLabel = configuration.categoryLabel {
                        Text(categoryLabel)
                            .font(DesignTokens.ResponsiveTypography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .tracking(1.5)
                    }
                    
                    // Main title
                    Text(configuration.title)
                        .font(DesignTokens.ResponsiveTypography.headingLarge)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
                
                Spacer()
                
                // Right side content (status indicator and/or action button)
                HStack(spacing: 12) {
                    // Status indicator (optional) - moved to right side
                    if let status = configuration.statusIndicator {
                        statusView(status)
                    }
                    
                    // Action button (optional)
                    if let actionButton = configuration.actionButton {
                        actionButtonView(actionButton)
                    }
                }
            }
            .responsiveHorizontalPadding(20, 24, 28)
            .responsiveVerticalPadding(16, 20, 24)
        }
        
        // Divider (optional)
        if configuration.showDivider {
            Rectangle()
                .fill(DesignTokens.Colors.borderPrimary)
                .frame(height: 1)
        }
    }
    
    // MARK: - Status View
    
    @ViewBuilder
    private func statusView(_ status: StatusIndicator) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
                .scaleEffect(status.isAnimated ? 1.2 : 1.0)
                .animation(
                    status.isAnimated ? 
                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : 
                        .default,
                    value: status.isAnimated
                )
            
            Text(status.text)
                .font(DesignTokens.ResponsiveTypography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
    }
    
    // MARK: - Action Button View
    
    @ViewBuilder
    private func actionButtonView(_ button: ActionButton) -> some View {
        Button(action: button.action) {
            Group {
                switch button.style {
                case .circular(let icon, let color):
                    circularButton(icon: icon, color: color)
                case .capsule(let text, let color):
                    capsuleButton(text: text, color: color)
                case .glass(let icon):
                    glassButton(icon: icon)
                }
            }
        }
        .buttonStyle(StandardButtonStyle())
    }
    
    @ViewBuilder
    private func circularButton(icon: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(
                    width: DesignTokens.DeviceSize.current.spacing(44, 48, 52),
                    height: DesignTokens.DeviceSize.current.spacing(44, 48, 52)
                )
                .standardShadowMedium()
            
            Image(systemName: icon)
                .font(.system(size: DesignTokens.DeviceSize.current.fontSize(16, 18, 20), weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private func capsuleButton(text: String, color: Color) -> some View {
        Text(text)
            .font(DesignTokens.ResponsiveTypography.bodyMedium)
            .foregroundColor(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
    }
    
    @ViewBuilder
    private func glassButton(icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: DesignTokens.DeviceSize.current.fontSize(14, 16, 18), weight: .medium))
            .foregroundColor(DesignTokens.Colors.textSecondary)
            .frame(
                width: DesignTokens.DeviceSize.current.spacing(40, 44, 48),
                height: DesignTokens.DeviceSize.current.spacing(40, 44, 48)
            )
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(DesignTokens.Colors.borderPrimary, lineWidth: 1)
                    )
                    .standardShadowLight()
            )
    }
}

// MARK: - Configuration Models

struct HeaderConfiguration {
    let categoryLabel: String?
    let title: String
    let subtitle: String?
    let titleSpacing: CGFloat
    let subtitleColor: Color
    let showDivider: Bool
    let backgroundColor: Material?
    let statusIndicator: StatusIndicator?
    let actionButton: ActionButton?
    
    // Default initializer with sensible defaults
    init(
        categoryLabel: String? = nil,
        title: String,
        subtitle: String? = nil,
        titleSpacing: CGFloat = DesignTokens.ResponsiveSpacing.xs,
        subtitleColor: Color = DesignTokens.Colors.textSecondary,
        showDivider: Bool = false,
        backgroundColor: Material? = nil,
        statusIndicator: StatusIndicator? = nil,
        actionButton: ActionButton? = nil
    ) {
        self.categoryLabel = categoryLabel
        self.title = title
        self.subtitle = subtitle
        self.titleSpacing = titleSpacing
        self.subtitleColor = subtitleColor
        self.showDivider = showDivider
        self.backgroundColor = backgroundColor
        self.statusIndicator = statusIndicator
        self.actionButton = actionButton
    }
}

struct StatusIndicator {
    let text: String
    let color: Color
    let isAnimated: Bool
    
    init(text: String, color: Color, isAnimated: Bool = false) {
        self.text = text
        self.color = color
        self.isAnimated = isAnimated
    }
}

struct ActionButton {
    let style: ActionButtonStyle
    let action: () -> Void
    
    enum ActionButtonStyle {
        case circular(icon: String, color: Color)
        case capsule(text: String, color: Color)
        case glass(icon: String)
    }
}


// MARK: - Convenience Extensions

/// Header Component Architecture Guidelines:
///
/// COMPONENT SEPARATION STRATEGY:
/// 1. StandardTabHeader: Generic component for simple headers (Home, Chat, Settings)
///    - Basic title/subtitle display
///    - Simple status indicators  
///    - Lightweight action buttons
///    - Minimal dependencies
///
/// 2. Specialized Headers: Domain-specific components (ForumView.enhancedHeader)
///    - Complex business logic
///    - Multiple service dependencies
///    - Advanced user interactions
///    - Domain-specific UI patterns
///
/// SHARED DESIGN SYSTEM:
/// - Both use DesignTokens.ResponsiveTypography for consistent fonts
/// - Both use DesignTokens.ResponsiveSpacing for consistent spacing
/// - Both use responsive padding: .responsiveHorizontalPadding(20, 24, 28)
/// - Both use modern styling: glassmorphism, shadows, animations
///
/// DECISION CRITERIA:
/// - Use StandardTabHeader if: Simple config, minimal state, generic patterns
/// - Use specialized header if: Complex state, domain logic, multiple dependencies
extension HeaderConfiguration {
    // Preset configurations for each tab - ForumView style layout
    static func home() -> HeaderConfiguration {
        HeaderConfiguration(
            categoryLabel: "WELCOME",
            title: LocalizedKeys.tabHome.localized
        )
    }
 
    static func chat(onOptions: @escaping () -> Void, connectionState: ConnectionState = .disconnected, isTyping: Bool = false) -> HeaderConfiguration {
        let statusText: String
        let statusColor: Color
        let shouldAnimate: Bool
        
        switch connectionState {
        case .connected:
            statusText = isTyping ? "Agent typing..." : "Agent Online"
            statusColor = DesignTokens.Colors.primaryGreen
            shouldAnimate = isTyping
        case .connecting:
            statusText = "Connecting..."
            statusColor = DesignTokens.Colors.primaryAmber
            shouldAnimate = true
        case .reconnecting:
            statusText = "Reconnecting..."
            statusColor = DesignTokens.Colors.primaryAmber
            shouldAnimate = true
        case .disconnected:
            statusText = "Disconnected"
            statusColor = DesignTokens.Colors.textSecondary
            shouldAnimate = false
        case .error:
            statusText = "Connection Error"
            statusColor = DesignTokens.Colors.primaryRed
            shouldAnimate = false
        }
        
        return HeaderConfiguration(
            categoryLabel: LocalizedKeys.chatSupport.localized,
            title: LocalizedKeys.chatTitle.localized,
            showDivider: true,
            statusIndicator: StatusIndicator(
                text: statusText,
                color: statusColor,
                isAnimated: shouldAnimate
            ),
            actionButton: ActionButton(
                style: .glass(icon: "ellipsis"),
                action: onOptions
            )
        )
    }
    
    static func settings(selectedColor: Color, onColorPicker: @escaping () -> Void) -> HeaderConfiguration {
        HeaderConfiguration(
            categoryLabel: "PREFERENCES",
            title: "Settings"
        )
    }
}
