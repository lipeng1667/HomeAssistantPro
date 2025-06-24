//
//  SettingsStore.swift
//  HomeAssistantPro
//
//  Purpose: Manages user settings and first-launch intro flag using UserDefaults.
//  Author: Michael
//  Created: 2025-06-24
//
//  This file defines the SettingsStore, an ObservableObject for app settings and onboarding logic.
//

import Foundation

/// View model for managing user settings and onboarding intro flag.
final class SettingsStore: ObservableObject {
    private let introKey = "isIntroShown"
    /// Returns true if the intro has already been shown.
    var isIntroShown: Bool {
        UserDefaults.standard.bool(forKey: introKey)
    }
    /// Sets the intro as shown in UserDefaults.
    func setIntroShown() {
        UserDefaults.standard.set(true, forKey: introKey)
        objectWillChange.send()
    }
} 