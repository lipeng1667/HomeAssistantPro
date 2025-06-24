//
//  AppViewModel.swift
//  HomeAssistantPro
//
//  Purpose: Manages global app state, including login status.
//  Author: Michael
//  Created: 2025-06-24
//
//  This file defines the AppViewModel, an ObservableObject for managing authentication and app-wide state.
//

import SwiftUI

/// View model for managing global app state, including login status.
final class AppViewModel: ObservableObject {
    /// Indicates whether the user is logged in.
    @Published var isLoggedIn: Bool = false
    
    /// Logs the user in (demo logic).
    func login() {
        isLoggedIn = true
    }
    
    /// Logs the user out.
    func logout() {
        isLoggedIn = false
    }
} 