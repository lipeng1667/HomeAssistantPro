//
//  MainTabView.swift
//  HomeAssistantPro
//
//  Created: March 3, 2025
//  Last Modified: July 5, 2025
//  Author: Michael Lee
//  Version: 2.1.0
//
//  Purpose: Main tab navigation controller with custom tab bar design,
//  glassmorphism effects, and keyboard-responsive behavior. Features
//  modern iOS 2025 aesthetics with dark mode support.
//
//  Update History:
//  v1.0.0 (March 3, 2025) - Initial creation with basic tab navigation
//  v1.5.0 (June 25, 2025) - Added glassmorphism effects and custom tab bar
//  v2.0.0 (June 26, 2025) - Implemented dark mode support and responsive spacing
//  v2.1.0 (July 5, 2025) - Added swipe gesture support for tab navigation
//
//  Features:
//  - Custom glassmorphism tab bar with floating design
//  - Keyboard-responsive behavior with smooth animations
//  - Dynamic island-inspired styling and transitions
//  - Adaptive colors and spacing for all device sizes
//  - Haptic feedback integration for tab selection
//  - Swipe gesture support for tab navigation
//

import SwiftUI

// MARK: - Tab Bar Visibility Manager
class TabBarVisibilityManager: ObservableObject {
    @Published var isTabBarVisible: Bool = true
    
    func hideTabBar() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isTabBarVisible = false
        }
    }
    
    func showTabBar() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isTabBarVisible = true
        }
    }
}

/// Modern main tab view with contemporary design aesthetics
struct MainTabView: View {
    @StateObject private var tabBarVisibility = TabBarVisibilityManager()
    @State private var selectedTab: Tab = .home
    @State private var previousTab: Tab = .home
    @State private var isMovingForward: Bool = true
    @State private var animateBackground = false
    @Namespace private var tabTransition
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case forum = "Forum"
        case chat = "Chat"
        case settings = "Settings"
        
        var index: Int {
            switch self {
            case .home: return 0
            case .forum: return 1
            case .chat: return 2
            case .settings: return 3
            }
        }
        
        static func fromIndex(_ index: Int) -> Tab {
            let allCases = Tab.allCases
            guard index >= 0 && index < allCases.count else { return .home }
            return allCases[index]
        }
        
        var localizedTitle: String {
            switch self {
            case .home: return LocalizedKeys.tabHome.localized
            case .forum: return LocalizedKeys.tabForum.localized
            case .chat: return LocalizedKeys.tabChat.localized
            case .settings: return LocalizedKeys.tabSettings.localized
            }
        }
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .forum: return "rectangle.on.rectangle.angled"
            case .chat: return "bubble.left.and.bubble.right.fill"
            case .settings: return "person.circle.fill"
            }
        }
        
        var activeColor: Color {
            switch self {
            case .home: return DesignTokens.Colors.primaryPurple
            case .forum: return DesignTokens.Colors.primaryCyan
            case .chat: return DesignTokens.Colors.primaryGreen
            case .settings: return DesignTokens.Colors.primaryAmber
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background with subtle animation
            backgroundView
            
            // Main content area
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .environmentObject(tabBarVisibility)
                .simultaneousGesture(swipeGesture)
            
            // Custom tab bar with keyboard-responsive behavior
            if tabBarVisibility.isTabBarVisible {
                customTabBar
                    .padding(.horizontal, DesignTokens.ResponsiveSpacing.xl)
                    .padding(.bottom, 34) // Safe area padding
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            startBackgroundAnimation()
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                DesignTokens.Colors.backgroundMediumLight,
                DesignTokens.Colors.backgroundMediumDark,
                DesignTokens.Colors.backgroundDark
            ],
            startPoint: animateBackground ? .topLeading : .bottomTrailing,
            endPoint: animateBackground ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateBackground)
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .home:
            HomeView()
                .transition(getTransition(for: .home))
        case .forum:
            ForumView()
                .transition(getTransition(for: .forum))
        case .chat:
            ChatView()
                .transition(getTransition(for: .chat))
        case .settings:
            SettingsView()
                .transition(getTransition(for: .settings))
        }
    }
    
    /// Gets the appropriate transition animation based on current navigation direction
    /// - Parameter tab: The target tab to transition to
    /// - Returns: AnyTransition configured for the direction of movement
    private func getTransition(for tab: Tab) -> AnyTransition {
        if isMovingForward {
            // Moving to next tab (left to right) - slide in from right
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        } else {
            // Moving to previous tab (right to left) - slide in from left
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }
    
    // MARK: - Custom Tab Bar
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabBarItem(for: tab)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(tabBarBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: DesignTokens.Shadow.strong.color, radius: DesignTokens.Shadow.strong.radius, x: DesignTokens.Shadow.strong.x, y: DesignTokens.Shadow.strong.y)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(DesignTokens.Colors.borderSecondary, lineWidth: 1)
        )
    }
    
    private var tabBarBackground: some View {
        ZStack {
            // Glass morphism effect
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
            
            // Subtle gradient overlay
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignTokens.Colors.backgroundSurface.opacity(0.3),
                            DesignTokens.Colors.backgroundSurface.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
    
    @ViewBuilder
    private func tabBarItem(for tab: Tab) -> some View {
        Button(action: {
            selectTab(tab)
        }) {
            VStack(spacing: 6) {
                ZStack {
                    // Active background indicator
                    if selectedTab == tab {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [tab.activeColor, tab.activeColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .shadow(color: tab.activeColor.opacity(0.4), radius: 8, x: 0, y: 4)
                            .matchedGeometryEffect(id: "activeTab", in: tabTransition)
                    }
                    
                    // Tab icon
                    Image(systemName: tab.icon)
                        .font(.system(size: selectedTab == tab ? 18 : 16, weight: .medium))
                        .foregroundColor(selectedTab == tab ? .white : DesignTokens.Colors.textSecondary)
                        .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                }
                .frame(height: 40)
                
                // Tab label
                Text(tab.localizedTitle)
                    .font(.system(size: selectedTab == tab ? 12 : 11, weight: .medium))
                    .foregroundColor(selectedTab == tab ? tab.activeColor : DesignTokens.Colors.textSecondary)
                    .scaleEffect(selectedTab == tab ? 1.05 : 1.0)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .tabBarButtonStyle()
        .accessibilityLabel("\(tab.localizedTitle) tab")
        .accessibilityHint("Tap to switch to \(tab.localizedTitle) section")
    }
    
    // MARK: - Gestures
    
    /// Swipe gesture for tab navigation
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onEnded { value in
                handleSwipeGesture(value)
            }
    }
    
    /// Handles swipe gesture for tab switching
    /// - Parameter value: The drag gesture value containing translation information
    private func handleSwipeGesture(_ value: DragGesture.Value) {
        let horizontalDistance = value.translation.width
        let verticalDistance = abs(value.translation.height)
        
        // Debug logging
        print("Swipe detected - H: \(horizontalDistance), V: \(verticalDistance), Current tab: \(selectedTab.rawValue)")
        
        // Only process horizontal swipes (ignore vertical scrolling)
        // Must be horizontal movement of at least 80px and predominantly horizontal
        guard abs(horizontalDistance) > 80 && abs(horizontalDistance) > verticalDistance * 1.5 else {
            print("Swipe ignored - not horizontal enough")
            return
        }
        
        let currentIndex = selectedTab.index
        
        if horizontalDistance > 0 {
            // Swipe right - go to previous tab
            let newIndex = max(0, currentIndex - 1)
            let newTab = Tab.fromIndex(newIndex)
            if newTab != selectedTab {
                selectTab(newTab)
            }
        } else {
            // Swipe left - go to next tab
            let newIndex = min(Tab.allCases.count - 1, currentIndex + 1)
            let newTab = Tab.fromIndex(newIndex)
            if newTab != selectedTab {
                selectTab(newTab)
            }
        }
    }
    
    // MARK: - Actions
    
    private func selectTab(_ tab: Tab) {
        guard selectedTab != tab else { return }
        
        // Calculate and store transition direction BEFORE animation
        isMovingForward = tab.index > selectedTab.index
        previousTab = selectedTab
        
        // Debug logging
        print("Tab transition: \(selectedTab.rawValue) → \(tab.rawValue), forward: \(isMovingForward)")
        
        // Haptic feedback
        HapticManager.tabSelection()
        
        // Animate tab change
        withAnimation(AnimationPresets.tabSelection) {
            selectedTab = tab
        }
    }
    
    private func startBackgroundAnimation() {
        animateBackground.toggle()
    }
}


// MARK: - Enhanced Tab Bar (Alternative Design)

struct EnhancedMainTabView: View {
    @StateObject private var tabBarVisibility = TabBarVisibilityManager()
    @State private var selectedTab: MainTabView.Tab = .home
    @State private var animateGradient = false
    @Namespace private var tabIndicator
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dynamic background
            dynamicBackground
            
            // Content
            contentArea
                .environmentObject(tabBarVisibility)
                .simultaneousGesture(enhancedSwipeGesture)
            
            // Floating tab bar with keyboard-responsive behavior
            if tabBarVisibility.isTabBarVisible {
                floatingTabBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
    
    private var dynamicBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    DesignTokens.Colors.backgroundPrimary,
                    DesignTokens.Colors.backgroundSecondary,
                    DesignTokens.Colors.backgroundTertiary
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            
            // Floating orbs for visual interest
            floatingOrbs
        }
    }
    
    private var floatingOrbs: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [selectedTab.activeColor.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: -80, y: -100)
                .blur(radius: 30)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [DesignTokens.Colors.primaryPurple.opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .offset(x: 120, y: 200)
                .blur(radius: 25)
        }
        .animation(.easeInOut(duration: 1.5), value: selectedTab)
    }
    
    @ViewBuilder
    private var contentArea: some View {
        switch selectedTab {
        case .home:
            HomeView()
        case .forum:
            ForumView()
        case .chat:
            ChatView()
        case .settings:
            SettingsView()
        }
    }
    
    private var floatingTabBar: some View {
        HStack(spacing: 8) {
            ForEach(MainTabView.Tab.allCases, id: \.self) { tab in
                floatingTabItem(tab)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: DesignTokens.Shadow.extraStrong.color, radius: DesignTokens.Shadow.extraStrong.radius, x: DesignTokens.Shadow.extraStrong.x, y: DesignTokens.Shadow.extraStrong.y)
                .overlay(
                    Capsule()
                        .stroke(DesignTokens.Colors.borderSecondary, lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func floatingTabItem(_ tab: MainTabView.Tab) -> some View {
        Button(action: {
            selectTab(tab)
        }) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(selectedTab == tab ? .white : DesignTokens.Colors.textSecondary)
                
                if selectedTab == tab {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, selectedTab == tab ? 20 : 16)
            .padding(.vertical, 12)
            .background(
                Group {
                    if selectedTab == tab {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [tab.activeColor, tab.activeColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: tab.activeColor.opacity(0.4), radius: 8, x: 0, y: 4)
                            .matchedGeometryEffect(id: "selectedTab", in: tabIndicator)
                    }
                }
            )
        }
        .tabBarButtonStyle()
        .accessibilityLabel(tab.rawValue)
    }
    
    /// Enhanced swipe gesture for tab navigation
    private var enhancedSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onEnded { value in
                handleEnhancedSwipeGesture(value)
            }
    }
    
    /// Handles swipe gesture for enhanced tab switching
    /// - Parameter value: The drag gesture value containing translation information
    private func handleEnhancedSwipeGesture(_ value: DragGesture.Value) {
        let horizontalDistance = value.translation.width
        let verticalDistance = abs(value.translation.height)
        
        // Only process horizontal swipes (ignore vertical scrolling)
        // Must be horizontal movement of at least 80px and predominantly horizontal
        guard abs(horizontalDistance) > 80 && abs(horizontalDistance) > verticalDistance * 1.5 else {
            return
        }
        
        let currentIndex = selectedTab.index
        
        if horizontalDistance > 0 {
            // Swipe right - go to previous tab
            let newIndex = max(0, currentIndex - 1)
            let newTab = MainTabView.Tab.fromIndex(newIndex)
            if newTab != selectedTab {
                selectTab(newTab)
            }
        } else {
            // Swipe left - go to next tab
            let newIndex = min(MainTabView.Tab.allCases.count - 1, currentIndex + 1)
            let newTab = MainTabView.Tab.fromIndex(newIndex)
            if newTab != selectedTab {
                selectTab(newTab)
            }
        }
    }
    
    private func selectTab(_ tab: MainTabView.Tab) {
        guard selectedTab != tab else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            selectedTab = tab
        }
    }
}
