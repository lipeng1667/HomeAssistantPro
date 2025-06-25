//
//  DesignTokens.swift
//  HomeAssistantPro
//
//  Purpose: Centralized design system tokens for consistent theming
//  Author: Michael
//  Updated: 2025-06-25
//
//  Features: Color palette, spacing scale, typography, corner radius,
//  and other design tokens used throughout the app.
//

import SwiftUI

/// Centralized design tokens for consistent theming across the app
struct DesignTokens {
    
    // MARK: - Color Palette
    
    /// Primary brand colors used throughout the app
    struct Colors {
        
        // MARK: Primary Brand Colors
        
        /// Primary purple brand color
        static let primaryPurple = Color(hex: "#8B5CF6")
        
        /// Primary cyan brand color  
        static let primaryCyan = Color(hex: "#06B6D4")
        
        /// Primary green brand color
        static let primaryGreen = Color(hex: "#10B981")
        
        /// Primary amber brand color
        static let primaryAmber = Color(hex: "#F59E0B")
        
        /// Primary red brand color
        static let primaryRed = Color(hex: "#EF4444")
        
        // MARK: Secondary Colors
        
        /// Secondary purple variation
        static let secondaryPurple = Color(hex: "#7C3AED")
        
        /// Secondary cyan variation
        static let secondaryCyan = Color(hex: "#0891B2")
        
        /// Secondary green variation
        static let secondaryGreen = Color(hex: "#059669")
        
        /// Secondary amber variation
        static let secondaryAmber = Color(hex: "#D97706")
        
        // MARK: Background Colors
        
        /// Light background tint
        static let backgroundLight = Color(hex: "#FAFAFA")
        
        /// Medium light background
        static let backgroundMediumLight = Color(hex: "#F8FAFC")
        
        /// Medium background
        static let backgroundMedium = Color(hex: "#F4F4F5")
        
        /// Medium dark background
        static let backgroundMediumDark = Color(hex: "#F1F5F9")
        
        /// Darker background tint
        static let backgroundDark = Color(hex: "#E4E4E7")
        
        // MARK: Surface Colors
        
        /// Login background light
        static let loginLight = Color(hex: "#F8FAFC")
        
        /// Login background medium
        static let loginMedium = Color(hex: "#E2E8F0")
        
        /// Login background dark
        static let loginDark = Color(hex: "#CBD5E1")
        
        // MARK: Tab Colors
        
        /// Home tab color scheme
        struct Home {
            static let primary = primaryPurple
            static let secondary = primaryCyan
        }
        
        /// Forum tab color scheme
        struct Forum {
            static let primary = primaryCyan
            static let secondary = primaryGreen
        }
        
        /// Chat tab color scheme
        struct Chat {
            static let primary = primaryGreen
            static let secondary = primaryPurple
        }
        
        /// Settings tab color scheme
        struct Settings {
            static let primary = primaryPurple
            static let accent = primaryCyan
            static let secondary = primaryGreen
        }
    }
    
    // MARK: - Spacing Scale
    
    /// Consistent spacing values used throughout the app
    struct Spacing {
        
        /// Extra small spacing (4pt)
        static let xs: CGFloat = 4
        
        /// Small spacing (8pt)
        static let sm: CGFloat = 8
        
        /// Medium spacing (12pt)
        static let md: CGFloat = 12
        
        /// Large spacing (16pt)
        static let lg: CGFloat = 16
        
        /// Extra large spacing (20pt)
        static let xl: CGFloat = 20
        
        /// 2X large spacing (24pt) - Most common horizontal padding
        static let xxl: CGFloat = 24
        
        /// 3X large spacing (28pt)
        static let xxxl: CGFloat = 28
        
        /// 4X large spacing (32pt)
        static let xxxxl: CGFloat = 32
        
        /// 5X large spacing (40pt)
        static let xxxxxl: CGFloat = 40
        
        /// 6X large spacing (48pt)
        static let xxxxxxl: CGFloat = 48
        
        /// Tab bar bottom spacing (120pt)
        static let tabBarBottom: CGFloat = 120
        
        /// Safe area top spacing (60pt)
        static let safeAreaTop: CGFloat = 60
    }
    
    // MARK: - Corner Radius
    
    /// Consistent border radius values
    struct CornerRadius {
        
        /// Small radius (8pt)
        static let sm: CGFloat = 8
        
        /// Medium radius (12pt)
        static let md: CGFloat = 12
        
        /// Large radius (16pt)
        static let lg: CGFloat = 16
        
        /// Extra large radius (20pt)
        static let xl: CGFloat = 20
        
        /// 2X large radius (24pt) - Most common for cards
        static let xxl: CGFloat = 24
        
        /// 3X large radius (28pt) - Tab bar and major components
        static let xxxl: CGFloat = 28
    }
    
    // MARK: - Typography
    
    /// Consistent typography scale
    struct Typography {
        
        // MARK: Display Fonts (Large titles)
        
        /// Large display font (36pt, bold, rounded)
        static let displayLarge = Font.system(size: 36, weight: .bold, design: .rounded)
        
        /// Medium display font (32pt, bold, rounded)
        static let displayMedium = Font.system(size: 32, weight: .bold, design: .rounded)
        
        /// Small display font (28pt, bold, rounded)
        static let displaySmall = Font.system(size: 28, weight: .bold, design: .rounded)
        
        // MARK: Heading Fonts
        
        /// Large heading (24pt, bold, rounded)
        static let headingLarge = Font.system(size: 24, weight: .bold, design: .rounded)
        
        /// Medium heading (22pt, bold, rounded)
        static let headingMedium = Font.system(size: 22, weight: .bold, design: .rounded)
        
        /// Small heading (20pt, bold, rounded)
        static let headingSmall = Font.system(size: 20, weight: .bold, design: .rounded)
        
        /// Extra small heading (18pt, semibold)
        static let headingExtraSmall = Font.system(size: 18, weight: .semibold)
        
        // MARK: Body Text
        
        /// Large body text (18pt, medium)
        static let bodyLarge = Font.system(size: 18, weight: .medium)
        
        /// Medium body text (16pt, medium)
        static let bodyMedium = Font.system(size: 16, weight: .medium)
        
        /// Small body text (15pt, medium)
        static let bodySmall = Font.system(size: 15, weight: .medium)
        
        /// Extra small body text (14pt, medium)
        static let bodyExtraSmall = Font.system(size: 14, weight: .medium)
        
        // MARK: Label Text
        
        /// Large label (16pt, semibold)
        static let labelLarge = Font.system(size: 16, weight: .semibold)
        
        /// Medium label (14pt, semibold)
        static let labelMedium = Font.system(size: 14, weight: .semibold)
        
        /// Small label (13pt, semibold, rounded)
        static let labelSmall = Font.system(size: 13, weight: .semibold, design: .rounded)
        
        /// Extra small label (12pt, semibold)
        static let labelExtraSmall = Font.system(size: 12, weight: .semibold)
        
        /// Tiny label (11pt, medium)
        static let labelTiny = Font.system(size: 11, weight: .medium)
        
        // MARK: Button Text
        
        /// Large button text (18pt, semibold)
        static let buttonLarge = Font.system(size: 18, weight: .semibold)
        
        /// Medium button text (16pt, semibold)
        static let buttonMedium = Font.system(size: 16, weight: .semibold)
        
        /// Small button text (14pt, semibold)
        static let buttonSmall = Font.system(size: 14, weight: .semibold)
        
        // MARK: Caption Text
        
        /// Caption text (12pt, medium)
        static let caption = Font.system(size: 12, weight: .medium)
        
        /// Small caption (11pt, medium)
        static let captionSmall = Font.system(size: 11, weight: .medium)
    }
    
    // MARK: - Shadow Presets
    
    /// Consistent shadow configurations
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        
        /// Light shadow for subtle elevation
        static let light = Shadow(
            color: Color.black.opacity(0.04),
            radius: 8,
            x: 0,
            y: 2
        )
        
        /// Medium shadow for cards and containers
        static let medium = Shadow(
            color: Color.black.opacity(0.06),
            radius: 16,
            x: 0,
            y: 6
        )
        
        /// Strong shadow for elevated elements
        static let strong = Shadow(
            color: Color.black.opacity(0.08),
            radius: 20,
            x: 0,
            y: 8
        )
        
        /// Extra strong shadow for modals
        static let extraStrong = Shadow(
            color: Color.black.opacity(0.1),
            radius: 25,
            x: 0,
            y: 12
        )
    }
    
    // MARK: - Icon Sizes
    
    /// Consistent icon sizing
    struct IconSize {
        
        /// Small icon (14pt)
        static let sm: CGFloat = 14
        
        /// Medium icon (16pt)
        static let md: CGFloat = 16
        
        /// Large icon (18pt)
        static let lg: CGFloat = 18
        
        /// Extra large icon (20pt)
        static let xl: CGFloat = 20
        
        /// 2X large icon (22pt)
        static let xxl: CGFloat = 22
        
        /// 3X large icon (24pt)
        static let xxxl: CGFloat = 24
        
        /// Feature icon (32pt)
        static let feature: CGFloat = 32
        
        /// Large feature icon (40pt)
        static let featureLarge: CGFloat = 40
    }
    
    // MARK: - Container Sizes
    
    /// Standard container dimensions
    struct Container {
        
        /// Small icon container (32pt)
        static let iconSmall: CGFloat = 32
        
        /// Medium icon container (44pt) - Most common
        static let iconMedium: CGFloat = 44
        
        /// Large icon container (48pt)
        static let iconLarge: CGFloat = 48
        
        /// Profile image container (100pt)
        static let profileImage: CGFloat = 100
    }
}

// MARK: - Convenience Extensions

extension Color {
    /// Create color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Apply standard light shadow
    func standardShadowLight() -> some View {
        self.shadow(
            color: DesignTokens.Shadow.light.color,
            radius: DesignTokens.Shadow.light.radius,
            x: DesignTokens.Shadow.light.x,
            y: DesignTokens.Shadow.light.y
        )
    }
    
    /// Apply standard medium shadow
    func standardShadowMedium() -> some View {
        self.shadow(
            color: DesignTokens.Shadow.medium.color,
            radius: DesignTokens.Shadow.medium.radius,
            x: DesignTokens.Shadow.medium.x,
            y: DesignTokens.Shadow.medium.y
        )
    }
    
    /// Apply standard strong shadow
    func standardShadowStrong() -> some View {
        self.shadow(
            color: DesignTokens.Shadow.strong.color,
            radius: DesignTokens.Shadow.strong.radius,
            x: DesignTokens.Shadow.strong.x,
            y: DesignTokens.Shadow.strong.y
        )
    }
}