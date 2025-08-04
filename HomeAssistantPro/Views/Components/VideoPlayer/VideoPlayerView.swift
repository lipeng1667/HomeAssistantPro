//
//  VideoPlayerView.swift
//  HomeAssistantPro
//
//  Purpose: SwiftUI video player component with custom controls and DesignTokens styling
//  Author: Michael
//  Created: 2025-07-07
//  Modified: 2025-07-07
//
//  Modification Log:
//  - 2025-07-07: Initial creation with custom video player UI
//
//  Functions:
//  - body: Main video player view with custom controls
//  - overlayContent: Play/pause overlay and controls
//  - loadingView: Loading state with spinner
//  - errorView: Error state with retry option
//

import SwiftUI
import AVKit

/// Custom video player view with DesignTokens styling
struct VideoPlayerView: View {
    @StateObject private var videoPlayer = LocalVideoPlayer()
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @State private var showFullscreenModal = false
    @State private var customThumbnail: UIImage?
    @State private var isLoadingThumbnail = true
    
    let asset: LocalVideoAssets
    let cornerRadius: CGFloat
    let showPlayButton: Bool
    let enableFullscreen: Bool
    
    init(
        asset: LocalVideoAssets,
        cornerRadius: CGFloat = 12,
        showPlayButton: Bool = true,
        enableFullscreen: Bool = true
    ) {
        self.asset = asset
        self.cornerRadius = cornerRadius
        self.showPlayButton = showPlayButton
        self.enableFullscreen = enableFullscreen
    }
    
    var body: some View {
        ZStack {
            // Video player background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(DesignTokens.Colors.backgroundSecondary)
            
            if videoPlayer.hasError {
                errorView
            } else if videoPlayer.isLoading {
                loadingView
            } else {
                videoPlayerContent
            }
        }
        .clipped()
        .onAppear {
            Task {
                // Load custom thumbnail first
                if let thumbnail = await asset.thumbnailImage() {
                    customThumbnail = thumbnail
                }
                isLoadingThumbnail = false
                
                // Load video but don't auto-play (thumbnail will show)
                await videoPlayer.loadVideo(asset)
                // Keep video paused by default for fullscreen workflow
                videoPlayer.pause()
            }
        }
        .onDisappear {
            videoPlayer.cleanup()
        }
        .fullScreenCover(isPresented: $showFullscreenModal) {
            FullscreenVideoModal(asset: asset, autoPlay: true)
        }
    }
    
    // MARK: - Computed Properties
    
    private var buttonIcon: String {
        if enableFullscreen {
            return "play.fill" // Always show play icon for fullscreen mode
        } else if videoPlayer.isPlaying {
            return "pause.fill"
        } else {
            return "play.fill"
        }
    }
    
    private var buttonIconOffset: CGFloat {
        if enableFullscreen || !videoPlayer.isPlaying {
            return 2 // Slight offset for play icon
        } else {
            return 0
        }
    }
    
    // MARK: - Video Player Content
    
    private var videoPlayerContent: some View {
        ZStack {
            // Show custom thumbnail when video is not playing
            if !videoPlayer.isPlaying && customThumbnail != nil {
                thumbnailView
            }
            
            // AVPlayer layer
            if let player = videoPlayer.player {
                VideoPlayer(player: player)
                    .disabled(true) // Disable built-in controls
                    .cornerRadius(cornerRadius)
                    .opacity(videoPlayer.isPlaying ? 1 : 0)
            }
            
            // Custom overlay controls
            if showControls || !videoPlayer.isPlaying {
                overlayContent
                    .transition(.opacity)
            }
        }
        .onTapGesture {
            if enableFullscreen {
                // Always go fullscreen when tapped (if fullscreen is enabled)
                showFullscreenModal = true
            } else {
                // Fallback to inline play/pause if fullscreen is disabled
                handleTap()
            }
        }
        .onAppear {
            resetControlsTimer()
        }
    }
    
    // MARK: - Thumbnail View
    
    private var thumbnailView: some View {
        Group {
            if let thumbnail = customThumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .cornerRadius(cornerRadius)
            } else if isLoadingThumbnail {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.primaryCyan))
                    .scaleEffect(1.2)
            } else {
                // Fallback background
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(DesignTokens.Colors.backgroundSecondary)
            }
        }
    }
    
    // MARK: - Overlay Content
    
    private var overlayContent: some View {
        ZStack {
            // Semi-transparent background for better visibility
            if showControls || !videoPlayer.isPlaying {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(0.3))
                    .transition(.opacity)
            }
            
            VStack(spacing: DesignTokens.DeviceSize.current.spacing(12, 16, 20)) {
                Spacer()
                
                // Play/Fullscreen button
                if showPlayButton {
                    Button(action: {
                        if enableFullscreen {
                            // Go directly to fullscreen modal (default behavior)
                            showFullscreenModal = true
                        } else {
                            // Fallback to inline play if fullscreen is disabled
                            videoPlayer.togglePlayPause()
                            if videoPlayer.isPlaying {
                                startControlsTimer()
                            } else {
                                showControls = true
                                stopControlsTimer()
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(
                                    width: DesignTokens.DeviceSize.current.spacing(48, 56, 64),
                                    height: DesignTokens.DeviceSize.current.spacing(48, 56, 64)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            
                            Image(systemName: buttonIcon)
                                .font(.system(
                                    size: DesignTokens.DeviceSize.current.fontSize(20, 24, 28),
                                    weight: .semibold
                                ))
                                .foregroundColor(.white)
                                .offset(x: buttonIconOffset)
                        }
                    }
                    .scaleButtonStyle()
                }
                
                Spacer()
                
                // Progress bar (only show when playing or controls visible)
//                if videoPlayer.isPlaying || showControls {
//                    progressBar
//                        .transition(.move(edge: .bottom).combined(with: .opacity))
//                }
            }
            .padding(DesignTokens.DeviceSize.current.spacing(12, 16, 20))
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(spacing: DesignTokens.DeviceSize.current.spacing(8, 10, 12)) {
            // Time labels
            HStack {
                Text(videoPlayer.formattedCurrentTime)
                    .font(.system(size: DesignTokens.DeviceSize.current.fontSize(10, 11, 12), weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text(videoPlayer.formattedDuration)
                    .font(.system(size: DesignTokens.DeviceSize.current.fontSize(10, 11, 12), weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Progress slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                    
                    // Progress track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignTokens.Colors.primaryCyan)
                        .frame(
                            width: geometry.size.width * CGFloat(videoPlayer.progress),
                            height: 4
                        )
                    
                    // Thumb
                    Circle()
                        .fill(DesignTokens.Colors.primaryCyan)
                        .frame(width: 12, height: 12)
                        .offset(x: geometry.size.width * CGFloat(videoPlayer.progress) - 6)
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
            .frame(height: 12)
        }
        .padding(.horizontal, DesignTokens.DeviceSize.current.spacing(4, 6, 8))
        .padding(.vertical, DesignTokens.DeviceSize.current.spacing(8, 10, 12))
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.DeviceSize.current.spacing(8, 10, 12))
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: DesignTokens.DeviceSize.current.spacing(12, 16, 20)) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.primaryCyan))
                .scaleEffect(1.2)
            
            Text("Loading video...")
                .font(DesignTokens.ResponsiveTypography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: DesignTokens.DeviceSize.current.spacing(12, 16, 20)) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: DesignTokens.DeviceSize.current.fontSize(24, 28, 32)))
                .foregroundColor(DesignTokens.Colors.primaryRed)
            
            Text("Video unavailable")
                .font(DesignTokens.ResponsiveTypography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            if let errorMessage = videoPlayer.errorMessage {
                Text(errorMessage)
                    .font(DesignTokens.ResponsiveTypography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            Button("Retry") {
                Task {
                    await videoPlayer.loadVideo(asset)
                }
            }
            .font(DesignTokens.ResponsiveTypography.buttonMedium)
            .foregroundColor(DesignTokens.Colors.primaryCyan)
            .padding(.horizontal, DesignTokens.DeviceSize.current.spacing(16, 20, 24))
            .padding(.vertical, DesignTokens.DeviceSize.current.spacing(8, 10, 12))
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.DeviceSize.current.spacing(8, 10, 12))
                    .fill(DesignTokens.Colors.primaryCyan.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.DeviceSize.current.spacing(8, 10, 12))
                            .stroke(DesignTokens.Colors.primaryCyan.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleButtonStyle()
        }
        .padding(DesignTokens.DeviceSize.current.spacing(20, 24, 28))
    }
    
    // MARK: - Helper Methods
    
    private func handleTap() {
        showControls.toggle()
        resetControlsTimer()
        
        if showControls && videoPlayer.isPlaying {
            startControlsTimer()
        }
    }
    
    private func startControlsTimer() {
        stopControlsTimer()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
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
}

// MARK: - Preview

#Preview {
    VideoPlayerView(asset: .smartHomeDemo)
        .frame(height: 200)
        .padding()
        .background(DesignTokens.Colors.backgroundPrimary)
}
