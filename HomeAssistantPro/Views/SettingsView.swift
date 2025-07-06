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
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var isEditingProfile = false
    @State private var selectedProfileColor: Color = DesignTokens.Colors.primaryPurple
    @State private var showLanguageSelection = false
    @State private var showLogoutConfirmation = false
    @FocusState private var isFieldFocused: Bool
    @Namespace private var profileTransition
    
    // Profile color options matching MainTabView palette
    private let profileColors: [Color] = [
        DesignTokens.Colors.primaryPurple,
        DesignTokens.Colors.primaryCyan,
        DesignTokens.Colors.primaryGreen,
        DesignTokens.Colors.primaryAmber,
        DesignTokens.Colors.primaryRed,
        DesignTokens.Colors.secondaryPurple
    ]
    
    var body: some View {
        ZStack {
            // Standardized background with dynamic color
            StandardTabBackground(configuration: .settings(primaryColor: selectedProfileColor))
            
            // Main content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    StandardTabHeader(configuration: .settings(
                        selectedColor: selectedProfileColor,
                        onColorPicker: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                isEditingProfile.toggle()
                            }
                        }
                    ))
                    profileSection
                        .padding(.horizontal, DesignTokens.Spacing.xxl)
                    accountSection
                        .padding(.horizontal, DesignTokens.Spacing.xxl)
                    preferencesSection
                        .padding(.horizontal, DesignTokens.Spacing.xxl)
                    securitySection
                        .padding(.horizontal, DesignTokens.Spacing.xxl)
                }
                .padding(.top, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.tabBarBottom)
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
    }
    
    
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        GlassmorphismCard(configuration: .settings) {
            VStack(spacing: 20) {
                // Profile avatar with dynamic color
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [selectedProfileColor, selectedProfileColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: selectedProfileColor.opacity(0.3), radius: 15, x: 0, y: 8)
                        .matchedGeometryEffect(id: "profileColor", in: profileTransition)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.white)
                }
                .onTapGesture {
                    cycleProfileColor()
                }
                
                VStack(spacing: 8) {
                    Text("Ethan Carter")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Premium Member")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedProfileColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(selectedProfileColor.opacity(0.15))
                        )
                    
                    Text("Member since 2021")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Color picker row (when editing)
                if isEditingProfile {
                    colorPickerRow
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Action buttons
                HStack(spacing: 16) {
                    actionButton(title: "Edit Profile", icon: "pencil", color: selectedProfileColor)
                    actionButton(title: "Share", icon: "square.and.arrow.up", color: DesignTokens.Colors.primaryCyan)
                }
            }
            .padding(.vertical, 24)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedProfileColor)
    }
    
    private var colorPickerRow: some View {
        HStack(spacing: 12) {
            ForEach(Array(profileColors.enumerated()), id: \.offset) { index, color in
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        selectedProfileColor = color
                    }
                }) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: selectedProfileColor == color ? 32 : 24, height: selectedProfileColor == color ? 32 : 24)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: selectedProfileColor == color ? 3 : 0)
                                .shadow(color: color.opacity(0.3), radius: 4)
                        )
                        .scaleEffect(selectedProfileColor == color ? 1.1 : 1.0)
                }
                .enhancedButtonStyle()
            }
        }
        .padding(.top, 8)
    }
    
    private func actionButton(title: String, icon: String, color: Color) -> some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(EnhancedButtonStyle())
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        GlassmorphismCard(configuration: .settings) {
            VStack(alignment: .leading, spacing: 24) {
                sectionHeader(title: "Account", icon: "person.crop.circle")
                
                VStack(spacing: 20) {
                    accountRow(icon: "phone.fill", title: "Phone Number", value: "+1 (555) 123-4567", color: DesignTokens.Colors.primaryGreen)
                    Divider().opacity(0.5)
                    accountRow(icon: "envelope.fill", title: "Email", value: "ethan.carter@email.com", color: DesignTokens.Colors.primaryCyan)
                    Divider().opacity(0.5)
                    accountRow(icon: "lock.fill", title: "Password", value: "••••••••", color: DesignTokens.Colors.primaryAmber)
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    private func accountRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.6))
        }
    }
       
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        VStack(spacing: DesignTokens.ResponsiveSpacing.lg) {
            // Language & Preferences
            GlassmorphismCard(configuration: .settings) {
                VStack(alignment: .leading, spacing: 24) {
                    sectionHeader(title: LocalizedKeys.settingsPreferences.localized, icon: "gearshape.fill")
                    
                    VStack(spacing: 20) {
                        // Language Selection
                        Button(action: {
                            showLanguageSelection = true
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(DesignTokens.Colors.primaryCyan.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "globe")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(DesignTokens.Colors.primaryCyan)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(LocalizedKeys.settingsLanguage.localized)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    
                                    Text(localizationManager.currentLanguage.nativeName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    Text(localizationManager.currentLanguage.flag)
                                        .font(.system(size: 20))
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(DesignTokens.Colors.textTertiary)
                                }
                            }.contentShape(Rectangle())  // <-- Make entire area tappable
                        }
                        .cardButtonStyle()
                        
                        Divider().opacity(0.5)
                        
                        settingsRow(
                            icon: "paintpalette.fill", 
                            title: LocalizedKeys.settingsColorTheme.localized, 
                            subtitle: LocalizedKeys.settingsColorDescription.localized, 
                            color: selectedProfileColor
                        )
                    }
                }
                .padding(.vertical, 20)
            }
        }
    }
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(selectedProfileColor)
            
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
    
    private func settingsRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.6))
        }
    }
    
    // MARK: - Security Section
    
    private var securitySection: some View {
        GlassmorphismCard(configuration: .settings) {
            VStack(alignment: .leading, spacing: 24) {
                sectionHeader(title: "Security", icon: "shield.fill")
                
                // Logout Button
                Button(action: {
                    HapticManager.buttonTap()
                    showLogoutConfirmation = true
                }) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(DesignTokens.Colors.primaryRed.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            if appViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.primaryRed))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.right.square.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(DesignTokens.Colors.primaryRed)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sign Out")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("End your current session")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .contentShape(Rectangle())
                }
                .disabled(appViewModel.isLoading)
                .cardButtonStyle()
            }
            .padding(.vertical, 20)
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
    
    
    private func cycleProfileColor() {
        guard let currentIndex = profileColors.firstIndex(of: selectedProfileColor) else { return }
        let nextIndex = (currentIndex + 1) % profileColors.count
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            selectedProfileColor = profileColors[nextIndex]
        }
        
        // Haptic feedback
        HapticManager.colorSelection()
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

#Preview {
    SettingsView()
        .environmentObject(AppViewModel())
}


