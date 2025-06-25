//
//  GlassmorphismCard.swift
//  HomeAssistantPro
//
//  Purpose: Reusable glassmorphism card component to eliminate styling duplication
//  Author: Michael
//  Updated: 2025-06-25
//
//  Features: Configurable glassmorphism effects, shadows, borders,
//  and corner radius for consistent card styling throughout the app.
//

import SwiftUI

/// Reusable glassmorphism card component with configurable styling
struct GlassmorphismCard<Content: View>: View {
    let content: Content
    let configuration: CardConfiguration
    
    init(
        configuration: CardConfiguration = .default,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.configuration = configuration
    }
    
    var body: some View {
        content
            .padding(.horizontal, configuration.horizontalPadding)
            .padding(.vertical, configuration.verticalPadding)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius, style: .continuous))
            .overlay(borderOverlay)
            .shadow(
                color: configuration.shadowColor,
                radius: configuration.shadowRadius,
                x: configuration.shadowOffsetX,
                y: configuration.shadowOffsetY
            )
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: configuration.cornerRadius, style: .continuous)
            .fill(configuration.backgroundMaterial)
            .overlay(
                // Additional gradient overlay if specified
                Group {
                    if let gradient = configuration.gradientOverlay {
                        RoundedRectangle(cornerRadius: configuration.cornerRadius, style: .continuous)
                            .fill(gradient)
                    }
                }
            )
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        if configuration.showBorder {
            RoundedRectangle(cornerRadius: configuration.cornerRadius, style: .continuous)
                .stroke(configuration.borderColor, lineWidth: configuration.borderWidth)
        }
    }
}

// MARK: - Card Configuration

struct CardConfiguration {
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let backgroundMaterial: Material
    let gradientOverlay: LinearGradient?
    let showBorder: Bool
    let borderColor: Color
    let borderWidth: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowOffsetX: CGFloat
    let shadowOffsetY: CGFloat
    
    init(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.xxl,
        horizontalPadding: CGFloat = DesignTokens.Spacing.xxl,
        verticalPadding: CGFloat = DesignTokens.Spacing.xl,
        backgroundMaterial: Material = .ultraThinMaterial,
        gradientOverlay: LinearGradient? = nil,
        showBorder: Bool = true,
        borderColor: Color = Color.white.opacity(0.4),
        borderWidth: CGFloat = 1,
        shadowColor: Color = DesignTokens.Shadow.medium.color,
        shadowRadius: CGFloat = DesignTokens.Shadow.medium.radius,
        shadowOffsetX: CGFloat = DesignTokens.Shadow.medium.x,
        shadowOffsetY: CGFloat = DesignTokens.Shadow.medium.y
    ) {
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.backgroundMaterial = backgroundMaterial
        self.gradientOverlay = gradientOverlay
        self.showBorder = showBorder
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowOffsetX = shadowOffsetX
        self.shadowOffsetY = shadowOffsetY
    }
}

// MARK: - Preset Configurations

extension CardConfiguration {
    
    /// Default card configuration used throughout the app
    static let `default` = CardConfiguration()
    
    /// Compact card with less padding
    static let compact = CardConfiguration(
        horizontalPadding: DesignTokens.Spacing.lg,
        verticalPadding: DesignTokens.Spacing.md
    )
    
    /// Large card with more padding
    static let large = CardConfiguration(
        horizontalPadding: DesignTokens.Spacing.xxxl,
        verticalPadding: DesignTokens.Spacing.xxl
    )
    
    /// Settings card configuration
    static let settings = CardConfiguration(
        cornerRadius: DesignTokens.CornerRadius.xxxl,
        shadowColor: DesignTokens.Shadow.strong.color,
        shadowRadius: DesignTokens.Shadow.strong.radius,
        shadowOffsetY: DesignTokens.Shadow.strong.y
    )
    
    /// Login card configuration
    static let login = CardConfiguration(
        verticalPadding: DesignTokens.Spacing.xxxxl,
        shadowColor: DesignTokens.Shadow.light.color,
        shadowRadius: DesignTokens.Shadow.light.radius,
        shadowOffsetY: 10
    )
    
    /// Chat message card configuration
    static let message = CardConfiguration(
        cornerRadius: DesignTokens.CornerRadius.lg,
        horizontalPadding: DesignTokens.Spacing.lg,
        verticalPadding: DesignTokens.Spacing.md,
        shadowColor: DesignTokens.Shadow.light.color,
        shadowRadius: DesignTokens.Shadow.light.radius,
        shadowOffsetY: DesignTokens.Shadow.light.y
    )
    
    /// Topic card configuration for forum
    static let topic = CardConfiguration(
        cornerRadius: DesignTokens.CornerRadius.xl,
        shadowColor: DesignTokens.Shadow.medium.color,
        shadowRadius: DesignTokens.Shadow.medium.radius,
        shadowOffsetY: DesignTokens.Shadow.medium.y
    )
    
    /// Feature card configuration with enhanced shadow
    static let feature = CardConfiguration(
        cornerRadius: DesignTokens.CornerRadius.xxl,
        verticalPadding: DesignTokens.Spacing.xxl,
        shadowColor: DesignTokens.Shadow.strong.color,
        shadowRadius: DesignTokens.Shadow.strong.radius,
        shadowOffsetY: DesignTokens.Shadow.strong.y
    )
    
    /// Floating card configuration
    static let floating = CardConfiguration(
        shadowColor: DesignTokens.Shadow.extraStrong.color,
        shadowRadius: DesignTokens.Shadow.extraStrong.radius,
        shadowOffsetY: DesignTokens.Shadow.extraStrong.y
    )
    
    /// Minimal card without border
    static let minimal = CardConfiguration(
        showBorder: false,
        shadowColor: DesignTokens.Shadow.light.color,
        shadowRadius: DesignTokens.Shadow.light.radius,
        shadowOffsetY: DesignTokens.Shadow.light.y
    )
    
    /// Input field card configuration
    static let input = CardConfiguration(
        cornerRadius: DesignTokens.CornerRadius.lg,
        horizontalPadding: DesignTokens.Spacing.xl,
        verticalPadding: DesignTokens.Spacing.lg,
        backgroundMaterial: .regularMaterial,
        showBorder: false,
        shadowColor: Color.clear,
        shadowRadius: 0,
        shadowOffsetY: 0
    )
}

// MARK: - Convenience Initializers

extension GlassmorphismCard {
    
    /// Create a default glassmorphism card
    static func standard<VC: View>(
        @ViewBuilder content: () -> VC
    ) -> GlassmorphismCard<VC> {
        GlassmorphismCard<VC>(configuration: .default, content: content)
    }
    
    /// Create a compact glassmorphism card
    static func compact<VC: View>(
        @ViewBuilder content: () -> VC
    ) -> GlassmorphismCard<VC> {
        GlassmorphismCard<VC>(configuration: .compact, content: content)
    }
    
    /// Create a large glassmorphism card
    static func large<VC: View>(
        @ViewBuilder content: () -> VC
    ) -> GlassmorphismCard<VC> {
        GlassmorphismCard<VC>(configuration: .large, content: content)
    }
    
    /// Create a settings glassmorphism card
    static func settings<VC: View>(
        @ViewBuilder content: () -> VC
    ) -> GlassmorphismCard<VC> {
        GlassmorphismCard<VC>(configuration: .settings, content: content)
    }
    
    /// Create a login glassmorphism card
    static func login<VC: View>(
        @ViewBuilder content: () -> VC
    ) -> GlassmorphismCard<VC> {
        GlassmorphismCard<VC>(configuration: .login, content: content)
    }
    
    /// Create a feature glassmorphism card
    static func feature<VC: View>(
        @ViewBuilder content: () -> VC
    ) -> GlassmorphismCard<VC> {
        GlassmorphismCard<VC>(configuration: .feature, content: content)
    }
}

// MARK: - View Extensions

extension View {
    /// Wrap view in a standard glassmorphism card
    func glassmorphismCard(configuration: CardConfiguration = .default) -> some View {
        GlassmorphismCard(configuration: configuration) {
            self
        }
    }
    
    /// Wrap view in a compact glassmorphism card
    func compactGlassmorphismCard() -> some View {
        GlassmorphismCard(configuration: .compact) {
            self
        }
    }
    
    /// Wrap view in a large glassmorphism card
    func largeGlassmorphismCard() -> some View {
        GlassmorphismCard(configuration: .large) {
            self
        }
    }
    
    /// Wrap view in a settings glassmorphism card
    func settingsGlassmorphismCard() -> some View {
        GlassmorphismCard(configuration: .settings) {
            self
        }
    }
    
    /// Wrap view in a feature glassmorphism card
    func featureGlassmorphismCard() -> some View {
        GlassmorphismCard(configuration: .feature) {
            self
        }
    }
}
