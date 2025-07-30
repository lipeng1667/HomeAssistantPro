//
//  CreatePostView.swift
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
import os.log

/// Enhanced create/edit post view with image attachments and responsive design
struct CreatePostView: View {
    
    /// Mode enum to differentiate between creating new topic or editing existing one
    enum Mode {
        case create
        case edit(ForumTopic)
        
        var title: String {
            switch self {
            case .create: return "Create New Post"
            case .edit: return "Edit Topic"
            }
        }
        
        var description: String {
            switch self {
            case .create: return "Share your question or insight with the community"
            case .edit: return "Update your topic information"
            }
        }
        
        var buttonText: String {
            switch self {
            case .create: return "Post"
            case .edit: return "Update"
            }
        }
        
        var loadingText: String {
            switch self {
            case .create: return "Posting..."
            case .edit: return "Updating..."
            }
        }
    }
    
    let mode: Mode
    let onCompletion: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var draftManager = DraftManager.shared
    
    // MARK: - Form State
    @State private var postTitle: String
    @State private var postContent: String
    @State private var selectedCategory: String
    @State private var attachedImages: [UIImage] = []
    @State private var existingImageUrls: [String] = []
    
    // MARK: - UI State
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var showValidationError = false
    @State private var validationMessage = ""
    @State private var categories: [ForumCategory] = []
    
    // MARK: - Services
    private let forumService = ForumService.shared
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "CreatePostView")
    
    // MARK: - Constants
    private let defaultCategories = ["Smart Home", "Lighting", "Security", "Voice Control", "DIY"]
    private let maxTitleLength = 100
    private let maxContentLength = 2000
    private let maxImages = 3
    
    /// Initialize with mode (create new or edit existing)
    /// - Parameters:
    ///   - mode: Create new topic or edit existing topic
    ///   - onCompletion: Callback when operation completes successfully
    init(mode: Mode = .create, onCompletion: @escaping () -> Void = {}) {
        self.mode = mode
        self.onCompletion = onCompletion
        
        // Initialize form state based on mode
        switch mode {
        case .create:
            self._postTitle = State(initialValue: "")
            self._postContent = State(initialValue: "")
            self._selectedCategory = State(initialValue: "Smart Home")
            
        case .edit(let topic):
            print("🔧 CreatePostView: Initializing in EDIT mode")
            print("🔧 Topic ID: \(topic.id)")
            print("🔧 Topic Title: '\(topic.title)'")
            print("🔧 Topic Content: '\(String(topic.content.prefix(100)))...'")
            print("🔧 Topic Category: '\(topic.category)'")
            print("🔧 Topic Images: \(topic.images)")
            
            self._postTitle = State(initialValue: topic.title)
            self._postContent = State(initialValue: topic.content)
            self._selectedCategory = State(initialValue: topic.category)
            self._existingImageUrls = State(initialValue: topic.images)
        }
    }
    
    var body: some View {
        let _ = print("🔧 CreatePostView: Body rendering - Mode: \(mode.title)")
        let _ = print("🔧 CreatePostView: Title: '\(postTitle)', Content: '\(String(postContent.prefix(50)))...'")
        
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
                print("🔧 CreatePostView: onAppear called - Mode: \(mode.title)")
                
                // Only load draft for create mode
                if case .create = mode {
                    loadDraftIfAvailable()
                } else {
                    print("🔧 CreatePostView: Edit mode - skipping draft loading")
                }
                loadCategories()
            }
            .onChange(of: postTitle) { _ in 
                // Only save draft for create mode
                if case .create = mode {
                    saveDraft()
                }
            }
            .onChange(of: postContent) { _ in 
                // Only save draft for create mode
                if case .create = mode {
                    saveDraft()
                }
            }
            .onChange(of: selectedCategory) { _ in 
                // Only save draft for create mode
                if case .create = mode {
                    saveDraft()
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: Binding<UIImage?>(
                    get: { nil },
                    set: { image in
                        if let image = image {
                            attachedImages.append(image)
                            // Only save draft for create mode
                            if case .create = mode {
                                saveDraft()
                            }
                        }
                    }
                ))
            }
            .alert("Error", isPresented: $showValidationError) {
                Button("OK") {
                    showValidationError = false
                    validationMessage = ""
                }
            } message: {
                Text(validationMessage)
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
            Text(mode.title)
                .font(DesignTokens.ResponsiveTypography.headingLarge)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text(mode.description)
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
                    ForEach(categoryNames, id: \.self) { category in
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
                
                Text("Optional (\(totalImageCount)/\(maxImages))")
                    .font(DesignTokens.ResponsiveTypography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.ResponsiveSpacing.sm) {
                    // Add image button
                    if totalImageCount < maxImages {
                        Button(action: {
                            showImagePicker = true
                        }) {
                            addImageButton
                        }
                    }
                    
                    // Existing images (for edit mode)
                    ForEach(Array(existingImageUrls.enumerated()), id: \.offset) { index, imageUrl in
                        existingImagePreview(imageUrl, index: index)
                    }
                    
                    // New attached images
                    ForEach(Array(attachedImages.enumerated()), id: \.offset) { index, image in
                        newImagePreview(image, index: index)
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
    
    private func existingImagePreview(_ imageUrl: String, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(DesignTokens.Colors.backgroundSecondary)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            }
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
                    existingImageUrls.remove(at: index)
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
    
    private func newImagePreview(_ image: UIImage, index: Int) -> some View {
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
                    
                    Text(isLoading ? mode.loadingText : mode.buttonText)
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
    
    private var categoryNames: [String] {
        if categories.isEmpty {
            return defaultCategories
        }
        return categories.map { $0.name }
    }
    
    private var totalImageCount: Int {
        return existingImageUrls.count + attachedImages.count
    }
    
    private var isFormInvalid: Bool {
        let trimmedTitle = postTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = postContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return trimmedTitle.isEmpty ||
               trimmedContent.isEmpty ||
               trimmedTitle.count < 3 ||
               trimmedContent.count < 10 ||
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
    
    
    /// Create or update post with validation and submission
    private func createPost() {
        guard !isFormInvalid else { return }
        
        isLoading = true
        HapticManager.buttonTap()
        
        Task {
            do {
                // Convert UIImages to FileUploadRequest objects
                let imageFiles = await convertImagesToUploadRequests()
                
                var finalImageUrls = existingImageUrls
                
                // Upload new images if any and add to final URLs
                for imageFile in imageFiles {
                    let uploadResponse = try await forumService.uploadFile(imageFile)
                    if let fileUrl = uploadResponse.data.fileUrl {
                        finalImageUrls.append(fileUrl)
                    }
                }
                
                let response: Any
                switch mode {
                case .create:
                    // Create new topic
                    let createResponse = try await forumService.createTopic(
                        title: postTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                        content: postContent.trimmingCharacters(in: .whitespacesAndNewlines),
                        category: selectedCategory,
                        imageFiles: imageFiles
                    )
                    response = createResponse
                    logger.info("Topic created successfully with ID: \(createResponse.data.topic.id)")
                    
                case .edit(let topic):
                    // Update existing topic
                    let updateResponse = try await forumService.updateTopic(
                        topicId: topic.id,
                        title: postTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                        content: postContent.trimmingCharacters(in: .whitespacesAndNewlines),
                        category: selectedCategory,
                        images: finalImageUrls
                    )
                    response = updateResponse
                    logger.info("Topic updated successfully with ID: \(topic.id)")
                }
                
                await MainActor.run {
                    isLoading = false
                    // Only clear draft for create mode
                    if case .create = mode {
                        draftManager.clearDraft()
                    }
                    onCompletion()
                    presentationMode.wrappedValue.dismiss()
                    HapticManager.buttonTap()
                }
                
            } catch {
                await MainActor.run {
                    logger.error("Failed to create topic: \(error.localizedDescription)")
                    isLoading = false
                    validationMessage = error.localizedDescription
                    showValidationError = true
                }
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
    
    /// Load forum categories from API
    @MainActor
    private func loadCategories() {
        Task {
            do {
                let response = try await forumService.fetchCategories()
                categories = response.data.categories
                logger.info("Loaded \(categories.count) categories")
                
                // Set default category if current selection is not valid
                if !categoryNames.contains(selectedCategory) {
                    selectedCategory = categoryNames.first ?? "Smart Home"
                }
            } catch {
                logger.error("Failed to load categories: \(error.localizedDescription)")
                // Use default categories on failure
            }
        }
    }
    
    /// Convert UIImages to FileUploadRequest objects for API upload
    @MainActor
    private func convertImagesToUploadRequests() async -> [FileUploadRequest] {
        guard !attachedImages.isEmpty else { 
            logger.info("No images to convert")
            return []
        }
        
        var fileRequests: [FileUploadRequest] = []
        
        // Get current user ID for upload requests
        guard let userIdString = try? SettingsStore().retrieveUserId(),
              let userId = Int(userIdString) else {
            logger.error("Failed to get user ID for image upload")
            return []
        }
        
        for (index, image) in attachedImages.enumerated() {
            // Convert UIImage to JPEG data
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                logger.error("Failed to convert image \(index) to JPEG data")
                continue
            }
            
            let fileNamePrefix: String
            let postId: Int?
            
            switch mode {
            case .create:
                fileNamePrefix = "image"
                postId = nil
            case .edit(let topic):
                fileNamePrefix = "topic_edit_\(topic.id)"
                postId = topic.id
            }
            
            let fileName = "\(fileNamePrefix)_\(index)_\(Date().timeIntervalSince1970).jpg"
            
            let fileRequest = FileUploadRequest(
                file: imageData,
                fileName: fileName,
                mimeType: "image/jpeg",
                userId: userId,
                type: "topic",
                postId: postId
            )
            
            fileRequests.append(fileRequest)
            logger.info("Prepared image \(index + 1) for upload - fileName: \(fileName), size: \(imageData.count) bytes")
        }
        
        logger.info("Converted \(fileRequests.count) images to upload requests")
        return fileRequests
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
    CreatePostView(mode: .create) {
        // Preview completion
    }
    .environmentObject(AppViewModel())
}
