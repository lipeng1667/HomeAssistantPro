//
//  AnimationPresets.swift
//  HomeAssistantPro
//
//  Purpose: Centralized animation presets for consistent timing and feel
//  Author: Michael
//  Updated: 2025-06-25
//
//  Features: Standard animation configurations, spring presets, 
//  easing functions, and specialized animations used throughout the app.
//

import SwiftUI

/// Centralized animation presets for consistent motion design
struct AnimationPresets {
    
    // MARK: - Spring Animations
    
    /// Standard spring animation for most UI interactions
    static let standardSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
    
    /// Quick spring animation for fast interactions
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    /// Gentle spring animation for subtle movements
    static let gentleSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    
    /// Bouncy spring animation for playful interactions
    static let bouncySpring = Animation.spring(response: 0.5, dampingFraction: 0.6)
    
    /// Smooth spring animation for elegant transitions
    static let smoothSpring = Animation.spring(response: 0.8, dampingFraction: 0.9)
    
    /// Strong spring animation for prominent actions
    static let strongSpring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    /// Fluid spring animation for natural movement
    static let fluidSpring = Animation.spring(response: 0.7, dampingFraction: 0.75)
    
    // MARK: - Easing Animations
    
    /// Fast ease-in-out for quick interactions
    static let fastEase = Animation.easeInOut(duration: 0.1)
    
    /// Standard ease-in-out for normal interactions
    static let standardEase = Animation.easeInOut(duration: 0.2)
    
    /// Smooth ease-in-out for transitions
    static let smoothEase = Animation.easeInOut(duration: 0.3)
    
    /// Slow ease-in-out for deliberate actions
    static let slowEase = Animation.easeInOut(duration: 0.5)
    
    /// Extra slow ease for background elements
    static let extraSlowEase = Animation.easeInOut(duration: 1.0)
    
    // MARK: - Linear Animations
    
    /// Quick linear animation
    static let quickLinear = Animation.linear(duration: 0.1)
    
    /// Standard linear animation
    static let standardLinear = Animation.linear(duration: 0.2)
    
    /// Smooth linear animation
    static let smoothLinear = Animation.linear(duration: 0.3)
    
    // MARK: - Custom Timing Curves
    
    /// Ease-out animation for appearing elements
    static let easeOut = Animation.timingCurve(0.25, 0.46, 0.45, 0.94, duration: 0.3)
    
    /// Ease-in animation for disappearing elements
    static let easeIn = Animation.timingCurve(0.55, 0.06, 0.68, 0.19, duration: 0.3)
    
    /// Anticipation animation with slight overshoot
    static let anticipation = Animation.timingCurve(0.68, -0.55, 0.265, 1.55, duration: 0.4)
    
    /// Overshoot animation for elastic feel
    static let overshoot = Animation.timingCurve(0.175, 0.885, 0.32, 1.275, duration: 0.4)
    
    // MARK: - Specialized Animations
    
    /// Button press animation
    static let buttonPress = quickSpring
    
    /// Tab selection animation
    static let tabSelection = standardSpring
    
    /// Card animation
    static let card = gentleSpring
    
    /// Modal presentation animation
    static let modalPresent = smoothSpring
    
    /// Modal dismissal animation
    static let modalDismiss = standardSpring
    
    /// Sheet presentation animation
    static let sheetPresent = fluidSpring
    
    /// Sheet dismissal animation
    static let sheetDismiss = quickSpring
    
    /// Navigation transition animation
    static let navigation = standardSpring
    
    /// Page transition animation
    static let pageTransition = smoothSpring
    
    /// Loading animation
    static let loading = standardLinear
    
    /// Progress animation
    static let progress = smoothLinear
    
    /// Typing indicator animation
    static let typingIndicator = Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)
    
    /// Pulse animation
    static let pulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    
    /// Breathing animation
    static let breathing = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    
    /// Shimmer animation
    static let shimmer = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
    
    // MARK: - Background Animations
    
    /// Slow background gradient animation
    static let backgroundGradient = Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true)
    
    /// Background orb animation
    static let backgroundOrb = Animation.easeInOut(duration: 6.0).repeatForever(autoreverses: true)
    
    /// Floating element animation
    static let floating = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)
    
    // MARK: - Form Animations
    
    /// Form field focus animation
    static let fieldFocus = standardSpring
    
    /// Form validation animation
    static let validation = quickSpring
    
    /// Form submission animation
    static let submission = smoothSpring
    
    /// Form error animation
    static let formError = strongSpring
    
    // MARK: - List Animations
    
    /// List item insertion animation
    static let listInsert = standardSpring
    
    /// List item deletion animation
    static let listDelete = quickSpring
    
    /// List item reorder animation
    static let listReorder = smoothSpring
    
    /// List refresh animation
    static let listRefresh = fluidSpring
    
    // MARK: - Search Animations
    
    /// Search bar focus animation
    static let searchFocus = standardSpring
    
    /// Search results animation
    static let searchResults = gentleSpring
    
    /// Search clear animation
    static let searchClear = quickSpring
    
    // MARK: - Color Animations
    
    /// Color change animation
    static let colorChange = smoothSpring
    
    /// Theme change animation
    static let themeChange = smoothEase
    
    /// Color picker animation
    static let colorPicker = standardSpring
    
    // MARK: - Keyboard Animations
    
    /// Keyboard appear animation
    static let keyboardAppear = Animation.easeInOut(duration: 0.3)
    
    /// Keyboard dismiss animation
    static let keyboardDismiss = Animation.easeInOut(duration: 0.3)
    
    // MARK: - Custom Animation Builders
    
    /// Create a delayed animation
    static func delayed(_ animation: Animation, delay: TimeInterval) -> Animation {
        animation.delay(delay)
    }
    
    /// Create a repeating animation
    static func repeating(_ animation: Animation, count: Int) -> Animation {
        animation.repeatCount(count, autoreverses: true)
    }
    
    /// Create an infinite repeating animation
    static func infiniteRepeating(_ animation: Animation, autoreverses: Bool = true) -> Animation {
        animation.repeatForever(autoreverses: autoreverses)
    }
    
    /// Create a spring animation with custom parameters
    static func customSpring(
        response: Double = 0.6,
        dampingFraction: Double = 0.8,
        blendDuration: Double = 0
    ) -> Animation {
        Animation.spring(
            response: response,
            dampingFraction: dampingFraction,
            blendDuration: blendDuration
        )
    }
    
    /// Create an ease animation with custom duration
    static func customEase(duration: Double) -> Animation {
        Animation.easeInOut(duration: duration)
    }
    
    /// Create a timing curve animation
    static func customTimingCurve(
        _ c0x: Double, _ c0y: Double,
        _ c1x: Double, _ c1y: Double,
        duration: Double = 0.3
    ) -> Animation {
        Animation.timingCurve(c0x, c0y, c1x, c1y, duration: duration)
    }
}

// MARK: - Animation Sequences

extension AnimationPresets {
    
    /// Multi-step animation for complex interactions
    struct Sequence {
        
        /// Login success sequence
        static func loginSuccess() {
            withAnimation(AnimationPresets.quickSpring) {
                // First step: scale down
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AnimationPresets.smoothSpring) {
                    // Second step: transition
                }
            }
        }
        
        /// Card flip sequence
        static func cardFlip(completion: @escaping () -> Void) {
            withAnimation(AnimationPresets.quickSpring) {
                // First half of flip
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                completion()
                withAnimation(AnimationPresets.quickSpring) {
                    // Second half of flip
                }
            }
        }
        
        /// Staggered list animation
        static func staggeredList(items: Int, delay: TimeInterval = 0.1) {
            for index in 0..<items {
                DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(index) * delay) {
                    withAnimation(AnimationPresets.standardSpring) {
                        // Animate each item
                    }
                }
            }
        }
        
        /// Loading complete sequence
        static func loadingComplete() {
            withAnimation(AnimationPresets.quickSpring) {
                // Stop loading
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AnimationPresets.standardSpring) {
                    // Show content
                }
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply standard animation
    func standardAnimation(value: some Equatable) -> some View {
        self.animation(AnimationPresets.standardSpring, value: value)
    }
    
    /// Apply quick animation
    func quickAnimation(value: some Equatable) -> some View {
        self.animation(AnimationPresets.quickSpring, value: value)
    }
    
    /// Apply smooth animation
    func smoothAnimation(value: some Equatable) -> some View {
        self.animation(AnimationPresets.smoothSpring, value: value)
    }
    
    /// Apply gentle animation
    func gentleAnimation(value: some Equatable) -> some View {
        self.animation(AnimationPresets.gentleSpring, value: value)
    }
    
    /// Apply bouncy animation
    func bouncyAnimation(value: some Equatable) -> some View {
        self.animation(AnimationPresets.bouncySpring, value: value)
    }
    
    /// Apply card animation
    func cardAnimation(value: some Equatable) -> some View {
        self.animation(AnimationPresets.card, value: value)
    }
    
    /// Apply button press animation
    func buttonPressAnimation(value: some Equatable) -> some View {
        self.animation(AnimationPresets.buttonPress, value: value)
    }
    
    /// Apply tab selection animation
    func tabSelectionAnimation(value: some Equatable) -> some View {
        self.animation(AnimationPresets.tabSelection, value: value)
    }
}