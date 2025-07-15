import Foundation
import Combine
import os.log
import SocketIO

class SocketManager: ObservableObject {
    private let manager: SocketIO.SocketManager
    private let socket: SocketIOClient
    
    @Published var connectionState: ConnectionState = .disconnected
    @Published var newMessage: ChatMessage?
    @Published var isAdminTyping = false
    @Published var currentConversationId: Int?
    
    static let shared = SocketManager()
    
    private init() {
        manager = SocketIO.SocketManager(
            socketURL: URL(string: "http://47.94.108.189:10000")!,
            config: [
                .log(true),
                .compress,
                .secure(false),           // HTTP, not HTTPS
                .reconnects(true),
                .reconnectAttempts(5),
                .reconnectWait(2)
            ]
        )
        
        socket = manager.defaultSocket
        setupSocketEvents()
    }
    
    func connect(userId: Int) {
        // Authentication using auth object
        socket.connect(withPayload: ["auth": ["token": "\(userId)"]])
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
    private func setupSocketEvents() {
        // Connection events
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            print("✅ Connected to Socket.io server")
            DispatchQueue.main.async {
                self?.connectionState = .connected
            }
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("❌ Disconnected from Socket.io server")
            DispatchQueue.main.async {
                self?.connectionState = .disconnected
            }
        }
        
        socket.on(clientEvent: .error) { [weak self] data, ack in
            print("❌ Socket.io error: \(data)")
            DispatchQueue.main.async {
                self?.connectionState = .error
            }
        }
        
        // Custom events
        socket.on("connected") { data, ack in
            print("📱 Server confirmed connection: \(data)")
        }
        
        socket.on("new_message") { [weak self] data, ack in
            print("💬 New message received: \(data)")
            self?.handleNewMessage(data)
        }
        
        socket.on("typing_indicator") { [weak self] data, ack in
            print("⌨️ Typing indicator: \(data)")
            self?.handleTypingIndicator(data)
        }
    }
    
    func joinConversation(_ conversationId: Int) {
        self.currentConversationId = conversationId
        socket.emit("join_conversation", ["conversation_id": conversationId])
    }
    
    func sendMessage(content: String, conversationId: Int) {
        socket.emit("send_message", [
            "conversation_id": conversationId,
            "message_type": "text",
            "content": content
        ])
    }
    
    func sendTypingIndicator(isTyping: Bool, conversationId: Int) {
        let event = isTyping ? "typing_start" : "typing_stop"
        socket.emit(event, ["conversation_id": conversationId])
    }
    
    private func handleNewMessage(_ data: [Any]) {
        guard let messageData = data.first as? [String: Any] else { return }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageData)
            let message = try JSONDecoder().decode(ChatMessage.self, from: jsonData)
            DispatchQueue.main.async {
                self.newMessage = message
            }
        } catch {
            print("Error decoding message: \(error)")
        }
    }
    
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
    
    func clearState() {
        newMessage = nil
        isAdminTyping = false
        currentConversationId = nil
    }
}

