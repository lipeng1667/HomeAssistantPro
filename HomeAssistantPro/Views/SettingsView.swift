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
    @State private var animateGradient = false
    @State private var animateOrbs = false
    @State private var isEditingProfile = false
    @State private var selectedProfileColor: Color = Color(hex: "#8B5CF6")
    @FocusState private var isFieldFocused: Bool
    @Namespace private var profileTransition
    
    // Profile color options matching MainTabView palette
    private let profileColors: [Color] = [
        Color(hex: "#8B5CF6"), // Purple
        Color(hex: "#06B6D4"), // Cyan
        Color(hex: "#10B981"), // Green
        Color(hex: "#F59E0B"), // Amber
        Color(hex: "#EF4444"), // Red
        Color(hex: "#8B5CF6")  // Purple variant
    ]
    
    var body: some View {
        ZStack {
            // Dynamic animated background
            dynamicBackground
            
            // Floating visual orbs
            floatingOrbs
            
            // Main content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    headerView
                    profileSection
                    accountSection
                    settingsSection
                    preferencesSection
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)
                .padding(.bottom, 120) // Extra space for floating tab bar
            }
        }
        .onAppear {
            startAnimations()
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
    
    // MARK: - Dynamic Background
    
    private var dynamicBackground: some View {
        ZStack {
            // Base animated gradient
            LinearGradient(
                colors: [
                    Color(hex: "#FAFAFA"),
                    Color(hex: "#F4F4F5"),
                    Color(hex: "#E4E4E7")
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateGradient)
        }
    }
    
    private var floatingOrbs: some View {
        ZStack {
            // Primary orb with profile color
            Circle()
                .fill(
                    RadialGradient(
                        colors: [selectedProfileColor.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 350, height: 350)
                .offset(
                    x: animateOrbs ? -60 : -100,
                    y: animateOrbs ? -120 : -80
                )
                .blur(radius: 40)
            
            // Secondary orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#06B6D4").opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .offset(
                    x: animateOrbs ? 140 : 100,
                    y: animateOrbs ? 180 : 220
                )
                .blur(radius: 30)
            
            // Accent orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#10B981").opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .offset(
                    x: animateOrbs ? -140 : -120,
                    y: animateOrbs ? 300 : 280
                )
                .blur(radius: 25)
        }
        .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animateOrbs)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Personalize your experience")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Profile color picker button
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isEditingProfile.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [selectedProfileColor, selectedProfileColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: selectedProfileColor.opacity(0.4), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(EnhancedButtonStyle())
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        EnhancedGlassCard {
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
                    actionButton(title: "Share", icon: "square.and.arrow.up", color: Color(hex: "#06B6D4"))
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
                .buttonStyle(EnhancedButtonStyle())
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
        EnhancedGlassCard {
            VStack(alignment: .leading, spacing: 24) {
                sectionHeader(title: "Account", icon: "person.crop.circle")
                
                VStack(spacing: 20) {
                    accountRow(icon: "phone.fill", title: "Phone Number", value: "+1 (555) 123-4567", color: Color(hex: "#10B981"))
                    Divider().opacity(0.5)
                    accountRow(icon: "envelope.fill", title: "Email", value: "ethan.carter@email.com", color: Color(hex: "#06B6D4"))
                    Divider().opacity(0.5)
                    accountRow(icon: "lock.fill", title: "Password", value: "••••••••", color: Color(hex: "#F59E0B"))
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
        EnhancedGlassCard {
            VStack(alignment: .leading, spacing: 24) {
                sectionHeader(title: "Preferences", icon: "gearshape.fill")
                
                VStack(spacing: 20) {
                    settingsRow(icon: "bell.fill", title: "Notifications", subtitle: "Push, email, SMS", color: Color(hex: "#EF4444"))
                    Divider().opacity(0.5)
                    settingsRow(icon: "moon.fill", title: "Dark Mode", subtitle: "System", color: Color(hex: "#6366F1"))
                    Divider().opacity(0.5)
                    settingsRow(icon: "globe", title: "Language", subtitle: "English", color: Color(hex: "#8B5CF6"))
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        EnhancedGlassCard {
            VStack(alignment: .leading, spacing: 24) {
                sectionHeader(title: "Support", icon: "questionmark.circle.fill")
                
                VStack(spacing: 20) {
                    settingsRow(icon: "headphones", title: "Help Center", subtitle: "FAQs and guides", color: Color(hex: "#10B981"))
                    Divider().opacity(0.5)
                    settingsRow(icon: "message.fill", title: "Contact Us", subtitle: "Get in touch", color: Color(hex: "#06B6D4"))
                    Divider().opacity(0.5)
                    settingsRow(icon: "star.fill", title: "Rate App", subtitle: "Share your feedback", color: Color(hex: "#F59E0B"))
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
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            animateGradient = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animateOrbs = true
            }
        }
    }
    
    private func cycleProfileColor() {
        guard let currentIndex = profileColors.firstIndex(of: selectedProfileColor) else { return }
        let nextIndex = (currentIndex + 1) % profileColors.count
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            selectedProfileColor = profileColors[nextIndex]
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Enhanced Glass Card

struct EnhancedGlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Enhanced Button Style

struct EnhancedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
