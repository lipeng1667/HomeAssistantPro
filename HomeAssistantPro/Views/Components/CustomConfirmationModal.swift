//
//  CustomConfirmationModal.swift
//  HomeAssistantPro
//
//  Purpose: Reusable confirmation modal component with glassmorphism design
//  Author: Claude
//  Created: 2025-07-04
//  Modified: 2025-07-04
//
//  Modification Log:
//  - 2025-07-04: Initial creation of reusable confirmation modal component
//
//  Functions:
//  - CustomConfirmationModal: Main modal view with configurable content
//  - ConfirmationConfig: Configuration struct for modal appearance
//  - ConfirmationStyle: Enum for different styling themes
//

import SwiftUI

/// Configuration for custom confirmation modal appearance and behavior
struct ConfirmationConfig {
    let title: String
    let message: String
    let icon: String
    let confirmText: String
    let cancelText: String
    let style: ConfirmationStyle
    let onConfirm: () -> Void
    let onCancel: (() -> Void)?
    
    /// Creates a destructive confirmation (e.g., delete, logout)
    /// - Parameters:
    ///   - title: Modal title text
    ///   - message: Descriptive message text
    ///   - icon: SF Symbol icon name
    ///   - confirmText: Text for confirm button
    ///   - cancelText: Text for cancel button
    ///   - onConfirm: Action when confirm button is tapped
    ///   - onCancel: Optional action when cancel button is tapped
    /// - Returns: ConfirmationConfig with destructive styling
    static func destructive(
        title: String,
        message: String,
        icon: String,
        confirmText: String = "Confirm",
        cancelText: String = "Cancel",
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) -> ConfirmationConfig {
        ConfirmationConfig(
            title: title,
            message: message,
            icon: icon,
            confirmText: confirmText,
            cancelText: cancelText,
            style: .destructive,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
    
    /// Creates a primary confirmation (e.g., save, continue)
    /// - Parameters:
    ///   - title: Modal title text
    ///   - message: Descriptive message text
    ///   - icon: SF Symbol icon name
    ///   - confirmText: Text for confirm button
    ///   - cancelText: Text for cancel button
    ///   - onConfirm: Action when confirm button is tapped
    ///   - onCancel: Optional action when cancel button is tapped
    /// - Returns: ConfirmationConfig with primary styling
    static func primary(
        title: String,
        message: String,
        icon: String,
        confirmText: String = "Confirm",
        cancelText: String = "Cancel",
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) -> ConfirmationConfig {
        ConfirmationConfig(
            title: title,
            message: message,
            icon: icon,
            confirmText: confirmText,
            cancelText: cancelText,
            style: .primary,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
    
    /// Creates a success confirmation (e.g., completed actions)
    /// - Parameters:
    ///   - title: Modal title text
    ///   - message: Descriptive message text
    ///   - icon: SF Symbol icon name
    ///   - confirmText: Text for confirm button
    ///   - cancelText: Text for cancel button
    ///   - onConfirm: Action when confirm button is tapped
    ///   - onCancel: Optional action when cancel button is tapped
    /// - Returns: ConfirmationConfig with success styling
    static func success(
        title: String,
        message: String,
        icon: String,
        confirmText: String = "Continue",
        cancelText: String = "Cancel",
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) -> ConfirmationConfig {
        ConfirmationConfig(
            title: title,
            message: message,
            icon: icon,
            confirmText: confirmText,
            cancelText: cancelText,
            style: .success,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
}

/// Styling themes for confirmation modal
enum ConfirmationStyle {
    case destructive
    case primary
    case success
    
    var primaryColor: Color {
        switch self {
        case .destructive:
            return DesignTokens.Colors.primaryRed
        case .primary:
            return DesignTokens.Colors.primaryCyan
        case .success:
            return DesignTokens.Colors.primaryGreen
        }
    }
    
    var iconBackgroundOpacity: Double {
        return 0.15
    }
}

/// Reusable confirmation modal with glassmorphism design
struct CustomConfirmationModal: View {
    @Binding var isPresented: Bool
    let config: ConfirmationConfig
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Backdrop with blur
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .contentShape(Rectangle()) // This line ensures the entire area is tappable and blocks interactions
                
            // Modal Content
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(config.style.primaryColor.opacity(config.style.iconBackgroundOpacity))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: config.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(config.style.primaryColor)
                    }
                    
                    // Title and Message
                    VStack(spacing: 8) {
                        Text(config.title)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(config.message)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                }
                .padding(.top, 32)
                .padding(.horizontal, 24)
                
                // Buttons
                VStack(spacing: 12) {
                    // Confirm Button
                    Button(action: {
                        HapticManager.buttonTap()
                        dismissModal()
                        config.onConfirm()
                    }) {
                        Text(config.confirmText)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                config.style.primaryColor,
                                                config.style.primaryColor.opacity(0.8)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: config.style.primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                    }
                    .enhancedButtonStyle()
                    
                    // Cancel Button
                    Button(action: {
                        HapticManager.buttonTap()
                        dismissModal()
                        config.onCancel?()
                    }) {
                        Text(config.cancelText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .enhancedButtonStyle()
                }
                .padding(.top, 32)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
            .frame(maxWidth: 300)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
    
    /// Dismisses the modal with animation
    private func dismissModal() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            scale = 0.8
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - View Extension for Easy Usage

extension View {
    /// Adds a custom confirmation modal overlay
    /// - Parameters:
    ///   - isPresented: Binding to control modal presentation
    ///   - config: Configuration for modal appearance and behavior
    /// - Returns: View with confirmation modal overlay
    func confirmationModal(
        isPresented: Binding<Bool>,
        config: ConfirmationConfig
    ) -> some View {
        self
            .blur(radius: isPresented.wrappedValue ? 3 : 0)
            .allowsHitTesting(!isPresented.wrappedValue)
            .animation(.easeInOut(duration: 0.3), value: isPresented.wrappedValue)
            .overlay {
                if isPresented.wrappedValue {
                    CustomConfirmationModal(
                        isPresented: isPresented,
                        config: config
                    )
                }
            }
    }
}
