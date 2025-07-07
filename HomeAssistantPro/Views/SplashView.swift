//
//  SplashView.swift
//  HomeAssistantPro
//
//  Purpose: Modern splash screen with glassmorphism design and floating animations
//  Author: Michael
//  Created: 2025-07-05
//  Modified: 2025-07-05
//
//  Modification Log:
//  - 2025-07-05: Initial creation with glassmorphism design, floating orbs, and smooth animations
//
//  Functions:
//  - startAnimations(): Initiates the splash screen animation sequence
//  - animateOut(): Handles the exit animation when transitioning to main app
//

import SwiftUI
import os.log

/// Modern splash screen with glassmorphism design and floating animations
/// Provides a delightful first impression with smooth transitions
struct SplashView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var backgroundOpacity: Double = 0
    @State private var orb1Offset: CGFloat = 0
    @State private var orb2Offset: CGFloat = 0
    @State private var orb3Offset: CGFloat = 0
    @State private var showContent: Bool = false
    
    /// Callback when splash screen completes
    let onComplete: () -> Void
    
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "SplashView")
    
    var body: some View {
        ZStack {
            // Background with floating orbs
            backgroundView
            
            // Main content
            contentView
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
        }
    }
    
    /// Background with animated gradient and floating orbs
    private var backgroundView: some View {
        ZStack {
            // Base gradient background
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: DesignTokens.Colors.backgroundPrimary, location: 0.0),
                    .init(color: DesignTokens.Colors.backgroundSecondary, location: 0.4),
                    .init(color: DesignTokens.Colors.backgroundTertiary, location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Floating orbs with glassmorphism effect
            floatingOrbs
        }
        .opacity(backgroundOpacity)
    }
    
    /// Floating orbs with glassmorphism design
    private var floatingOrbs: some View {
        ZStack {
            // Primary orb (top right)
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            DesignTokens.Colors.primaryPurple.opacity(0.6),
                            DesignTokens.Colors.primaryCyan.opacity(0.3),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: DesignTokens.DeviceSize.current.spacing(16, 18, 20),
                        endRadius: DesignTokens.DeviceSize.current.spacing(96, 108, 120)
                    )
                )
                .frame(
                    width: DesignTokens.DeviceSize.current.spacing(160, 180, 200),
                    height: DesignTokens.DeviceSize.current.spacing(160, 180, 200)
                )
                .blur(radius: DesignTokens.DeviceSize.current.spacing(16, 18, 20))
                .offset(
                    x: DesignTokens.DeviceSize.current.spacing(80, 90, 100) + orb1Offset,
                    y: DesignTokens.DeviceSize.current.spacing(-120, -135, -150) + orb1Offset * 0.5
                )
            
            // Secondary orb (bottom left)
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            DesignTokens.Colors.primaryGreen.opacity(0.5),
                            DesignTokens.Colors.primaryCyan.opacity(0.3),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: DesignTokens.DeviceSize.current.spacing(24, 27, 30),
                        endRadius: DesignTokens.DeviceSize.current.spacing(80, 90, 100)
                    )
                )
                .frame(
                    width: DesignTokens.DeviceSize.current.spacing(128, 144, 160),
                    height: DesignTokens.DeviceSize.current.spacing(128, 144, 160)
                )
                .blur(radius: DesignTokens.DeviceSize.current.spacing(12, 13.5, 15))
                .offset(
                    x: DesignTokens.DeviceSize.current.spacing(-96, -108, -120) + orb2Offset,
                    y: DesignTokens.DeviceSize.current.spacing(160, 180, 200) + orb2Offset * 0.3
                )
            
            // Accent orb (center background)
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            DesignTokens.Colors.primaryAmber.opacity(0.4),
                            DesignTokens.Colors.primaryPurple.opacity(0.2),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: DesignTokens.DeviceSize.current.spacing(32, 36, 40),
                        endRadius: DesignTokens.DeviceSize.current.spacing(112, 126, 140)
                    )
                )
                .frame(
                    width: DesignTokens.DeviceSize.current.spacing(192, 216, 240),
                    height: DesignTokens.DeviceSize.current.spacing(192, 216, 240)
                )
                .blur(radius: DesignTokens.DeviceSize.current.spacing(20, 22.5, 25))
                .offset(x: orb3Offset, y: orb3Offset * 0.4)
        }
    }
    
    /// Main content with logo and title
    private var contentView: some View {
        VStack(spacing: DesignTokens.DeviceSize.current.spacing(20, 22, 24)) {
            // App logo with glassmorphism container
            logoView
            
            // App title and subtitle
            titleView
        }
        .opacity(showContent ? 1 : 0)
    }
    
    /// App logo with glassmorphism effect
    private var logoView: some View {
        ZStack {
            // Glassmorphism background
            RoundedRectangle(cornerRadius: DesignTokens.DeviceSize.current.spacing(24, 26, 28))
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            DesignTokens.Colors.backgroundSurface.opacity(0.25),
                            DesignTokens.Colors.backgroundElevated.opacity(0.15)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.DeviceSize.current.spacing(24, 26, 28))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    DesignTokens.Colors.borderPrimary.opacity(0.3),
                                    DesignTokens.Colors.borderSecondary.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .blur(radius: 1)
                .frame(
                    width: DesignTokens.DeviceSize.current.spacing(96, 108, 120),
                    height: DesignTokens.DeviceSize.current.spacing(96, 108, 120)
                )
            
            // App icon/logo
            Image(systemName: "house.fill")
                .font(.system(size: DesignTokens.DeviceSize.current.fontSize(40, 45, 50), weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            DesignTokens.Colors.primaryPurple,
                            DesignTokens.Colors.primaryCyan
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: DesignTokens.Colors.primaryPurple.opacity(0.3),
                    radius: DesignTokens.DeviceSize.current.spacing(8, 9, 10),
                    x: 0,
                    y: DesignTokens.DeviceSize.current.spacing(4, 4.5, 5)
                )
        }
        .scaleEffect(logoScale)
        .opacity(logoOpacity)
    }
    
    /// App title and subtitle text
    private var titleView: some View {
        VStack(spacing: DesignTokens.DeviceSize.current.spacing(6, 7, 8)) {
            // Main title
            Text("HomeAssistant Pro")
                .font(DesignTokens.ResponsiveTypography.headingLarge)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            DesignTokens.Colors.textPrimary,
                            DesignTokens.Colors.textSecondary
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .multilineTextAlignment(.center)
            
            // Subtitle
            Text("Smart Home Excellence")
                .font(DesignTokens.ResponsiveTypography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .offset(y: titleOffset)
        .opacity(titleOpacity)
    }
    
    /// Initiates the splash screen animation sequence
    /// Coordinates background, logo, and title animations with proper timing
    private func startAnimations() {
        logger.info("Starting splash screen animations")
        
        // Haptic feedback for app launch
        HapticManager.soft()
        
        // Background fade in
        withAnimation(.easeOut(duration: 0.6)) {
            backgroundOpacity = 1.0
        }
        
        // Floating orbs animation
        withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
            orb1Offset = DesignTokens.DeviceSize.current.spacing(16, 18, 20)
            orb2Offset = DesignTokens.DeviceSize.current.spacing(-12, -13.5, -15)
            orb3Offset = DesignTokens.DeviceSize.current.spacing(8, 9, 10)
        }
        
        // Logo animation (starts after background)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0)) {
                logoScale = 1.0
                logoOpacity = 1.0
                showContent = true
            }
            
            // Haptic feedback for logo appearance
            HapticManager.medium()
        }
        
        // Title animation (starts after logo)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
        }
        
        // Auto-transition after display duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            animateOut()
        }
    }
    
    /// Handles the exit animation when transitioning to main app
    /// Provides smooth transition with scale and fade effects
    private func animateOut() {
        logger.info("Completing splash screen transition")
        
        // Exit animation
        withAnimation(.easeIn(duration: 0.4)) {
            logoScale = 0.8
            logoOpacity = 0
            titleOpacity = 0
            backgroundOpacity = 0
        }
        
        // Haptic feedback for transition
        HapticManager.navigate()
        
        // Complete callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onComplete()
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView {
        print("Splash completed")
    }
}
