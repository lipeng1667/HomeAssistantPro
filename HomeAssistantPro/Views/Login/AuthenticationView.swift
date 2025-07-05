//
//  AuthenticationView.swift
//  HomeAssistantPro
//
//  Purpose: Navigation container for login and registration flows
//  Author: Michael
//  Created: 2025-07-05
//  Modified: 2025-07-05
//
//  Modification Log:
//  - 2025-07-05: Initial creation with navigation between login and register views
//
//  Functions:
//  - showRegisterView(): Navigates to registration screen with animation
//  - showLoginView(): Navigates back to login screen with animation
//

import SwiftUI

/// Authentication flow container managing login and registration navigation
struct AuthenticationView: View {
    @State private var ifShowRegisterView = false
    
    var body: some View {
        ZStack {
            if ifShowRegisterView {
                RegisterView {
                    showLoginView()
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                ModernLoginView(onCreateAccount: {
                    showRegisterView()
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: ifShowRegisterView)
        .onAppear {
            UIScrollView.appearance().showsVerticalScrollIndicator = false
        }
    }
    
    /// Navigates to registration screen with animation
    private func showRegisterView() {
        HapticManager.navigate()
        withAnimation(.easeInOut(duration: 0.4)) {
            ifShowRegisterView = true
        }
    }
    
    /// Navigates back to login screen with animation
    private func showLoginView() {
        HapticManager.navigate()
        withAnimation(.easeInOut(duration: 0.4)) {
            ifShowRegisterView = false
        }
    }
}

// MARK: - Preview

#Preview {
    AuthenticationView()
        .environmentObject(AppViewModel())
}
