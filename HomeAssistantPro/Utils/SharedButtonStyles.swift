//
//  SharedButtonStyles.swift
//  HomeAssistantPro
//
//  Purpose: Centralized button styles to eliminate duplication across views
//  Author: Michael
//  Updated: 2025-06-25
//
//  Features: Standard button styles used throughout the app for consistent
//  interaction feedback and visual behavior.
//

import SwiftUI

// MARK: - Standard Button Styles

/// Standard scale animation button style used throughout the app
struct StandardButtonStyle: ButtonStyle {
    let scaleEffect: CGFloat
    let animationDuration: Double
    
    init(scaleEffect: CGFloat = 0.95, animationDuration: Double = 0.1) {
        self.scaleEffect = scaleEffect
        self.animationDuration = animationDuration
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleEffect : 1.0)
            .animation(.easeInOut(duration: animationDuration), value: configuration.isPressed)
    }
}

/// Scale button style with slight scale effect - most commonly used
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Enhanced button style with scale and opacity effects
struct EnhancedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Card button style with subtle scale effect for card-like buttons
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Tab bar button style with gentle scale animation
struct TabBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Gentle button style with minimal scale effect for subtle interactions
struct GentleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Prominent button style with stronger feedback for primary actions
struct ProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions

extension View {
    /// Apply standard button style with default settings
    func standardButtonStyle() -> some View {
        self.buttonStyle(StandardButtonStyle())
    }
    
    /// Apply scale button style (most common)
    func scaleButtonStyle() -> some View {
        self.buttonStyle(ScaleButtonStyle())
    }
    
    /// Apply enhanced button style with opacity effect
    func enhancedButtonStyle() -> some View {
        self.buttonStyle(EnhancedButtonStyle())
    }
    
    /// Apply card button style for card-like interactions
    func cardButtonStyle() -> some View {
        self.buttonStyle(CardButtonStyle())
    }
    
    /// Apply tab bar button style
    func tabBarButtonStyle() -> some View {
        self.buttonStyle(TabBarButtonStyle())
    }
    
    /// Apply gentle button style for subtle interactions
    func gentleButtonStyle() -> some View {
        self.buttonStyle(GentleButtonStyle())
    }
    
    /// Apply prominent button style for primary actions
    func prominentButtonStyle() -> some View {
        self.buttonStyle(ProminentButtonStyle())
    }
}

// MARK: - Specialized Button Components

/// A standard button with consistent styling and behavior
struct StandardButton: View {
    let title: String
    let icon: String?
    let style: ButtonVariant
    let action: () -> Void
    
    enum ButtonVariant {
        case primary(Color)
        case secondary(Color)
        case outline(Color)
        case ghost(Color)
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonVariant = .primary(DesignTokens.Colors.primaryPurple),
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: DesignTokens.IconSize.md, weight: .semibold))
                }
                
                Text(title)
                    .font(DesignTokens.Typography.buttonMedium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.lg)
            .padding(.horizontal, DesignTokens.Spacing.xxl)
            .background(backgroundForStyle)
            .foregroundColor(foregroundColorForStyle)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
            .overlay(overlayForStyle)
        }
        .standardButtonStyle()
    }
    
    @ViewBuilder
    private var backgroundForStyle: some View {
        switch style {
        case .primary(let color):
            LinearGradient(
                colors: [color, color.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary(let color):
            color.opacity(0.1)
        case .outline(_):
            Color.clear
        case .ghost(_):
            Color.clear
        }
    }
    
    private var foregroundColorForStyle: Color {
        switch style {
        case .primary(_):
            return .white
        case .secondary(let color), .outline(let color), .ghost(let color):
            return color
        }
    }
    
    @ViewBuilder
    private var overlayForStyle: some View {
        switch style {
        case .outline(let color):
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(color, lineWidth: 1)
        default:
            EmptyView()
        }
    }
}

/// Icon button with consistent styling
struct IconButton: View {
    let icon: String
    let size: CGFloat
    let color: Color
    let backgroundColor: Color?
    let action: () -> Void
    
    init(
        icon: String,
        size: CGFloat = DesignTokens.Container.iconMedium,
        color: Color = DesignTokens.Colors.primaryPurple,
        backgroundColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.color = color
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: DesignTokens.IconSize.lg, weight: .semibold))
                .foregroundColor(backgroundColor != nil ? .white : color)
                .frame(width: size, height: size)
                .background(
                    Group {
                        if let backgroundColor = backgroundColor {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [backgroundColor, backgroundColor.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        } else {
                            Circle()
                                .fill(color.opacity(0.1))
                        }
                    }
                )
        }
        .standardButtonStyle()
    }
}