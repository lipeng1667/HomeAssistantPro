import SwiftUI

struct MainTabView: View {
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