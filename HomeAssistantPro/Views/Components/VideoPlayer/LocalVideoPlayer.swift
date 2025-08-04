//
//  LocalVideoPlayer.swift
//  HomeAssistantPro
//
//  Purpose: Local video player manager for AVPlayer integration with SwiftUI
//  Author: Michael
//  Created: 2025-07-07
//  Modified: 2025-07-07
//
//  Modification Log:
//  - 2025-07-07: Initial creation with AVPlayer management
//
//  Functions:
//  - loadVideo(_:): Load local video from bundle
//  - play(): Start video playback
//  - pause(): Pause video playback
//  - seek(to:): Seek to specific time
//  - cleanup(): Proper cleanup of AVPlayer resources
//

import Foundation
import AVFoundation
import Combine
import SwiftUI

/// Observable video player for local bundle videos
@MainActor
class LocalVideoPlayer: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var currentAsset: LocalVideoAssets?
    @Published var hasError = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private var _player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Properties
    
    var player: AVPlayer? {
        return _player
    }
    
    // MARK: - Computed Properties
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    var formattedCurrentTime: String {
        return formatTime(currentTime)
    }
    
    var formattedDuration: String {
        return formatTime(duration)
    }
    
    // MARK: - Initialization
    
    init() {
        setupAudioSession()
    }
    
    deinit {
        // Clean up resources synchronously in deinit
        if let timeObserver = timeObserver {
            _player?.removeTimeObserver(timeObserver)
        }
        _player?.pause()
        _player = nil
        playerItem = nil
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    
    /// Load video from local bundle
    func loadVideo(_ asset: LocalVideoAssets) async {
        guard let url = asset.url else {
            await setError("Video file not found: \(asset.filename)")
            return
        }
        
        // Don't reload the same asset
        if currentAsset == asset && player != nil {
            return
        }
        
        isLoading = true
        hasError = false
        currentAsset = asset
        
        // Clean up previous player
        cleanup()
        
        // Create new player
        let playerItem = AVPlayerItem(url: url)
        self.playerItem = playerItem
        
        // Observe player item status
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                Task { @MainActor in
                    await self?.handlePlayerItemStatusChange(status)
                }
            }
            .store(in: &cancellables)
        
        _player = AVPlayer(playerItem: playerItem)
        setupTimeObserver()
        
        // Load duration
        do {
            let loadedDuration = try await playerItem.asset.load(.duration)
            duration = CMTimeGetSeconds(loadedDuration)
        } catch {
            await setError("Failed to load video duration: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Start playback
    func play() {
        guard let player = _player else { return }
        player.play()
        isPlaying = true
    }
    
    /// Pause playback
    func pause() {
        guard let player = _player else { return }
        player.pause()
        isPlaying = false
    }
    
    /// Toggle play/pause
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    /// Seek to specific time
    func seek(to time: Double) {
        guard let player = _player else { return }
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime) { [weak self] _ in
            Task { @MainActor in
                self?.currentTime = time
            }
        }
    }
    
    /// Seek to progress (0.0 to 1.0)
    func seek(toProgress progress: Double) {
        let time = progress * duration
        seek(to: time)
    }
    
    /// Reset to beginning
    func reset() {
        seek(to: 0)
        pause()
    }
    
    /// Clean up resources
    func cleanup() {
        if let timeObserver = timeObserver {
            _player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        _player?.pause()
        _player = nil
        playerItem = nil
        cancellables.removeAll()
        
        isPlaying = false
        currentTime = 0
        duration = 0
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
    
    private func setupTimeObserver() {
        guard let player = _player else { return }
        
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = CMTimeGetSeconds(time)
            }
        }
    }
    
    private func handlePlayerItemStatusChange(_ status: AVPlayerItem.Status) async {
        switch status {
        case .readyToPlay:
            isLoading = false
            hasError = false
            
        case .failed:
            if let error = playerItem?.error {
                await setError("Video playback failed: \(error.localizedDescription)")
            } else {
                await setError("Unknown video playback error")
            }
            
        case .unknown:
            break
            
        @unknown default:
            break
        }
    }
    
    private func setError(_ message: String) async {
        hasError = true
        errorMessage = message
        isLoading = false
        print("LocalVideoPlayer Error: \(message)")
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - AVPlayer Extension

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}