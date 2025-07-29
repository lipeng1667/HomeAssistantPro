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
    @StateObject private var settingsStore: SettingsStore
    @StateObject private var appViewModel: AppViewModel
    @StateObject private var backgroundDataPreloader = BackgroundDataPreloader.shared
    @State private var showSplash = true
    
    init() {
        let sharedSettingsStore = SettingsStore()
        _settingsStore = StateObject(wrappedValue: sharedSettingsStore)
        _appViewModel = StateObject(wrappedValue: AppViewModel(settingsStore: sharedSettingsStore))
    }
    
    /// Converts stored theme preference to SwiftUI ColorScheme
    private var preferredColorScheme: ColorScheme? {
        switch settingsStore.selectedTheme {
        case "light":
            return .light
        case "dark":
            return .dark
        case "system":
            return nil
        default:
            return nil
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView {
                        completeSplash()
                    }
                    .environmentObject(appViewModel)
                    .environmentObject(settingsStore)
                    .environment(\.backgroundDataPreloader, backgroundDataPreloader)
                } else if settingsStore.isFirstLaunch {
                    IntroView()
                        .environmentObject(appViewModel)
                        .environmentObject(settingsStore)
                        .environment(\.backgroundDataPreloader, backgroundDataPreloader)
                } else if appViewModel.isLoggedIn {
                    MainTabView()
                        .environmentObject(appViewModel)
                        .environmentObject(settingsStore)
                        .environment(\.backgroundDataPreloader, backgroundDataPreloader)
                } else {
                    AuthenticationView()
                        .environmentObject(appViewModel)
                        .environmentObject(settingsStore)
                        .environment(\.backgroundDataPreloader, backgroundDataPreloader)
                }
            }
            .preferredColorScheme(preferredColorScheme)
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
