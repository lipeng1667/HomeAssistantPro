//
//  SocketManager.swift
//  HomeAssistantPro
//
//  Purpose: WebSocket manager for real-time instant messaging
//  Author: Michael
//  Created: 2025-07-14
//  Modified: 2025-07-14
//
//  Modification Log:
//  - 2025-07-14: Initial creation with Socket.io integration
//
//  Functions:
//  - WebSocket connection management
//  - Real-time message handling
//  - Typing indicators
//  - Connection state management
//

import Foundation
import Combine
import os.log

/// WebSocket manager for real-time messaging
class SocketManager: ObservableObject {
    
    // MARK: - Properties
    
    /// Shared instance
    static let shared = SocketManager()
    
    /// WebSocket server URL
    private let serverURL = "http://47.94.108.189:10000"
    
    /// Current connection state
    @Published var connectionState: ConnectionState = .disconnected
    
    /// New message publisher
    @Published var newMessage: ChatMessage?
    
    /// Typing indicator publisher
    @Published var isAdminTyping = false
    
    /// Current conversation ID
    @Published var currentConversationId: Int?
    
    /// Current user ID
    private var currentUserId: Int?
    
    /// Logger for debugging
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "SocketManager")
    
    /// WebSocket connection (placeholder for actual Socket.io implementation)
    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    
    /// Reconnection timer
    private var reconnectionTimer: Timer?
    private var reconnectionAttempts = 0
    private let maxReconnectionAttempts = 5
    
    // MARK: - Initialization
    
    private init() {
        setupWebSocket()
    }
    
    // MARK: - Public Methods
    
    /// Connect to WebSocket server
    /// - Parameter userId: User ID for authentication
    func connect(userId: Int) {
        logger.info("Connecting to WebSocket server with user ID: \(userId)")
        
        currentUserId = userId
        connectionState = .connecting
        
        // For now, simulate connection (will be replaced with actual Socket.io implementation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.connectionState = .connected
            self.logger.info("WebSocket connected successfully")
        }
    }
    
    /// Disconnect from WebSocket server
    func disconnect() {
        logger.info("Disconnecting from WebSocket server")
        
        webSocket?.cancel()
        reconnectionTimer?.invalidate()
        reconnectionTimer = nil
        
        connectionState = .disconnected
        currentUserId = nil
        currentConversationId = nil
        isAdminTyping = false
    }
    
    /// Join a conversation room
    /// - Parameter conversationId: Conversation ID to join
    func joinConversation(_ conversationId: Int) {
        logger.info("Joining conversation: \(conversationId)")
        
        guard connectionState.isConnected else {
            logger.warning("Cannot join conversation: WebSocket not connected")
            return
        }
        
        currentConversationId = conversationId
        
        // Send join conversation event
        let joinEvent = JoinConversationEvent(
            data: JoinConversationEvent.JoinConversationData(conversationId: conversationId)
        )
        
        sendEvent(joinEvent)
    }
    
    /// Send message via WebSocket
    /// - Parameters:
    ///   - content: Message content
    ///   - conversationId: Conversation ID
    ///   - messageType: Type of message
    func sendMessage(content: String, conversationId: Int, messageType: MessageType = .text) {
        logger.info("Sending message via WebSocket")
        
        guard connectionState.isConnected else {
            logger.warning("Cannot send message: WebSocket not connected")
            return
        }
        
        let messageEvent = SendMessageEvent(
            data: SendMessageEvent.SendMessageEventData(
                conversationId: conversationId,
                messageType: messageType,
                content: content,
                fileId: nil
            )
        )
        
        sendEvent(messageEvent)
    }
    
    /// Send typing indicator
    /// - Parameters:
    ///   - isTyping: Whether user is typing
    ///   - conversationId: Conversation ID
    func sendTypingIndicator(isTyping: Bool, conversationId: Int) {
        guard connectionState.isConnected else {
            logger.warning("Cannot send typing indicator: WebSocket not connected")
            return
        }
        
        let typingEvent = isTyping ? 
            TypingEvent.start(conversationId: conversationId) :
            TypingEvent.stop(conversationId: conversationId)
        
        sendEvent(typingEvent)
    }
    
    // MARK: - Private Methods
    
    /// Setup WebSocket connection
    private func setupWebSocket() {
        urlSession = URLSession(configuration: .default)
        
        // Note: This is a placeholder implementation
        // In a real implementation, you would use Socket.io-Client-Swift
        // Example setup:
        /*
        import SocketIO
        
        let manager = SocketManager(
            socketURL: URL(string: serverURL)!,
            config: [
                .log(true),
                .compress
            ]
        )
        
        socket = manager.defaultSocket
        setupSocketEvents()
        */
    }
    
    /// Setup Socket.io event handlers (placeholder)
    private func setupSocketEvents() {
        // Note: This would be implemented with actual Socket.io client
        /*
        socket?.on(clientEvent: .connect) { [weak self] data, ack in
            self?.handleConnect()
        }
        
        socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            self?.handleDisconnect()
        }
        
        socket?.on("new_message") { [weak self] data, ack in
            if let messageData = data[0] as? [String: Any] {
                self?.handleNewMessage(messageData)
            }
        }
        
        socket?.on("typing_indicator") { [weak self] data, ack in
            if let typingData = data[0] as? [String: Any] {
                self?.handleTypingIndicator(typingData)
            }
        }
        
        socket?.on("error") { [weak self] data, ack in
            self?.handleError(data)
        }
        */
    }
    
    /// Handle WebSocket connection
    private func handleConnect() {
        logger.info("WebSocket connected")
        
        DispatchQueue.main.async {
            self.connectionState = .connected
            self.reconnectionAttempts = 0
        }
    }
    
    /// Handle WebSocket disconnection
    private func handleDisconnect() {
        logger.info("WebSocket disconnected")
        
        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
        
        // Attempt reconnection
        attemptReconnection()
    }
    
    /// Handle new message event
    /// - Parameter messageData: Message data from WebSocket
    private func handleNewMessage(_ messageData: [String: Any]) {
        logger.info("Received new message event")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageData)
            let message = try JSONDecoder().decode(ChatMessage.self, from: jsonData)
            
            DispatchQueue.main.async {
                self.newMessage = message
            }
        } catch {
            logger.error("Failed to decode new message: \(error.localizedDescription)")
        }
    }
    
    /// Handle typing indicator event
    /// - Parameter typingData: Typing data from WebSocket
    private func handleTypingIndicator(_ typingData: [String: Any]) {
        logger.info("Received typing indicator event")
        
        guard let senderRole = typingData["sender_role"] as? String,
              let isTyping = typingData["typing"] as? Bool else {
            return
        }
        
        // Only show typing indicator for admin messages
        if senderRole == "admin" {
            DispatchQueue.main.async {
                self.isAdminTyping = isTyping
            }
        }
    }
    
    /// Handle WebSocket error
    /// - Parameter errorData: Error data from WebSocket
    private func handleError(_ errorData: [Any]) {
        logger.error("WebSocket error: \(errorData)")
        
        DispatchQueue.main.async {
            self.connectionState = .error
        }
    }
    
    /// Send event to WebSocket server
    /// - Parameter event: Event to send
    private func sendEvent<T: Codable>(_ event: T) {
        do {
            let jsonData = try JSONEncoder().encode(event)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                logger.debug("Sending event: \(jsonString)")
                
                // Note: This would be implemented with actual Socket.io client
                // socket?.emit(event.event, jsonData)
            }
        } catch {
            logger.error("Failed to encode event: \(error.localizedDescription)")
        }
    }
    
    /// Attempt to reconnect to WebSocket
    private func attemptReconnection() {
        guard reconnectionAttempts < maxReconnectionAttempts else {
            logger.error("Max reconnection attempts reached")
            return
        }
        
        reconnectionAttempts += 1
        
        DispatchQueue.main.async {
            self.connectionState = .reconnecting
        }
        
        let delay = min(pow(2.0, Double(reconnectionAttempts)), 30.0) // Exponential backoff, max 30 seconds
        
        reconnectionTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            if let userId = self.currentUserId {
                self.connect(userId: userId)
            }
        }
    }
    
    // MARK: - Utility Methods
    
    /// Check if WebSocket is connected
    var isConnected: Bool {
        return connectionState.isConnected
    }
    
    /// Get connection status description
    var connectionStatusDescription: String {
        return connectionState.displayName
    }
    
    /// Clear all state
    func clearState() {
        newMessage = nil
        isAdminTyping = false
        currentConversationId = nil
    }
}

// MARK: - Socket.io Integration Notes

/*
 To implement actual Socket.io integration, you would need to:
 
 1. Add Socket.io-Client-Swift to your project:
    - Add to Package.swift or Podfile
    - import SocketIO
 
 2. Replace the placeholder implementation with actual Socket.io code:
    - Create SocketManager with proper configuration
    - Setup event handlers for all events
    - Handle authentication with user_id
    - Implement proper error handling and reconnection
 
 3. Example Socket.io setup:
 
 ```swift
 import SocketIO
 
 class SocketManager: ObservableObject {
     private let manager: SocketManager
     private let socket: SocketIOClient
     
     init() {
         manager = SocketManager(
             socketURL: URL(string: "http://47.94.108.189:10000")!,
             config: [
                 .log(true),
                 .compress,
                 .reconnects(true),
                 .reconnectAttempts(5),
                 .reconnectWait(2)
             ]
         )
         
         socket = manager.defaultSocket
         setupSocketEvents()
     }
     
     func connect(userId: Int) {
         socket.connect(withPayload: ["user_id": userId])
     }
     
     private func setupSocketEvents() {
         socket.on(clientEvent: .connect) { [weak self] data, ack in
             self?.handleConnect()
         }
         
         socket.on("new_message") { [weak self] data, ack in
             self?.handleNewMessage(data)
         }
         
         // ... other event handlers
     }
 }
 ```
 
 4. Update the sendEvent method to use actual Socket.io emit:
 
 ```swift
 private func sendEvent<T: Codable>(_ event: T) {
     do {
         let jsonData = try JSONEncoder().encode(event)
         let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
         socket.emit(event.event, dict ?? [:])
     } catch {
         logger.error("Failed to send event: \(error)")
     }
 }
 ```
 */