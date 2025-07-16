//
//  SocketManager.swift
//  HomeAssistantPro
//
//  Purpose: WebSocket connection manager for real-time chat messaging
//  Author: Michael
//  Created: 2025-07-15
//  Modified: 2025-07-16
//
//  Modification Log:
//  - 2025-07-15: Initial creation with Socket.IO integration
//  - 2025-07-16: Added proper documentation and function descriptions
//
//  Functions:
//  - connect: Establishes WebSocket connection with user authentication
//  - disconnect: Closes WebSocket connection
//  - joinConversation: Joins a specific chat conversation room
//  - sendMessage: Sends chat message through WebSocket
//  - sendTypingIndicator: Sends typing status to other participants
//  - handleNewMessage: Processes incoming chat messages
//  - handleTypingIndicator: Handles typing indicator updates
//  - clearState: Resets connection state and message data
//  - retryConnection: Attempts to reconnect after connection failure
//  - checkConnectionHealth: Monitors and maintains connection health
//

import Foundation
import Combine
import os.log
import SocketIO

/// Real-time WebSocket connection manager for chat messaging
/// Manages Socket.IO connections, message handling, and typing indicators
class SocketManager: ObservableObject {
    @Published var connectionState: ConnectionState = .disconnected
    @Published var newMessage: ChatMessage?
    @Published var isAdminTyping = false
    @Published var currentConversationId: Int?

    static let shared = SocketManager()

    private var manager: SocketIO.SocketManager?
    private var socket: SocketIOClient?
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "SocketManager")

    private init() {}

    /// Establishes WebSocket connection with user authentication
    /// - Parameter userId: User ID for authentication token
    /// - Side Effects: Updates connectionState, sets up socket events, configures reconnection
    func connect(userId: Int) {
        disconnect()

        logger.info("🔌 SOCKET.IO: Configuring connection for user ID: \(userId)")
        
        DispatchQueue.main.async {
            self.connectionState = .connecting
        }

        manager = SocketIO.SocketManager(
            socketURL: URL(string: "http://47.94.108.189:10000")!,
            config: [
                .log(true),
                .compress,
                .connectParams(["token": "\(userId)"]),
                .secure(false),
                .reconnects(true),
                .reconnectAttempts(5),
                .reconnectWait(2),
                .forcePolling(false),
                .forceWebsockets(false)
            ]
        )

        guard let manager = manager else {
            logger.error("🔌 SOCKET.IO: Failed to create SocketManager")
            DispatchQueue.main.async {
                self.connectionState = .error
            }
            return
        }

        socket = manager.defaultSocket
        setupSocketEvents()
        socket?.connect()
        
        // Set connection timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            if self.connectionState == .connecting {
                self.logger.error("🔌 SOCKET.IO: Connection timeout after 15 seconds")
                self.connectionState = .error
                self.socket?.disconnect()
            }
        }
    }

    /// Closes WebSocket connection
    /// - Side Effects: Disconnects socket and cleans up connection
    func disconnect() {
        logger.info("🔌 SOCKET.IO: Disconnecting...")
        socket?.disconnect()
    }

    /// Sets up WebSocket event handlers for connection, messages, and typing indicators
    /// - Side Effects: Configures socket event listeners and handlers
    private func setupSocketEvents() {
        guard let socket = socket else {
            logger.error("🔌 SOCKET.IO: Socket is nil, cannot set up events.")
            return
        }

        socket.removeAllHandlers()

        socket.on(clientEvent: .connect) { [weak self] data, ack in
            self?.logger.info("🔌 SOCKET.IO: ✅ Connected to server")
            DispatchQueue.main.async {
                self?.connectionState = .connected
            }
        }

        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            self?.logger.info("🔌 SOCKET.IO: ❌ Disconnected from server: \(data)")
            DispatchQueue.main.async {
                self?.connectionState = .disconnected
            }
        }

        socket.on(clientEvent: .error) { [weak self] data, ack in
            self?.logger.error("🔌 SOCKET.IO: ❌ Connection error: \(data)")
            DispatchQueue.main.async {
                self?.connectionState = .error
            }
            
            // Try to reconnect after error
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if let self = self, self.connectionState == .error {
                    self.logger.info("🔌 SOCKET.IO: Attempting to recover from error...")
                    self.socket?.connect()
                }
            }
        }
        
        socket.on(clientEvent: .reconnect) { [weak self] data, ack in
            self?.logger.info("🔌 SOCKET.IO: 🔄 Reconnected to server")
            DispatchQueue.main.async {
                self?.connectionState = .connected
            }
        }
        
        socket.on(clientEvent: .reconnectAttempt) { [weak self] data, ack in
            self?.logger.info("🔌 SOCKET.IO: 🔄 Attempting to reconnect...")
            DispatchQueue.main.async {
                self?.connectionState = .reconnecting
            }
        }

        socket.on("connected") { [weak self] data, ack in
            self?.logger.info("🔌 SOCKET.IO: 📱 Server confirmed connection: \(data)")
        }

        socket.on("new_message") { [weak self] data, ack in
            self?.logger.info("🔌 SOCKET.IO: 💬 New message received: \(data)")
            self?.handleNewMessage(data)
        }

        socket.on("typing_indicator") { [weak self] data, ack in
            self?.logger.info("🔌 SOCKET.IO: ⌨️ Typing indicator: \(data)")
            self?.handleTypingIndicator(data)
        }
    }

    /// Joins a specific chat conversation room
    /// - Parameter conversationId: ID of the conversation to join
    /// - Side Effects: Updates currentConversationId, emits join_conversation event
    func joinConversation(_ conversationId: Int) {
        self.currentConversationId = conversationId
        socket?.emit("join_conversation", ["conversation_id": conversationId])
    }

    /// Sends chat message through WebSocket
    /// - Parameters:
    ///   - content: Message text content
    ///   - conversationId: ID of the conversation to send message to
    /// - Side Effects: Emits send_message event to server
    func sendMessage(content: String, conversationId: Int) {
        socket?.emit("send_message", [
            "conversation_id": conversationId,
            "message_type": "text",
            "content": content
        ])
    }

    /// Sends typing status to other participants
    /// - Parameters:
    ///   - isTyping: True if user is typing, false if stopped
    ///   - conversationId: ID of the conversation
    /// - Side Effects: Emits typing_start or typing_stop event
    func sendTypingIndicator(isTyping: Bool, conversationId: Int) {
        let event = isTyping ? "typing_start" : "typing_stop"
        socket?.emit(event, ["conversation_id": conversationId])
    }

    /// Processes incoming chat messages from WebSocket
    /// - Parameter data: Raw message data from socket event
    /// - Side Effects: Updates newMessage property with decoded ChatMessage
    private func handleNewMessage(_ data: [Any]) {
        guard let messageData = data.first as? [String: Any] else { 
            logger.error("🔌 SOCKET.IO: Invalid message data format")
            return 
        }
        
        logger.info("🔌 SOCKET.IO: Processing message data: \(messageData)")
        
        // Only process admin messages from WebSocket
        guard let senderRole = messageData["sender_role"] as? String, senderRole == "admin" else {
            logger.info("🔌 SOCKET.IO: Ignoring non-admin message from WebSocket")
            return
        }
        
        do {
            // Create a mutable copy to add missing fields
            var completeMessageData = messageData
            
            // Add missing fields with default values for WebSocket messages
            if completeMessageData["user_id"] == nil {
                completeMessageData["user_id"] = NSNull()
            }
            if completeMessageData["admin_id"] == nil {
                completeMessageData["admin_id"] = NSNull()
            }
            if completeMessageData["file_id"] == nil {
                completeMessageData["file_id"] = NSNull()
            }
            if completeMessageData["file_url"] == nil {
                completeMessageData["file_url"] = NSNull()
            }
            if completeMessageData["metadata"] == nil {
                completeMessageData["metadata"] = NSNull()
            }
            if completeMessageData["is_read"] == nil {
                completeMessageData["is_read"] = 0
            }
            
            logger.info("🔌 SOCKET.IO: Complete message data: \(completeMessageData)")
            
            let jsonData = try JSONSerialization.data(withJSONObject: completeMessageData)
            let message = try JSONDecoder().decode(ChatMessage.self, from: jsonData)
            
            DispatchQueue.main.async {
                self.logger.info("🔌 SOCKET.IO: Setting newMessage on main thread")
                self.newMessage = message
            }
        } catch {
            logger.error("🔌 SOCKET.IO: Error decoding message: \(error)")
            logger.error("🔌 SOCKET.IO: Raw message data: \(messageData)")
        }
    }

    /// Handles typing indicator updates from other participants
    /// - Parameter data: Raw typing indicator data from socket event
    /// - Side Effects: Updates isAdminTyping property based on sender role
    private func handleTypingIndicator(_ data: [Any]) {
        guard let typingData = data.first as? [String: Any],
              let senderRole = typingData["sender_role"] as? String,
              let isTyping = typingData["typing"] as? Bool else { return }

        if senderRole == "admin" {
            DispatchQueue.main.async {
                self.isAdminTyping = isTyping
            }
        }
    }
    
    /// Resets connection state and message data
    /// - Side Effects: Clears newMessage, isAdminTyping, and currentConversationId
    func clearState() {
        newMessage = nil
        isAdminTyping = false
        currentConversationId = nil
    }
    
    /// Attempts to reconnect after connection failure
    /// - Parameter userId: User ID for authentication token
    /// - Side Effects: Updates connectionState to reconnecting, delays before reconnect
    func retryConnection(userId: Int) {
        logger.info("🔌 SOCKET.IO: Retrying connection...")
        DispatchQueue.main.async {
            self.connectionState = .reconnecting
        }
        
        // Wait a bit before retrying
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.connect(userId: userId)
        }
    }
    
    /// Check if connection is healthy and retry if needed
    func checkConnectionHealth(userId: Int) {
        if connectionState == .error || connectionState == .disconnected {
            logger.info("🔌 SOCKET.IO: Connection unhealthy, attempting to reconnect...")
            retryConnection(userId: userId)
        }
    }
}
