//
//  SettingsView.swift
//  HomeAssistantPro
//
//  Purpose: Modern settings interface matching MainTabView design language with enhanced glassmorphism,
//  floating orbs, dynamic animations, and contemporary 2025 iOS aesthetics
//  Author: Michael
//  Updated: 2025-06-25
//
//  Features: Floating orbs background, enhanced glassmorphism, smooth animations,
//  profile section with dynamic colors, and keyboard-responsive UX.
//

import SwiftUI

/// Enhanced settings view with MainTabView design consistency
struct SettingsView: View {
    @EnvironmentObject var tabBarVisibility: TabBarVisibilityManager
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsStore: SettingsStore
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var restrictionViewModel = AnonymousRestrictionViewModel()
    @State private var showLanguageSelection = false
    @State private var showLogoutConfirmation = false
    @State private var showThemeSelection = false
    @FocusState private var isFieldFocused: Bool
    
    
    // MARK: - Dynamic Profile Properties
    
    /// Display name based on user authentication status
    private var displayName: String {
        print("DEBUG SETTINGS: Checking currentUser: \(appViewModel.currentUser?.id ?? -1)")
        guard let currentUser = appViewModel.currentUser else { 
            print("DEBUG SETTINGS: No currentUser found - appViewModel.currentUser is nil")
            return "Not Logged In" 
        }
        
        print("DEBUG SETTINGS: Found currentUser - id: \(currentUser.id), name: \(currentUser.accountName ?? "nil"), status: \(currentUser.status), userStatus: \(currentUser.userStatus)")
        
        switch currentUser.userStatus {
        case .anonymous:
            return "Guest User"
        case .normal:
            return currentUser.accountName ?? "Registered User"
        case .admin:
            return currentUser.accountName ?? "Administrator"
        case .deleted:
            return "Not Logged In"
        }
    }
    
    /// User status text for display
    private var userStatusText: String {
        guard let currentUser = appViewModel.currentUser else { return "Offline" }
        
        switch currentUser.userStatus {
        case .anonymous:
            return "Anonymous Access"
        case .normal:
            return "Premium Member"
        case .admin:
            return "Administrator"
        case .deleted:
            return "Offline"
        }
    }
    
    /// Color for status badge based on user status
    private var statusColor: Color {
        guard let currentUser = appViewModel.currentUser else { return DesignTokens.Colors.primaryRed }
        
        switch currentUser.userStatus {
        case .anonymous:
            return DesignTokens.Colors.primaryAmber
        case .normal:
            return DesignTokens.Colors.primaryGreen
        case .admin:
            return Color.init(red: 1.0, green: 0.84, blue: 0.0) // Gold color for admin
        case .deleted:
            return DesignTokens.Colors.primaryRed
        }
    }
    
    /// Profile icon based on user status
    private var profileIconName: String {
        guard let currentUser = appViewModel.currentUser else { return "person.slash" }
        
        switch currentUser.userStatus {
        case .anonymous:
            return "person.crop.circle.dashed"
        case .normal:
            return "person.fill"
        case .admin:
            return "crown.fill" // Crown icon for admin
        case .deleted:
            return "person.slash"
        }
    }
    
    /// Optional membership text based on user status
    private var membershipText: String? {
        guard let currentUser = appViewModel.currentUser else { return nil }
        
        switch currentUser.userStatus {
        case .anonymous:
            return "Upgrade to unlock full features"
        case .normal:
            if let phoneNumber = currentUser.phoneNumber {
                return "Phone: \(PhoneNumberUtils.formatPhoneNumber(phoneNumber))"
            } else {
                return "Member since registration"
            }
        case .admin:
            return "Full system access • Can moderate content"
        case .deleted:
            return nil
        }
    }
    
    var body: some View {
        ZStack {
            // Standardized background
            StandardTabBackground(configuration: .settings(primaryColor: DesignTokens.Colors.primaryPurple))
            
            // Main content
            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignTokens.ResponsiveSpacing.sectionSpacing) {
                    StandardTabHeader(configuration: .settings(
                        selectedColor: DesignTokens.Colors.primaryPurple,
                        onColorPicker: {}
                    ))
                    
                    VStack(spacing: DesignTokens.ResponsiveSpacing.lg) {
                        profileSection
                        preferencesSection
                        
                        // Only show security section for authenticated users
                        if let currentUser = appViewModel.currentUser,
                           currentUser.userStatus != .anonymous {
                            securitySection
                        }
                    }
                    .responsiveHorizontalPadding(6, 8, 10)
                    .limitedContentWidth()
                }
                .padding(.bottom, DesignTokens.DeviceSize.current.spacing(96, 108, 120))
            }
        }
        .onChange(of: isFieldFocused) { focused in
            if focused {
                tabBarVisibility.hideTabBar()
            } else {
                tabBarVisibility.showTabBar()
            }
        }
        .dismissKeyboardOnSwipeDown()
        .sheet(isPresented: $showLanguageSelection) {
            LanguageSelectionView()
                .environmentObject(localizationManager)
        }
        .sheet(isPresented: $showThemeSelection) {
            ThemeSelectionView()
                .environmentObject(settingsStore)
        }
        .confirmationModal(
            isPresented: $showLogoutConfirmation,
            config: .destructive(
                title: "Sign Out",
                message: "Are you sure you want to end your current session?",
                icon: "arrow.right.square.fill",
                confirmText: "Sign Out",
                onConfirm: {
                    Task {
                        await handleLogout()
                    }
                }
            )
        )
        .overlay(
            // Anonymous restriction modal - only show when needed
            Group {
                if restrictionViewModel.showModal {
                    CustomConfirmationModal(
                        isPresented: $restrictionViewModel.showModal,
                        config: .primary(
                            title: restrictionViewModel.restrictedAction.title,
                            message: restrictionViewModel.restrictedAction.message,
                            icon: "person.crop.circle.fill",
                            confirmText: "Log In",
                            cancelText: "Cancel",
                            onConfirm: {
                                restrictionViewModel.navigateToLogin(appViewModel: appViewModel)
                            },
                            onCancel: {
                                restrictionViewModel.dismissModal()
                            }
                        )
                    )
                }
            }
        )
    }
    
    
    
    // MARK: - Profile Section
    
    /// Profile section with modern card-based design without profile image
    private var profileSection: some View {
        VStack(spacing: DesignTokens.DeviceSize.current.spacing(12, 14, 16)) {
            // Main profile info card
            GlassmorphismCard(configuration: .settings) {
                // User information
                VStack(alignment: .leading, spacing: DesignTokens.ResponsiveSpacing.md) {
                    
                    // Quick stats or info based on status
                    HStack(spacing: DesignTokens.DeviceSize.current.spacing(12, 14, 16)) {
                        Text(displayName)
                            .font(DesignTokens.ResponsiveTypography.headingMedium)
                            .foregroundColor(.primary)
                        
                        if let currentUser = appViewModel.currentUser {
                            switch currentUser.userStatus {
                            case .normal:
                                quickInfoItem(icon: "checkmark.shield.fill", text: "Verified", color: DesignTokens.Colors.primaryGreen)
                            case .admin:
                                quickInfoItem(icon: "star.fill", text: "Admin", color: Color.init(red: 1.0, green: 0.84, blue: 0.0))
                            case .anonymous:
                                quickInfoItem(icon: "eye.fill", text: "View Only", color: DesignTokens.Colors.primaryAmber)
                            case .deleted:
                                quickInfoItem(icon: "person.slash", text: "Offline", color: DesignTokens.Colors.primaryRed)
                            }
                        }
                        Spacer()
                    }
                    
                    if let membershipText = membershipText {
                        Text(membershipText)
                            .font(DesignTokens.ResponsiveTypography.bodySmall)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    // Action buttons row
                    HStack(spacing: DesignTokens.ResponsiveSpacing.md) {
                        if let currentUser = appViewModel.currentUser {
                            switch currentUser.userStatus {
                            case .admin:
                                Button(action: {
                                    // Admin-specific settings could go here
                                    HapticManager.buttonTap()
                                }) {
                                    HStack(spacing: DesignTokens.DeviceSize.current.spacing(6, 7, 8)) {
                                        Image(systemName: "gearshape.2.fill")
                                            .font(.system(size: DesignTokens.DeviceSize.current.fontSize(11, 12.5, 14), weight: .semibold))
                                        
                                        Text("Admin Settings")
                                            .font(DesignTokens.ResponsiveTypography.buttonMedium)
                                    }
                                    .foregroundColor(.white)
                                    .responsiveHorizontalPadding(12, 16, 20)
                                    .responsiveVerticalPadding(10, 12, 14)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: DesignTokens.DeviceSize.current.spacing(10, 11, 12))
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.init(red: 1.0, green: 0.84, blue: 0.0), Color.init(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .shadow(
                                                color: Color.init(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3),
                                                radius: DesignTokens.DeviceSize.current.spacing(6, 7, 8),
                                                x: 0,
                                                y: DesignTokens.DeviceSize.current.spacing(3, 3.5, 4)
                                            )
                                    )
                                }
                                .enhancedButtonStyle()
                            case .anonymous:
                                Button(action: {
                                    restrictionViewModel.showRestrictionModal(for: .upgradeAccount)
                                }) {
                                    HStack(spacing: DesignTokens.DeviceSize.current.spacing(6, 7, 8)) {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .font(.system(size: DesignTokens.DeviceSize.current.fontSize(11, 12.5, 14), weight: .semibold))
                                        
                                        Text("Upgrade Account")
                                            .font(DesignTokens.ResponsiveTypography.buttonMedium)
                                    }
                                    .foregroundColor(.white)
                                    .responsiveHorizontalPadding(12, 16, 20)
                                    .responsiveVerticalPadding(10, 12, 14)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: DesignTokens.DeviceSize.current.spacing(10, 11, 12))
                                            .fill(
                                                LinearGradient(
                                                    colors: [DesignTokens.Colors.primaryGreen, DesignTokens.Colors.primaryGreen.opacity(0.8)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .shadow(
                                                color: DesignTokens.Colors.primaryGreen.opacity(0.3),
                                                radius: DesignTokens.DeviceSize.current.spacing(6, 7, 8),
                                                x: 0,
                                                y: DesignTokens.DeviceSize.current.spacing(3, 3.5, 4)
                                            )
                                    )
                                }
                                .enhancedButtonStyle()
                            case .normal:
                                modernActionButton(
                                    title: "Edit Profile",
                                    icon: "pencil.circle.fill",
                                    color: DesignTokens.Colors.primaryCyan,
                                    style: .secondary
                                )
                            case .deleted:
                                modernActionButton(
                                    title: "Sign In",
                                    icon: "person.crop.circle.fill",
                                    color: DesignTokens.Colors.primaryCyan,
                                    style: .primary
                                )
                            }
                        } else {
                            modernActionButton(
                                title: "Get Started",
                                icon: "arrow.right.circle.fill",
                                color: DesignTokens.Colors.primaryCyan,
                                style: .primary
                            )
                        }
                    }
                }
            }
        }
    }
    
    
    /// Quick info item for status display
    private func quickInfoItem(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: DesignTokens.DeviceSize.current.spacing(4, 5, 6)) {
            Image(systemName: icon)
                .font(.system(size: DesignTokens.DeviceSize.current.fontSize(10, 11, 12), weight: .semibold))
                .foregroundColor(color)
            
            Text(text)
                .font(.system(size: DesignTokens.DeviceSize.current.fontSize(10, 11, 12), weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.horizontal, DesignTokens.DeviceSize.current.spacing(8, 9, 10))
        .padding(.vertical, DesignTokens.DeviceSize.current.spacing(3, 3.5, 4))
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
    }
    
    /// Modern action button style
    private func modernActionButton(title: String, icon: String, color: Color, style: ButtonStyle) -> some View {
        Button(action: {
            HapticManager.buttonTap()
        }) {
            HStack(spacing: DesignTokens.DeviceSize.current.spacing(6, 7, 8)) {
                Image(systemName: icon)
                    .font(.system(size: DesignTokens.DeviceSize.current.fontSize(11, 12.5, 14), weight: .semibold))
                
                Text(title)
                    .font(DesignTokens.ResponsiveTypography.buttonMedium)
            }
            .foregroundColor(style == .primary ? .white : color)
            .responsiveHorizontalPadding(12, 16, 20)
            .responsiveVerticalPadding(10, 12, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.DeviceSize.current.spacing(10, 11, 12))
                    .fill(
                        style == .primary ?
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [color.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.DeviceSize.current.spacing(10, 11, 12))
                            .stroke(style == .primary ? Color.clear : color.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(
                        color: style == .primary ? color.opacity(0.3) : Color.clear,
                        radius: style == .primary ? DesignTokens.DeviceSize.current.spacing(6, 7, 8) : 0,
                        x: 0,
                        y: DesignTokens.DeviceSize.current.spacing(3, 3.5, 4)
                    )
            )
        }
        .enhancedButtonStyle()
    }
    
    enum ButtonStyle {
        case primary
        case secondary
    }
    

    /// Current theme display name
    private var currentThemeDisplayName: String {
        switch settingsStore.selectedTheme {
        case "light":
            return "Light Mode"
        case "dark":
            return "Dark Mode"
        case "system":
            return "Follow System"
        default:
            return "Follow System"
        }
    }
    
    /// Theme icon based on current selection
    private var themeIcon: String {
        switch settingsStore.selectedTheme {
        case "light":
            return "sun.max.fill"
        case "dark":
            return "moon.fill"
        case "system":
            return "circle.lefthalf.filled"
        default:
            return "circle.lefthalf.filled"
        }
    }
    
    /// Theme emoji based on current selection
    private var themeEmoji: String {
        switch settingsStore.selectedTheme {
        case "light":
            return "☀️"
        case "dark":
            return "🌙"
        case "system":
            return "⚫"
        default:
            return "⚫"
        }
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        VStack(spacing: DesignTokens.ResponsiveSpacing.lg) {
            // Language & Preferences
            GlassmorphismCard(configuration: .settings) {
                VStack(alignment: .leading, spacing: DesignTokens.DeviceSize.current.spacing(20, 22, 24)) {
                    sectionHeader(title: LocalizedKeys.settingsPreferences.localized, icon: "gearshape.fill")
                    
                    VStack(spacing: DesignTokens.DeviceSize.current.spacing(16, 18, 20)) {
                        // Language Selection
                        Button(action: {
                            showLanguageSelection = true
                        }) {
                            HStack(spacing: DesignTokens.DeviceSize.current.spacing(12, 14, 16)) {
                                ZStack {
                                    Circle()
                                        .fill(DesignTokens.Colors.primaryCyan.opacity(0.15))
                                        .frame(
                                            width: DesignTokens.DeviceSize.current.spacing(35, 39.5, 44),
                                            height: DesignTokens.DeviceSize.current.spacing(35, 39.5, 44)
                                        )
                                    
                                    Image(systemName: "globe")
                                        .font(.system(size: DesignTokens.DeviceSize.current.fontSize(14, 16, 18), weight: .semibold))
                                        .foregroundColor(DesignTokens.Colors.primaryCyan)
                                }
                                
                                VStack(alignment: .leading, spacing: DesignTokens.DeviceSize.current.spacing(1.5, 1.75, 2)) {
                                    Text(LocalizedKeys.settingsLanguage.localized)
                                        .font(.system(size: DesignTokens.DeviceSize.current.fontSize(12, 14, 16), weight: .semibold))
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    
                                    Text(localizationManager.currentLanguage.nativeName)
                                        .font(.system(size: DesignTokens.DeviceSize.current.fontSize(11, 12.5, 14), weight: .medium))
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: DesignTokens.DeviceSize.current.spacing(6, 7, 8)) {
                                    Text(localizationManager.currentLanguage.flag)
                                        .font(.system(size: DesignTokens.DeviceSize.current.fontSize(16, 18, 20)))
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: DesignTokens.DeviceSize.current.fontSize(10, 11, 12), weight: .semibold))
                                        .foregroundColor(DesignTokens.Colors.textTertiary)
                                }
                            }.contentShape(Rectangle())  // <-- Make entire area tappable
                        }
                        .cardButtonStyle()
                        
                        Divider().opacity(0.5)
                        
                        // Theme Selection Row
                        Button(action: {
                            showThemeSelection = true
                        }) {
                            HStack(spacing: DesignTokens.DeviceSize.current.spacing(12, 14, 16)) {
                                ZStack {
                                    Circle()
                                        .fill(DesignTokens.Colors.primaryPurple.opacity(0.15))
                                        .frame(
                                            width: DesignTokens.DeviceSize.current.spacing(35, 39.5, 44),
                                            height: DesignTokens.DeviceSize.current.spacing(35, 39.5, 44)
                                        )
                                    
                                    Image(systemName: themeIcon)
                                        .font(.system(size: DesignTokens.DeviceSize.current.fontSize(14, 16, 18), weight: .semibold))
                                        .foregroundColor(DesignTokens.Colors.primaryPurple)
                                }
                                
                                VStack(alignment: .leading, spacing: DesignTokens.DeviceSize.current.spacing(1.5, 1.75, 2)) {
                                    Text("Theme")
                                        .font(.system(size: DesignTokens.DeviceSize.current.fontSize(12, 14, 16), weight: .semibold))
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    
                                    Text(currentThemeDisplayName)
                                        .font(.system(size: DesignTokens.DeviceSize.current.fontSize(11, 12.5, 14), weight: .medium))
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: DesignTokens.DeviceSize.current.spacing(6, 7, 8)) {
                                    Text(themeEmoji)
                                        .font(.system(size: DesignTokens.DeviceSize.current.fontSize(16, 18, 20)))
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: DesignTokens.DeviceSize.current.fontSize(10, 11, 12), weight: .semibold))
                                        .foregroundColor(DesignTokens.Colors.textTertiary)
                                }
                            }.contentShape(Rectangle())
                        }
                        .cardButtonStyle()
                        
                    }
                }
                .padding(.vertical, DesignTokens.DeviceSize.current.spacing(16, 18, 20))
            }
        }
    }
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: DesignTokens.DeviceSize.current.spacing(10, 11, 12)) {
            Image(systemName: icon)
                .font(.system(size: DesignTokens.DeviceSize.current.fontSize(16, 18, 20), weight: .semibold))
                .foregroundColor(DesignTokens.Colors.primaryPurple)
            
            Text(title)
                .font(.system(size: DesignTokens.DeviceSize.current.fontSize(16, 18, 20), weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
    
    private func settingsRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: DesignTokens.DeviceSize.current.spacing(12, 14, 16)) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(
                        width: DesignTokens.DeviceSize.current.spacing(35, 39.5, 44),
                        height: DesignTokens.DeviceSize.current.spacing(35, 39.5, 44)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: DesignTokens.DeviceSize.current.fontSize(14, 16, 18), weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: DesignTokens.DeviceSize.current.spacing(1.5, 1.75, 2)) {
                Text(title)
                    .font(.system(size: DesignTokens.DeviceSize.current.fontSize(12, 14, 16), weight: .semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: DesignTokens.DeviceSize.current.fontSize(11, 12.5, 14), weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: DesignTokens.DeviceSize.current.fontSize(11, 12.5, 14), weight: .semibold))
                .foregroundColor(.secondary.opacity(0.6))
        }
    }
    
    // MARK: - Security Section
    
    private var securitySection: some View {
        GlassmorphismCard(configuration: .settings) {
            VStack(alignment: .leading, spacing: DesignTokens.DeviceSize.current.spacing(20, 22, 24)) {
                sectionHeader(title: "Security", icon: "shield.fill")
                
                // Logout Button
                Button(action: {
                    HapticManager.buttonTap()
                    showLogoutConfirmation = true
                }) {
                    HStack(spacing: DesignTokens.DeviceSize.current.spacing(12, 14, 16)) {
                        ZStack {
                            Circle()
                                .fill(DesignTokens.Colors.primaryRed.opacity(0.15))
                                .frame(
                                    width: DesignTokens.DeviceSize.current.spacing(35, 39.5, 44),
                                    height: DesignTokens.DeviceSize.current.spacing(35, 39.5, 44)
                                )
                            
                            if appViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.primaryRed))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.right.square.fill")
                                    .font(.system(size: DesignTokens.DeviceSize.current.fontSize(14, 16, 18), weight: .semibold))
                                    .foregroundColor(DesignTokens.Colors.primaryRed)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: DesignTokens.DeviceSize.current.spacing(1.5, 1.75, 2)) {
                            Text("Sign Out")
                                .font(.system(size: DesignTokens.DeviceSize.current.fontSize(12, 14, 16), weight: .semibold))
                                .foregroundColor(.primary)
                            Text("End your current session")
                                .font(.system(size: DesignTokens.DeviceSize.current.fontSize(11, 12.5, 14), weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: DesignTokens.DeviceSize.current.fontSize(11, 12.5, 14), weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .contentShape(Rectangle())
                }
                .disabled(appViewModel.isLoading)
                .cardButtonStyle()
            }
            .padding(.vertical, DesignTokens.DeviceSize.current.spacing(16, 18, 20))
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleLogout() async {
        HapticManager.medium()
        let success = await appViewModel.logout()
        
        if !success {
            // Show error feedback
            HapticManager.error()
        } else {
            HapticManager.success()
        }
    }
    
}

// MARK: - Theme Selection View

struct ThemeSelectionView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.presentationMode) var presentationMode
    @State private var applyingTheme = false
    
    private let themes: [(key: String, name: String, description: String, icon: String, emoji: String)] = [
        ("system", "Follow System", "Matches your device settings", "circle.lefthalf.filled", "⚫"),
        ("light", "Light Mode", "Always use light appearance", "sun.max.fill", "☀️"),
        ("dark", "Dark Mode", "Always use dark appearance", "moon.fill", "🌙")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        DesignTokens.Colors.backgroundPrimary,
                        DesignTokens.Colors.backgroundSecondary
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignTokens.ResponsiveSpacing.lg) {
                        // Header
                        VStack(spacing: DesignTokens.ResponsiveSpacing.sm) {
                            Text("Theme")
                                .font(DesignTokens.ResponsiveTypography.headingLarge)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            
                            Text("Choose your preferred appearance")
                                .font(DesignTokens.ResponsiveTypography.bodyMedium)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, DesignTokens.ResponsiveSpacing.xl)
                        
                        // Theme Options
                        GlassmorphismCard(configuration: .settings) {
                            VStack(spacing: 0) {
                                ForEach(themes, id: \.key) { theme in
                                    themeRow(theme: theme)
                                    
                                    if theme.key != themes.last?.key {
                                        Divider()
                                            .padding(.horizontal, DesignTokens.ResponsiveSpacing.md)
                                    }
                                }
                            }
                            .padding(.vertical, DesignTokens.ResponsiveSpacing.md)
                        }
                        .padding(.horizontal, DesignTokens.ResponsiveSpacing.md)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DesignTokens.Colors.primaryCyan)
                }
            }
        }
    }
    
    private func themeRow(theme: (key: String, name: String, description: String, icon: String, emoji: String)) -> some View {
        Button(action: {
            guard !applyingTheme else { return }
            
            HapticManager.buttonTap()
            applyingTheme = true
            
            // Apply theme immediately with animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                settingsStore.storeSelectedTheme(theme.key)
            }
            
            // Provide success feedback
            HapticManager.success()
            
            // Dismiss after a short delay to show the selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                applyingTheme = false
                presentationMode.wrappedValue.dismiss()
            }
        }) {
            HStack(spacing: DesignTokens.ResponsiveSpacing.md) {
                // Theme icon
                ZStack {
                    Circle()
                        .fill(DesignTokens.Colors.primaryPurple.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    if applyingTheme && settingsStore.selectedTheme == theme.key {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.primaryPurple))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: theme.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.primaryPurple)
                    }
                }
                
                // Theme Info
                VStack(alignment: .leading, spacing: DesignTokens.ResponsiveSpacing.xs) {
                    HStack(spacing: 8) {
                        Text(theme.emoji)
                            .font(.system(size: 20))
                        Text(theme.name)
                            .font(DesignTokens.ResponsiveTypography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                if settingsStore.selectedTheme == theme.key && !applyingTheme {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.primaryCyan)
                        .transition(.scale.combined(with: .opacity))
                } else if applyingTheme && settingsStore.selectedTheme == theme.key {
                    Text("Applying...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.primaryPurple)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, DesignTokens.ResponsiveSpacing.md)
            .padding(.vertical, DesignTokens.ResponsiveSpacing.md)
            .contentShape(Rectangle())
        }
        .disabled(applyingTheme)
        .scaleButtonStyle()
    }
}

// MARK: - Language Selection View

struct LanguageSelectionView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        DesignTokens.Colors.backgroundPrimary,
                        DesignTokens.Colors.backgroundSecondary
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignTokens.ResponsiveSpacing.lg) {
                        // Header
                        VStack(spacing: DesignTokens.ResponsiveSpacing.sm) {
                            Text(LocalizedKeys.settingsLanguage.localized)
                                .font(DesignTokens.ResponsiveTypography.headingLarge)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            
                            Text(LocalizedKeys.settingsLanguageDescription.localized)
                                .font(DesignTokens.ResponsiveTypography.bodyMedium)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, DesignTokens.ResponsiveSpacing.xl)
                        
                        // Language Options
                        GlassmorphismCard(configuration: .settings) {
                            VStack(spacing: 0) {
                                ForEach(Language.allCases, id: \.self) { language in
                                    languageRow(language: language)
                                    
                                    if language != Language.allCases.last {
                                        Divider()
                                            .padding(.horizontal, DesignTokens.ResponsiveSpacing.lg)
                                    }
                                }
                            }
                            .padding(.vertical, DesignTokens.ResponsiveSpacing.md)
                        }
                        .padding(.horizontal, DesignTokens.ResponsiveSpacing.lg)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedKeys.commonDone.localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DesignTokens.Colors.primaryCyan)
                }
            }
        }
    }
    
    private func languageRow(language: Language) -> some View {
        Button(action: {
            HapticManager.buttonTap()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                localizationManager.setLanguage(language)
            }
            
            // Dismiss after a short delay to show the selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                presentationMode.wrappedValue.dismiss()
            }
        }) {
            HStack(spacing: DesignTokens.ResponsiveSpacing.lg) {
                // Flag
                Text(language.flag)
                    .font(.system(size: 32))
                
                // Language Info
                VStack(alignment: .leading, spacing: DesignTokens.ResponsiveSpacing.xs) {
                    Text(language.nativeName)
                        .font(DesignTokens.ResponsiveTypography.bodyLarge)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text(language.displayName)
                        .font(DesignTokens.ResponsiveTypography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
                
                // Selection Indicator
                if localizationManager.currentLanguage == language {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.primaryCyan)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, DesignTokens.ResponsiveSpacing.lg)
            .padding(.vertical, DesignTokens.ResponsiveSpacing.lg)
            .contentShape(Rectangle())
        }
        .scaleButtonStyle()
    }
}

// MARK: - Preview

// MARK: – Preview
#Preview("Registered user") {
    // Build a configured AppViewModel in one expression
    let mockVM: AppViewModel = {
        let vm = AppViewModel()
        vm.currentUser = User(id: 0, deviceId: "sdfs", status: 2, accountName: "Jenny", phoneNumber: "18655554444")
        return vm
    }()

    // Pass the configured objects into the preview
    SettingsView()
        .environmentObject(mockVM)
        .environmentObject(SettingsStore())   // keep your settings store
}
