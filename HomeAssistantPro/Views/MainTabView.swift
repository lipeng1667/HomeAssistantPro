//
//  MainTabView.swift
//  HomeAssistantPro
//
//  Purpose: Hosts the main tab navigation for Home, Forum, Chat, and Settings.
//  Author: Michael
//  Created: 2025-06-24
//
//  This file defines the MainTabView SwiftUI screen, providing tab navigation between the app's core sections.
//

import SwiftUI

/// The main tab view hosting navigation for Home, Forum, Chat, and Settings.
struct MainTabView: View {
    /// The body of the MainTabView, containing the tab navigation UI.
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            ForumView()
                .tabItem {
                    Image(systemName: "rectangle.on.rectangle")
                    Text("Forum")
                }
            ChatView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("Chat")
                }
            SettingsView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Settings")
                }
        }
    }
} 