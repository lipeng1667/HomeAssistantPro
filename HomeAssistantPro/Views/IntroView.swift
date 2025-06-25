//
//  IntroView.swift
//  HomeAssistantPro
//
//  Purpose: Modern onboarding intro with dynamic backgrounds, floating orbs, glassmorphism effects,
//  and contemporary 2025 iOS design aesthetics matching MainTabView design language
//  Author: Michael
//  Updated: 2025-06-25
//
//  Features: Dynamic animated backgrounds, floating orbs, enhanced glassmorphism,
//  smooth page transitions, interactive elements, and modern onboarding flow.
//

import SwiftUI

/// Enhanced onboarding intro view with MainTabView design consistency
struct IntroView: View {
    @State private var currentPage = 0
    @State private var animateBackground = false
    @State private var animateOrbs = false
    @State private var showContent = false
    @State private var dragOffset: CGFloat = 0
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var settingsStore: SettingsStore
    @Namespace private var pageTransition
    
    // Enhanced onboarding pages with colors and icons
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "house.fill",
            title: "Welcome to\nAuraHome",
            description: "Discover smart home inspiration and daily tips with our beautiful, intuitive interface.",
            primaryColor: Color(hex: "#8B5CF6"),
            secondaryColor: Color(hex: "#A78BFA")
        ),
        OnboardingPage(
            icon: "people.fill",
            title: "Join the\nCommunity",
            description: "Engage with other users, ask questions, and share experiences in our vibrant community.",
            primaryColor: Color(hex: "#06B6D4"),
            secondaryColor: Color(hex: "#22D3EE")
        ),
        OnboardingPage(
            icon: "message.fill",
            title: "Get Support\nInstantly",
            description: "Chat directly with our technical team for help anytime, anywhere, instantly.",
            primaryColor: Color(hex: "#10B981"),
            secondaryColor: Color(hex: "#34D399")
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic animated background
                dynamicBackground(for: geometry)
                
                // Floating visual orbs
                floatingOrbs(for: geometry)
                
                // Main content
                if showContent {
                    mainContent(for: geometry)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.8)),
                            removal: .opacity
                        ))
                }
                
                // Page indicators and navigation
                VStack {
                    Spacer()
                    bottomControls
                        .padding(.bottom, 50)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let threshold: CGFloat = 50
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        if value.translation.width > threshold && currentPage > 0 {
                            currentPage -= 1
                        } else if value.translation.width < -threshold && currentPage < pages.count - 1 {
                            currentPage += 1
                        }
                        dragOffset = 0
                    }
                }
        )
    }
    
    // MARK: - Dynamic Background
    
    private func dynamicBackground(for geometry: GeometryProxy) -> some View {
        let currentPageData = pages[currentPage]
        
        return ZStack {
            // Base animated gradient
            LinearGradient(
                colors: [
                    Color(hex: "#FAFAFA"),
                    currentPageData.primaryColor.opacity(0.1),
                    currentPageData.secondaryColor.opacity(0.05)
                ],
                startPoint: animateBackground ? .topLeading : .bottomTrailing,
                endPoint: animateBackground ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.0), value: currentPage)
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateBackground)
        }
    }
    
    private func floatingOrbs(for geometry: GeometryProxy) -> some View {
        let currentPageData = pages[currentPage]
        
        return ZStack {
            // Primary orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [currentPageData.primaryColor.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 250
                    )
                )
                .frame(width: 400, height: 400)
                .offset(
                    x: animateOrbs ? -80 : -120,
                    y: animateOrbs ? -150 : -100
                )
                .blur(radius: 50)
            
            // Secondary orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [currentPageData.secondaryColor.opacity(0.25), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 300, height: 300)
                .offset(
                    x: animateOrbs ? 120 : 160,
                    y: animateOrbs ? 200 : 160
                )
                .blur(radius: 40)
            
            // Accent orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .offset(
                    x: animateOrbs ? -100 : -80,
                    y: animateOrbs ? 400 : 380
                )
                .blur(radius: 30)
        }
        .animation(.easeInOut(duration: 1.2), value: currentPage)
        .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateOrbs)
    }
    
    // MARK: - Main Content
    
    private func mainContent(for geometry: GeometryProxy) -> some View {
        TabView(selection: $currentPage) {
            ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                pageContent(page: page, geometry: geometry)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentPage)
    }
    
    private func pageContent(page: OnboardingPage, geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: geometry.safeAreaInsets.top + 60)
            
            // Icon section
            iconSection(page: page)
            
            Spacer()
                .frame(height: 60)
            
            // Content section
            contentSection(page: page)
            
            Spacer()
                .frame(height: 80)
            
            // Action section (only on last page)
            if currentPage == pages.count - 1 {
                actionSection(page: page)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
            
            Spacer()
                .frame(height: 140)
        }
        .padding(.horizontal, 32)
        .offset(x: dragOffset * 0.1) // Subtle drag feedback
    }
    
    private func iconSection(page: OnboardingPage) -> some View {
        ZStack {
            // Background circle with glassmorphism
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 140, height: 140)
                .shadow(color: page.primaryColor.opacity(0.3), radius: 20, x: 0, y: 10)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                )
            
            // Gradient overlay
            Circle()
                .fill(
                    LinearGradient(
                        colors: [page.primaryColor.opacity(0.8), page.secondaryColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(color: page.primaryColor.opacity(0.4), radius: 15, x: 0, y: 8)
            
            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(.white)
        }
        .scaleEffect(showContent ? 1.0 : 0.5)
        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3), value: showContent)
    }
    
    private func contentSection(page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            // Title
            Text(page.title)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 30)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5), value: showContent)
            
            // Description in glass card
            Text(page.description)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                )
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 30)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.7), value: showContent)
        }
    }
    
    private func actionSection(page: OnboardingPage) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                settingsStore.setIntroShown()
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }) {
            HStack(spacing: 12) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [page.primaryColor, page.secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: page.primaryColor.opacity(0.4), radius: 15, x: 0, y: 8)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(EnhancedButtonStyle())
        .opacity(showContent ? 1.0 : 0.0)
        .offset(y: showContent ? 0 : 30)
        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.9), value: showContent)
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 24) {
            // Custom page indicators
            pageIndicators
            
            // Skip button (not on last page)
            if currentPage < pages.count - 1 {
                skipButton
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .move(edge: .bottom))
                    ))
            }
        }
        .padding(.horizontal, 32)
    }
    
    private var pageIndicators: some View {
        HStack(spacing: 12) {
            ForEach(0..<pages.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        currentPage = index
                    }
                }) {
                    Capsule()
                        .fill(
                            index == currentPage
                                ? LinearGradient(
                                    colors: [pages[currentPage].primaryColor, pages[currentPage].secondaryColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                                : LinearGradient(
                                    colors: [Color.primary.opacity(0.3), Color.primary.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                        )
                        .frame(
                            width: index == currentPage ? 32 : 8,
                            height: 8
                        )
                        .shadow(
                            color: index == currentPage ? pages[currentPage].primaryColor.opacity(0.4) : Color.clear,
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                }
                .buttonStyle(EnhancedButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
        )
    }
    
    private var skipButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                settingsStore.setIntroShown()
            }
        }) {
            Text("Skip")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary.opacity(0.7))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(EnhancedButtonStyle())
    }
    
    // MARK: - Helper Functions
    
    private func startAnimations() {
        // Start background animation
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            animateBackground = true
        }
        
        // Start orb animations with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animateOrbs = true
            }
        }
        
        // Show content with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                showContent = true
            }
        }
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let primaryColor: Color
    let secondaryColor: Color
}
