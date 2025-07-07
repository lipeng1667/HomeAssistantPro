//
//  EnhancedCreatePostView.swift
//  HomeAssistantPro
//
//  Created: July 7, 2025
//  Last Modified: July 7, 2025
//  Author: Michael Lee
//  Version: 1.0.0
//
//  Purpose: Enhanced forum post creation view with image attachments, responsive design,
//  form validation, and draft saving capabilities using DesignTokens system.
//
//  Update History:
//  v1.0.0 (July 7, 2025) - Initial creation with enhanced features
//
//  Features:
//  - Image attachment support with PhotosPicker
//  - Responsive design using DesignTokens
//  - Real-time form validation with character limits
//  - Auto-save draft functionality
//  - Enhanced category selection with visual feedback
//  - Character counting and validation indicators
//

import SwiftUI

/// Enhanced create post view with image attachments and responsive design
struct EnhancedCreatePostView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var draftManager = DraftManager.shared
    
    // MARK: - Form State
    @State private var postTitle = ""
    @State private var postContent = ""
    @State private var selectedCategory = "General"
    @State private var attachedImages: [UIImage] = []
    
    // MARK: - UI State
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var showValidationError = false
    @State private var validationMessage = ""
    
    // MARK: - Constants
    private let categories = ["General", "Smart Home", "Lighting", "Security", "Voice Control", "DIY"]
    private let maxTitleLength = 100
    private let maxContentLength = 2000
    private let maxImages = 3
    
    var body: some View {
        NavigationView {
            ZStack {
                // Responsive background
                backgroundView
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignTokens.ResponsiveSpacing.lg) {
                        // Header section
                        headerSection
                        
                        // Form content
                        VStack(spacing: DesignTokens.ResponsiveSpacing.md) {
                            categorySection
                            titleSection
                            contentSection
                            imageSection
                        }
                        
                        // Action buttons
                        actionButtons
                    }
                    .contentMargins()
                    .responsiveBottomPadding(80, 100, 120)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadDraftIfAvailable()
            }
            .onChange(of: postTitle) { _ in saveDraft() }
            .onChange(of: postContent) { _ in saveDraft() }
            .onChange(of: selectedCategory) { _ in saveDraft() }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: Binding<UIImage?>(
                    get: { nil },
                    set: { image in
                        if let image = image {
                            attachedImages.append(image)
                            saveDraft()
                        }
                    }
                ))
            }
        }
    }
    
    // MARK: - Background View
    
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                DesignTokens.Colors.backgroundPrimary,
                DesignTokens.Colors.backgroundSecondary
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: DesignTokens.ResponsiveSpacing.sm) {
            Text("Create New Post")
                .font(DesignTokens.ResponsiveTypography.headingLarge)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text("Share your question or insight with the community")
                .font(DesignTokens.ResponsiveTypography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(DesignTokens.DeviceSize.current.isSmallDevice ? 2 : nil)
        }
        .responsiveVerticalPadding(20, 24, 28)
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.ResponsiveSpacing.sm) {
            HStack {
                Text("Category")
                    .font(DesignTokens.ResponsiveTypography.bodyLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Text("Required")
                    .font(DesignTokens.ResponsiveTypography.caption)
                    .foregroundColor(DesignTokens.Colors.primaryCyan)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.ResponsiveSpacing.sm) {
                    ForEach(categories, id: \.self) { category in
                        categoryButton(category)
                    }
                }
                .responsiveHorizontalPadding(4, 6, 8)
            }
        }
    }
    
    private func categoryButton(_ category: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = category
            }
            HapticManager.buttonTap()
        }) {
            Text(category)
                .font(DesignTokens.ResponsiveTypography.bodyMedium)
                .foregroundColor(selectedCategory == category ? .white : DesignTokens.Colors.textPrimary)
                .responsivePadding(8, 10, 12)
                .background(
                    Capsule()
                        .fill(selectedCategory == category ? 
                              DesignTokens.Colors.Forum.primary : 
                              DesignTokens.Colors.backgroundSurface)
                        .overlay(
                            Capsule()
                                .stroke(
                                    selectedCategory == category ? 
                                    Color.clear : 
                                    DesignTokens.Colors.borderPrimary, 
                                    lineWidth: 1
                                )
                        )
                )
        }
        .scaleButtonStyle()
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.ResponsiveSpacing.sm) {
            HStack {
                Text("Title")
                    .font(DesignTokens.ResponsiveTypography.bodyLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(postTitle.count)/\(maxTitleLength)")
                        .font(DesignTokens.ResponsiveTypography.caption)
                        .foregroundColor(titleLengthColor)
                    
                    Text("Required")
                        .font(DesignTokens.ResponsiveTypography.caption)
                        .foregroundColor(DesignTokens.Colors.primaryCyan)
                }
            }
            
            TextField("Enter your post title...", text: $postTitle)
                .font(DesignTokens.ResponsiveTypography.bodyMedium)
                .responsivePadding(12, 14, 16)
                .frame(height: DesignTokens.ResponsiveContainer.inputFieldHeight)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.ResponsiveSpacing.sm)
                        .fill(DesignTokens.Colors.backgroundSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.ResponsiveSpacing.sm)
                                .stroke(titleBorderColor, lineWidth: 1)
                        )
                )
                .onChange(of: postTitle) { newValue in
                    if newValue.count > maxTitleLength {
                        postTitle = String(newValue.prefix(maxTitleLength))
                    }
                }
        }
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.ResponsiveSpacing.sm) {
            HStack {
                Text("Content")
                    .font(DesignTokens.ResponsiveTypography.bodyLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(postContent.count)/\(maxContentLength)")
                        .font(DesignTokens.ResponsiveTypography.caption)
                        .foregroundColor(contentLengthColor)
                    
                    Text("Required")
                        .font(DesignTokens.ResponsiveTypography.caption)
                        .foregroundColor(DesignTokens.Colors.primaryCyan)
                }
            }
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $postContent)
                    .font(DesignTokens.ResponsiveTypography.bodyMedium)
                    .frame(minHeight: DesignTokens.DeviceSize.current.spacing(120, 140, 160))
                    .responsivePadding(12, 14, 16)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.ResponsiveSpacing.sm)
                            .fill(DesignTokens.Colors.backgroundSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.ResponsiveSpacing.sm)
                                    .stroke(contentBorderColor, lineWidth: 1)
                            )
                    )
                    .onChange(of: postContent) { newValue in
                        if newValue.count > maxContentLength {
                            postContent = String(newValue.prefix(maxContentLength))
                        }
                    }
                
                // Placeholder text
                if postContent.isEmpty {
                    Text("Write your post content...")
                        .font(DesignTokens.ResponsiveTypography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textSecondary.opacity(0.6))
                        .responsivePadding(16, 18, 20)
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    // MARK: - Image Section
    
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.ResponsiveSpacing.sm) {
            HStack {
                Text("Images")
                    .font(DesignTokens.ResponsiveTypography.bodyLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Text("Optional (\(attachedImages.count)/\(maxImages))")
                    .font(DesignTokens.ResponsiveTypography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.ResponsiveSpacing.sm) {
                    // Add image button
                    if attachedImages.count < maxImages {
                        Button(action: {
                            showImagePicker = true
                        }) {
                            addImageButton
                        }
                    }
                    
                    // Attached images
                    ForEach(Array(attachedImages.enumerated()), id: \.offset) { index, image in
                        imagePreview(image, index: index)
                    }
                }
                .responsiveHorizontalPadding(4, 6, 8)
            }
        }
    }
    
    private var addImageButton: some View {
        VStack(spacing: DesignTokens.ResponsiveSpacing.xs) {
            Image(systemName: "plus")
                .font(.system(size: DesignTokens.DeviceSize.current.fontSize(16, 18, 20), weight: .semibold))
                .foregroundColor(DesignTokens.Colors.primaryCyan)
            
            Text("Add Photo")
                .font(DesignTokens.ResponsiveTypography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .frame(
            width: DesignTokens.DeviceSize.current.spacing(80, 90, 100),
            height: DesignTokens.DeviceSize.current.spacing(80, 90, 100)
        )
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.ResponsiveSpacing.sm)
                .fill(DesignTokens.Colors.backgroundSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.ResponsiveSpacing.sm)
                        .stroke(DesignTokens.Colors.primaryCyan.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                )
        )
        .scaleButtonStyle()
    }
    
    private func imagePreview(_ image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(
                    width: DesignTokens.DeviceSize.current.spacing(80, 90, 100),
                    height: DesignTokens.DeviceSize.current.spacing(80, 90, 100)
                )
                .clipped()
                .background(DesignTokens.Colors.backgroundSecondary)
                .cornerRadius(DesignTokens.ResponsiveSpacing.sm)
            
            // Remove button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    attachedImages.remove(at: index)
                }
                HapticManager.buttonTap()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: DesignTokens.DeviceSize.current.fontSize(16, 18, 20)))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(DesignTokens.Colors.primaryRed)
                            .frame(width: 20, height: 20)
                    )
            }
            .offset(x: 8, y: -8)
            .scaleButtonStyle()
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: DesignTokens.ResponsiveSpacing.md) {
            // Cancel button
            Button(action: {
                HapticManager.buttonTap()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .font(DesignTokens.ResponsiveTypography.buttonMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignTokens.ResponsiveContainer.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.ResponsiveSpacing.sm)
                            .fill(DesignTokens.Colors.backgroundSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.ResponsiveSpacing.sm)
                                    .stroke(DesignTokens.Colors.borderPrimary, lineWidth: 1)
                            )
                    )
            }
            .scaleButtonStyle()
            
            // Post button
            Button(action: {
                createPost()
            }) {
                HStack(spacing: DesignTokens.ResponsiveSpacing.xs) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(isLoading ? "Posting..." : "Post")
                        .font(DesignTokens.ResponsiveTypography.buttonMedium)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.ResponsiveContainer.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.ResponsiveSpacing.sm)
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignTokens.Colors.Forum.primary,
                                    DesignTokens.Colors.Forum.secondary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .standardShadowMedium()
                )
            }
            .scaleButtonStyle()
            .disabled(isFormInvalid || isLoading)
            .opacity(isFormInvalid ? 0.6 : 1.0)
        }
        .responsiveVerticalPadding(16, 20, 24)
    }
    
    // MARK: - Computed Properties
    
    private var isFormInvalid: Bool {
        postTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        postContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        postTitle.count > maxTitleLength ||
        postContent.count > maxContentLength
    }
    
    private var titleLengthColor: Color {
        if postTitle.count > maxTitleLength * 9 / 10 {
            return DesignTokens.Colors.primaryRed
        } else if postTitle.count > maxTitleLength * 7 / 10 {
            return DesignTokens.Colors.primaryAmber
        } else {
            return DesignTokens.Colors.textSecondary
        }
    }
    
    private var contentLengthColor: Color {
        if postContent.count > maxContentLength * 9 / 10 {
            return DesignTokens.Colors.primaryRed
        } else if postContent.count > maxContentLength * 7 / 10 {
            return DesignTokens.Colors.primaryAmber
        } else {
            return DesignTokens.Colors.textSecondary
        }
    }
    
    private var titleBorderColor: Color {
        if postTitle.isEmpty {
            return DesignTokens.Colors.borderPrimary
        } else if postTitle.count > maxTitleLength {
            return DesignTokens.Colors.primaryRed
        } else {
            return DesignTokens.Colors.primaryCyan.opacity(0.5)
        }
    }
    
    private var contentBorderColor: Color {
        if postContent.isEmpty {
            return DesignTokens.Colors.borderPrimary
        } else if postContent.count > maxContentLength {
            return DesignTokens.Colors.primaryRed
        } else {
            return DesignTokens.Colors.primaryCyan.opacity(0.5)
        }
    }
    
    // MARK: - Helper Methods
    
    
    /// Create new post with validation and submission
    private func createPost() {
        guard !isFormInvalid else { return }
        
        isLoading = true
        HapticManager.buttonTap()
        
        // Simulate post creation
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            await MainActor.run {
                isLoading = false
                draftManager.clearDraft()
                presentationMode.wrappedValue.dismiss()
                
                // Show success feedback
                HapticManager.buttonTap()
            }
        }
    }
    
    /// Save current form state as draft
    private func saveDraft() {
        let draft = PostDraft(
            title: postTitle,
            content: postContent,
            category: selectedCategory,
            imageCount: attachedImages.count,
            lastModified: Date()
        )
        draftManager.saveDraft(draft)
    }
    
    /// Load existing draft if available
    private func loadDraftIfAvailable() {
        if let draft = draftManager.currentDraft {
            postTitle = draft.title
            postContent = draft.content
            selectedCategory = draft.category
        }
    }
}

// MARK: - Draft Management

/// Post draft data structure
struct PostDraft: Codable {
    let title: String
    let content: String
    let category: String
    let imageCount: Int
    let lastModified: Date
}

/// Draft manager for auto-saving and loading drafts
@MainActor
class DraftManager: ObservableObject {
    static let shared = DraftManager()
    
    @Published var currentDraft: PostDraft?
    
    private let draftKey = "forum_post_draft"
    
    private init() {
        loadDraft()
    }
    
    /// Save draft to UserDefaults
    /// - Parameter draft: PostDraft to save
    func saveDraft(_ draft: PostDraft) {
        guard !draft.title.isEmpty || !draft.content.isEmpty else {
            clearDraft()
            return
        }
        
        if let encoded = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(encoded, forKey: draftKey)
            currentDraft = draft
        }
    }
    
    /// Load draft from UserDefaults
    func loadDraft() {
        if let data = UserDefaults.standard.data(forKey: draftKey),
           let draft = try? JSONDecoder().decode(PostDraft.self, from: data) {
            currentDraft = draft
        }
    }
    
    /// Clear current draft
    func clearDraft() {
        UserDefaults.standard.removeObject(forKey: draftKey)
        currentDraft = nil
    }
}

// MARK: - Image Picker

/// UIImagePickerController wrapper for SwiftUI
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    EnhancedCreatePostView()
        .environmentObject(AppViewModel())
}
