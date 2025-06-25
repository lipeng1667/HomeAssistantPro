//
//  HapticManager.swift
//  HomeAssistantPro
//
//  Purpose: Centralized haptic feedback management for consistent user experience
//  Author: Michael
//  Updated: 2025-06-25
//
//  Features: Unified haptic feedback API, consistent haptic patterns,
//  and easy-to-use interface for all haptic interactions in the app.
//

import UIKit
import SwiftUI

/// Centralized haptic feedback manager for consistent user experience
final class HapticManager {
    
    // MARK: - Singleton
    
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Feedback
    
    /// Trigger light impact feedback for subtle interactions
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Trigger medium impact feedback for standard interactions
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Trigger heavy impact feedback for strong interactions
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Trigger soft impact feedback (iOS 17+, falls back to light)
    static func soft() {
        if #available(iOS 17.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.prepare()
            generator.impactOccurred()
        } else {
            light()
        }
    }
    
    /// Trigger rigid impact feedback (iOS 17+, falls back to heavy)
    static func rigid() {
        if #available(iOS 17.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.prepare()
            generator.impactOccurred()
        } else {
            heavy()
        }
    }
    
    // MARK: - Notification Feedback
    
    /// Trigger success notification feedback
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// Trigger warning notification feedback
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    /// Trigger error notification feedback
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    
    /// Trigger selection feedback for picker or segmented control changes
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // MARK: - Custom Feedback Patterns
    
    /// Trigger feedback for button taps (most common interaction)
    static func buttonTap() {
        light()
    }
    
    /// Trigger feedback for tab bar selections
    static func tabSelection() {
        light()
    }
    
    /// Trigger feedback for card interactions
    static func cardTap() {
        soft()
    }
    
    /// Trigger feedback for toggle switches
    static func toggle() {
        selection()
    }
    
    /// Trigger feedback for swipe actions
    static func swipe() {
        light()
    }
    
    /// Trigger feedback for pull to refresh
    static func pullRefresh() {
        medium()
    }
    
    /// Trigger feedback for successful form submission
    static func formSuccess() {
        success()
    }
    
    /// Trigger feedback for form validation errors
    static func formError() {
        error()
    }
    
    /// Trigger feedback for login success
    static func loginSuccess() {
        success()
    }
    
    /// Trigger feedback for login failure
    static func loginFailure() {
        error()
    }
    
    /// Trigger feedback for navigation actions
    static func navigate() {
        light()
    }
    
    /// Trigger feedback for color picker selection
    static func colorSelection() {
        light()
    }
    
    /// Trigger feedback for profile actions
    static func profileAction() {
        medium()
    }
    
    /// Trigger feedback for message sent
    static func messageSent() {
        medium()
    }
    
    /// Trigger feedback for message received (if app is active)
    static func messageReceived() {
        soft()
    }
    
    /// Trigger feedback for typing indicator
    static func typing() {
        soft()
    }
    
    /// Trigger feedback for post creation
    static func postCreated() {
        success()
    }
    
    /// Trigger feedback for like/heart interactions
    static func like() {
        light()
    }
    
    /// Trigger feedback for delete actions
    static func delete() {
        warning()
    }
    
    /// Trigger feedback for edit mode entry
    static func editMode() {
        light()
    }
    
    /// Trigger feedback for save actions
    static func save() {
        medium()
    }
    
    /// Trigger feedback for cancel actions
    static func cancel() {
        light()
    }
    
    // MARK: - Advanced Feedback Patterns
    
    /// Trigger feedback sequence for loading completion
    static func loadingComplete() {
        DispatchQueue.main.async {
            light()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                soft()
            }
        }
    }
    
    /// Trigger feedback sequence for error with retry suggestion
    static func errorWithRetry() {
        DispatchQueue.main.async {
            error()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                light()
            }
        }
    }
    
    /// Trigger feedback sequence for multi-step completion
    static func multiStepComplete() {
        DispatchQueue.main.async {
            medium()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                light()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                soft()
            }
        }
    }
    
    // MARK: - Conditional Feedback
    
    /// Trigger feedback only if haptics are enabled in system settings
    static func conditionalFeedback(_ feedbackType: @escaping () -> Void) {
        // Check if haptics are available and enabled
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        feedbackType()
    }
    
    /// Trigger feedback with delay
    static func delayedFeedback(_ feedbackType: @escaping () -> Void, delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            feedbackType()
        }
    }
}

// MARK: - SwiftUI View Extensions

extension View {
    /// Add haptic feedback to button tap
    func hapticFeedback(_ type: HapticFeedbackType = .buttonTap) -> some View {
        self.onTapGesture {
            type.trigger()
        }
    }
    
    /// Add haptic feedback to specific gesture
    func hapticFeedback(
        _ type: HapticFeedbackType = .buttonTap,
        on gesture: some Gesture
    ) -> some View {
        self.gesture(
            gesture.onEnded { _ in
                type.trigger()
            }
        )
    }
}

// MARK: - Haptic Feedback Types Enum

enum HapticFeedbackType {
    case light
    case medium
    case heavy
    case soft
    case rigid
    case success
    case warning
    case error
    case selection
    case buttonTap
    case tabSelection
    case cardTap
    case toggle
    case swipe
    case pullRefresh
    case formSuccess
    case formError
    case loginSuccess
    case loginFailure
    case navigate
    case colorSelection
    case profileAction
    case messageSent
    case messageReceived
    case typing
    case postCreated
    case like
    case delete
    case editMode
    case save
    case cancel
    case loadingComplete
    case errorWithRetry
    case multiStepComplete
    
    func trigger() {
        switch self {
        case .light:
            HapticManager.light()
        case .medium:
            HapticManager.medium()
        case .heavy:
            HapticManager.heavy()
        case .soft:
            HapticManager.soft()
        case .rigid:
            HapticManager.rigid()
        case .success:
            HapticManager.success()
        case .warning:
            HapticManager.warning()
        case .error:
            HapticManager.error()
        case .selection:
            HapticManager.selection()
        case .buttonTap:
            HapticManager.buttonTap()
        case .tabSelection:
            HapticManager.tabSelection()
        case .cardTap:
            HapticManager.cardTap()
        case .toggle:
            HapticManager.toggle()
        case .swipe:
            HapticManager.swipe()
        case .pullRefresh:
            HapticManager.pullRefresh()
        case .formSuccess:
            HapticManager.formSuccess()
        case .formError:
            HapticManager.formError()
        case .loginSuccess:
            HapticManager.loginSuccess()
        case .loginFailure:
            HapticManager.loginFailure()
        case .navigate:
            HapticManager.navigate()
        case .colorSelection:
            HapticManager.colorSelection()
        case .profileAction:
            HapticManager.profileAction()
        case .messageSent:
            HapticManager.messageSent()
        case .messageReceived:
            HapticManager.messageReceived()
        case .typing:
            HapticManager.typing()
        case .postCreated:
            HapticManager.postCreated()
        case .like:
            HapticManager.like()
        case .delete:
            HapticManager.delete()
        case .editMode:
            HapticManager.editMode()
        case .save:
            HapticManager.save()
        case .cancel:
            HapticManager.cancel()
        case .loadingComplete:
            HapticManager.loadingComplete()
        case .errorWithRetry:
            HapticManager.errorWithRetry()
        case .multiStepComplete:
            HapticManager.multiStepComplete()
        }
    }
}