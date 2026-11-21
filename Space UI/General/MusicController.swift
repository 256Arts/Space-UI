#if !os(macOS)
import MediaPlayer
import CoreImage.CIFilterBuiltins

/// Controls for the system music player
@Observable @MainActor
final class MusicController {

    static let shared = MusicController()

    let systemPlayer = MPMusicPlayerController.systemMusicPlayer
    private var observerTasks: [Task<Void, Never>] = []
    /// Reused across tracks — a `CIContext` is expensive to build and holds the GPU resources the artwork filter renders through.
    private let ciContext = CIContext()

    var volume: Double = 0.0
    var artwork: UIImage?
    var isStarWarsMainTitleSoundtrack = false

    // Stored (not computed off `systemPlayer.playbackState`) so @Observable can track it — SwiftUI
    // only observes stored properties, and playback state lives on the non-observable system player.
    private(set) var isPlaying = false

    init() {
        // Required for the player to post playback-state / now-playing notifications below.
        systemPlayer.beginGeneratingPlaybackNotifications()
        observerTasks.append(Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .MPMusicPlayerControllerPlaybackStateDidChange) {
                self?.playbackChanged()
            }
        })
        #if !os(tvOS)
        observerTasks.append(Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .MPMusicPlayerControllerVolumeDidChange) {
                self?.volumeChanged()
            }
        })
        #endif
        observerTasks.append(Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .MPMusicPlayerControllerNowPlayingItemDidChange) {
                self?.nowPlayingItemChanged()
            }
        })

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
            volume = Double(audioSession.outputVolume)
        } catch {
            print("Error Setting Up Audio Session")
        }

        playbackChanged()
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
//        objectWillChange.send()
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
        isPlaying = systemPlayer.playbackState == .playing
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
        if let output = lineFilter.outputImage, let cgImage = ciContext.createCGImage(output, from: output.extent) {
            self.artwork = UIImage(cgImage: cgImage)
        }
    }
    
}
#endif
