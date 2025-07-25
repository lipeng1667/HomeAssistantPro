//
//  EditReplyView.swift
//  HomeAssistantPro
//
//  Created: July 14, 2025
//  Last Modified: July 14, 2025
//  Author: Claude
//  Version: 1.0.0
//
//  Purpose: Edit existing forum reply view with pre-filled form data, responsive design,
//  form validation, and image management using DesignTokens system.
//
//  Update History:
//  v1.0.0 (July 14, 2025) - Initial creation with enhanced editing features
//
//  Features:
//  - Pre-filled form with existing reply data
//  - Image attachment support with PhotosPicker
//  - Responsive design using DesignTokens
//  - Real-time form validation with character limits
//  - Character counting and validation indicators
//

import SwiftUI
import os.log

/// Enhanced edit reply view with pre-filled data and responsive design
struct EditReplyView: View {
    let reply: ForumReply
    let topicId: Int
    let onReplyUpdated: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Form State
    @State private var replyContent: String
    @State private var attachedImages: [UIImage] = []
    @State private var existingImageUrls: [String]
    
    // MARK: - UI State
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var showValidationError = false
    @State private var validationMessage = ""
    
    // MARK: - Services
    private let forumService = ForumService.shared
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "EditReplyView")
    
    // MARK: - Constants
    private let maxContentLength = 1000
    private let maxImages = 2
    
    /// Initialize with existing reply data
    /// - Parameters:
    ///   - reply: The reply to edit
    ///   - topicId: The parent topic ID
    ///   - onReplyUpdated: Callback when reply is successfully updated
    init(reply: ForumReply, topicId: Int, onReplyUpdated: @escaping () -> Void) {
        self.reply = reply
        self.topicId = topicId
        self.onReplyUpdated = onReplyUpdated
        self._replyContent = State(initialValue: reply.content)
        self._existingImageUrls = State(initialValue: reply.images)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                Divider()
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DesignTokens.ResponsiveSpacing.lg) {
                        // Parent reply context (if editing a nested reply)
                        if let parentReply = reply.parentReply {
                            parentReplyContext(parentReply)
                        }
                        
                        // Content editor
                        contentSection
                        
                        // Image section
                        imageSection
                        
                        // Action buttons
                        actionButtons
                    }
                    .contentMargins()
                    .responsiveBottomPadding(80, 100, 120)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: Binding<UIImage?>(
                    get: { nil },
                    set: { image in
                        if let image = image {
                            attachedImages.append(image)
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
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Button("Cancel") {
                HapticManager.buttonTap()
                presentationMode.wrappedValue.dismiss()
            }
            .font(DesignTokens.ResponsiveTypography.bodyMedium)
            .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Spacer()
            
            Text("Edit Reply")
                .font(DesignTokens.ResponsiveTypography.headingMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Spacer()
            
            Button("Update") {
                updateReply()
            }
            .font(DesignTokens.ResponsiveTypography.bodyMedium)
            .foregroundColor(isFormInvalid ? DesignTokens.Colors.textSecondary : DesignTokens.Colors.primaryCyan)
            .disabled(isFormInvalid || isLoading)
        }
        .responsivePadding(16, 20, 24)
    }
    
    // MARK: - Parent Reply Context
    
    private func parentReplyContext(_ parentReply: ParentReplyInfo) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.ResponsiveSpacing.sm) {
            Text("Replying to:")
                .font(DesignTokens.ResponsiveTypography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(parentReply.author.name)
                    .font(DesignTokens.ResponsiveTypography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .fontWeight(.medium)
                
                Text(parentReply.contentPreview)
                    .font(DesignTokens.ResponsiveTypography.bodySmall)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(3)
            }
            .responsivePadding(12, 14, 16)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.ResponsiveSpacing.sm)
                    .fill(DesignTokens.Colors.Forum.primary.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.ResponsiveSpacing.sm)
                            .stroke(DesignTokens.Colors.Forum.primary.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.ResponsiveSpacing.sm) {
            HStack {
                Text("Reply Content")
                    .font(DesignTokens.ResponsiveTypography.bodyLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Text("\(replyContent.count)/\(maxContentLength)")
                    .font(DesignTokens.ResponsiveTypography.caption)
                    .foregroundColor(contentLengthColor)
            }
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $replyContent)
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
                    .onChange(of: replyContent) { newValue in
                        if newValue.count > maxContentLength {
                            replyContent = String(newValue.prefix(maxContentLength))
                        }
                    }
                
                // Placeholder text
                if replyContent.isEmpty {
                    Text("Write your reply...")
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
                    
                    // Existing images
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
            
            // Update button
            Button(action: {
                updateReply()
            }) {
                HStack(spacing: DesignTokens.ResponsiveSpacing.xs) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(isLoading ? "Updating..." : "Update")
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
    
    private var totalImageCount: Int {
        return existingImageUrls.count + attachedImages.count
    }
    
    private var isFormInvalid: Bool {
        let trimmedContent = replyContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return trimmedContent.isEmpty ||
               trimmedContent.count < 1 ||
               replyContent.count > maxContentLength
    }
    
    private var contentLengthColor: Color {
        if replyContent.count > maxContentLength * 9 / 10 {
            return DesignTokens.Colors.primaryRed
        } else if replyContent.count > maxContentLength * 7 / 10 {
            return DesignTokens.Colors.primaryAmber
        } else {
            return DesignTokens.Colors.textSecondary
        }
    }
    
    private var contentBorderColor: Color {
        if replyContent.isEmpty {
            return DesignTokens.Colors.borderPrimary
        } else if replyContent.count > maxContentLength {
            return DesignTokens.Colors.primaryRed
        } else {
            return DesignTokens.Colors.primaryCyan.opacity(0.5)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Updates the reply with validation and submission
    private func updateReply() {
        guard !isFormInvalid else { return }
        
        isLoading = true
        HapticManager.buttonTap()
        
        Task {
            do {
                // Prepare final image URLs (existing + new uploads)
                var finalImageUrls = existingImageUrls
                
                // Upload new images if any
                if !attachedImages.isEmpty {
                    let imageFiles = await convertImagesToUploadRequests()
                    
                    for imageFile in imageFiles {
                        let uploadResponse = try await forumService.uploadFile(imageFile)
                        
                        if let fileUrl = uploadResponse.data.fileUrl {
                            finalImageUrls.append(fileUrl)
                            logger.info("✅ New image uploaded successfully: \(fileUrl)")
                        }
                    }
                }
                
                // Update the reply
                let response = try await forumService.updateReply(
                    replyId: reply.id,
                    content: replyContent.trimmingCharacters(in: .whitespacesAndNewlines),
                    images: finalImageUrls
                )
                
                await MainActor.run {
                    logger.info("Reply updated successfully with ID: \(response.data.reply.id)")
                    isLoading = false
                    onReplyUpdated()
                    presentationMode.wrappedValue.dismiss()
                    HapticManager.buttonTap()
                }
                
            } catch {
                await MainActor.run {
                    logger.error("Failed to update reply: \(error.localizedDescription)")
                    isLoading = false
                    validationMessage = error.localizedDescription
                    showValidationError = true
                }
            }
        }
    }
    
    /// Convert UIImages to FileUploadRequest objects for API upload
    @MainActor
    private func convertImagesToUploadRequests() async -> [FileUploadRequest] {
        guard !attachedImages.isEmpty else { 
            logger.info("No new images to convert")
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
            
            let fileName = "reply_edit_\(reply.id)_\(index)_\(Date().timeIntervalSince1970).jpg"
            
            let fileRequest = FileUploadRequest(
                file: imageData,
                fileName: fileName,
                mimeType: "image/jpeg",
                userId: userId,
                type: "reply",
                postId: reply.id
            )
            
            fileRequests.append(fileRequest)
            logger.info("Prepared new image \(index + 1) for upload - fileName: \(fileName), size: \(imageData.count) bytes")
        }
        
        logger.info("Converted \(fileRequests.count) new images to upload requests")
        return fileRequests
    }
}

// MARK: - Preview

#Preview {
    EditReplyView(
        reply: ForumReply(
            id: 1,
            content: "This is a test reply content",
            author: ForumAuthor(id: 1, name: "Test User", status: 0),
            parentReplyId: nil,
            parentReply: nil,
            likeCount: 3,
            isLiked: false,
            status: 0,
            images: ["https://example.com/image1.jpg"],
            createdAt: "2024-01-15T10:30:00Z",
            updatedAt: "2024-01-15T10:30:00Z"
        ),
        topicId: 1,
        onReplyUpdated: {}
    )
}
