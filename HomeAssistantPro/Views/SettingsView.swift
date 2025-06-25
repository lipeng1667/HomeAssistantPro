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
    @State private var isEditingProfile = false
    @State private var selectedProfileColor: Color = DesignTokens.Colors.primaryPurple
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
                    settingsSection
                        .padding(.horizontal, DesignTokens.Spacing.xxl)
                    preferencesSection
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
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        GlassmorphismCard(configuration: .settings) {
            VStack(alignment: .leading, spacing: 24) {
                sectionHeader(title: "Preferences", icon: "gearshape.fill")
                
                VStack(spacing: 20) {
                    settingsRow(icon: "bell.fill", title: "Notifications", subtitle: "Push, email, SMS", color: DesignTokens.Colors.primaryRed)
                    Divider().opacity(0.5)
                    settingsRow(icon: "moon.fill", title: "Dark Mode", subtitle: "System", color: DesignTokens.Colors.secondaryPurple)
                    Divider().opacity(0.5)
                    settingsRow(icon: "globe", title: "Language", subtitle: "English", color: DesignTokens.Colors.primaryPurple)
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        GlassmorphismCard(configuration: .settings) {
            VStack(alignment: .leading, spacing: 24) {
                sectionHeader(title: "Support", icon: "questionmark.circle.fill")
                
                VStack(spacing: 20) {
                    settingsRow(icon: "headphones", title: "Help Center", subtitle: "FAQs and guides", color: DesignTokens.Colors.primaryGreen)
                    Divider().opacity(0.5)
                    settingsRow(icon: "message.fill", title: "Contact Us", subtitle: "Get in touch", color: DesignTokens.Colors.primaryCyan)
                    Divider().opacity(0.5)
                    settingsRow(icon: "star.fill", title: "Rate App", subtitle: "Share your feedback", color: DesignTokens.Colors.primaryAmber)
                }
            }
            .padding(.vertical, 20)
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
    
    // MARK: - Helper Functions
    
    
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

