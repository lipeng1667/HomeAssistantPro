//
//  ModernLoginView.swift
//  HomeAssistantPro
//
//  Purpose: Modern, stylish login screen aligned with 2025 iOS design aesthetics
//  Author: Michael
//  Updated: 2025-06-25
//
//  Features modern design trends: Liquid Glass effects, dynamic islands,
//  minimalist approach, improved accessibility, and refined animations.
//

import SwiftUI

/// Modern login screen with 2025 iOS design aesthetics
struct ModernLoginView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var isPhoneNumberValid = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @FocusState private var isPhoneNumberFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    
    /// Callback to navigate to registration view
    let onCreateAccount: (() -> Void)?
    
    /// Initializer with optional create account callback
    /// - Parameter onCreateAccount: Callback for create account navigation
    init(onCreateAccount: (() -> Void)? = nil) {
        self.onCreateAccount = onCreateAccount
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Standardized background
                StandardTabBackground(configuration: .login)
                
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 40)
                        
                        // Header section with modern styling
                        headerSection
                            .padding(.bottom, 48)
                        
                        // Main content card
                        mainContentCard
                            .padding(.horizontal, 20)
                        
                        Spacer(minLength: 20)
                        
                        // Footer section
                        footerSection
                            .padding(.bottom, 40)
                    }
                }
            }
        }
        .onTapGesture {
            dismissKeyboard()
        }
        .onAppear {
            UIScrollView.appearance().showsVerticalScrollIndicator = false
        }
        .dismissKeyboardOnSwipeDown()
    }
    
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 24) {
            // Modern logo with liquid glass effect
            modernLogo
            
            // Welcome text with refined typography
            VStack(spacing: 12) {
                Text("AuraHome")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(titleGradient)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Your smart sanctuary awaits")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary.opacity(0.8))
                    .tracking(0.5)
            }
        }
    }
    
    private var modernLogo: some View {
        ZStack {
            // Background blur effect
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .frame(width: 100, height: 100)
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
            
            // Logo content
            Image("icon")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .accessibilityLabel("AuraHome app logo")
    }
    
    private var titleGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#8B5CF6"), Color(hex: "#06B6D4"), Color(hex: "#3B82F6")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Main Content Card
    
    private var mainContentCard: some View {
        VStack(spacing: 28) {
            // Input fields section
            inputFieldsSection
            
            // Error display
            errorDisplay
            
            // Sign in button
            signInButton
            
            // Alternative options
            alternativeOptions
            
            // Divider
            dividerSection
            
            // Guest access
            guestAccessButton
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Input Fields
    
    private var inputFieldsSection: some View {
        VStack(spacing: 16) {
            modernPhoneNumberField
            modernPasswordField
        }
    }
    
    private var modernPhoneNumberField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                TextField("Phone number", text: $phoneNumber)
                    .font(.system(size: 16, weight: .medium))
                    .keyboardType(.phonePad)
                    .autocapitalization(.none)
                    .focused($isPhoneNumberFocused)
                    .onChange(of: phoneNumber) { newValue in
                        phoneNumber = PhoneNumberUtils.formatPhoneNumber(newValue)
                        validatePhoneNumber(phoneNumber)
                    }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isPhoneNumberFocused ? Color(hex: "#8B5CF6") :
                                !isPhoneNumberValid ? Color.red : Color.clear,
                                lineWidth: isPhoneNumberFocused ? 2 : 1
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isPhoneNumberFocused)
            
            if !isPhoneNumberValid {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text("Please enter a valid phone number")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .accessibilityLabel("Phone number field")
    }
    
    private var modernPasswordField: some View {
        HStack {
            Image(systemName: "lock.fill")
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Group {
                if showPassword {
                    TextField("Password", text: $password)
                        .focused($isPasswordFocused)
                } else {
                    SecureField("Password", text: $password)
                        .focused($isPasswordFocused)
                }
            }
            .font(.system(size: 16, weight: .medium))
            
            Button(action: togglePasswordVisibility) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
            }
            .accessibilityLabel(showPassword ? "Hide password" : "Show password")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isPasswordFocused ? Color(hex: "#8B5CF6") : Color.clear,
                            lineWidth: isPasswordFocused ? 2 : 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isPasswordFocused)
        .accessibilityLabel("Password field")
    }
    
    // MARK: - Buttons and Actions
    
    private var signInButton: some View {
        Button(action: handleLogin) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }
                
                Text(isLoading ? "Signing In..." : "Sign In")
                    .font(.system(size: 18, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isFormValid() ?
                        LinearGradient(
                            colors: [Color(hex: "#8B5CF6"), Color(hex: "#06B6D4")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(
                        color: isFormValid() ? Color(hex: "#8B5CF6").opacity(0.3) : Color.clear,
                        radius: isFormValid() ? 12 : 0,
                        x: 0,
                        y: 6
                    )
            )
            .foregroundColor(.white)
            .scaleEffect(isLoading ? 0.98 : 1.0)
        }
        .disabled(isLoading || !isFormValid())
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .accessibilityLabel("Sign in button")
    }
    
    private var alternativeOptions: some View {
        HStack {
            Button("Forgot Password?") {
                hapticFeedback(.light)
                // Handle forgot password
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(Color(hex: "#8B5CF6"))
            
            Spacer()
            
            Button("Create Account") {
                hapticFeedback(.light)
                onCreateAccount?()
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(Color(hex: "#8B5CF6"))
        }
    }
    
    private var guestAccessButton: some View {
        Button(action: handleGuestLogin) {
            HStack(spacing: 8) {
                if appViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "person.circle")
                        .font(.system(size: 16))
                }
                
                Text(appViewModel.isLoading ? "Connecting..." : "Continue as Guest")
                    .font(.system(size: 16, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundColor(.primary)
            .scaleEffect(appViewModel.isLoading ? 0.98 : 1.0)
        }
        .disabled(appViewModel.isLoading)
        .animation(.easeInOut(duration: 0.2), value: appViewModel.isLoading)
        .accessibilityLabel("Continue as guest")
    }
    
    // MARK: - Supporting Views
    
    private var errorDisplay: some View {
        Group {
            if showError {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var dividerSection: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.primary.opacity(0.1))
            
            Text("or")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.primary.opacity(0.1))
        }
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        Button(action: {
            hapticFeedback(.light)
            // Handle terms/privacy
        }) {
            Text("By continuing, you agree to our **Terms** & **Privacy Policy**")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Helper Methods
    
    
    private func dismissKeyboard() {
        isPhoneNumberFocused = false
        isPasswordFocused = false
    }
    
    private func togglePasswordVisibility() {
        showPassword.toggle()
        hapticFeedback(.light)
    }
    
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    private func validatePhoneNumber(_ phoneNumber: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPhoneNumberValid = PhoneNumberUtils.validatePhoneNumber(phoneNumber)
        }
    }
    
    private func isFormValid() -> Bool {
        return !phoneNumber.isEmpty && !password.isEmpty && isPhoneNumberValid
    }
    
    
    private func handleLogin() {
        guard isFormValid() else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
            showError = false
        }
        
        hapticFeedback(.medium)
        
        // Check if user has a stored user ID from previous sessions
        guard let userId = appViewModel.currentUserId, !userId.isEmpty else {
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoading = false
                showError = true
                errorMessage = "Please register for an account first or continue as guest to get started."
            }
            
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
            return
        }
        
        // Remove spaces from phone number for API
        let cleanPhoneNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        
        Task {
            do {
                let response = try await APIClient.shared.login(
                    userId: userId,
                    phoneNumber: cleanPhoneNumber,
                    password: password
                )
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoading = false
                    }
                    
                    // Login successful
                    HapticManager.success()
                    
                    // Update user ID in app state
                    appViewModel.currentUserId = String(response.data.user.id)
                    appViewModel.isLoggedIn = true
                    appViewModel.login()
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoading = false
                    }
                    
                    // Handle login error
                    let errorMsg: String
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .badRequest(let message):
                            errorMsg = message
                        case .unauthorized:
                            errorMsg = "Invalid credentials. Please check your phone number and password."
                        case .serverError:
                            errorMsg = "Server error. Please try again later."
                        case .networkError:
                            errorMsg = "Network error. Please check your connection."
                        default:
                            errorMsg = "Login failed. Please try again."
                        }
                    } else {
                        errorMsg = "Login failed. Please try again."
                    }
                    
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showError = true
                        errorMessage = errorMsg
                    }
                    
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.error)
                }
            }
        }
    }
    
    private func handleGuestLogin() {
        hapticFeedback(.light)
        
        Task {
            let success = await appViewModel.loginAnonymously()
            if !success {
                await MainActor.run {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showError = true
                        errorMessage = appViewModel.errorMessage ?? "Anonymous login failed"
                    }
                    
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.error)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ModernLoginView {
        print("Create account")
    }
    .environmentObject(AppViewModel())
}
