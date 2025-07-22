//
//  AnonymousRestrictionViewModel.swift
//  HomeAssistantPro
//
//  Purpose: Manages modal state and user guidance for anonymous user restrictions
//  Author: Michael
//  Created: 2025-07-10
//  Modified: 2025-07-10
//
//  Modification Log:
//  - 2025-07-10: Initial creation with modal state management
//
//  Functions:
//  - showRestrictionModal(): Displays restriction modal with appropriate message
//  - dismissModal(): Hides the restriction modal
//  - navigateToRegistration(): Handles navigation to registration flow
//  - navigateToLogin(): Handles navigation to login flow
//

import SwiftUI
import os.log

/// ViewModel for managing anonymous user restriction modal state and actions
@MainActor
class AnonymousRestrictionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Controls visibility of the restriction modal
    @Published var showModal: Bool = false
    
    /// The type of action that was restricted
    @Published var restrictedAction: RestrictedActionType = .createTopic
    
    /// Loading state for authentication actions
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "AnonymousRestrictionViewModel")
    
    // MARK: - Restricted Action Types
    
    /// Types of actions that are restricted for anonymous users
    enum RestrictedActionType: CaseIterable {
        case createTopic
        case replyToTopic
        case replyToReply
        case likeTopic
        case likeReply
        case editPost
        case sendChatMessage
        case upgradeAccount
        
        /// Human-readable title for the restriction modal
        var title: String {
            switch self {
            case .createTopic:
                return "Log In to Create Topics"
            case .replyToTopic, .replyToReply:
                return "Log In to Reply"
            case .likeTopic, .likeReply:
                return "Log In to Like Posts"
            case .editPost:
                return "Log In to Edit Posts"
            case .sendChatMessage:
                return "Log In to Chat"
            case .upgradeAccount:
                return "Create Your Account"
            }
        }
        
        /// Detailed message explaining the restriction
        var message: String {
            switch self {
            case .createTopic:
                return "Log in to start discussions and share your Home Assistant experiences with the community."
            case .replyToTopic, .replyToReply:
                return "Log in to participate in discussions and help other Home Assistant users."
            case .likeTopic, .likeReply:
                return "Log in to show appreciation for helpful posts and connect with the community."
            case .editPost:
                return "Log in to manage your posts and contribute to the community."
            case .sendChatMessage:
                return "Log in to chat with our support team and get help with your Home Assistant setup."
            case .upgradeAccount:
                return "Create an account to access full features, manage your profile, and save your preferences."
            }
        }
        
        /// Primary action button text
        var primaryButtonText: String {
            return "Log In"
        }
        
        /// Secondary action button text
        var secondaryButtonText: String {
            return "Cancel"
        }
    }
    
    // MARK: - Public Methods
    
    /// Shows the restriction modal for a specific action type
    /// - Parameter actionType: The type of restricted action attempted
    func showRestrictionModal(for actionType: RestrictedActionType) {
        restrictedAction = actionType
        showModal = true
        
        // Log restriction event for analytics
        logger.info("Anonymous user attempted restricted action: \(String(describing: actionType))")
        
        // Provide haptic feedback
        HapticManager.warning()
    }
    
    /// Dismisses the restriction modal
    func dismissModal() {
        showModal = false
        logger.info("Restriction modal dismissed")
    }
    
    /// Handles navigation to registration flow (deprecated - no longer used)
    /// This method should be called when user taps "Sign Up"
    func navigateToRegistration() {
        logger.info("User initiated registration from restriction modal")
        dismissModal()
        
        // Post notification for app-level navigation handling
        NotificationCenter.default.post(
            name: .navigateToRegistration,
            object: restrictedAction
        )
    }
    
    /// Handles navigation to login flow
    /// This method should be called when user taps "Log In"
    func navigateToLogin(appViewModel: AppViewModel) {
        logger.info("User initiated login from restriction modal")
        dismissModal()
        
        // Logout current anonymous session to force navigation to AuthenticationView
        Task {
            await appViewModel.logout()
        }
    }
    
    /// Provides contextual hint text for different UI elements
    /// - Parameter actionType: The type of action being hinted
    /// - Returns: Brief hint text to display in UI
    func getHintText(for actionType: RestrictedActionType) -> String {
        switch actionType {
        case .createTopic:
            return "Log in to create topics"
        case .replyToTopic, .replyToReply:
            return "Log in to reply"
        case .likeTopic, .likeReply:
            return "Log in to like posts"
        case .editPost:
            return "Log in to edit"
        case .sendChatMessage:
            return "Log in to chat"
        case .upgradeAccount:
            return "Log in to upgrade"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when user wants to navigate to registration from restriction modal
    static let navigateToRegistration = Notification.Name("navigateToRegistration")
    
    /// Posted when user wants to navigate to login from restriction modal
    static let navigateToLogin = Notification.Name("navigateToLogin")
}