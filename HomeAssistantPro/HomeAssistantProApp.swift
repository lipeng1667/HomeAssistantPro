//
//  HomeAssistantProApp.swift
//  HomeAssistantPro
//
//  Purpose: App entry point, manages navigation between intro, login, and main tabs.
//  Author: Michael
//  Created: 2025-06-24
//
//  This file defines the main app entry, injecting view models and handling onboarding logic.
//

import SwiftUI

@main
struct HomeAssistantProApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var settingsStore = SettingsStore()
    
    var body: some Scene {
        WindowGroup {
            if !settingsStore.isIntroShown {
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
} 
