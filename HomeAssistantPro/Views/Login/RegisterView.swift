//
//  RegisterView.swift
//  HomeAssistantPro
//
//  Purpose: Modern registration screen with glassmorphism design and form validation
//  Author: Michael
//  Created: 2025-07-05
//  Modified: 2025-07-05
//
//  Modification Log:
//  - 2025-07-05: Initial creation with glassmorphism design, form validation, and accessibility
//
//  Functions:
//  - handleRegistration(): Processes user registration with validation
//  - validatePhoneNumber(_:): Validates phone number format with regex pattern
//  - validatePassword(_:): Validates password strength requirements
//  - validateConfirmPassword(): Checks password confirmation match
//  - isFormValid(): Validates entire form before submission
//

import SwiftUI

/// Modern registration screen with 2025 iOS design aesthetics
struct RegisterView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var fullName: String = ""
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var isPhoneNumberValid = true
    @State private var isPasswordValid = true
    @State private var isConfirmPasswordValid = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var agreedToTerms = false
    @FocusState private var isFullNameFocused: Bool
    @FocusState private var isPhoneNumberFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    @FocusState private var isConfirmPasswordFocused: Bool
    
    /// Callback to navigate back to login view
    let onBackToLogin: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Standardized background
                StandardTabBackground(configuration: .login)
                
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 20)
                        
                        // Header section with modern styling
                        headerSection
                            .padding(.bottom, 32)
                        
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
        .dismissKeyboardOnSwipeDown()
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 24) {
            // Back button
            HStack {
                Button(action: {
                    HapticManager.buttonTap()
                    onBackToLogin()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(DesignTokens.Colors.primaryPurple)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(DesignTokens.Colors.borderSecondary, lineWidth: 1)
                            )
                    )
                }
                .accessibilityLabel("Go back to login")
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Modern logo with liquid glass effect
            modernLogo
            
            // Welcome text with refined typography
            VStack(spacing: 12) {
                Text("Create Account")
                    .font(DesignTokens.ResponsiveTypography.headingLarge)
                    .foregroundStyle(titleGradient)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Join the smart home revolution")
                    .font(DesignTokens.ResponsiveTypography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .tracking(0.5)
            }
        }
    }
    
    private var modernLogo: some View {
        ZStack {
            // Background blur effect
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xxxl)
                .fill(.ultraThinMaterial)
                .frame(width: 80, height: 80)
                .standardShadowMedium()
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xxxl)
                        .stroke(DesignTokens.Colors.borderPrimary.opacity(0.5), lineWidth: 1)
                )
            
            // Logo content
            Image(systemName: "person.badge.plus.fill")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            DesignTokens.Colors.primaryPurple,
                            DesignTokens.Colors.primaryCyan
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: DesignTokens.Colors.primaryPurple.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel("Registration icon")
    }
    
    private var titleGradient: LinearGradient {
        LinearGradient(
            colors: [
                DesignTokens.Colors.primaryPurple,
                DesignTokens.Colors.primaryCyan,
                DesignTokens.Colors.primaryGreen
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Main Content Card
    
    private var mainContentCard: some View {
        VStack(spacing: DesignTokens.ResponsiveSpacing.lg) {
            // Input fields section
            inputFieldsSection
            
            // Terms agreement
            termsAgreementSection
            
            // Error display
            errorDisplay
            
            // Register button
            registerButton
            
            // Alternative options
            alternativeOptions
        }
        .padding(.vertical, DesignTokens.ResponsiveSpacing.xl)
        .padding(.horizontal, DesignTokens.ResponsiveSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xxl)
                .fill(.ultraThinMaterial)
                .standardShadowMedium()
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xxl)
                        .stroke(DesignTokens.Colors.borderPrimary.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Input Fields
    
    private var inputFieldsSection: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            modernFullNameField
            modernPhoneNumberField
            modernPasswordField
            modernConfirmPasswordField
        }
    }
    
    private var modernFullNameField: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .frame(width: DesignTokens.IconSize.lg)
                
                TextField("Full Name", text: $fullName)
                    .font(DesignTokens.ResponsiveTypography.bodyMedium)
                    .autocapitalization(.words)
                    .focused($isFullNameFocused)
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.vertical, DesignTokens.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .fill(DesignTokens.Colors.backgroundSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .stroke(
                                isFullNameFocused ? DesignTokens.Colors.primaryPurple : Color.clear,
                                lineWidth: isFullNameFocused ? 2 : 1
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFullNameFocused)
        }
        .accessibilityLabel("Full name field")
    }
    
    private var modernPhoneNumberField: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .frame(width: DesignTokens.IconSize.lg)
                
                TextField("Phone Number", text: $phoneNumber)
                    .font(DesignTokens.ResponsiveTypography.bodyMedium)
                    .keyboardType(.phonePad)
                    .autocapitalization(.none)
                    .focused($isPhoneNumberFocused)
                    .onChange(of: phoneNumber) { newValue in
                        phoneNumber = formatPhoneNumber(newValue)
                        validatePhoneNumber(phoneNumber)
                    }
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.vertical, DesignTokens.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .fill(DesignTokens.Colors.backgroundSurface)
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
                        .font(.caption)
                    
                    Text("Please enter a valid phone number")
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.primaryRed)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .accessibilityLabel("Phone number field")
    }
    
    private var modernPasswordField: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(DesignTokens.Colors.textSecondary)
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
                .onChange(of: password) { newValue in
                    validatePassword(newValue)
                }
                
                Button(action: togglePasswordVisibility) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .font(.system(size: DesignTokens.IconSize.lg))
                }
                .accessibilityLabel(showPassword ? "Hide password" : "Show password")
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.vertical, DesignTokens.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .fill(DesignTokens.Colors.backgroundSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .stroke(
                                isPasswordFocused ? DesignTokens.Colors.primaryPurple :
                                !isPasswordValid ? DesignTokens.Colors.primaryRed : Color.clear,
                                lineWidth: isPasswordFocused ? 2 : 1
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isPasswordFocused)
            
            if !isPasswordValid && !password.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Password must contain:")
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: password.count >= 7 ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(password.count >= 7 ? DesignTokens.Colors.primaryGreen : DesignTokens.Colors.textTertiary)
                            .font(.caption)
                        Text("At least 7 characters")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: password.contains(where: { $0.isNumber }) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(password.contains(where: { $0.isNumber }) ? DesignTokens.Colors.primaryGreen : DesignTokens.Colors.textTertiary)
                            .font(.caption)
                        Text("One number")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .accessibilityLabel("Password field")
    }
    
    private var modernConfirmPasswordField: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Image(systemName: "lock.rectangle.fill")
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .frame(width: DesignTokens.IconSize.lg)
                
                Group {
                    if showConfirmPassword {
                        TextField("Confirm Password", text: $confirmPassword)
                            .focused($isConfirmPasswordFocused)
                    } else {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .focused($isConfirmPasswordFocused)
                    }
                }
                .font(DesignTokens.ResponsiveTypography.bodyMedium)
                .onChange(of: confirmPassword) { _ in
                    validateConfirmPassword()
                }
                
                Button(action: toggleConfirmPasswordVisibility) {
                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .font(.system(size: DesignTokens.IconSize.lg))
                }
                .accessibilityLabel(showConfirmPassword ? "Hide confirm password" : "Show confirm password")
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.vertical, DesignTokens.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .fill(DesignTokens.Colors.backgroundSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .stroke(
                                isConfirmPasswordFocused ? DesignTokens.Colors.primaryPurple :
                                !isConfirmPasswordValid ? DesignTokens.Colors.primaryRed : Color.clear,
                                lineWidth: isConfirmPasswordFocused ? 2 : 1
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isConfirmPasswordFocused)
            
            if !isConfirmPasswordValid && !confirmPassword.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignTokens.Colors.primaryRed)
                        .font(.caption)
                    
                    Text("Passwords do not match")
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.primaryRed)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .accessibilityLabel("Confirm password field")
    }
    
    // MARK: - Terms Agreement
    
    private var termsAgreementSection: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            Button(action: {
                HapticManager.toggle()
                agreedToTerms.toggle()
            }) {
                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                    .foregroundColor(agreedToTerms ? DesignTokens.Colors.primaryGreen : DesignTokens.Colors.textTertiary)
                    .font(.system(size: DesignTokens.IconSize.lg))
            }
            .accessibilityLabel(agreedToTerms ? "Terms agreed" : "Agree to terms")
            
            VStack(alignment: .leading, spacing: 4) {
                Text("I agree to the Terms of Service and Privacy Policy")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                HStack(spacing: 16) {
                    Button("Terms of Service") {
                        HapticManager.buttonTap()
                        // Handle terms viewing
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.primaryPurple)
                    
                    Button("Privacy Policy") {
                        HapticManager.buttonTap()
                        // Handle privacy policy viewing
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.primaryPurple)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Buttons and Actions
    
    private var registerButton: some View {
        Button(action: handleRegistration) {
            HStack(spacing: DesignTokens.Spacing.md) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }
                
                Text(isLoading ? "Creating Account..." : "Create Account")
                    .font(DesignTokens.ResponsiveTypography.buttonLarge)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .fill(
                        isFormValid() ?
                        LinearGradient(
                            colors: [
                                DesignTokens.Colors.primaryPurple,
                                DesignTokens.Colors.primaryCyan
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [DesignTokens.Colors.textTertiary.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
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
        .accessibilityLabel("Create account button")
    }
    
    private var alternativeOptions: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Divider
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(DesignTokens.Colors.borderPrimary)
                
                Text("or")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(DesignTokens.Colors.borderPrimary)
            }
            
            // Back to login
            Button(action: {
                HapticManager.buttonTap()
                onBackToLogin()
            }) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Text("Already have an account?")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Text("Sign In")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.primaryPurple)
                }
            }
            .accessibilityLabel("Sign in instead")
        }
    }
    
    // MARK: - Supporting Views
    
    private var errorDisplay: some View {
        Group {
            if showError {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignTokens.Colors.primaryRed)
                    
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.primaryRed)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.vertical, DesignTokens.Spacing.md)
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
    
    // MARK: - Footer
    
    private var footerSection: some View {
        Button(action: {
            HapticManager.buttonTap()
            // Handle help/support
        }) {
            Text("Need help? Contact our support team")
                .font(.system(size: 13))
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Dismisses the keyboard by removing focus from all text fields
    private func dismissKeyboard() {
        isFullNameFocused = false
        isPhoneNumberFocused = false
        isPasswordFocused = false
        isConfirmPasswordFocused = false
    }
    
    /// Toggles password field visibility with haptic feedback
    private func togglePasswordVisibility() {
        showPassword.toggle()
        HapticManager.buttonTap()
    }
    
    /// Toggles confirm password field visibility with haptic feedback
    private func toggleConfirmPasswordVisibility() {
        showConfirmPassword.toggle()
        HapticManager.buttonTap()
    }
    
    /// Formats phone number with China mobile format (3-4-4 spacing)
    /// - Parameter phoneNumber: Raw phone number string
    /// - Returns: Formatted phone number string in China format
    private func formatPhoneNumber(_ phoneNumber: String) -> String {
        // Remove all non-numeric characters
        let digits = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // Limit to 11 digits (China mobile standard)
        let limitedDigits = String(digits.prefix(11))
        
        // Format based on length - China format: XXX XXXX XXXX
        switch limitedDigits.count {
        case 0:
            return ""
        case 1...3:
            return limitedDigits
        case 4...7:
            let firstPart = String(limitedDigits.prefix(3))
            let secondPart = String(limitedDigits.dropFirst(3))
            return "\(firstPart) \(secondPart)"
        case 8...11:
            let firstPart = String(limitedDigits.prefix(3))
            let secondPart = String(limitedDigits.dropFirst(3).prefix(4))
            let thirdPart = String(limitedDigits.dropFirst(7))
            return "\(firstPart) \(secondPart) \(thirdPart)"
        default:
            return limitedDigits
        }
    }
    
    /// Validates China mobile phone number format
    /// - Parameter phoneNumber: Phone number string to validate
    private func validatePhoneNumber(_ phoneNumber: String) {
        // Extract digits only for validation
        let digits = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            // China mobile numbers: 11 digits starting with 1 and valid second digit
            if phoneNumber.isEmpty {
                isPhoneNumberValid = true
            } else if digits.count == 11 && digits.hasPrefix("1") {
                // Valid China mobile prefixes: 13X, 14X, 15X, 16X, 17X, 18X, 19X
                let secondDigit = String(digits.dropFirst(1).prefix(1))
                isPhoneNumberValid = ["3", "4", "5", "6", "7", "8", "9"].contains(secondDigit)
            } else {
                isPhoneNumberValid = false
            }
        }
    }
    
    /// Validates password strength requirements
    /// - Parameter password: Password string to validate
    private func validatePassword(_ password: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPasswordValid = password.isEmpty ||
                            (password.count >= 7 &&
                             password.contains(where: { $0.isNumber }))
        }
        
        // Re-validate confirm password when password changes
        if !confirmPassword.isEmpty {
            validateConfirmPassword()
        }
    }
    
    /// Validates that confirm password matches password
    private func validateConfirmPassword() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isConfirmPasswordValid = confirmPassword.isEmpty || password == confirmPassword
        }
    }
    
    /// Validates entire form before submission
    /// - Returns: True if all form fields are valid and required fields are filled
    private func isFormValid() -> Bool {
        return !fullName.isEmpty &&
               !phoneNumber.isEmpty &&
               !password.isEmpty &&
               !confirmPassword.isEmpty &&
               isPhoneNumberValid &&
               isPasswordValid &&
               isConfirmPasswordValid &&
               agreedToTerms
    }
    
    /// Handles registration process with form validation and API integration
    private func handleRegistration() {
        guard isFormValid() else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
            showError = false
        }
        
        HapticManager.buttonTap()
        
        // Remove spaces from phone number for API
        let cleanPhoneNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        
        Task {
            do {
                let response = try await APIClient.shared.register(
                    accountName: fullName,
                    phoneNumber: cleanPhoneNumber,
                    password: password,
                    userId: appViewModel.currentUserId // Optional: nil for direct registration, user_id for anonymous-to-registered conversion
                )
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoading = false
                    }
                    
                    // Registration successful
                    HapticManager.success()
                    
                    // Update user ID in app state
                    appViewModel.currentUserId = String(response.data.user.id)
                    appViewModel.isLoggedIn = true
                    
                    // Navigate back to login or main app flow
                    onBackToLogin()
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoading = false
                    }
                    
                    // Handle registration error
                    let errorMsg: String
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .badRequest(let message):
                            errorMsg = message
                        case .unauthorized:
                            errorMsg = "Registration not authorized. Please try again."
                        case .serverError:
                            errorMsg = "Server error. Please try again later."
                        case .networkError:
                            errorMsg = "Network error. Please check your connection."
                        default:
                            errorMsg = "Registration failed. Please try again."
                        }
                    } else {
                        errorMsg = "Registration failed. Please try again."
                    }
                    
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showError = true
                        errorMessage = errorMsg
                    }
                    
                    HapticManager.error()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RegisterView {
        print("Back to login")
    }
    .environmentObject(AppViewModel())
}
