//
//  MainTabView.swift
//  HomeAssistantPro
//
//  Purpose: Modern tab navigation with 2025 iOS design aesthetics and keyboard-responsive behavior
//  Author: Michael
//  Updated: 2025-06-25
//
//  Features: Custom tab bar design, dynamic island-inspired styling,
//  glassmorphism effects, smooth animations, and keyboard-responsive tab bar.
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
    @State private var animateBackground = false
    @Namespace private var tabTransition
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case forum = "Forum"
        case chat = "Chat"
        case settings = "Settings"
        
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
            case .home: return Color(hex: "#8B5CF6")
            case .forum: return Color(hex: "#06B6D4")
            case .chat: return Color(hex: "#10B981")
            case .settings: return Color(hex: "#F59E0B")
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
            
            // Custom tab bar with keyboard-responsive behavior
            if tabBarVisibility.isTabBarVisible {
                customTabBar
                    .padding(.horizontal, 20)
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
                Color(hex: "#F8FAFC"),
                Color(hex: "#F1F5F9"),
                Color(hex: "#E2E8F0")
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
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        case .forum:
            ForumView()
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        case .chat:
            ChatView()
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        case .settings:
            SettingsView()
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
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
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
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
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
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
                        .foregroundColor(selectedTab == tab ? .white : .primary.opacity(0.6))
                        .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                }
                .frame(height: 40)
                
                // Tab label
                Text(tab.rawValue)
                    .font(.system(size: selectedTab == tab ? 12 : 11, weight: .medium))
                    .foregroundColor(selectedTab == tab ? tab.activeColor : .primary.opacity(0.6))
                    .scaleEffect(selectedTab == tab ? 1.05 : 1.0)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabBarButtonStyle())
        .accessibilityLabel("\(tab.rawValue) tab")
        .accessibilityHint("Tap to switch to \(tab.rawValue) section")
    }
    
    // MARK: - Actions
    
    private func selectTab(_ tab: Tab) {
        guard selectedTab != tab else { return }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        // Animate tab change
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            selectedTab = tab
        }
    }
    
    private func startBackgroundAnimation() {
        animateBackground.toggle()
    }
}

// MARK: - Custom Button Style

struct TabBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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
                    Color(hex: "#FAFAFA"),
                    Color(hex: "#F4F4F5"),
                    Color(hex: "#E4E4E7")
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
                        colors: [Color(hex: "#8B5CF6").opacity(0.1), Color.clear],
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
                .shadow(color: Color.black.opacity(0.1), radius: 25, x: 0, y: 12)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
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
                    .foregroundColor(selectedTab == tab ? .white : .primary.opacity(0.7))
                
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
        .buttonStyle(TabBarButtonStyle())
        .accessibilityLabel(tab.rawValue)
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
