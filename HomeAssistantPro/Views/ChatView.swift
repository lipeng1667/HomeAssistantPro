//
//  ChatView.swift
//  HomeAssistantPro
//
//  Purpose: Modern chat interface with technical support featuring 2025 design aesthetics
//  Author: Michael
//  Updated: 2025-07-14
//
//  Features: Real-time messaging with IM service integration, WebSocket support,
//  glassmorphism effects, smooth animations, dynamic typing indicators,
//  contemporary message bubbles with enhanced UX, and keyboard-responsive tab bar.
//

import SwiftUI

/// Modern chat view with sophisticated design and real-time messaging
struct ChatView: View {
    @State private var message: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var isTyping = false
    @State private var showEmojiPicker = false
    @State private var isKeyboardVisible = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isMessageFieldFocused: Bool
    
    // Services
    @StateObject private var imService = IMService.shared
    @StateObject private var socketManager = SocketManager.shared
    
    // Environment
    @EnvironmentObject var tabBarVisibility: TabBarVisibilityManager
    @EnvironmentObject private var appViewModel: AppViewModel
    
    var body: some View {
        ZStack {
            // Standardized background
            StandardTabBackground(configuration: .chat)
            
            VStack(spacing: 0) {
                // Standardized header
                StandardTabHeader(configuration: .chat(onOptions: {
                    // Options action
                }, isTyping: isTyping))
                
                // Connection status bar
                if socketManager.connectionState != .connected {
                    ConnectionStatusBar(connectionState: socketManager.connectionState)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Messages area
                messagesView
                
                // Input area
                inputView
                    .padding(.bottom, (!isKeyboardVisible && tabBarVisibility.isTabBarVisible) ? 100 : 0)
            }
        }
        .onAppear {
            setupKeyboardObservers()
            loadInitialData()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
        .onChange(of: socketManager.newMessage) { newMessage in
            if let newMessage = newMessage {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    messages.append(newMessage)
                }
                socketManager.clearState()
                
                // Ensure scroll to new message after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // This will trigger the onChange(of: messages.count) which handles scrolling
                }
            }
        }
        .onChange(of: socketManager.isAdminTyping) { isAdminTyping in
            withAnimation(.easeInOut(duration: 0.3)) {
                isTyping = isAdminTyping
            }
        }
        .onChange(of: socketManager.connectionState) { connectionState in
            // Join conversation when WebSocket connection is established
            if connectionState.isConnected, let firstMessage = messages.first {
                socketManager.joinConversation(firstMessage.conversationId)
            }
            
            // Handle connection errors
            if connectionState == .error {
                // Try to reconnect after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    if let userId = getUserId() {
                        socketManager.checkConnectionHealth(userId: userId)
                    }
                }
            }
        }
        .alert("Connection Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
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
    
    
    
    // MARK: - Messages
    
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Loading indicator
                    if isLoading {
                        ProgressView("Loading messages...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                            .id(message.id)
                    }
                    
                    // Typing indicator
                    if isTyping {
                        TypingIndicator()
                            .transition(.scale.combined(with: .opacity))
                            .id("typing-indicator")
                    }
                }
                .padding(.horizontal, DesignTokens.ResponsiveSpacing.lg)
                .padding(.vertical, 16)
            }
            .background(Color.clear)
            .onChange(of: messages.count) { _ in
                // Auto-scroll to bottom when new messages arrive
                if let lastMessage = messages.last {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: isTyping) { typing in
                // Auto-scroll to bottom when typing indicator appears
                if typing {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo("typing-indicator", anchor: .bottom)
                    }
                } else if let lastMessage = messages.last {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
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
                        .foregroundColor(DesignTokens.Colors.primaryGreen)
                }
                .scaleButtonStyle()
                
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
                    .scaleButtonStyle()
                }
                
                // Send button
                Button(action: sendMessage) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: message.isEmpty ?
                                        [Color.primary.opacity(0.3), Color.primary.opacity(0.2)] :
                                        [DesignTokens.Colors.primaryGreen, DesignTokens.Colors.secondaryGreen],
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
                .scaleButtonStyle()
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !message.isEmpty)
            }
            .padding(.horizontal, DesignTokens.ResponsiveSpacing.lg)
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
        
        // Get current user ID
        guard let currentUserId = imService.currentUserId else {
            errorMessage = "User not authenticated"
            return
        }
        
        // Haptic feedback
        HapticManager.messageSent()
        
        // Clear message field immediately
        let messageToSend = trimmedMessage
        message = ""
        
        // Dismiss keyboard after sending
        isMessageFieldFocused = false
        
        // Send message via IM service
        Task {
            do {
                let sentMessage = try await imService.sendMessage(
                    message: messageToSend,
                    userId: currentUserId
                )
                
                // Add sent message to UI
                await MainActor.run {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        messages.append(sentMessage)
                    }
                }
                
                // Note: Message is sent via REST API only
                // WebSocket is used for receiving real-time messages from admin
                
            } catch {
                await MainActor.run {
                    errorMessage = imService.handleError(error)
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadInitialData() {
        // Get current user ID from app view model
        guard let userId = getUserId() else {
            errorMessage = "User not authenticated"
            return
        }
        
        // Set user ID in IM service
        imService.setCurrentUserId(userId)
        
        // Connect to WebSocket
        socketManager.connect(userId: userId)
        
        // Load chat history
        Task {
            isLoading = true
            do {
                let chatMessages = try await imService.fetchMessages(userId: userId)
                
                await MainActor.run {
                    messages = chatMessages
                    isLoading = false
                    
                    // Note: Conversation joining is handled by onChange(of: socketManager.connectionState)
                    // when WebSocket connection is established
                }
            } catch {
                await MainActor.run {
                    errorMessage = imService.handleError(error)
                    isLoading = false
                }
            }
        }
    }
    
    private func getUserId() -> Int? {
        // Try to get user ID from app view model or authentication service
        // This is a placeholder - you'll need to implement based on your auth system
        return 53 // Placeholder user ID
    }
    
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
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
                .font(DesignTokens.ResponsiveTypography.bodyLarge)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [DesignTokens.Colors.primaryGreen, DesignTokens.Colors.secondaryGreen],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(MessageBubbleShape(isFromUser: true))
                .shadow(color: DesignTokens.Colors.primaryGreen.opacity(0.3), radius: 8, x: 0, y: 4)
            
            Text(message.timeAgo)
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
                            colors: [DesignTokens.Colors.primaryPurple, DesignTokens.Colors.secondaryPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: "headphones")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .shadow(color: DesignTokens.Colors.primaryPurple.opacity(0.3), radius: 6, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Support Agent")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.primaryPurple)
                
                Text(message.content)
                    .font(DesignTokens.ResponsiveTypography.bodyLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(
                        MessageBubbleShape(isFromUser: false)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                MessageBubbleShape(isFromUser: false)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    )
                
                Text(message.timeAgo)
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
                            colors: [DesignTokens.Colors.primaryPurple, DesignTokens.Colors.secondaryPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: "headphones")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .shadow(color: DesignTokens.Colors.primaryPurple.opacity(0.3), radius: 6, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Support Agent")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.primaryPurple)
                
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

// MARK: - Connection Status Bar

struct ConnectionStatusBar: View {
    let connectionState: ConnectionState
    
    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .scaleEffect(connectionState == .connecting || connectionState == .reconnecting ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: connectionState)
            
            Text(connectionState.displayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(statusColor)
            
            Spacer()
        }
        .padding(.horizontal, DesignTokens.ResponsiveSpacing.lg)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(statusColor.opacity(0.1))
                .overlay(
                    Rectangle()
                        .fill(statusColor.opacity(0.2))
                        .frame(height: 1),
                    alignment: .bottom
                )
        )
    }
    
    private var statusColor: Color {
        switch connectionState {
        case .connecting, .reconnecting:
            return DesignTokens.Colors.primaryAmber
        case .connected:
            return DesignTokens.Colors.primaryGreen
        case .disconnected, .error:
            return DesignTokens.Colors.primaryRed
        }
    }
}

// MARK: - Message Bubble Shape

struct MessageBubbleShape: Shape {
    let isFromUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailSize: CGFloat = 1 // Adjusted for a more visible curve
        
        var path = Path()
        
        if isFromUser {
            // User message bubble (right-aligned)
            path.move(to: CGPoint(x: radius, y: 0))
            path.addLine(to: CGPoint(x: rect.width - radius - tailSize, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: rect.width - tailSize, y: radius),
                control: CGPoint(x: rect.width - tailSize, y: 0)
            )
            path.addLine(to: CGPoint(x: rect.width - tailSize, y: rect.height - radius/2))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width - radius/2, y: rect.height - tailSize))
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
            path.move(to: CGPoint(x: radius/2, y: tailSize))
            path.addLine(to: CGPoint(x: rect.width - radius, y: tailSize))
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: radius + tailSize),
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
            path.addLine(to: CGPoint(x: tailSize, y: radius/2))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: radius/2, y: tailSize))
        }
        
        return path
    }
}


// MARK: - Note: ChatMessage model is now imported from IMModels.swift

// MARK: - Preview

#Preview {
    ChatView()
        .environmentObject(AppViewModel())
        .environmentObject(TabBarVisibilityManager())
}
