//
//  DesignTokens.swift
//  HomeAssistantPro
//
//  Created: June 25, 2025
//  Last Modified: June 26, 2025
//  Author: Michael Lee
//  Version: 2.1.0
//
//  Purpose: Centralized design system tokens for consistent theming across
//  all views and components. Provides adaptive colors, responsive spacing,
//  typography scales, and device detection for optimal UX.
//
//  Update History:
//  v1.0.0 (June 25, 2025) - Initial creation with basic color tokens and spacing
//  v2.0.0 (June 26, 2025) - Added dark mode support, responsive design system
//  v2.1.0 (June 26, 2025) - Enhanced shadow system with adaptive colors
//
//  Features: 
//  - Adaptive colors for light/dark mode switching
//  - Responsive spacing that scales with device size
//  - Typography system with device-aware font sizes
//  - Shadow presets with mode-appropriate opacity
//  - Device size detection and categorization
//

import SwiftUI

/// Centralized design tokens for consistent theming across the app
struct DesignTokens {
    
    // MARK: - Color Palette
    
    /// Environment-aware colors that adapt to light and dark modes
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
        
        // MARK: Dynamic Background Colors
        
        /// Primary background - adapts to light/dark mode
        static let backgroundPrimary = Color(
            light: Color(hex: "#FAFAFA"),
            dark: Color(hex: "#0F0F0F")
        )
        
        /// Secondary background - adapts to light/dark mode
        static let backgroundSecondary = Color(
            light: Color(hex: "#F8FAFC"),
            dark: Color(hex: "#1A1A1A")
        )
        
        /// Tertiary background - adapts to light/dark mode
        static let backgroundTertiary = Color(
            light: Color(hex: "#F4F4F5"),
            dark: Color(hex: "#262626")
        )
        
        /// Surface background - adapts to light/dark mode
        static let backgroundSurface = Color(
            light: Color(hex: "#FFFFFF"),
            dark: Color(hex: "#171717")
        )
        
        /// Elevated surface - adapts to light/dark mode
        static let backgroundElevated = Color(
            light: Color(hex: "#F1F5F9"),
            dark: Color(hex: "#1F1F1F")
        )
        
        // MARK: Dynamic Text Colors
        
        /// Primary text color - adapts to light/dark mode
        static let textPrimary = Color(
            light: Color(hex: "#1F2937"),
            dark: Color(hex: "#F9FAFB")
        )
        
        /// Secondary text color - adapts to light/dark mode
        static let textSecondary = Color(
            light: Color(hex: "#6B7280"),
            dark: Color(hex: "#9CA3AF")
        )
        
        /// Tertiary text color - adapts to light/dark mode
        static let textTertiary = Color(
            light: Color(hex: "#9CA3AF"),
            dark: Color(hex: "#6B7280")
        )
        
        // MARK: Dynamic Border Colors
        
        /// Primary border color - adapts to light/dark mode
        static let borderPrimary = Color(
            light: Color(hex: "#E5E7EB"),
            dark: Color(hex: "#374151")
        )
        
        /// Secondary border color - adapts to light/dark mode
        static let borderSecondary = Color(
            light: Color(hex: "#F3F4F6"),
            dark: Color(hex: "#2D3748")
        )
        
        // MARK: Legacy Colors (for backwards compatibility)
        
        /// Light background tint
        static let backgroundLight = Color(
            light: Color(hex: "#FAFAFA"),
            dark: Color(hex: "#0F0F0F")
        )
        
        /// Medium light background
        static let backgroundMediumLight = Color(
            light: Color(hex: "#F8FAFC"),
            dark: Color(hex: "#1A1A1A")
        )
        
        /// Medium background
        static let backgroundMedium = Color(
            light: Color(hex: "#F4F4F5"),
            dark: Color(hex: "#262626")
        )
        
        /// Medium dark background
        static let backgroundMediumDark = Color(
            light: Color(hex: "#F1F5F9"),
            dark: Color(hex: "#1F1F1F")
        )
        
        /// Darker background tint
        static let backgroundDark = Color(
            light: Color(hex: "#E4E4E7"),
            dark: Color(hex: "#171717")
        )
        
        // MARK: Surface Colors
        
        /// Login background light
        static let loginLight = Color(
            light: Color(hex: "#F8FAFC"),
            dark: Color(hex: "#1A1A1A")
        )
        
        /// Login background medium
        static let loginMedium = Color(
            light: Color(hex: "#E2E8F0"),
            dark: Color(hex: "#2D3748")
        )
        
        /// Login background dark
        static let loginDark = Color(
            light: Color(hex: "#CBD5E1"),
            dark: Color(hex: "#374151")
        )
        
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
            color: Color(
                light: Color.black.opacity(0.04),
                dark: Color.black.opacity(0.2)
            ),
            radius: 8,
            x: 0,
            y: 2
        )
        
        /// Medium shadow for cards and containers
        static let medium = Shadow(
            color: Color(
                light: Color.black.opacity(0.06),
                dark: Color.black.opacity(0.3)
            ),
            radius: 16,
            x: 0,
            y: 6
        )
        
        /// Strong shadow for elevated elements
        static let strong = Shadow(
            color: Color(
                light: Color.black.opacity(0.08),
                dark: Color.black.opacity(0.4)
            ),
            radius: 20,
            x: 0,
            y: 8
        )
        
        /// Extra strong shadow for modals
        static let extraStrong = Shadow(
            color: Color(
                light: Color.black.opacity(0.1),
                dark: Color.black.opacity(0.5)
            ),
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
    
    /// Responsive container dimensions
    struct ResponsiveContainer {
        
        /// Card width that adapts to screen size
        static var cardWidth: CGFloat {
            let screenWidth = UIScreen.main.bounds.width
            return screenWidth - (DesignTokens.ResponsiveSpacing.contentMargins * 2)
        }
        
        /// Maximum content width for readability
        static var maxContentWidth: CGFloat {
            switch DeviceSize.current {
            case .compact:
                return UIScreen.main.bounds.width - 32
            case .regular:
                return UIScreen.main.bounds.width - 40
            case .large:
                return UIScreen.main.bounds.width - 48
            }
        }
        
        /// Tab bar height that adapts to device
        static var tabBarHeight: CGFloat {
            DeviceSize.current.spacing(60, 70, 80)
        }
        
        /// Profile icon size
        static var profileIconSize: CGFloat {
            DeviceSize.current.spacing(64, 72, 80)
        }
        
        /// Button height
        static var buttonHeight: CGFloat {
            DeviceSize.current.spacing(44, 48, 52)
        }
        
        /// Input field height
        static var inputFieldHeight: CGFloat {
            DeviceSize.current.spacing(48, 52, 56)
        }
    }
    
    // MARK: - Device Detection
    
    /// Device size categories for responsive design
    enum DeviceSize {
        case compact    // iPhone SE, iPhone 12 mini, iPhone 13 mini (375pt width)
        case regular    // iPhone 12, iPhone 13, iPhone 14, iPhone 15, iPhone 15 Pro (390-393pt width)
        case large      // iPhone 12 Plus, iPhone 13 Plus, iPhone 14 Plus, iPhone 15 Plus, iPhone 15 Pro Max (428-430pt width)
        
        static var current: DeviceSize {
            let screenWidth = UIScreen.main.bounds.width
            switch screenWidth {
            case 0..<385:
                return .compact  // SE, mini series
            case 385..<415:
                return .regular  // Standard models
            default:
                return .large    // Plus/Pro Max models
            }
        }
        
        /// Check if device is iPhone SE or mini size
        var isSmallDevice: Bool {
            return self == .compact
        }
        
        /// Check if device is Pro Max or Plus size
        var isLargeDevice: Bool {
            return self == .large
        }
        
        /// Get responsive spacing value
        func spacing(_ compact: CGFloat, _ regular: CGFloat? = nil, _ large: CGFloat? = nil) -> CGFloat {
            switch self {
            case .compact:
                return compact
            case .regular:
                return regular ?? compact * 1.2
            case .large:
                return large ?? regular ?? compact * 1.4
            }
        }
        
        /// Get responsive font size
        func fontSize(_ compact: CGFloat, _ regular: CGFloat? = nil, _ large: CGFloat? = nil) -> CGFloat {
            switch self {
            case .compact:
                return compact
            case .regular:
                return regular ?? compact + 1
            case .large:
                return large ?? regular ?? compact + 2
            }
        }
    }
    
    // MARK: - Responsive Values
    
    /// Responsive spacing that adapts to device size
    struct ResponsiveSpacing {
        
        /// Extra small responsive spacing
        static var xs: CGFloat {
            DeviceSize.current.spacing(4, 5, 6)
        }
        
        /// Small responsive spacing
        static var sm: CGFloat {
            DeviceSize.current.spacing(8, 10, 12)
        }
        
        /// Medium responsive spacing
        static var md: CGFloat {
            DeviceSize.current.spacing(16, 20, 24)
        }
        
        /// Large responsive spacing
        static var lg: CGFloat {
            DeviceSize.current.spacing(24, 28, 32)
        }
        
        /// Extra large responsive spacing
        static var xl: CGFloat {
            DeviceSize.current.spacing(32, 38, 44)
        }
        
        /// Extra extra large responsive spacing
        static var xxl: CGFloat {
            DeviceSize.current.spacing(48, 56, 64)
        }
        
        /// Card padding responsive spacing
        static var cardPadding: CGFloat {
            DeviceSize.current.spacing(20, 24, 28)
        }
        
        /// Section spacing
        static var sectionSpacing: CGFloat {
            DeviceSize.current.spacing(28, 32, 36)
        }
        
        /// Tab bar responsive spacing
        static var tabBarSpacing: CGFloat {
            DeviceSize.current.spacing(12, 16, 20)
        }
        
        /// Header spacing
        static var headerSpacing: CGFloat {
            DeviceSize.current.spacing(24, 32, 40)
        }
        
        /// Content margins
        static var contentMargins: CGFloat {
            DeviceSize.current.spacing(16, 20, 24)
        }
        
        /// Button padding
        static var buttonPadding: CGFloat {
            DeviceSize.current.spacing(12, 16, 20)
        }
        
        /// Input field padding
        static var inputPadding: CGFloat {
            DeviceSize.current.spacing(16, 18, 20)
        }
    }
    
    /// Responsive typography that adapts to device size
    struct ResponsiveTypography {
        
        /// Display heading responsive
        static var displayLarge: Font {
            Font.system(
                size: DeviceSize.current.fontSize(32, 36, 40),
                weight: .bold,
                design: .rounded
            )
        }
        
        /// Large heading responsive
        static var headingLarge: Font {
            Font.system(
                size: DeviceSize.current.fontSize(24, 26, 28),
                weight: .bold,
                design: .rounded
            )
        }
        
        /// Medium heading responsive
        static var headingMedium: Font {
            Font.system(
                size: DeviceSize.current.fontSize(20, 22, 24),
                weight: .bold,
                design: .rounded
            )
        }
        
        /// Small heading responsive
        static var headingSmall: Font {
            Font.system(
                size: DeviceSize.current.fontSize(18, 19, 20),
                weight: .bold,
                design: .rounded
            )
        }
        
        /// Body text responsive
        static var bodyLarge: Font {
            Font.system(
                size: DeviceSize.current.fontSize(16, 17, 18),
                weight: .medium
            )
        }
        
        /// Body medium responsive
        static var bodyMedium: Font {
            Font.system(
                size: DeviceSize.current.fontSize(14, 15, 16),
                weight: .medium
            )
        }
        
        /// Body small responsive
        static var bodySmall: Font {
            Font.system(
                size: DeviceSize.current.fontSize(13, 14, 15),
                weight: .medium
            )
        }
        
        /// Button text responsive
        static var buttonLarge: Font {
            Font.system(
                size: DeviceSize.current.fontSize(16, 17, 18),
                weight: .semibold
            )
        }
        
        /// Button medium responsive
        static var buttonMedium: Font {
            Font.system(
                size: DeviceSize.current.fontSize(14, 15, 16),
                weight: .semibold
            )
        }
        
        /// Caption text responsive
        static var caption: Font {
            Font.system(
                size: DeviceSize.current.fontSize(11, 12, 13),
                weight: .medium
            )
        }
        
        /// Label text responsive
        static var label: Font {
            Font.system(
                size: DeviceSize.current.fontSize(12, 13, 14),
                weight: .semibold
            )
        }
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
    
    /// Create adaptive color for light and dark mode
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
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
    
    /// Apply responsive padding that adapts to device size
    func responsivePadding(_ compact: CGFloat, _ regular: CGFloat? = nil, _ large: CGFloat? = nil) -> some View {
        self.padding(DesignTokens.DeviceSize.current.spacing(compact, regular, large))
    }
    
    /// Apply responsive horizontal padding
    func responsiveHorizontalPadding(_ compact: CGFloat, _ regular: CGFloat? = nil, _ large: CGFloat? = nil) -> some View {
        self.padding(.horizontal, DesignTokens.DeviceSize.current.spacing(compact, regular, large))
    }
    
    /// Apply responsive vertical padding
    func responsiveVerticalPadding(_ compact: CGFloat, _ regular: CGFloat? = nil, _ large: CGFloat? = nil) -> some View {
        self.padding(.vertical, DesignTokens.DeviceSize.current.spacing(compact, regular, large))
    }
    
    /// Apply content margins based on device size
    func contentMargins() -> some View {
        self.padding(.horizontal, DesignTokens.ResponsiveSpacing.contentMargins)
    }
    
    /// Apply card padding based on device size
    func cardPadding() -> some View {
        self.padding(DesignTokens.ResponsiveSpacing.cardPadding)
    }
    
    /// Limit content width for better readability on large screens
    func limitedContentWidth() -> some View {
        self.frame(maxWidth: DesignTokens.ResponsiveContainer.maxContentWidth)
    }
    
    /// Make view responsive to device size changes
    func deviceSizeAdaptive<Content: View>(@ViewBuilder content: @escaping (DesignTokens.DeviceSize) -> Content) -> some View {
        content(DesignTokens.DeviceSize.current)
    }
}