//
//  LoginView.swift
//  HomeAssistantPro
//
//  Purpose: Modern login screen with glassmorphism design and user authentication
//  Author: Michael
//  Created: 2025-06-25
//  Modified: 2025-07-06
//
//  Modification Log:
//  - 2025-06-25: Initial creation with modern iOS design aesthetics
//  - 2025-07-06: Added phone number validation utilities and enhanced error handling
//
//  Functions:
//  - init(onCreateAccount:): Initialize view with optional create account callback
//  - dismissKeyboard(): Removes focus from input fields
//  - togglePasswordVisibility(): Shows/hides password field content
//  - hapticFeedback(_:): Triggers haptic feedback with specified intensity
//  - validatePhoneNumber(_:): Validates phone number format using utility functions
//  - isFormValid(): Checks if all required form fields are valid
//  - handleLogin(): Processes user login with API authentication
//  - handleGuestLogin(): Processes anonymous login for guest access
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
    
    /// Initializes the login view with optional navigation callback
    /// - Parameter onCreateAccount: Optional callback function for create account navigation
    /// - Returns: Configured ModernLoginView instance
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
                            .responsiveBottomPadding(24, 36, 48)
                        
                        // Main content card
                        mainContentCard
                            .responsiveHorizontalPadding(6, 8, 10)
                        
//                        Spacer(minLength: DesignTokens.DeviceSize.current.spacing(10, 15, 20))
                        
                        // Footer section
                        footerSection
                            .responsiveVerticalPadding(6, 8, 10)
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
            VStack(spacing: DesignTokens.ResponsiveSpacing.md) {
                Text("AuraHome")
                    .font(DesignTokens.ResponsiveTypography.displayLarge)
                    .foregroundStyle(titleGradient)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Your smart sanctuary awaits")
                    .font(DesignTokens.ResponsiveTypography.bodyLarge)
                    .foregroundColor(.primary.opacity(0.8))
                    .tracking(0.5)
            }
        }
    }
    
    private var modernLogo: some View {
        ZStack {
            // Background blur effect
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xxxl)
                .fill(.ultraThinMaterial)
                .frame(
                    width: DesignTokens.ResponsiveContainer.profileIconSize,
                    height: DesignTokens.ResponsiveContainer.profileIconSize
                )
                .standardShadowMedium()
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xxxl)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
            
            // Logo content
            Image("icon")
                .resizable()
                .scaledToFit()
                .frame(
                    width: DesignTokens.DeviceSize.current.spacing(30, 45, 60),
                    height: DesignTokens.DeviceSize.current.spacing(30, 45, 60)
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
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
        VStack(spacing: DesignTokens.ResponsiveSpacing.lg) {
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
        .cardPadding()
        .limitedContentWidth()
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xxl)
                .fill(.ultraThinMaterial)
                .standardShadowMedium()
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xxl)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Input Fields
    
    private var inputFieldsSection: some View {
        VStack(spacing: DesignTokens.DeviceSize.current.spacing(8, 12, 16)) {
            modernPhoneNumberField
            modernPasswordField
        }
    }
    
    private var modernPhoneNumberField: some View {
        VStack(alignment: .leading, spacing: DesignTokens.ResponsiveSpacing.sm) {
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(.secondary)
                    .frame(width: DesignTokens.IconSize.lg)
                
                TextField("Phone number", text: $phoneNumber)
                    .font(DesignTokens.ResponsiveTypography.bodyMedium)
                    .keyboardType(.phonePad)
                    .autocapitalization(.none)
                    .focused($isPhoneNumberFocused)
                    .onChange(of: phoneNumber) { newValue in
                        phoneNumber = PhoneNumberUtils.formatPhoneNumber(newValue)
                        validatePhoneNumber(phoneNumber)
                    }
            }
            .padding(.horizontal, DesignTokens.ResponsiveSpacing.inputPadding)
            .padding(.vertical, DesignTokens.ResponsiveSpacing.buttonPadding)
            .frame(height: DesignTokens.ResponsiveContainer.inputFieldHeight)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .stroke(
                                isPhoneNumberFocused ? DesignTokens.Colors.primaryPurple :
                                !isPhoneNumberValid ? DesignTokens.Colors.primaryRed : Color.clear,
                                lineWidth: isPhoneNumberFocused ? 2 : 1
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isPhoneNumberFocused)
            
            if !isPhoneNumberValid {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignTokens.Colors.primaryRed)
                        .font(DesignTokens.ResponsiveTypography.caption)
                    
                    Text("Please enter a valid phone number")
                        .font(DesignTokens.ResponsiveTypography.caption)
                        .foregroundColor(DesignTokens.Colors.primaryRed)
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
                .frame(width: DesignTokens.IconSize.lg)
            
            Group {
                if showPassword {
                    TextField("Password", text: $password)
                        .focused($isPasswordFocused)
                } else {
                    SecureField("Password", text: $password)
                        .focused($isPasswordFocused)
                }
            }
            .font(DesignTokens.ResponsiveTypography.bodyMedium)
            
            Button(action: togglePasswordVisibility) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: DesignTokens.IconSize.lg))
            }
            .accessibilityLabel(showPassword ? "Hide password" : "Show password")
        }
        .padding(.horizontal, DesignTokens.ResponsiveSpacing.inputPadding)
        .padding(.vertical, DesignTokens.ResponsiveSpacing.buttonPadding)
        .frame(height: DesignTokens.ResponsiveContainer.inputFieldHeight)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                        .stroke(
                            isPasswordFocused ? DesignTokens.Colors.primaryPurple : Color.clear,
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
            HStack(spacing: DesignTokens.ResponsiveSpacing.md) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }
                
                Text(isLoading ? "Signing In..." : "Sign In")
                    .font(DesignTokens.ResponsiveTypography.buttonLarge)
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.ResponsiveContainer.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .fill(
                        isFormValid() ?
                        LinearGradient(
                            colors: [DesignTokens.Colors.primaryPurple, DesignTokens.Colors.primaryCyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(colors: [DesignTokens.Colors.textTertiary.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(
                        color: isFormValid() ? DesignTokens.Colors.primaryPurple.opacity(0.3) : Color.clear,
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
            .font(DesignTokens.ResponsiveTypography.bodySmall)
            .foregroundColor(DesignTokens.Colors.primaryPurple)
            
            Spacer()
            
            Button("Create Account") {
                hapticFeedback(.light)
                onCreateAccount?()
            }
            .font(DesignTokens.ResponsiveTypography.bodySmall)
            .foregroundColor(DesignTokens.Colors.primaryPurple)
        }
    }
    
    private var guestAccessButton: some View {
        Button(action: handleGuestLogin) {
            HStack(spacing: DesignTokens.ResponsiveSpacing.sm) {
                if appViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "person.circle")
                        .font(.system(size: DesignTokens.IconSize.lg))
                }
                
                Text(appViewModel.isLoading ? "Connecting..." : "Continue as Guest")
                    .font(DesignTokens.ResponsiveTypography.bodyMedium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.ResponsiveContainer.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .fill(DesignTokens.Colors.backgroundSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .stroke(DesignTokens.Colors.borderPrimary, lineWidth: 1)
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
                HStack(spacing: DesignTokens.ResponsiveSpacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignTokens.Colors.primaryRed)
                    
                    Text(errorMessage)
                        .font(DesignTokens.ResponsiveTypography.bodySmall)
                        .foregroundColor(DesignTokens.Colors.primaryRed)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .responsivePadding(12, 16, 18)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                        .fill(DesignTokens.Colors.primaryRed.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                                .stroke(DesignTokens.Colors.primaryRed.opacity(0.3), lineWidth: 1)
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
                .foregroundColor(DesignTokens.Colors.borderPrimary)
            
            Text("or")
                .font(DesignTokens.ResponsiveTypography.bodySmall)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .responsiveHorizontalPadding(12, 16, 20)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(DesignTokens.Colors.borderPrimary)
        }
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        Button(action: {
            hapticFeedback(.light)
            // Handle terms/privacy
        }) {
            Text("By continuing, you agree to our **Terms** & **Privacy Policy**")
                .font(DesignTokens.ResponsiveTypography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Dismisses the keyboard by removing focus from all input fields
    /// - Side Effects: Sets both phone number and password focus states to false
    private func dismissKeyboard() {
        isPhoneNumberFocused = false
        isPasswordFocused = false
    }
    
    /// Toggles password field visibility and provides haptic feedback
    /// - Side Effects: Toggles showPassword state and triggers light haptic feedback
    private func togglePasswordVisibility() {
        showPassword.toggle()
        hapticFeedback(.light)
    }
    
    /// Triggers haptic feedback with specified intensity
    /// - Parameter style: UIImpactFeedbackGenerator.FeedbackStyle intensity level
    /// - Side Effects: Generates device haptic feedback
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    /// Validates phone number format using utility functions with animation
    /// - Parameter phoneNumber: String containing phone number to validate
    /// - Side Effects: Updates isPhoneNumberValid state with animation
    private func validatePhoneNumber(_ phoneNumber: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPhoneNumberValid = PhoneNumberUtils.validatePhoneNumber(phoneNumber)
        }
    }
    
    /// Checks if all required form fields contain valid data
    /// - Returns: Bool indicating whether form is ready for submission
    private func isFormValid() -> Bool {
        return !phoneNumber.isEmpty && !password.isEmpty && isPhoneNumberValid
    }
    
    /// Processes user login with API authentication and error handling
    /// - Side Effects: Updates loading state, makes API call, updates app state on success
    /// - Throws: Handles APIError cases and displays appropriate error messages
    private func handleLogin() {
        guard isFormValid() else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
            showError = false
        }
        
        hapticFeedback(.medium)
        
        // Get stored user ID if available (optional for login)
        let userId = appViewModel.currentUserId
        
        // Remove spaces from phone number for API
        let cleanPhoneNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        
        Task {
            do {
                let response = try await APIClient.shared.login(
                    userId: userId, // Optional - can be nil for first-time login on this device
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
                    appViewModel.isUserLoggedIn = true // Persist login state to UserDefaults
                    print("DEBUG LOGIN: Set appViewModel state - currentUserId: \(String(response.data.user.id)), isLoggedIn: true, isUserLoggedIn: true")
                    
                    // Create registered user object with available data
                    // Note: APIClient already stored the profile data in SettingsStore
                    let newUser = User(
                        id: response.data.user.id,
                        deviceId: nil, // Will be populated from SettingsStore
                        status: response.data.user.status ?? 2, // Use actual status from API, default to registered if missing
                        accountName: response.data.user.name, // Will be restored from SettingsStore
                        phoneNumber: cleanPhoneNumber
                    )
                    appViewModel.currentUser = newUser
                    print("DEBUG LOGIN: Set currentUser to \(newUser.id), name: \(newUser.accountName ?? "nil"), status: \(newUser.status)")
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
    
    /// Processes anonymous login for guest access with error handling
    /// - Side Effects: Calls AppViewModel anonymous login, displays errors on failure
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
