//
//  LocalVideoAssets.swift
//  HomeAssistantPro
//
//  Purpose: Local video asset management for app bundle videos
//  Author: Michael
//  Created: 2025-07-07
//  Modified: 2025-07-07
//
//  Modification Log:
//  - 2025-07-07: Initial creation with local video asset management
//
//  Functions:
//  - url: Returns URL for local video asset from app bundle
//  - thumbnailImage: Generates thumbnail from video asset
//  - fileExists: Checks if video file exists in bundle
//

import Foundation
import AVFoundation
import UIKit

/// Enum for managing local video assets in the app bundle
enum LocalVideoAssets: String, CaseIterable {
    case smartHomeDemo = "smart_home_demo"
    case energyTipsDemo = "energy_tips_demo"
    case securityDemo = "security_demo"
    
    /// Video filename with extension
    var filename: String {
        return "\(rawValue).mov"
    }
    
    /// URL for video file in app bundle
    var url: URL? {
        return Bundle.main.url(forResource: rawValue, withExtension: "mov")
    }
    
    /// Display title for the video
    var title: String {
        switch self {
        case .smartHomeDemo:
            return "Smart Home Design"
        case .energyTipsDemo:
            return "Energy Saving Tips"
        case .securityDemo:
            return "Security Features"
        }
    }
    
    /// Video description
    var description: String {
        switch self {
        case .smartHomeDemo:
            return "A sleek, minimalist design with integrated smart lighting and security systems for the modern lifestyle."
        case .energyTipsDemo:
            return "Learn how to optimize your home's energy consumption with smart automation and intelligent scheduling."
        case .securityDemo:
            return "Advanced security features including facial recognition, motion detection, and real-time alerts."
        }
    }
    
    /// Video duration (estimated, will be calculated from actual file)
    var estimatedDuration: TimeInterval {
        switch self {
        case .smartHomeDemo:
            return 30.0
        case .energyTipsDemo:
            return 25.0
        case .securityDemo:
            return 35.0
        }
    }
    
    /// Custom thumbnail image name (if exists in bundle)
    var customThumbnailName: String {
        return "\(rawValue)_thumbnail" // Match your actual filename (missing 'h')
    }
    
    /// URL for custom thumbnail image in app bundle
    var customThumbnailURL: URL? {
        return Bundle.main.url(forResource: customThumbnailName, withExtension: "jpg") ??
               Bundle.main.url(forResource: customThumbnailName, withExtension: "png")
    }
    
    /// Check if video file exists in bundle
    var fileExists: Bool {
        return url != nil
    }
    
    /// Get thumbnail image (custom or generated from video)
    func thumbnailImage() async -> UIImage? {
        // First try to load custom thumbnail
        if let customURL = customThumbnailURL,
           let imageData = try? Data(contentsOf: customURL),
           let customImage = UIImage(data: imageData) {
            return customImage
        }
        
        // Fallback to generating thumbnail from video
        return await generateThumbnailFromVideo()
    }
    
    /// Generate thumbnail image from video
    private func generateThumbnailFromVideo() async -> UIImage? {
        guard let videoURL = url else { return nil }
        
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        return await withCheckedContinuation { continuation in
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: CMTime(seconds: 1.0, preferredTimescale: 600))]) { _, cgImage, _, _, error in
                if let error = error {
                    print("Failed to generate thumbnail for \(self.filename): \(error)")
                    continuation.resume(returning: nil)
                } else if let cgImage = cgImage {
                    continuation.resume(returning: UIImage(cgImage: cgImage))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    /// Get actual video duration
    func actualDuration() async -> TimeInterval {
        guard let videoURL = url else { return estimatedDuration }
        
        let asset = AVAsset(url: videoURL)
        do {
            let duration = try await asset.load(.duration)
            return CMTimeGetSeconds(duration)
        } catch {
            print("Failed to load duration for \(filename): \(error)")
            return estimatedDuration
        }
    }
}

/// Video asset info structure
struct VideoAssetInfo {
    let asset: LocalVideoAssets
    let url: URL
    let duration: TimeInterval
    let thumbnail: UIImage?
    
    init(asset: LocalVideoAssets, url: URL, duration: TimeInterval, thumbnail: UIImage? = nil) {
        self.asset = asset
        self.url = url
        self.duration = duration
        self.thumbnail = thumbnail
    }
}

/// Manager for loading and caching video asset information
@MainActor
class VideoAssetManager: ObservableObject {
    static let shared = VideoAssetManager()
    
    @Published private(set) var loadedAssets: [LocalVideoAssets: VideoAssetInfo] = [:]
    @Published private(set) var isLoading = false
    
    private init() {}
    
    /// Load video asset information
    func loadAsset(_ asset: LocalVideoAssets) async -> VideoAssetInfo? {
        // Return cached if available
        if let cached = loadedAssets[asset] {
            return cached
        }
        
        guard let url = asset.url else {
            print("Video file not found: \(asset.filename)")
            return nil
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Load duration and thumbnail concurrently
        async let duration = asset.actualDuration()
        async let thumbnail = asset.thumbnailImage()
        
        let assetInfo = VideoAssetInfo(
            asset: asset,
            url: url,
            duration: await duration,
            thumbnail: await thumbnail
        )
        
        loadedAssets[asset] = assetInfo
        return assetInfo
    }
    
    /// Preload all video assets
    func preloadAllAssets() async {
        for asset in LocalVideoAssets.allCases {
            await loadAsset(asset)
        }
    }
    
    /// Clear cached assets
    func clearCache() {
        loadedAssets.removeAll()
    }
}
