import SwiftUI

@main
struct HomeAssistantProApp: App {
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            if appViewModel.isLoggedIn {
                MainTabView()
                    .environmentObject(appViewModel)
            } else {
                LoginView()
                    .environmentObject(appViewModel)
            }
        }
    }
} 
