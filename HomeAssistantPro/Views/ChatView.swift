//
//  ChatView.swift
//  HomeAssistantPro
//
//  Purpose: Displays the Chat tab for 1-on-1 messaging with technical support.
//  Author: Michael
//  Created: 2025-06-24
//
//  This file defines the ChatView SwiftUI screen, allowing users to chat with support.
//

import SwiftUI

/// The Chat tab view for direct messaging with technical support.
struct ChatView: View {
    /// The message currently being composed by the user.
    @State private var message: String = ""
    /// The body of the ChatView, containing the UI layout.
    var body: some View {
        VStack {
            HStack {
                Text("Chat")
                    .font(.title2).bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            }
            .padding(.top)
            ScrollView {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Support")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Hi there, I'm here to help. What can I help you?")
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    Spacer()
                }
                .padding(.top)
            }
            Spacer()
            HStack {
                TextField("Message", text: $message)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .padding(.horizontal)
    }
} 