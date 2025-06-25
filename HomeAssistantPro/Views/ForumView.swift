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
    @State private var backgroundAnimation = false
    @State private var showCreatePost = false
    
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
        ZStack {
            // Dynamic background
            backgroundView
            
            VStack(spacing: 0) {
                // Header section
                headerSection
                    .padding(.top, 60)
                
                // Search bar
                searchSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                
                // Topics list
                topicsListSection
            }
        }
        .onAppear {
            startAnimations()
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView()
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
            // Cyan accent orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#06B6D4").opacity(0.12), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .offset(x: -80, y: -120)
                .blur(radius: 40)
            
            // Green accent orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#10B981").opacity(0.08), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .offset(x: 120, y: 180)
                .blur(radius: 30)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("COMMUNITY")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary.opacity(0.6))
                    .tracking(2)
                
                Text("Forum")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Create post button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showCreatePost = true
                }
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#06B6D4"), Color(hex: "#06B6D4").opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: Color(hex: "#06B6D4").opacity(0.4), radius: 12, x: 0, y: 6)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        HStack(spacing: 16) {
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary.opacity(searchFocused ? 0.8 : 0.5))
                
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
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(searchFocused ? Color(hex: "#06B6D4").opacity(0.5) : Color.white.opacity(0.4), lineWidth: searchFocused ? 2 : 1)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
            )
            .scaleEffect(searchFocused ? 1.02 : 1.0)
            
            // Filter button
            Button(action: {
                // Show filter options
            }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary.opacity(0.7))
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
            .buttonStyle(ScaleButtonStyle())
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
                                colors: [Color(hex: "#06B6D4").opacity(0.2), Color(hex: "#10B981").opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: topic.avatar)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(Color(hex: "#06B6D4"))
                        )
                    
                    if topic.isHot {
                        Circle()
                            .fill(Color(hex: "#F59E0B"))
                            .frame(width: 16, height: 16)
                            .overlay(
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: Color(hex: "#F59E0B").opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Category and time
                    HStack {
                        Text(topic.category)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#06B6D4"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "#06B6D4").opacity(0.15))
                            )
                        
                        Spacer()
                        
                        Text(topic.timeAgo)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary.opacity(0.5))
                    }
                    
                    // Title
                    Text(topic.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
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
                                .foregroundColor(.primary.opacity(0.7))
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "#F59E0B"))
                            
                            Text("\(topic.likes)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary.opacity(0.7))
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
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
            )
        }
        .buttonStyle(CardButtonStyle())
    }
    
    // MARK: - Actions & Animations
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
            animateCards = true
        }
        
        withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
            backgroundAnimation.toggle()
        }
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

// MARK: - Create Post View

struct CreatePostView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var postTitle = ""
    @State private var postContent = ""
    @State private var selectedCategory = "General"
    
    let categories = ["General", "Smart Home", "Lighting", "Security", "Voice Control", "DIY"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(hex: "#FAFAFA"),
                        Color(hex: "#F8FAFC")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create New Post")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Share your question or insight with the community")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 20) {
                        // Category picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Category")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(categories, id: \.self) { category in
                                        Button(action: {
                                            selectedCategory = category
                                        }) {
                                            Text(category)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(selectedCategory == category ? .white : .primary.opacity(0.7))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(
                                                    Capsule()
                                                        .fill(selectedCategory == category ? Color(hex: "#06B6D4") : Color.clear)
                                                        .overlay(
                                                            Capsule()
                                                                .stroke(selectedCategory == category ? Color.clear : Color.primary.opacity(0.2), lineWidth: 1)
                                                        )
                                                )
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        // Title input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Title")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            TextField("Enter your post title...", text: $postTitle)
                                .font(.system(size: 16, weight: .medium))
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                        )
                                )
                        }
                        .padding(.horizontal, 24)
                        
                        // Content input - Fixed for iOS compatibility
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Content")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            // Use TextEditor for multiline text input (available in iOS 14+)
                            TextEditor(text: $postContent)
                                .font(.system(size: 16, weight: .medium))
                                .padding(12)
                                .frame(minHeight: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                        )
                                )
                                .overlay(
                                    // Placeholder text for TextEditor
                                    Group {
                                        if postContent.isEmpty {
                                            VStack {
                                                HStack {
                                                    Text("Write your post content...")
                                                        .font(.system(size: 16, weight: .medium))
                                                        .foregroundColor(.primary.opacity(0.4))
                                                        .padding(.horizontal, 16)
                                                        .padding(.top, 20)
                                                    Spacer()
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                )
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: {
                            // Create post logic
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Post")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "#06B6D4"), Color(hex: "#06B6D4").opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color(hex: "#06B6D4").opacity(0.4), radius: 8, x: 0, y: 4)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(postTitle.isEmpty || postContent.isEmpty)
                        .opacity(postTitle.isEmpty || postContent.isEmpty ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Custom Button Styles

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
