//
//  ImageViewerModal.swift
//  HomeAssistantPro
//
//  Purpose: Full-screen image viewer with zoom, pan, and swipe capabilities
//  Author: Claude
//  Created: 2025-07-11
//  Modified: 2025-07-11
//
//  Modification Log:
//  - 2025-07-11: Initial creation with full-screen image viewing capabilities
//
//  Functions:
//  - ImageViewerModal: Main modal view for full-screen image viewing
//  - ZoomableAsyncImage: Zoomable image component with gestures
//  - gestureHandling: Pinch, pan, and swipe gesture management
//  - navigationControls: Image counter and dismiss controls
//  - transitionAnimations: Smooth enter/exit animations
//

import SwiftUI
import os.log

/// Full-screen image viewer modal with zoom, pan, and swipe capabilities
struct ImageViewerModal: View {
    let images: [String]
    let selectedIndex: Int
    @Binding var isPresented: Bool
    
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showControls = true
    @State private var isLoading = false
    
    private let logger = Logger(subsystem: "com.homeassistant.ios", category: "ImageViewerModal")
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 3.0
    
    /// Initialize with images array and selected index
    /// - Parameters:
    ///   - images: Array of image URLs to display
    ///   - selectedIndex: Initially selected image index
    ///   - isPresented: Binding to control modal presentation
    init(images: [String], selectedIndex: Int, isPresented: Binding<Bool>) {
        self.images = images
        self.selectedIndex = selectedIndex
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: selectedIndex)
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black
                .opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showControls.toggle()
                    }
                }
            
            // Main image viewer
            GeometryReader { geometry in
                ZStack {
                    // Image content
                    if !images.isEmpty && currentIndex < images.count {
                        ZoomableAsyncImage(
                            url: images[currentIndex],
                            scale: $scale,
                            offset: $offset,
                            lastOffset: $lastOffset,
                            isLoading: $isLoading,
                            geometry: geometry
                        )
                    }
                }
                .gesture(
                    SimultaneousGesture(
                        swipeGesture,
                        dismissGesture
                    )
                )
            }
            
            // Controls overlay
            if showControls {
                VStack {
                    // Top controls
                    HStack {
                        // Image counter
                        if images.count > 1 {
                            Text("\(currentIndex + 1) of \(images.count)")
                                .font(DesignTokens.ResponsiveTypography.bodyMedium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.5))
                                )
                        }
                        
                        Spacer()
                        
                        // Close button
                        Button(action: {
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isPresented = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30, weight: .medium))
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: 40, height: 40)
                                )
                        }
                    }
                    .padding()
                    .padding(.top, DesignTokens.ResponsiveSpacing.sm)
                    
                    Spacer()
                    
                    // Bottom controls (if needed for future features)
                    if isLoading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            
                            Text("Loading...")
                                .font(DesignTokens.ResponsiveTypography.bodyMedium)
                                .foregroundColor(.white)
                                .padding(.leading, 8)
                        }
                        .padding()
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.5))
                        )
                        .padding(.bottom, DesignTokens.ResponsiveSpacing.lg)
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            logger.info("ImageViewer opened with \(images.count) images, index: \(currentIndex)")
            
            // Reset zoom state on appear
            DispatchQueue.main.async {
                resetZoom()
            }
            
            // Auto-hide controls after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControls = false
                }
            }
        }
        .onChange(of: currentIndex) { _ in
            // Reset zoom when switching images
            DispatchQueue.main.async {
                resetZoom()
            }
        }
    }
    
    // MARK: - Gesture Handlers
    
    /// Swipe gesture for navigation between images
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onEnded { value in
                guard images.count > 1 && scale <= 1.1 else { return } // Only allow swipe when not zoomed
                
                let horizontalDistance = value.translation.width
                let verticalDistance = abs(value.translation.height)
                
                // Must be predominantly horizontal swipe
                guard abs(horizontalDistance) > verticalDistance * 1.5 else { return }
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    if horizontalDistance > 0 && currentIndex > 0 {
                        // Swipe right - previous image
                        currentIndex -= 1
                        resetZoom()
                    } else if horizontalDistance < 0 && currentIndex < images.count - 1 {
                        // Swipe left - next image
                        currentIndex += 1
                        resetZoom()
                    }
                }
                
                logger.info("Swiped to image index: \(currentIndex)")
            }
    }
    
    /// Dismiss gesture (swipe down)
    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 50, coordinateSpace: .local)
            .onEnded { value in
                guard scale <= 1.1 else { return } // Only allow dismiss when not zoomed
                
                let verticalDistance = value.translation.height
                let horizontalDistance = abs(value.translation.width)
                
                // Must be predominantly vertical downward swipe
                if verticalDistance > 80 && verticalDistance > horizontalDistance * 1.5 {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                    
                    logger.info("ImageViewer dismissed via swipe down")
                }
            }
    }
    
    /// Reset zoom and pan to default state
    private func resetZoom() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            scale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
}

// MARK: - Zoomable Async Image

/// Zoomable async image component with pan and zoom gestures
struct ZoomableAsyncImage: View {
    let url: String
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    @Binding var lastOffset: CGSize
    @Binding var isLoading: Bool
    let geometry: GeometryProxy
    
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 3.0
    
    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    isLoading = true
                }
                
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            magnificationGesture,
                            panGesture
                        )
                    )
                    .onAppear {
                        isLoading = false
                    }
                    
            case .failure(_):
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                    
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("Failed to load image")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    isLoading = false
                }
                
            @unknown default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
    
    /// Pinch-to-zoom gesture
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = scale * value
                if newScale >= minScale && newScale <= maxScale {
                    scale = newScale
                }
            }
            .onEnded { _ in
                // Snap back to bounds if needed
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if scale < minScale {
                        scale = minScale
                        offset = .zero
                        lastOffset = .zero
                    } else if scale > maxScale {
                        scale = maxScale
                    }
                }
            }
    }
    
    /// Pan gesture for moving zoomed image
    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard scale > 1.0 else { return } // Only pan when zoomed
                
                let newOffset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                
                // Constrain pan to image bounds
                let maxOffsetX = (geometry.size.width * (scale - 1)) / 2
                let maxOffsetY = (geometry.size.height * (scale - 1)) / 2
                
                offset = CGSize(
                    width: max(-maxOffsetX, min(maxOffsetX, newOffset.width)),
                    height: max(-maxOffsetY, min(maxOffsetY, newOffset.height))
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }
}

// MARK: - Preview

#Preview {
    ImageViewerModal(
        images: [
            "https://picsum.photos/800/600?random=1",
            "https://picsum.photos/800/600?random=2",
            "https://picsum.photos/800/600?random=3"
        ],
        selectedIndex: 0,
        isPresented: .constant(true)
    )
}