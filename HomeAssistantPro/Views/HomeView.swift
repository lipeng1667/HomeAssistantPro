//
//  HomeView.swift
//  HomeAssistantPro
//
//  Purpose: Modern home dashboard with 2025 iOS design aesthetics
//  Author: Michael
//  Updated: 2025-06-25
//
//  Features: Glassmorphism cards, dynamic gradients, smooth animations,
//  floating elements, and contemporary visual hierarchy.
//

import SwiftUI

/// Modern home view with contemporary design aesthetics
struct HomeView: View {
    @State private var animateCards = false
    @State private var featuredCardOffset: CGFloat = 0
    @State private var tipCardScale: CGFloat = 1.0
    @State private var backgroundAnimation = false
    
    var body: some View {
        ZStack {
            // Dynamic background
            backgroundView
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 28) {
                    // Header section
                    headerSection
                        .padding(.top, 60)
                    
                    // Featured case card
                    featuredCaseCard
                        .scaleEffect(animateCards ? 1.0 : 0.95)
                        .opacity(animateCards ? 1.0 : 0.8)
                        .offset(y: featuredCardOffset)
                    
                    // Daily tips card
                    dailyTipsCard
                        .scaleEffect(tipCardScale)
                        .opacity(animateCards ? 1.0 : 0.8)
                    
                    // Bottom padding for tab bar
                    Spacer()
                        .frame(height: 120)
                }
                .padding(.horizontal, 24)
            }
            .refreshable {
                await refreshContent()
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(hex: "#FAFAFA"),
                    Color(hex: "#F8FAFC"),
                    Color(hex: "#F1F5F9")
                ],
                startPoint: backgroundAnimation ? .topLeading : .bottomTrailing,
                endPoint: backgroundAnimation ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            
            // Floating ambient elements
            floatingElements
        }
        .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: backgroundAnimation)
    }
    
    private var floatingElements: some View {
        ZStack {
            // Purple accent orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#8B5CF6").opacity(0.12), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .offset(x: -60, y: -150)
                .blur(radius: 40)
            
            // Cyan accent orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#06B6D4").opacity(0.08), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .offset(x: 100, y: 200)
                .blur(radius: 30)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("HOME")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.primary.opacity(0.6))
                .tracking(2)
            
            VStack(spacing: 6) {
                Text("Welcome back")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Discover smart solutions for your home")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Featured Case Card
    
    private var featuredCaseCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Featured Case")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Trending design")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#8B5CF6"))
                }
                
                Spacer()
                
                Button(action: {
                    // Navigate to full case study
                }) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            // Main card content
            ZStack(alignment: .bottomLeading) {
                // Card background
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .frame(height: 220)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)
                
                // Background pattern
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#8B5CF6").opacity(0.1),
                                Color(hex: "#06B6D4").opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 220)
                
                // Icon container
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#8B5CF6").opacity(0.2), Color(hex: "#06B6D4").opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .blur(radius: 20)
                            
                            Image(systemName: "house.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(Color(hex: "#8B5CF6"))
                        }
                        Spacer()
                    }
                    Spacer()
                }
                
                // Content overlay
                VStack(alignment: .leading, spacing: 8) {
                    Text("Modern Smart Home Design")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("A sleek, minimalist design with integrated smart lighting and security systems for the modern lifestyle.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary.opacity(0.7))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .padding(4)
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
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Tips")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Smart living advice")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#F59E0B"))
                }
                
                Spacer()
                
                Button(action: {
                    // Show more tips
                }) {
                    Text("More")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#F59E0B"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(hex: "#F59E0B").opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(Color(hex: "#F59E0B").opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            // Tip card
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    // Tip category
                    HStack {
                        Text("💡")
                            .font(.system(size: 16))
                        
                        Text("Energy Saving")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#F59E0B"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "#F59E0B").opacity(0.15))
                            )
                    }
                    
                    // Tip content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Turn off lights in unoccupied rooms")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Small actions can lead to significant savings on your energy bill. Make it a habit to switch off lights when leaving a room.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary.opacity(0.7))
                            .lineLimit(3)
                    }
                }
                
                Spacer()
                
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#F59E0B").opacity(0.15), Color(hex: "#F59E0B").opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#F59E0B").opacity(0.2), lineWidth: 1)
                        )
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(Color(hex: "#F59E0B"))
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 8)
            )
        }
        .padding(4)
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
        
        withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
            backgroundAnimation.toggle()
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
