//
//  ForumView.swift
//  HomeAssistantPro
//
//  Purpose: Displays the Forum tab with a list of community topics and search functionality.
//  Author: Michael
//  Created: 2025-06-24
//
//  This file defines the ForumView SwiftUI screen, showing a searchable list of topics and navigation to topic details.
//

import SwiftUI

/// The Forum tab view displaying a searchable list of community topics and navigation to topic details.
struct ForumView: View {
    /// The search text entered by the user.
    @State private var searchText = ""
    /// The currently selected topic (if any).
    @State private var selectedTopic: Topic? = nil
    /// The list of topics to display.
    let topics = [
        Topic(id: 1, title: "How to connect my smart...", comments: 123, likes: 123, avatar: "person.crop.circle"),
        Topic(id: 2, title: "How to connect my smart...", comments: 123, likes: 123, avatar: "person.crop.circle"),
        Topic(id: 3, title: "How to connect my smart...", comments: 123, likes: 123, avatar: "person.crop.circle")
    ]
    /// The body of the ForumView, containing the UI layout.
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Text("Community")
                        .font(.title2).bold()
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                    Image(systemName: "pencil")
                        .padding(.trailing)
                }
                .padding(.top)
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding([.horizontal, .bottom])
                List(topics) { topic in
                    NavigationLink(destination: TopicDetailView(topic: topic)) {
                        HStack(spacing: 16) {
                            Image(systemName: topic.avatar)
                                .resizable()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                Text(topic.title)
                                    .font(.headline)
                                Text("\(topic.comments) comments • \(topic.likes) likes")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "ellipsis")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarHidden(true)
        }
    }
}

/// Model representing a forum topic.
struct Topic: Identifiable {
    /// Unique identifier for the topic.
    let id: Int
    /// Title of the topic.
    let title: String
    /// Number of comments on the topic.
    let comments: Int
    /// Number of likes on the topic.
    let likes: Int
    /// Avatar image name for the topic author.
    let avatar: String
} 