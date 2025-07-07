//
//  HomeView.swift
//  HomeAssistantPro
//
//  Created: March 3, 2025
//  Last Modified: June 26, 2025
//  Author: Michael Lee
//  Version: 2.0.0
//
//  Purpose: Home dashboard featuring curated smart home case studies
//  and daily tips with modern iOS 2025 design aesthetics including
//  glassmorphism effects and responsive layouts.
//
//  Update History:
//  v1.0.0 (March 3, 2025) - Initial creation with basic dashboard layout
//  v1.5.0 (June 25, 2025) - Added glassmorphism cards and standardized components
//  v2.0.0 (June 26, 2025) - Implemented responsive typography and dark mode colors
//
//  Features:
//  - Featured case card with interactive animations
//  - Daily tips section with energy saving advice
//  - Responsive spacing for different device sizes
//  - Adaptive colors for light and dark modes
//  - Smooth card interactions with haptic feedback
//

import SwiftUI
import AVFoundation

/// Modern home view with contemporary design aesthetics
struct HomeView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var animateCards = false
    @State private var featuredCardOffset: CGFloat = 0
    @State private var tipCardScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Standardized background
            StandardTabBackground(configuration: .home)
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: DesignTokens.ResponsiveSpacing.sectionSpacing) {
                    // Standardized header
                    StandardTabHeader(configuration: .home())
                    
                    // Featured case card
                    featuredCaseCard
                        .scaleEffect(animateCards ? 1.0 : 0.95)
                        .opacity(animateCards ? 1.0 : 0.8)
                        .offset(y: featuredCardOffset)
                        .responsiveHorizontalPadding(16, 20, 24)
                    
                    // Daily tips card
                    dailyTipsCard
                        .scaleEffect(tipCardScale)
                        .opacity(animateCards ? 1.0 : 0.8)
                        .responsiveHorizontalPadding(16, 20, 24)
                    
                    // Bottom padding for tab bar
                    Spacer()
                        .frame(height: DesignTokens.DeviceSize.current.spacing(80, 100, 120))
                }
            }
            .refreshable {
                await refreshContent()
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    
    
    // MARK: - Featured Case Card
    
    private var featuredCaseCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.DeviceSize.current.spacing(16, 18, 20)) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.DeviceSize.current.spacing(3, 4, 5)) {
                    Text(LocalizedKeys.homeFeaturedCase.localized)
                        .font(DesignTokens.ResponsiveTypography.headingMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text(LocalizedKeys.homeTrendingDesign.localized)
                        .font(DesignTokens.ResponsiveTypography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.primaryPurple)
                }
                
                Spacer()
                
                Button(action: {
                    // Navigate to full case study
                }) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: DesignTokens.DeviceSize.current.fontSize(14, 16, 18), weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .frame(
                            width: DesignTokens.DeviceSize.current.spacing(28, 32, 36),
                            height: DesignTokens.DeviceSize.current.spacing(28, 32, 36)
                        )
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .stroke(DesignTokens.Colors.borderSecondary, lineWidth: 1)
                                )
                        )
                }
                .scaleButtonStyle()
            }
            
            // Hybrid video card (70% video, 30% content)
            VStack(spacing: 0) {
                // Video section (70% of total height) - Only top corners rounded
                VideoPlayerView(
                    asset: .smartHomeDemo,
                    cornerRadius: 0 // Remove internal corner radius
                )
                .frame(height: DesignTokens.DeviceSize.current.spacing(126, 140, 154))
                .clipShape(
                    TopRoundedRectangle(
                        topLeadingRadius: DesignTokens.DeviceSize.current.spacing(20, 22, 24),
                        topTrailingRadius: DesignTokens.DeviceSize.current.spacing(20, 22, 24)
                    )
                )
                
                // Content section (30% of total height)
                VStack(alignment: .leading, spacing: DesignTokens.DeviceSize.current.spacing(6, 8, 10)) {
                    Text(LocalizedKeys.homeSmartHomeDesign.localized)
                        .font(DesignTokens.ResponsiveTypography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("A sleek, minimalist design with integrated smart lighting and security systems for the modern lifestyle.")
                        .font(DesignTokens.ResponsiveTypography.bodySmall)
                        .foregroundColor(.primary.opacity(0.7))
                        .lineLimit(DesignTokens.DeviceSize.current.isSmallDevice ? 1 : 2)
                        .multilineTextAlignment(.leading)
                }
                .padding(DesignTokens.DeviceSize.current.spacing(16, 18, 20))
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: DesignTokens.DeviceSize.current.spacing(54, 60, 66)) // 30% of 180/200/220
                .background(
                    BottomRoundedRectangle(
                        bottomLeadingRadius: DesignTokens.DeviceSize.current.spacing(20, 22, 24),
                        bottomTrailingRadius: DesignTokens.DeviceSize.current.spacing(20, 22, 24)
                    )
                    .fill(.ultraThinMaterial)
                    .overlay(
                        BottomRoundedRectangle(
                            bottomLeadingRadius: DesignTokens.DeviceSize.current.spacing(20, 22, 24),
                            bottomTrailingRadius: DesignTokens.DeviceSize.current.spacing(20, 22, 24)
                        )
                        .stroke(DesignTokens.Colors.borderPrimary, lineWidth: 1)
                    )
                )
            }
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.DeviceSize.current.spacing(20, 22, 24))
                    .fill(.ultraThinMaterial)
                    .shadow(color: DesignTokens.Shadow.strong.color, radius: DesignTokens.Shadow.strong.radius, x: DesignTokens.Shadow.strong.x, y: DesignTokens.Shadow.strong.y)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.DeviceSize.current.spacing(20, 22, 24)))
        }
        .responsivePadding(6, 8, 10)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                featuredCardOffset = -5
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    featuredCardOffset = 0
                }
            }
        }
    }
    
    // MARK: - Daily Tips Card
    
    private var dailyTipsCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.DeviceSize.current.spacing(16, 18, 20)) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.DeviceSize.current.spacing(3, 4, 5)) {
                    Text("Daily Tips")
                        .font(DesignTokens.ResponsiveTypography.headingMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("Smart living advice")
                        .font(DesignTokens.ResponsiveTypography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.primaryAmber)
                }
                
                Spacer()
                
                Button(action: {
                    // Show more tips
                }) {
                    Text("More")
                        .font(DesignTokens.ResponsiveTypography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.primaryAmber)
                        .padding(.horizontal, DesignTokens.DeviceSize.current.spacing(14, 16, 18))
                        .padding(.vertical, DesignTokens.DeviceSize.current.spacing(6, 8, 10))
                        .background(
                            Capsule()
                                .fill(DesignTokens.Colors.primaryAmber.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(DesignTokens.Colors.primaryAmber.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .scaleButtonStyle()
            }
            
            // Tip card
            HStack(spacing: DesignTokens.DeviceSize.current.spacing(16, 20, 24)) {
                VStack(alignment: .leading, spacing: DesignTokens.DeviceSize.current.spacing(10, 12, 14)) {
                    // Tip category
                    HStack {
                        Text("💡")
                            .font(.system(size: DesignTokens.DeviceSize.current.fontSize(14, 16, 18)))
                        
                        Text("Energy Saving")
                            .font(.system(size: DesignTokens.DeviceSize.current.fontSize(11, 12, 13), weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.primaryAmber)
                            .padding(.horizontal, DesignTokens.DeviceSize.current.spacing(10, 12, 14))
                            .padding(.vertical, DesignTokens.DeviceSize.current.spacing(3, 4, 5))
                            .background(
                                Capsule()
                                    .fill(DesignTokens.Colors.primaryAmber.opacity(0.15))
                            )
                    }
                    
                    // Tip content
                    VStack(alignment: .leading, spacing: DesignTokens.DeviceSize.current.spacing(6, 8, 10)) {
                        Text("Turn off lights in unoccupied rooms")
                            .font(DesignTokens.ResponsiveTypography.bodyLarge)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Text("Small actions can lead to significant savings on your energy bill. Make it a habit to switch off lights when leaving a room.")
                            .font(DesignTokens.ResponsiveTypography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .lineLimit(DesignTokens.DeviceSize.current.isSmallDevice ? 2 : 3)
                    }
                }
                
                Spacer()
                
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.DeviceSize.current.spacing(16, 20, 24))
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.Colors.primaryAmber.opacity(0.15), DesignTokens.Colors.primaryAmber.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(
                            width: DesignTokens.DeviceSize.current.spacing(80, 90, 100),
                            height: DesignTokens.DeviceSize.current.spacing(80, 90, 100)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.DeviceSize.current.spacing(16, 20, 24))
                                .stroke(DesignTokens.Colors.primaryAmber.opacity(0.2), lineWidth: 1)
                        )
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: DesignTokens.DeviceSize.current.fontSize(28, 32, 36), weight: .medium))
                        .foregroundColor(DesignTokens.Colors.primaryAmber)
                }
            }
            .padding(DesignTokens.ResponsiveSpacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.DeviceSize.current.spacing(20, 22, 24))
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.DeviceSize.current.spacing(20, 22, 24))
                            .stroke(DesignTokens.Colors.borderPrimary, lineWidth: 1)
                    )
                    .shadow(color: DesignTokens.Shadow.strong.color, radius: DesignTokens.Shadow.strong.radius, x: DesignTokens.Shadow.strong.x, y: DesignTokens.Shadow.strong.y)
            )
        }
        .responsivePadding(6, 8, 10)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                tipCardScale = 0.98
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    tipCardScale = 1.0
                }
            }
        }
    }
    
    // MARK: - Actions & Animations
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
            animateCards = true
        }
        
    }
    
    private func refreshContent() async {
        // Simulate content refresh
        await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                continuation.resume()
            }
        }
    }
}

// MARK: - Custom Shapes

/// Custom shape for selective corner rounding (top corners only)
struct TopRoundedRectangle: Shape {
    let topLeadingRadius: CGFloat
    let topTrailingRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.size.width
        let height = rect.size.height
        
        // Start from bottom left
        path.move(to: CGPoint(x: 0, y: height))
        
        // Left edge to top left corner
        path.addLine(to: CGPoint(x: 0, y: topLeadingRadius))
        
        // Top left corner curve
        path.addArc(
            center: CGPoint(x: topLeadingRadius, y: topLeadingRadius),
            radius: topLeadingRadius,
            startAngle: Angle(degrees: 180),
            endAngle: Angle(degrees: 270),
            clockwise: false
        )
        
        // Top edge to top right corner
        path.addLine(to: CGPoint(x: width - topTrailingRadius, y: 0))
        
        // Top right corner curve
        path.addArc(
            center: CGPoint(x: width - topTrailingRadius, y: topTrailingRadius),
            radius: topTrailingRadius,
            startAngle: Angle(degrees: 270),
            endAngle: Angle(degrees: 0),
            clockwise: false
        )
        
        // Right edge to bottom right (straight corner)
        path.addLine(to: CGPoint(x: width, y: height))
        
        // Bottom edge back to start
        path.addLine(to: CGPoint(x: 0, y: height))
        
        return path
    }
}

/// Custom shape for selective corner rounding (bottom corners only)
struct BottomRoundedRectangle: Shape {
    let bottomLeadingRadius: CGFloat
    let bottomTrailingRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.size.width
        let height = rect.size.height
        
        // Start from top left (straight corner)
        path.move(to: CGPoint(x: 0, y: 0))
        
        // Top edge to top right (straight corner)
        path.addLine(to: CGPoint(x: width, y: 0))
        
        // Right edge to bottom right corner
        path.addLine(to: CGPoint(x: width, y: height - bottomTrailingRadius))
        
        // Bottom right corner curve
        path.addArc(
            center: CGPoint(x: width - bottomTrailingRadius, y: height - bottomTrailingRadius),
            radius: bottomTrailingRadius,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: 90),
            clockwise: false
        )
        
        // Bottom edge to bottom left corner
        path.addLine(to: CGPoint(x: bottomLeadingRadius, y: height))
        
        // Bottom left corner curve
        path.addArc(
            center: CGPoint(x: bottomLeadingRadius, y: height - bottomLeadingRadius),
            radius: bottomLeadingRadius,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 180),
            clockwise: false
        )
        
        // Left edge back to start
        path.addLine(to: CGPoint(x: 0, y: 0))
        
        return path
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(AppViewModel())
}
