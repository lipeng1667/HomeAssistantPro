//
//  ForumView.swift
//  HomeAssistantPro
//
//  Purpose: Modern forum community with 2025 iOS design aesthetics
//  Author: Michael
//  Updated: 2025-06-25
//
//  Features: Glassmorphism search, floating cards, smooth animations,
//  dynamic interactions, and contemporary visual hierarchy.
//

import SwiftUI

/// Modern forum view with contemporary design aesthetics
struct ForumView: View {
    @State private var searchText = ""
    @State private var selectedTopic: Topic? = nil
    @State private var animateCards = false
    @State private var searchFocused = false
    @State private var showCreatePost = false
    @State private var showCreateMenu = false
    @StateObject private var draftManager = DraftManager.shared
    
    // Sample topics data
    let topics = [
        Topic(id: 1, title: "How to connect my smart thermostat to HomeKit?", comments: 23, likes: 156, avatar: "person.crop.circle.fill", category: "Smart Home", timeAgo: "2h ago", isHot: true),
        Topic(id: 2, title: "Best smart lighting setup for beginners", comments: 45, likes: 203, avatar: "person.crop.circle.fill", category: "Lighting", timeAgo: "4h ago", isHot: false),
        Topic(id: 3, title: "Security camera recommendations for outdoor use", comments: 67, likes: 89, avatar: "person.crop.circle.fill", category: "Security", timeAgo: "1d ago", isHot: true),
        Topic(id: 4, title: "Smart speakers comparison: Alexa vs Google vs Siri", comments: 102, likes: 334, avatar: "person.crop.circle.fill", category: "Voice Control", timeAgo: "2d ago", isHot: false),
        Topic(id: 5, title: "DIY smart home automation on a budget", comments: 78, likes: 245, avatar: "person.crop.circle.fill", category: "DIY", timeAgo: "3d ago", isHot: true)
    ]
    
    var filteredTopics: [Topic] {
        if searchText.isEmpty {
            return topics
        } else {
            return topics.filter { $0.title.lowercased().contains(searchText.lowercased()) || $0.category.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Standardized background
                StandardTabBackground(configuration: .forum)
                
                VStack(spacing: 0) {
                    // Enhanced header with contextual menu
                    enhancedHeader
                    
                    // Search bar
                    searchSection
                        .padding(.horizontal, DesignTokens.ResponsiveSpacing.lg)
                        .padding(.bottom, 16)
                    
                    // Topics list
                    topicsListSection
                }
            }
            .navigationBarHidden(true)
        }
        .dismissKeyboardOnSwipeDown()
        .onAppear {
            startAnimations()
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView()
        }
        .confirmationDialog("Create Post", isPresented: $showCreateMenu, titleVisibility: .visible) {
            Button("New Topic") {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showCreatePost = true
                }
            }
            
            if draftManager.currentDraft != nil {
                Button("Continue Draft") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showCreatePost = true
                    }
                }
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            if let draft = draftManager.currentDraft {
                Text("You have an unfinished draft from \(formatDraftDate(draft.lastModified))")
            } else {
                Text("Choose how you'd like to contribute to the community")
            }
        }
    }
    
    
    // MARK: - Enhanced Header
    
    private var enhancedHeader: some View {
        HStack(alignment: .center) {
            // Left section
            VStack(alignment: .leading, spacing: DesignTokens.ResponsiveSpacing.xs) {
                Text("COMMUNITY")
                    .font(DesignTokens.ResponsiveTypography.caption)
                    .foregroundColor(DesignTokens.Colors.Forum.primary)
                    .tracking(1.5)
                
                Text("Forum")
                    .font(DesignTokens.ResponsiveTypography.headingLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            
            Spacer()
            
            // Right action button with contextual menu
            Button(action: {
                HapticManager.buttonTap()
                if draftManager.currentDraft != nil {
                    showCreateMenu = true
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showCreatePost = true
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(
                            width: DesignTokens.DeviceSize.current.spacing(44, 48, 52),
                            height: DesignTokens.DeviceSize.current.spacing(44, 48, 52)
                        )
                        .overlay(
                            Circle()
                                .stroke(DesignTokens.Colors.Forum.primary.opacity(0.3), lineWidth: 1)
                        )
                        .standardShadowLight()
                    
                    // Show draft indicator if available
                    if draftManager.currentDraft != nil {
                        VStack(spacing: 2) {
                            Image(systemName: "doc.text")
                                .font(.system(size: DesignTokens.DeviceSize.current.fontSize(12, 14, 16), weight: .semibold))
                                .foregroundColor(DesignTokens.Colors.Forum.primary)
                            
                            Circle()
                                .fill(DesignTokens.Colors.primaryAmber)
                                .frame(width: 6, height: 6)
                        }
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: DesignTokens.DeviceSize.current.fontSize(16, 18, 20), weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.Forum.primary)
                    }
                }
            }
            .scaleButtonStyle()
            .contextMenu {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showCreatePost = true
                    }
                } label: {
                    Label("New Topic", systemImage: "plus.bubble")
                }
                
                if draftManager.currentDraft != nil {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showCreatePost = true
                        }
                    } label: {
                        Label("Continue Draft", systemImage: "doc.text")
                    }
                    
                    Button(role: .destructive) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            draftManager.clearDraft()
                        }
                        HapticManager.buttonTap()
                    } label: {
                        Label("Delete Draft", systemImage: "trash")
                    }
                }
            }
        }
        .responsiveHorizontalPadding(20, 24, 28)
        .responsiveVerticalPadding(16, 20, 24)
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        HStack(spacing: 16) {
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(searchFocused ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textSecondary)
                
                TextField("Search topics, categories...", text: $searchText)
                    .font(.system(size: 16, weight: .medium))
                    .textFieldStyle(PlainTextFieldStyle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            searchFocused = true
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            searchText = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary.opacity(0.4))
                    }
                    .scaleButtonStyle()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(searchFocused ? DesignTokens.Colors.primaryCyan.opacity(0.5) : DesignTokens.Colors.borderPrimary, lineWidth: searchFocused ? 2 : 1)
                    )
                    .shadow(color: DesignTokens.Shadow.light.color, radius: DesignTokens.Shadow.light.radius, x: DesignTokens.Shadow.light.x, y: DesignTokens.Shadow.light.y)
            )
            .scaleEffect(searchFocused ? 1.02 : 1.0)
            
            // Filter button
            Button(action: {
                // Show filter options
            }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                    )
            }
            .scaleButtonStyle()
        }
    }
    
    // MARK: - Topics List Section
    
    private var topicsListSection: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(Array(filteredTopics.enumerated()), id: \.element.id) { index, topic in
                    topicCard(topic: topic, index: index)
                        .scaleEffect(animateCards ? 1.0 : 0.95)
                        .opacity(animateCards ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateCards)
                }
                
                // Bottom padding for tab bar
                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Topic Card
    
    @ViewBuilder
    private func topicCard(topic: Topic, index: Int) -> some View {
        Button(action: {
            // Navigate to topic detail
            selectedTopic = topic
        }) {
            HStack(spacing: 16) {
                // Avatar with status indicator
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.Colors.primaryCyan.opacity(0.2), DesignTokens.Colors.primaryGreen.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: topic.avatar)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.primaryCyan)
                        )
                    
                    if topic.isHot {
                        Circle()
                            .fill(DesignTokens.Colors.primaryAmber)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: DesignTokens.Colors.primaryAmber.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Category and time
                    HStack {
                        Text(topic.category)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.primaryCyan)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(DesignTokens.Colors.primaryCyan.opacity(0.15))
                            )
                        
                        Spacer()
                        
                        Text(topic.timeAgo)
                            .font(DesignTokens.Typography.captionSmall)
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                    }
                    
                    // Title
                    Text(topic.title)
                        .font(DesignTokens.ResponsiveTypography.bodyLarge)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    // Stats
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary.opacity(0.6))
                            
                            Text("\(topic.comments)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.primaryAmber)
                            
                            Text("\(topic.likes)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary.opacity(0.4))
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(DesignTokens.Colors.borderPrimary, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
            )
        }
        .cardButtonStyle()
    }
    
    // MARK: - Actions & Animations
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
            animateCards = true
        }
    }
    
    /// Format draft date for display in confirmation dialog
    /// - Parameter date: Draft creation/modification date
    /// - Returns: Formatted relative date string
    private func formatDraftDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Topic Model

struct Topic: Identifiable {
    let id: Int
    let title: String
    let comments: Int
    let likes: Int
    let avatar: String
    let category: String
    let timeAgo: String
    let isHot: Bool
}


// MARK: - Preview

#Preview {
    ForumView()
        .environmentObject(AppViewModel())
}

