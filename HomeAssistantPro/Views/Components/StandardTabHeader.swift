//
//  StandardTabHeader.swift
//  HomeAssistantPro
//
//  Purpose: Standardized header component for consistent tab navigation styling
//  Author: Michael
//  Updated: 2025-06-25
//
//  Features: Flexible configuration, modern iOS 2025 design consistency,
//  glassmorphism effects, and smooth animations across all tab views.
//

import SwiftUI

/// Standardized header component for tab views with consistent styling
struct StandardTabHeader: View {
    let configuration: HeaderConfiguration
    
    var body: some View {
        VStack(spacing: 16) {
            // Main header content - ForumView style layout
            HStack(alignment: .center) {
                // Left side content (category label and main title)
                VStack(alignment: .leading, spacing: configuration.titleSpacing) {
                    // Category label (optional)
                    if let categoryLabel = configuration.categoryLabel {
                        Text(categoryLabel)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary.opacity(0.6))
                            .tracking(2)
                    }
                    
                    // Main title
                    Text(configuration.title)
                        .font(.system(size: configuration.titleSize, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
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
            .padding(.horizontal, 24)
            .padding(.top, configuration.topPadding)
            .padding(.bottom, configuration.bottomPadding)
            
            // Divider (optional)
            if configuration.showDivider {
                Rectangle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(height: 0.5)
                    .padding(.horizontal, 20)
            }
        }
        .background {
            if let backgroundColor = configuration.backgroundColor {
                Rectangle()
                    .fill(backgroundColor)
            }
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
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
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
                .frame(width: 48, height: 48)
                .shadow(color: color.opacity(0.4), radius: 12, x: 0, y: 6)
            
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private func capsuleButton(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
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
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.primary.opacity(0.7))
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
    }
}

// MARK: - Configuration Models

struct HeaderConfiguration {
    let categoryLabel: String?
    let title: String
    let subtitle: String?
    let titleSize: CGFloat
    let subtitleSize: CGFloat
    let titleSpacing: CGFloat
    let subtitleColor: Color
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let showDivider: Bool
    let backgroundColor: Material?
    let statusIndicator: StatusIndicator?
    let actionButton: ActionButton?
    
    // Default initializer with sensible defaults
    init(
        categoryLabel: String? = nil,
        title: String,
        subtitle: String? = nil,
        titleSize: CGFloat = 32,
        subtitleSize: CGFloat = 16,
        titleSpacing: CGFloat = 6,
        subtitleColor: Color = .primary.opacity(0.7),
        topPadding: CGFloat = 60,
        bottomPadding: CGFloat = 24,
        showDivider: Bool = false,
        backgroundColor: Material? = nil,
        statusIndicator: StatusIndicator? = nil,
        actionButton: ActionButton? = nil
    ) {
        self.categoryLabel = categoryLabel
        self.title = title
        self.subtitle = subtitle
        self.titleSize = titleSize
        self.subtitleSize = subtitleSize
        self.titleSpacing = titleSpacing
        self.subtitleColor = subtitleColor
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
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

extension HeaderConfiguration {
    // Preset configurations for each tab - ForumView style layout
    static func home() -> HeaderConfiguration {
        HeaderConfiguration(
            categoryLabel: "WELCOME",
            title: "HOME",
            topPadding: 40,
            bottomPadding: 24
        )
    }
    
    static func forum(onCreatePost: @escaping () -> Void) -> HeaderConfiguration {
        HeaderConfiguration(
            categoryLabel: "COMMUNITY",
            title: "Forum",
            topPadding: 40,
            bottomPadding: 24,
            actionButton: ActionButton(
                style: .circular(icon: "plus", color: Color(hex: "#06B6D4")),
                action: onCreatePost
            )
        )
    }
    
    static func chat(onOptions: @escaping () -> Void, isTyping: Bool = false) -> HeaderConfiguration {
        HeaderConfiguration(
            categoryLabel: "TECHNICAL",
            title: "Support",
            topPadding: 40,
            bottomPadding: 24,
            showDivider: true,
            statusIndicator: StatusIndicator(
                text: "Agent Online",
                color: Color(hex: "#10B981"),
                isAnimated: isTyping
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
            title: "Settings",
            topPadding: 20,
            bottomPadding: 8,
            actionButton: ActionButton(
                style: .circular(icon: "paintbrush.fill", color: selectedColor),
                action: onColorPicker
            )
        )
    }
}