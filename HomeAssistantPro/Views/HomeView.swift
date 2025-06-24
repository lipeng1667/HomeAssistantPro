//
//  HomeView.swift
//  HomeAssistantPro
//
//  Purpose: Displays the Home tab with featured smart home cases and daily tips.
//  Author: Michael
//  Created: 2025-06-24
//
//  This file defines the HomeView SwiftUI screen, showing a featured case and daily tips for users.
//

import SwiftUI

/// The main Home tab view displaying featured smart home cases and daily tips.
struct HomeView: View {
    /// The body of the HomeView, containing the UI layout.
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("HOME")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Featured Case")
                            .font(.title2).bold()
                        ZStack(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                                .frame(height: 180)
                                .overlay(
                                    Image(systemName: "house.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 120)
                                        .padding()
                                )
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Modern Smart Home Design")
                                    .font(.headline)
                                Text("A sleek, minimalist design with integrated smart lighting and security systems.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Tips")
                            .font(.title2).bold()
                        HStack(alignment: .top, spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tip of the day")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Save energy by turning off lights in unoccupied rooms")
                                    .font(.headline)
                                Text("Small actions can lead to significant savings on your energy bill. Make it a habit to switch off lights when you leave a room.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemYellow).opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "lightbulb")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.yellow)
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
} 