//
//  ChatView.swift
//  HomeAssistantPro
//
//  Purpose: Modern chat interface with technical support featuring 2025 design aesthetics
//  Author: Michael
//  Updated: 2025-07-17
//
//  Features: Real-time messaging with IM service integration, WebSocket support,
//  glassmorphism effects, smooth animations, dynamic typing indicators,
//  contemporary message bubbles with enhanced UX, keyboard-responsive tab bar,
//  and optimized data loading using splash screen preloaded chat history cache.
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
    
    // Pagination support
    @State private var currentPage = 1
    @State private var hasMoreMessages = true
    @State private var isLoadingMore = false
    @State private var loadMoreTask: Task<Void, Never>?
    
    // Scroll position management
    @State private var isLoadingOlderMessages = false
    @State private var firstVisibleMessageId: Int?
    @State private var shouldRestorePosition = false
    
    // Track if initial data has been loaded to avoid reloading on every appear
    @State private var hasLoadedInitialData = false
    
    // Services
    @StateObject private var imService = IMService.shared
    @StateObject private var socketManager = SocketManager.shared
    @StateObject private var restrictionViewModel = AnonymousRestrictionViewModel()
    
    // Environment
    @EnvironmentObject var tabBarVisibility: TabBarVisibilityManager
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.backgroundDataPreloader) private var backgroundDataPreloader
    
    var body: some View {
        ZStack {
            // Standardized background
            StandardTabBackground(configuration: .chat)
            
            VStack(spacing: 0) {
                // Standardized header
                StandardTabHeader(configuration: .chat(onOptions: {
                    // Options action
                }, connectionState: socketManager.connectionState, isTyping: isTyping))
                
                // Messages area
                messagesView
                
                // Input area
                inputView
                    .padding(.bottom, (!isKeyboardVisible && tabBarVisibility.isTabBarVisible) ? 100 : 0)
            }
        }
        .onAppear {
            print("💬 CHAT: onAppear called, hasLoadedInitialData: \(hasLoadedInitialData)")
            setupKeyboardObservers()
            
            // Only load initial data once, not on every appear
            if !hasLoadedInitialData {
                print("💬 CHAT: Loading initial data for first time")
                loadInitialData()
                hasLoadedInitialData = true
            } else {
                print("💬 CHAT: Skipping initial data load (already loaded)")
            }
        }
        .onDisappear {
            removeKeyboardObservers()
            // Cancel any ongoing load task to prevent memory leaks
            loadMoreTask?.cancel()
        }
        .onChange(of: socketManager.newMessage) { newMessage in
            if let newMessage = newMessage {
                // Check if message already exists by ID to prevent duplicates
                if !messages.contains(where: { $0.id == newMessage.id }) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        messages.append(newMessage)
                    }
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
        .onChange(of: appViewModel.isAnonymousUser) { isAnonymous in
            print("💬 CHAT: User status changed, isAnonymous: \(isAnonymous)")
            
            if isAnonymous {
                // User became anonymous (logged out) - clear all chat data
                clearChatData()
            } else {
                // User is no longer anonymous (logged in) - load fresh data
                if !hasLoadedInitialData {
                    loadInitialData()
                    hasLoadedInitialData = true
                }
            }
        }
        .dismissKeyboardOnSwipeDown()
        .overlay {
            if restrictionViewModel.showModal {
                CustomConfirmationModal(
                    isPresented: $restrictionViewModel.showModal,
                    config: ConfirmationConfig.primary(
                        title: restrictionViewModel.restrictedAction.title,
                        message: restrictionViewModel.restrictedAction.message,
                        icon: "message.fill",
                        confirmText: restrictionViewModel.restrictedAction.primaryButtonText,
                        cancelText: restrictionViewModel.restrictedAction.secondaryButtonText,
                        onConfirm: {
                            restrictionViewModel.navigateToLogin(appViewModel: appViewModel)
                        },
                        onCancel: {
                            restrictionViewModel.dismissModal()
                        }
                    )
                )
            }
        }
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
                    // Show empty state for anonymous users
                    if appViewModel.isAnonymousUser {
                        VStack(spacing: 24) {
                            Spacer()
                            
                            // Chat icon
                            Image(systemName: "message.fill")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(DesignTokens.Colors.primaryGreen.opacity(0.6))
                            
                            // Message
                            VStack(spacing: 12) {
                                Text("Chat with Support")
                                    .font(DesignTokens.ResponsiveTypography.headingLarge)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                
                                Text("Log in to view your chat history and get help from our support team.")
                                    .font(DesignTokens.ResponsiveTypography.bodyLarge)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Show normal chat messages for logged-in users
                        
                        // Pull-to-refresh indicator for loading older messages
                        if isLoadingMore {
                            ProgressView("Loading older messages...")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        }
                        
                        // Loading indicator for initial load
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
                }
                .padding(.horizontal, DesignTokens.ResponsiveSpacing.sm)
                .padding(.vertical, 16)
            }
            .background(Color.clear)
            .refreshable {
                await loadOlderMessages()
            }
            .onChange(of: messages.count) { _ in
                // Auto-scroll to bottom only when NOT loading older messages
                if !isLoadingOlderMessages, let lastMessage = messages.last {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: isTyping) { typing in
                // Auto-scroll to bottom when typing indicator appears (only if NOT loading older messages)
                if !isLoadingOlderMessages {
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
            .onChange(of: shouldRestorePosition) { restore in
                if restore, let messageId = firstVisibleMessageId {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // Verify the message still exists before scrolling
                        if messages.contains(where: { $0.id == messageId }) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(messageId, anchor: .top)
                            }
                        }
                        shouldRestorePosition = false
                        firstVisibleMessageId = nil
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
                    if appViewModel.isAnonymousUser {
                        // Show a button that looks like a text field for anonymous users
                        Button(action: {
                            restrictionViewModel.showRestrictionModal(for: .sendChatMessage)
                        }) {
                            HStack {
                                Text("Log in to send messages...")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                        )
                    } else {
                        // Show normal TextField for logged-in users
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
                        
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .scaleEffect(message.isEmpty ? 1.0 : 1.1)
                    }
                }
                .scaleButtonStyle()
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !message.isEmpty)
            }
            .padding(.horizontal, DesignTokens.ResponsiveSpacing.md)
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
        
        // Check if user is anonymous
        if appViewModel.isAnonymousUser {
            restrictionViewModel.showRestrictionModal(for: .sendChatMessage)
            return
        }
        
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
                
                // Add sent message to UI (with duplicate check)
                await MainActor.run {
                    // Check if message already exists by ID
                    if !messages.contains(where: { $0.id == sentMessage.id }) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            messages.append(sentMessage)
                        }
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
        // Check if user is anonymous first - don't load any chat data for anonymous users
        if appViewModel.isAnonymousUser {
            print("💬 CHAT: Anonymous user detected, skipping chat history loading")
            clearChatData()
            return
        }
        
        // Get current user ID from app view model
        guard let userId = getUserId() else {
            errorMessage = "User not authenticated"
            return
        }
        
        // Set user ID in IM service
        imService.setCurrentUserId(userId)
        
        // Connect to WebSocket only if not already connected
        if socketManager.connectionState != .connected {
            print("💬 CHAT: WebSocket not connected (\(socketManager.connectionState)), connecting...")
            socketManager.connect(userId: userId)
        } else {
            print("💬 CHAT: WebSocket already connected, skipping reconnection")
        }
        
        // Load chat history - use cached data first, then API if needed
        loadChatHistory(userId: userId)
    }
    
    /// Loads chat history using cached data first, then API if cache is invalid
    private func loadChatHistory(userId: Int) {
        // Reset pagination state
        currentPage = 1
        hasMoreMessages = true
        
        // Check cache first for instant display
        let cachedMessages = backgroundDataPreloader.getCachedChatHistory()
        
        if !cachedMessages.isEmpty {
            messages = cachedMessages
            // Don't show loading state if we have cached data
            isLoading = false
        }
        
        // Only load fresh data from API if cache is invalid or expired
        if !backgroundDataPreloader.hasValidCachedChatData() {
            Task {
                if cachedMessages.isEmpty {
                    isLoading = true
                }
                
                do {
                    let chatMessages = try await imService.fetchMessages(userId: userId, page: 1)
                    
                    await MainActor.run {
                        messages = chatMessages
                        isLoading = false
                        
                        // Update pagination state based on results
                        if chatMessages.count < 20 {
                            hasMoreMessages = false
                        }
                        
                        // Cache the fresh data we just loaded
                        let cacheManager = CacheManager.shared
                        cacheManager.cacheChatHistory(chatMessages)
                        
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
    }
    
    private func getUserId() -> Int? {
        // Get user ID from stored authentication
        let settingsStore = SettingsStore()
        guard let userIdString = try? settingsStore.retrieveUserId(),
              let userId = Int(userIdString) else {
            print("No valid user ID found for chat")
            return nil
        }
        print("Using user ID \(userId) for chat")
        return userId
    }
    
    /// Load older messages for pagination (triggered by pull-to-refresh)
    private func loadOlderMessages() async {
        // Cancel any existing load task
        loadMoreTask?.cancel()
        
        guard hasMoreMessages && !isLoadingMore else { return }
        guard let userId = getUserId() else { return }
        
        await MainActor.run {
            isLoadingMore = true
            isLoadingOlderMessages = true
            
            // Store reference to the first visible message to maintain scroll position
            // If no messages exist, we won't need to restore position
            firstVisibleMessageId = messages.first?.id
        }
        
        let nextPage = currentPage + 1
        
        // Create a new task to handle the loading
        loadMoreTask = Task {
            do {
                let olderMessages = try await imService.fetchMessages(userId: userId, page: nextPage)
                
                // Check if task was cancelled
                guard !Task.isCancelled else {
                    await MainActor.run {
                        isLoadingMore = false
                        isLoadingOlderMessages = false
                    }
                    return
                }
                
                await MainActor.run {
                    if olderMessages.isEmpty {
                        hasMoreMessages = false
                        // Clear reference since no restoration is needed
                        firstVisibleMessageId = nil
                    } else {
                        // Prepend older messages to the beginning of the array
                        messages = olderMessages + messages
                        currentPage = nextPage
                        
                        // Trigger scroll position restoration only if we have a reference message
                        shouldRestorePosition = firstVisibleMessageId != nil
                    }
                    isLoadingMore = false
                    isLoadingOlderMessages = false
                }
            } catch {
                // Check if task was cancelled
                guard !Task.isCancelled else {
                    await MainActor.run {
                        isLoadingMore = false
                        isLoadingOlderMessages = false
                    }
                    return
                }
                
                await MainActor.run {
                    // Only show error if it's not a cancellation error
                    if !error.localizedDescription.contains("cancelled") {
                        errorMessage = imService.handleError(error)
                    }
                    isLoadingMore = false
                    isLoadingOlderMessages = false
                }
            }
        }
        
        // Wait for the task to complete
        await loadMoreTask?.value
    }
    
    /// Clears all chat data and state (used for anonymous users and logout)
    private func clearChatData() {
        print("💬 CHAT: Clearing all chat data and state")
        
        // Clear messages
        messages.removeAll()
        
        // Reset pagination state
        currentPage = 1
        hasMoreMessages = true
        
        // Clear loading states
        isLoading = false
        isLoadingMore = false
        isLoadingOlderMessages = false
        
        // Clear input state
        message = ""
        isTyping = false
        
        // Clear error state
        errorMessage = nil
        
        // Cancel any ongoing tasks
        loadMoreTask?.cancel()
        loadMoreTask = nil
        
        // Disconnect WebSocket
        socketManager.disconnect()
        
        // Clear IM service user ID
        imService.setCurrentUserId(nil)
        
        // Reset data loading flag to allow fresh load on next login
        hasLoadedInitialData = false
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
