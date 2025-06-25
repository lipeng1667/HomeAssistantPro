//
//  StandardTabBackground.swift
//  HomeAssistantPro
//
//  Purpose: Reusable animated background component for consistent tab view styling
//  Author: Michael
//  Updated: 2025-06-25
//
//  Features: Animated gradients, floating orbs, customizable colors,
//  modern iOS 2025 design consistency across all tab views.
//

import SwiftUI

/// Standardized animated background for tab views with floating orbs
struct StandardTabBackground: View {
    let configuration: BackgroundConfiguration
    @State private var animateGradient = false
    @State private var animateOrbs = false
    
    var body: some View {
        ZStack {
            // Base animated gradient
            animatedGradient
            
            // Floating orbs for visual depth
            floatingOrbs
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Animated Gradient
    
    private var animatedGradient: some View {
        LinearGradient(
            colors: configuration.gradientColors,
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .animation(
            .easeInOut(duration: configuration.gradientAnimationDuration)
                .repeatForever(autoreverses: true),
            value: animateGradient
        )
    }
    
    // MARK: - Floating Orbs
    
    private var floatingOrbs: some View {
        ZStack {
            ForEach(Array(configuration.orbs.enumerated()), id: \.offset) { index, orb in
                orbView(orb: orb, index: index)
            }
        }
        .animation(
            .easeInOut(duration: configuration.orbAnimationDuration)
                .repeatForever(autoreverses: true),
            value: animateOrbs
        )
    }
    
    @ViewBuilder
    private func orbView(orb: OrbConfiguration, index: Int) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [orb.color.opacity(orb.opacity), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: orb.radius
                )
            )
            .frame(width: orb.size, height: orb.size)
            .offset(
                x: animateOrbs ? orb.animatedOffset.x : orb.initialOffset.x,
                y: animateOrbs ? orb.animatedOffset.y : orb.initialOffset.y
            )
            .blur(radius: orb.blurRadius)
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: configuration.gradientAnimationDuration).repeatForever(autoreverses: true)) {
            animateGradient = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + configuration.orbAnimationDelay) {
            withAnimation(.easeInOut(duration: configuration.orbAnimationDuration).repeatForever(autoreverses: true)) {
                animateOrbs = true
            }
        }
    }
}

// MARK: - Configuration Models

struct BackgroundConfiguration {
    let gradientColors: [Color]
    let gradientAnimationDuration: Double
    let orbs: [OrbConfiguration]
    let orbAnimationDuration: Double
    let orbAnimationDelay: Double
    
    init(
        gradientColors: [Color] = [
            Color(hex: "#FAFAFA"),
            Color(hex: "#F8FAFC"),
            Color(hex: "#F1F5F9")
        ],
        gradientAnimationDuration: Double = 4.0,
        orbs: [OrbConfiguration] = [],
        orbAnimationDuration: Double = 6.0,
        orbAnimationDelay: Double = 0.5
    ) {
        self.gradientColors = gradientColors
        self.gradientAnimationDuration = gradientAnimationDuration
        self.orbs = orbs
        self.orbAnimationDuration = orbAnimationDuration
        self.orbAnimationDelay = orbAnimationDelay
    }
}

struct OrbConfiguration {
    let color: Color
    let opacity: Double
    let size: CGFloat
    let radius: CGFloat
    let blurRadius: CGFloat
    let initialOffset: CGPoint
    let animatedOffset: CGPoint
    
    init(
        color: Color,
        opacity: Double = 0.12,
        size: CGFloat = 240,
        radius: CGFloat = 120,
        blurRadius: CGFloat = 40,
        initialOffset: CGPoint,
        animatedOffset: CGPoint
    ) {
        self.color = color
        self.opacity = opacity
        self.size = size
        self.radius = radius
        self.blurRadius = blurRadius
        self.initialOffset = initialOffset
        self.animatedOffset = animatedOffset
    }
}

// MARK: - Preset Configurations

extension BackgroundConfiguration {
    // Standard background used across most views
    static let standard = BackgroundConfiguration(
        orbs: [
            OrbConfiguration(
                color: Color(hex: "#8B5CF6"),
                opacity: 0.12,
                size: 240,
                radius: 120,
                blurRadius: 40,
                initialOffset: CGPoint(x: -80, y: -150),
                animatedOffset: CGPoint(x: -60, y: -120)
            ),
            OrbConfiguration(
                color: Color(hex: "#06B6D4"),
                opacity: 0.08,
                size: 160,
                radius: 80,
                blurRadius: 30,
                initialOffset: CGPoint(x: 100, y: 200),
                animatedOffset: CGPoint(x: 120, y: 180)
            )
        ]
    )
    
    // Home view specific background
    static let home = BackgroundConfiguration(
        orbs: [
            OrbConfiguration(
                color: Color(hex: "#8B5CF6"),
                opacity: 0.12,
                size: 240,
                radius: 120,
                blurRadius: 40,
                initialOffset: CGPoint(x: -60, y: -150),
                animatedOffset: CGPoint(x: -80, y: -120)
            ),
            OrbConfiguration(
                color: Color(hex: "#06B6D4"),
                opacity: 0.08,
                size: 160,
                radius: 80,
                blurRadius: 30,
                initialOffset: CGPoint(x: 100, y: 200),
                animatedOffset: CGPoint(x: 120, y: 220)
            )
        ]
    )
    
    // Forum view specific background
    static let forum = BackgroundConfiguration(
        orbs: [
            OrbConfiguration(
                color: Color(hex: "#06B6D4"),
                opacity: 0.12,
                size: 240,
                radius: 120,
                blurRadius: 40,
                initialOffset: CGPoint(x: -80, y: -120),
                animatedOffset: CGPoint(x: -100, y: -100)
            ),
            OrbConfiguration(
                color: Color(hex: "#10B981"),
                opacity: 0.08,
                size: 160,
                radius: 80,
                blurRadius: 30,
                initialOffset: CGPoint(x: 120, y: 180),
                animatedOffset: CGPoint(x: 140, y: 200)
            )
        ]
    )
    
    // Chat view specific background
    static let chat = BackgroundConfiguration(
        orbs: [
            OrbConfiguration(
                color: Color(hex: "#10B981"),
                opacity: 0.1,
                size: 300,
                radius: 150,
                blurRadius: 30,
                initialOffset: CGPoint(x: -100, y: -150),
                animatedOffset: CGPoint(x: -80, y: -120)
            ),
            OrbConfiguration(
                color: Color(hex: "#8B5CF6"),
                opacity: 0.08,
                size: 250,
                radius: 120,
                blurRadius: 25,
                initialOffset: CGPoint(x: 120, y: 100),
                animatedOffset: CGPoint(x: 140, y: 120)
            )
        ]
    )
    
    // Settings view with dynamic color support
    static func settings(primaryColor: Color) -> BackgroundConfiguration {
        BackgroundConfiguration(
            gradientColors: [
                Color(hex: "#FAFAFA"),
                Color(hex: "#F4F4F5"),
                Color(hex: "#E4E4E7")
            ],
            orbs: [
                OrbConfiguration(
                    color: primaryColor,
                    opacity: 0.2,
                    size: 350,
                    radius: 200,
                    blurRadius: 40,
                    initialOffset: CGPoint(x: -100, y: -80),
                    animatedOffset: CGPoint(x: -60, y: -120)
                ),
                OrbConfiguration(
                    color: Color(hex: "#06B6D4"),
                    opacity: 0.15,
                    size: 240,
                    radius: 120,
                    blurRadius: 30,
                    initialOffset: CGPoint(x: 100, y: 220),
                    animatedOffset: CGPoint(x: 140, y: 180)
                ),
                OrbConfiguration(
                    color: Color(hex: "#10B981"),
                    opacity: 0.1,
                    size: 160,
                    radius: 80,
                    blurRadius: 25,
                    initialOffset: CGPoint(x: -120, y: 280),
                    animatedOffset: CGPoint(x: -140, y: 300)
                )
            ]
        )
    }
    
    // Login view specific background
    static let login = BackgroundConfiguration(
        gradientColors: [
            Color(hex: "#F8FAFC"),
            Color(hex: "#E2E8F0"),
            Color(hex: "#CBD5E1")
        ],
        gradientAnimationDuration: 3.0,
        orbs: [
            OrbConfiguration(
                color: Color(hex: "#8B5CF6"),
                opacity: 0.1,
                size: 400,
                radius: 200,
                blurRadius: 20,
                initialOffset: CGPoint(x: -100, y: -200),
                animatedOffset: CGPoint(x: -80, y: -180)
            ),
            OrbConfiguration(
                color: Color(hex: "#06B6D4"),
                opacity: 0.08,
                size: 300,
                radius: 150,
                blurRadius: 15,
                initialOffset: CGPoint(x: 150, y: 300),
                animatedOffset: CGPoint(x: 130, y: 280)
            )
        ]
    )
}