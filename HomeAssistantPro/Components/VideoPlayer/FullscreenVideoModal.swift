//
//  FullscreenVideoModal.swift
//  HomeAssistantPro
//
//  Purpose: Full-screen video modal player with custom controls and DesignTokens styling
//  Author: Michael
//  Created: 2025-07-07
//  Modified: 2025-07-07
//
//  Modification Log:
//  - 2025-07-07: Initial creation with fullscreen video player modal
//
//  Functions:
//  - body: Main fullscreen video modal view
//  - videoControls: Custom fullscreen video controls
//  - handleDismiss: Handle modal dismissal with animation
//

import SwiftUI
import AVKit

/// Fullscreen video modal player with custom controls
struct FullscreenVideoModal: View {
    @StateObject private var videoPlayer = LocalVideoPlayer()
    @Environment(\.presentationMode) var presentationMode
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @State private var isLoading = true
    @State private var orientation = UIDeviceOrientation.portrait
    
    let asset: LocalVideoAssets
    let autoPlay: Bool
    
    init(asset: LocalVideoAssets, autoPlay: Bool = true) {
        self.asset = asset
        self.autoPlay = autoPlay
    }
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            if isLoading {
                loadingView
            } else {
                videoPlayerContent
            }
            
            // Top controls overlay
            if showControls {
                topControlsOverlay
            }
            
            // Bottom controls overlay
            if showControls {
                bottomControlsOverlay
            }
        }
        .onAppear {
            loadVideo()
            startControlsTimer()
        }
        .onDisappear {
            videoPlayer.cleanup()
            stopControlsTimer()
        }
        .onTapGesture {
            toggleControls()
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    // Swipe down to dismiss
                    if gesture.translation.height > 100 && abs(gesture.translation.width) < 100 {
                        handleDismiss()
                    }
                }
        )
        .statusBarHidden()
    }
    
    // MARK: - Video Player Content
    
    private var videoPlayerContent: some View {
        GeometryReader { geometry in
            if let player = videoPlayer.player {
                VideoPlayer(player: player)
                    .disabled(true) // Disable built-in controls
                    .ignoresSafeArea()
                    .scaleEffect(calculateVideoScale(for: geometry.size))
                    .clipped()
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: DesignTokens.ResponsiveSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Loading video...")
                .font(DesignTokens.ResponsiveTypography.bodyLarge)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Top Controls Overlay
    
    private var topControlsOverlay: some View {
        VStack {
            HStack {
                // Close button
                Button(action: handleDismiss) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .scaleButtonStyle()
                
                Spacer()
                
                // Video title
                VStack(alignment: .trailing, spacing: 4) {
                    Text(asset.title)
                        .font(DesignTokens.ResponsiveTypography.headingMedium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.trailing)
                    
                    Text(asset.description)
                        .font(DesignTokens.ResponsiveTypography.bodyMedium)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(.horizontal, DesignTokens.ResponsiveSpacing.lg)
            .padding(.top, DesignTokens.ResponsiveSpacing.xl)
            
            Spacer()
        }
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.6), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
            .allowsHitTesting(false)
        )
    }
    
    // MARK: - Bottom Controls Overlay
    
    private var bottomControlsOverlay: some View {
        VStack {
            Spacer()
            
            VStack(spacing: DesignTokens.ResponsiveSpacing.lg) {
                // Main play/pause button
                Button(action: {
                    videoPlayer.togglePlayPause()
                    if videoPlayer.isPlaying {
                        startControlsTimer()
                    } else {
                        showControls = true
                        stopControlsTimer()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                        
                        Image(systemName: videoPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                            .offset(x: videoPlayer.isPlaying ? 0 : 3) // Slight offset for play icon
                    }
                }
                .scaleButtonStyle()
                
                // Progress and time controls
                progressControls
            }
            .padding(.horizontal, DesignTokens.ResponsiveSpacing.xl)
            .padding(.bottom, DesignTokens.ResponsiveSpacing.xl)
        }
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
            .allowsHitTesting(false)
        )
    }
    
    // MARK: - Progress Controls
    
    private var progressControls: some View {
        VStack(spacing: DesignTokens.ResponsiveSpacing.md) {
            // Time labels
            HStack {
                Text(videoPlayer.formattedCurrentTime)
                    .font(DesignTokens.ResponsiveTypography.bodyMedium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(videoPlayer.formattedDuration)
                    .font(DesignTokens.ResponsiveTypography.bodyMedium)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Progress slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 6)
                    
                    // Progress track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DesignTokens.Colors.primaryCyan)
                        .frame(
                            width: geometry.size.width * CGFloat(videoPlayer.progress),
                            height: 6
                        )
                    
                    // Thumb
                    Circle()
                        .fill(DesignTokens.Colors.primaryCyan)
                        .frame(width: 16, height: 16)
                        .offset(x: geometry.size.width * CGFloat(videoPlayer.progress) - 8)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let progress = min(max(0, value.location.x / geometry.size.width), 1)
                            videoPlayer.seek(toProgress: Double(progress))
                            showControls = true
                            resetControlsTimer()
                        }
                )
            }
            .frame(height: 24)
            
            // Additional controls
            HStack {
                // Restart button
                Button(action: {
                    videoPlayer.reset()
                    showControls = true
                    resetControlsTimer()
                }) {
                    Image(systemName: "gobackward")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .scaleButtonStyle()
                
                Spacer()
                
                // Volume indicator (placeholder)
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                // Fullscreen toggle (already fullscreen)
                Image(systemName: "arrow.down.right.and.arrow.up.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadVideo() {
        Task {
            await videoPlayer.loadVideo(asset)
            isLoading = false
            
            if autoPlay {
                videoPlayer.play()
                startControlsTimer()
            }
        }
    }
    
    private func calculateVideoScale(for size: CGSize) -> CGFloat {
        // Maintain aspect ratio while filling screen
        return 1.0
    }
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls.toggle()
        }
        resetControlsTimer()
    }
    
    private func startControlsTimer() {
        stopControlsTimer()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
    }
    
    private func stopControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = nil
    }
    
    private func resetControlsTimer() {
        if videoPlayer.isPlaying {
            startControlsTimer()
        } else {
            stopControlsTimer()
        }
    }
    
    private func handleDismiss() {
        HapticManager.buttonTap()
        videoPlayer.pause()
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Preview

#Preview {
    FullscreenVideoModal(asset: .smartHomeDemo)
}