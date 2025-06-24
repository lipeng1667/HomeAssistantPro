//
//  LoginView.swift
//  HomeAssistantPro
//
//  Purpose: Displays the login screen for user authentication and anonymous access.
//  Author: Michael
//  Created: 2025-06-24
//
//  This file defines the LoginView SwiftUI screen, allowing users to sign in, create an account, or continue anonymously.
//

import SwiftUI

/// The login screen for user authentication and anonymous access.
struct LoginView: View {
    /// The shared app view model for login state.
    @EnvironmentObject var appViewModel: AppViewModel
    /// The user's email or phone input.
    @State private var email: String = ""
    /// The user's password input.
    @State private var password: String = ""
    /// The body of the LoginView, containing the UI layout.
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "house")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundStyle(LinearGradient(
                    colors: [.red, .orange, .yellow, .green, .blue, .purple],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(.bottom, 8)
                (
                    Text("Aura").foregroundColor(.primary) +
                    Text("Home").foregroundColor(.blue)
                )
                .font(.system(size: 40, weight: .bold))
            VStack(spacing: 16) {
                TextField("Email Address / Phone Number", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            Button(action: { appViewModel.login() }) {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            HStack {
                Button("Forgot Password?") {}
                    .foregroundColor(.purple)
                Spacer()
                Button("Create Account") {}
                    .foregroundColor(.purple)
            }
            HStack {
                Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.2))
                Text("or continue with").font(.caption).foregroundColor(.gray)
                Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.2))
            }
            Button(action: { appViewModel.login() }) {
                Text("Anonymous")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
            }
            Spacer()
            Text("By proceeding, you align with our ")
                .font(.footnote)
                .foregroundColor(.gray) +
            Text("Terms of Use").font(.footnote).foregroundColor(.purple) +
            Text(" & ").font(.footnote).foregroundColor(.gray) +
            Text("Privacy Protocol.").font(.footnote).foregroundColor(.purple)
        }
        .padding()
        .background(Color(.systemPink).opacity(0.07).ignoresSafeArea())
    }
} 
