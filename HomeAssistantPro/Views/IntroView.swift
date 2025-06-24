//
//  IntroView.swift
//  HomeAssistantPro
//
//  Purpose: Displays a three-page onboarding intro for first app launch.
//  Author: Michael
//  Created: 2025-06-24
//
//  This file defines the IntroView SwiftUI screen, showing onboarding images and info before login on first launch.
//

import SwiftUI

/// The onboarding intro view shown only on first app launch.
struct IntroView: View {
    /// The current page index.
    @State private var page = 0
    /// The shared app view model for navigation.
    @EnvironmentObject var appViewModel: AppViewModel
    /// The settings store for first-launch tracking.
    @EnvironmentObject var settingsStore: SettingsStore
    
    /// The onboarding pages data.
    private let pages: [(image: String, title: String, description: String)] = [
        ("page1", "Welcome to AuraHome", "Discover smart home inspiration and daily tips."),
        ("page2", "Join the Community", "Engage with other users, ask questions, and share experiences."),
        ("page3", "Get Support Instantly", "Chat directly with our technical team for help anytime.")
    ]
    
    /// The body of the IntroView, containing the onboarding UI.
    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $page) {
                ForEach(0..<pages.count, id: \.self) { idx in
                    ZStack {
                        Image(pages[idx].image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .ignoresSafeArea(.all)
                        
                        Color.black.opacity(0)
                            .ignoresSafeArea(.all)
                        
                        VStack(spacing: 32) {
                            Spacer().frame(height: 80)
                            VStack(spacing: 16) {
                                Text(pages[idx].title)
                                    .font(.largeTitle).bold()
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .shadow(radius: 8)
                                Text(pages[idx].description)
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .shadow(radius: 4)
                            }
                            Spacer()
                            if idx == pages.count - 1 {
                                Button(action: {
                                    settingsStore.setIntroShown()
                                }) {
                                    Text("Get Started")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(hex:"#00a2ed"))
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                        .padding(.horizontal)
                                }
                                .padding(.bottom, 100) // Add some bottom padding for the button
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 24)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .tag(idx)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .animation(.easeInOut, value: page)
        }
        .ignoresSafeArea(.all) // This ensures the entire view ignores safe areas
    }
}
