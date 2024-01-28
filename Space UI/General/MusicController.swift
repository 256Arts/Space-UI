//
//  MusicController.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-19.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import MediaPlayer
import Combine
import CoreImage.CIFilterBuiltins

final class MusicController: ObservableObject {
    
    static let shared = MusicController()
    
    let systemPlayer = MPMusicPlayerController.systemMusicPlayer
    var cancellables: Set<AnyCancellable> = []
    
    @Published var volume: Double = 0.0
    @Published var artwork: UIImage?
    @Published var isStarWarsMainTitleSoundtrack = false
    
    var isPlaying: Bool {
        systemPlayer.playbackState == .playing
    }
    
    init() {
        NotificationCenter.default
            .publisher(for: Notification.Name.MPMusicPlayerControllerPlaybackStateDidChange)
            .sink { _ in self.playbackChanged() }
            .store(in: &cancellables)
        #if !os(tvOS)
        NotificationCenter.default
            .publisher(for: Notification.Name.MPMusicPlayerControllerVolumeDidChange)
            .sink { _ in self.volumeChanged() }
            .store(in: &cancellables)
        #endif
        NotificationCenter.default
            .publisher(for: Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange)
            .sink { _ in self.nowPlayingItemChanged() }
            .store(in: &cancellables)
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
            volume = Double(audioSession.outputVolume)
        } catch {
            print("Error Setting Up Audio Session")
        }
        
        nowPlayingItemChanged()
    }
    
    func toggleRepeat() {
        switch systemPlayer.repeatMode {
        case .none:
            systemPlayer.repeatMode = .all
        case .all:
            systemPlayer.repeatMode = .one
        case .one:
            systemPlayer.repeatMode = .none
        default:
            break
        }
        objectWillChange.send()
    }
    
    func skipToPrevious() {
        if systemPlayer.currentPlaybackTime < 2.0 {
            systemPlayer.skipToBeginning()
        } else {
            systemPlayer.skipToPreviousItem()
        }
    }
    
    func playPause() {
        if systemPlayer.playbackState == .playing {
            systemPlayer.pause()
        } else {
            systemPlayer.play()
        }
    }
    
    func skipToNext() {
        systemPlayer.skipToNextItem()
    }
    
    func playbackChanged() {
        self.objectWillChange.send()
    }
    
    #if !os(tvOS)
    func volumeChanged() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
            volume = Double(audioSession.outputVolume)
        } catch {
            print("Error Setting Up Audio Session")
        }
    }
    #endif
    
    func nowPlayingItemChanged() {
        guard let playingItem = systemPlayer.nowPlayingItem else { return }
        
        isStarWarsMainTitleSoundtrack = (playingItem.albumTitle?.contains("Star Wars") ?? false) && (playingItem.title?.contains("Main Title") ?? false) && (systemPlayer.playbackState == .playing)
        
        guard let art1 = playingItem.artwork?.image(at: CGSize(width: 100, height: 100)) else { return }
        let lineFilter = CIFilter.lineScreen()
        lineFilter.angle = .pi/2.0
        lineFilter.width = 8.0
        lineFilter.sharpness = 0.0
        lineFilter.inputImage = CIImage(image: art1)
        if let output = lineFilter.outputImage, let cgImage = CIContext().createCGImage(output, from: output.extent) {
            self.artwork = UIImage(cgImage: cgImage)
        }
    }
    
}
