//
//  ChatView.swift
//  HomeAssistantPro
//
//  Purpose: Modern chat interface with technical support featuring 2025 design aesthetics
//  Author: Michael
//  Updated: 2025-06-25
//
//  Features: Glassmorphism effects, smooth animations, dynamic typing indicators,
//  contemporary message bubbles with enhanced UX, and keyboard-responsive tab bar.
//

import SwiftUI

/// Modern chat view with sophisticated design and animations
struct ChatView: View {
    @State private var message: String = ""
    @State private var messages: [ChatMessage] = ChatMessage.sampleMessages
    @State private var isTyping = false
    @State private var animateBackground = false
    @State private var showEmojiPicker = false
    @State private var isKeyboardVisible = false
    @FocusState private var isMessageFieldFocused: Bool
    
    // Access the tab bar visibility manager from environment
    @EnvironmentObject var tabBarVisibility: TabBarVisibilityManager
    
    var body: some View {
        ZStack {
            // Animated background
            backgroundView
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Messages area
                messagesView
                
                // Input area
                inputView
                    .padding(.bottom, (!isKeyboardVisible && tabBarVisibility.isTabBarVisible) ? 100 : 0)
            }
        }
        .onAppear {
            startBackgroundAnimation()
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
        .onTapGesture {
            isMessageFieldFocused = false
        }
        .onChange(of: isMessageFieldFocused) { focused in
            if focused {
                // Hide tab bar when text field is focused
                tabBarVisibility.hideTabBar()
            } else {
                // Show tab bar when text field loses focus
                // Add a small delay to ensure smooth transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if !isKeyboardVisible {
                        tabBarVisibility.showTabBar()
                    }
                }
            }
        }
        .dismissKeyboardOnSwipeDown()
    }
    
    // MARK: - Keyboard Handling
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isKeyboardVisible = true
            }
            // Hide tab bar when keyboard appears
            tabBarVisibility.hideTabBar()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isKeyboardVisible = false
            }
            // Show tab bar when keyboard disappears
            tabBarVisibility.showTabBar()
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
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
        .overlay(
            // Floating orbs for visual depth
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "#10B981").opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(x: -100, y: -150)
                    .blur(radius: 30)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "#8B5CF6").opacity(0.08), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 250, height: 250)
                    .offset(x: 120, y: 100)
                    .blur(radius: 25)
            }
        )
        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateBackground)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                // Back button area (if needed)
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 44, height: 44)
                
                Spacer()
                
                // Title with support status
                VStack(spacing: 4) {
                    Text("Technical Support")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: "#10B981"))
                            .frame(width: 8, height: 8)
                            .scaleEffect(isTyping ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isTyping)
                        
                        Text("Support Agent Online")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Options button
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary.opacity(0.7))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // Divider
            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(height: 0.5)
                .padding(.horizontal, 20)
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Messages
    
    private var messagesView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(messages) { message in
                    MessageBubble(message: message)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
                
                // Typing indicator
                if isTyping {
                    TypingIndicator()
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.clear)
    }
    
    // MARK: - Input Area
    
    private var inputView: some View {
        VStack(spacing: 0) {
            // Input container
            HStack(spacing: 12) {
                // Attachment button
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#10B981"))
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Message input field
                HStack(spacing: 12) {
                    TextField("Type your message...", text: $message)
                        .focused($isMessageFieldFocused)
                        .font(.system(size: 16))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .onSubmit {
                            sendMessage()
                        }
                    
                    // Emoji button
                    Button(action: { showEmojiPicker.toggle() }) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 20))
                            .foregroundColor(.primary.opacity(0.6))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                // Send button
                Button(action: sendMessage) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: message.isEmpty ?
                                        [Color.primary.opacity(0.3), Color.primary.opacity(0.2)] :
                                        [Color(hex: "#10B981"), Color(hex: "#059669")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: message.isEmpty ? "mic.fill" : "arrow.up")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .scaleEffect(message.isEmpty ? 1.0 : 1.1)
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !message.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -2)
                    .ignoresSafeArea(.container, edges: .bottom)
            )
        }
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Add user message
        let newMessage = ChatMessage(
            id: UUID(),
            content: trimmedMessage,
            isFromUser: true,
            timestamp: Date()
        )
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            messages.append(newMessage)
            message = ""
        }
        
        // Dismiss keyboard after sending
        isMessageFieldFocused = false
        
        // Simulate typing response
        simulateTypingResponse()
    }
    
    private func simulateTypingResponse() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isTyping = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isTyping = false
            }
            
            let responses = [
                "I understand your concern. Let me help you with that.",
                "That's a great question! Here's what I recommend...",
                "I can definitely assist you with this issue.",
                "Thanks for the details. Let me walk you through the solution."
            ]
            
            let responseMessage = ChatMessage(
                id: UUID(),
                content: responses.randomElement() ?? "How else can I help you today?",
                isFromUser: false,
                timestamp: Date()
            )
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                messages.append(responseMessage)
            }
        }
    }
    
    private func startBackgroundAnimation() {
        animateBackground.toggle()
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 60)
                userMessageBubble
            } else {
                supportMessageBubble
                Spacer(minLength: 60)
            }
        }
    }
    
    private var userMessageBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(MessageBubbleShape(isFromUser: true))
                .shadow(color: Color(hex: "#10B981").opacity(0.3), radius: 8, x: 0, y: 4)
            
            Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.trailing, 4)
        }
    }
    
    private var supportMessageBubble: some View {
        HStack(alignment: .top, spacing: 12) {
            // Support avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#8B5CF6"), Color(hex: "#7C3AED")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: "headphones")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .shadow(color: Color(hex: "#8B5CF6").opacity(0.3), radius: 6, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Support Agent")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#8B5CF6"))
                
                Text(message.content)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .clipShape(MessageBubbleShape(isFromUser: false))
                
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animatePhase = 0
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Support avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#8B5CF6"), Color(hex: "#7C3AED")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: "headphones")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .shadow(color: Color(hex: "#8B5CF6").opacity(0.3), radius: 6, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Support Agent")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#8B5CF6"))
                
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.primary.opacity(0.4))
                            .frame(width: 6, height: 6)
                            .scaleEffect(animatePhase == index ? 1.3 : 1.0)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: animatePhase
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            
            Spacer(minLength: 60)
        }
        .onAppear {
            animatePhase = 0
        }
    }
}

// MARK: - Message Bubble Shape

struct MessageBubbleShape: Shape {
    let isFromUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailSize: CGFloat = 8
        
        var path = Path()
        
        if isFromUser {
            // User message bubble (right-aligned)
            path.move(to: CGPoint(x: radius, y: 0))
            path.addLine(to: CGPoint(x: rect.width - radius - tailSize, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: rect.width - tailSize, y: radius),
                control: CGPoint(x: rect.width - tailSize, y: 0)
            )
            path.addLine(to: CGPoint(x: rect.width - tailSize, y: rect.height - radius - tailSize))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width - tailSize - radius, y: rect.height - tailSize))
            path.addLine(to: CGPoint(x: radius, y: rect.height - tailSize))
            path.addQuadCurve(
                to: CGPoint(x: 0, y: rect.height - tailSize - radius),
                control: CGPoint(x: 0, y: rect.height - tailSize)
            )
            path.addLine(to: CGPoint(x: 0, y: radius))
            path.addQuadCurve(
                to: CGPoint(x: radius, y: 0),
                control: CGPoint(x: 0, y: 0)
            )
        } else {
            // Support message bubble (left-aligned)
            path.move(to: CGPoint(x: tailSize + radius, y: 0))
            path.addLine(to: CGPoint(x: rect.width - radius, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: radius),
                control: CGPoint(x: rect.width, y: 0)
            )
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.width - radius, y: rect.height),
                control: CGPoint(x: rect.width, y: rect.height)
            )
            path.addLine(to: CGPoint(x: tailSize + radius, y: rect.height))
            path.addQuadCurve(
                to: CGPoint(x: tailSize, y: rect.height - radius),
                control: CGPoint(x: tailSize, y: rect.height)
            )
            path.addLine(to: CGPoint(x: tailSize, y: tailSize + radius))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: tailSize + radius, y: tailSize))
            path.addQuadCurve(
                to: CGPoint(x: tailSize + radius, y: 0),
                control: CGPoint(x: tailSize, y: tailSize)
            )
        }
        
        return path
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    
    static let sampleMessages: [ChatMessage] = [
        ChatMessage(
            id: UUID(),
            content: "Hi there! I'm here to help with any technical questions you might have. What can I assist you with today?",
            isFromUser: false,
            timestamp: Date().addingTimeInterval(-3600)
        ),
        ChatMessage(
            id: UUID(),
            content: "Hello! I'm having trouble connecting my smart home devices to the network.",
            isFromUser: true,
            timestamp: Date().addingTimeInterval(-3500)
        ),
        ChatMessage(
            id: UUID(),
            content: "I'd be happy to help you with that! Can you tell me which specific devices you're trying to connect and what error messages you're seeing?",
            isFromUser: false,
            timestamp: Date().addingTimeInterval(-3400)
        )
    ]
}
