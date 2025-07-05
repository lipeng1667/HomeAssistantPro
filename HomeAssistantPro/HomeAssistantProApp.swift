//
//  HomeAssistantProApp.swift
//  HomeAssistantPro
//
//  Purpose: App entry point, manages navigation between splash, intro, login, and main tabs.
//  Author: Michael
//  Created: 2025-06-24
//  Modified: 2025-07-05
//
//  Modification Log:
//  - 2025-07-05: Added modern splash screen with glassmorphism design and animations
//
//  Functions:
//  - completeSplash(): Handles splash screen completion and navigation flow
//
//  This file defines the main app entry, injecting view models and handling onboarding logic.
//

import SwiftUI

@main
struct HomeAssistantProApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var settingsStore = SettingsStore()
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashView {
                    completeSplash()
                }
                .environmentObject(appViewModel)
                .environmentObject(settingsStore)
            } else if !settingsStore.isIntroShown {
                IntroView()
                    .environmentObject(appViewModel)
                    .environmentObject(settingsStore)
            } else if appViewModel.isLoggedIn {
                MainTabView()
                    .environmentObject(appViewModel)
                    .environmentObject(settingsStore)
            } else {
                ModernLoginView()
                    .environmentObject(appViewModel)
                    .environmentObject(settingsStore)
            }
        }
    }
    
    /// Handles splash screen completion and navigation flow
    /// Transitions from splash screen to appropriate app screen
    private func completeSplash() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showSplash = false
        }
    }
} 
