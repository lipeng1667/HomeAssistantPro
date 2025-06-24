//
//  SettingsView.swift
//  HomeAssistantPro
//
//  Purpose: Displays the Settings tab for managing account and app preferences.
//  Author: Michael
//  Created: 2025-06-24
//
//  This file defines the SettingsView SwiftUI screen, allowing users to view and edit their profile and settings.
//

import SwiftUI

/// The Settings tab view for managing account and app preferences.
struct SettingsView: View {
    /// The body of the SettingsView, containing the UI layout.
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Spacer()
                        Text("Me")
                            .font(.title2).bold()
                        Spacer()
                        Image(systemName: "gearshape")
                    }
                    .padding(.top)
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    Text("Ethan Carter")
                        .font(.title).bold()
                    Text("View profile")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Text("Member since 2021")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account").font(.headline)
                        HStack {
                            Image(systemName: "phone")
                                .frame(width: 32, height: 32)
                            VStack(alignment: .leading) {
                                Text("Phone Number").font(.subheadline)
                                Text("+1 (555) 123-4567").font(.caption).foregroundColor(.secondary)
                            }
                        }
                        HStack {
                            Image(systemName: "envelope")
                                .frame(width: 32, height: 32)
                            VStack(alignment: .leading) {
                                Text("Email").font(.subheadline)
                                Text("ethan.carter@email.com").font(.caption).foregroundColor(.secondary)
                            }
                        }
                        HStack {
                            Image(systemName: "lock")
                                .frame(width: 32, height: 32)
                            VStack(alignment: .leading) {
                                Text("Password").font(.subheadline)
                                Text("Password").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Settings").font(.headline)
                        HStack {
                            Image(systemName: "bell")
                                .frame(width: 32, height: 32)
                            Text("Notifications").font(.subheadline)
                        }
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .frame(width: 32, height: 32)
                            Text("Help").font(.subheadline)
                        }
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
} 