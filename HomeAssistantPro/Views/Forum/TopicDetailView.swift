//
//  TopicDetailView.swift
//  HomeAssistantPro
//
//  Purpose: Displays the detail view for a selected forum topic, including replies.
//  Author: Michael
//  Created: 2025-06-24
//
//  This file defines the TopicDetailView SwiftUI screen, showing topic details and user replies.
//

import SwiftUI

/// The detail view for a selected forum topic, including replies.
struct TopicDetailView: View {
    /// The topic to display details for.
    let topic: Topic
    /// The body of the TopicDetailView, containing the UI layout.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: topic.avatar)
                        .resizable()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(topic.title)
                            .font(.headline)
                        Text("2d")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Text("I'm having trouble connecting my smart lights to the hub. I've followed the instructions in the manual, but they still won't connect. Any suggestions?")
                    .font(.body)
                Image(systemName: "lightbulb")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .padding(.vertical)
                HStack(spacing: 24) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                        Text("12")
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                        Text("3")
                    }
                }
                Divider()
                Text("Replies")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 36, height: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ethan Harper")
                                .font(.subheadline).bold()
                            Text("1d")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Make sure your lights are in pairing mode. You may need to reset them by turning them on and off a few times.")
                                .font(.body)
                        }
                    }
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 36, height: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sophia Carter")
                                .font(.subheadline).bold()
                            Text("1d")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Also, check if your hub is on the same Wi-Fi network as your lights. They need to be on the same network to communicate.")
                                .font(.body)
                        }
                    }
                }
                HStack {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 32, height: 32)
                    TextField("Write a reply...", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
                .padding(.vertical)
            }
            .padding()
        }
        .navigationTitle("Topic")
        .navigationBarTitleDisplayMode(.inline)
    }
}
