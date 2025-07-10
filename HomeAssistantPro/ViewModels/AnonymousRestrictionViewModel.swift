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
        
        /// Human-readable title for the restriction modal
        var title: String {
            switch self {
            case .createTopic:
                return "Sign Up to Create Topics"
            case .replyToTopic, .replyToReply:
                return "Sign Up to Reply"
            case .likeTopic, .likeReply:
                return "Sign Up to Like Posts"
            case .editPost:
                return "Sign Up to Edit Posts"
            }
        }
        
        /// Detailed message explaining the restriction
        var message: String {
            switch self {
            case .createTopic:
                return "Create an account to start discussions and share your Home Assistant experiences with the community."
            case .replyToTopic, .replyToReply:
                return "Join our community to participate in discussions and help other Home Assistant users."
            case .likeTopic, .likeReply:
                return "Sign up to show appreciation for helpful posts and connect with the community."
            case .editPost:
                return "Create an account to manage your posts and contribute to the community."
            }
        }
        
        /// Primary action button text
        var primaryButtonText: String {
            return "Sign Up"
        }
        
        /// Secondary action button text
        var secondaryButtonText: String {
            return "Log In"
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
    
    /// Handles navigation to registration flow
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
    func navigateToLogin() {
        logger.info("User initiated login from restriction modal")
        dismissModal()
        
        // Post notification for app-level navigation handling
        NotificationCenter.default.post(
            name: .navigateToLogin,
            object: restrictedAction
        )
    }
    
    /// Provides contextual hint text for different UI elements
    /// - Parameter actionType: The type of action being hinted
    /// - Returns: Brief hint text to display in UI
    func getHintText(for actionType: RestrictedActionType) -> String {
        switch actionType {
        case .createTopic:
            return "Sign up to create topics"
        case .replyToTopic, .replyToReply:
            return "Sign up to reply"
        case .likeTopic, .likeReply:
            return "Sign up to like posts"
        case .editPost:
            return "Sign up to edit"
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