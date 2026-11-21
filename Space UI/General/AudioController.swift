import AVKit

@MainActor
final class AudioController: NSObject {
    
    enum MixGroup {
        case ui, dialogue, ambience, environmental, music
    }
    
    static let shared = AudioController()
    
    private var secondaryAudioTask: Task<Void, Never>?
    private var finishedPlayingContinuations: [PlayableSound: [CheckedContinuation<Void, Never>]] = [:]
    /// The pending stop half of each in-flight `fadeOutSound`, with the volume the fade started from. Keyed by
    /// sound so a replay can call the fade off — see `cancelFadeOut`.
    private var pendingFadeOuts: [PlayableSound: (task: Task<Void, Never>, restoreVolume: Float)] = [:]
    private var ambientSoundTimer1: Task<(), Never>?
    private var ambientSoundTimer2: Task<(), Never>?
    
    private var playAmbience: Bool {
        UserDefaults.standard.bool(forKey: UserDefaults.Key.playAmbience)
    }
    private var playEnvironmental: Bool {
        UserDefaults.standard.bool(forKey: UserDefaults.Key.playEnvironmental)
    }
    private var playUISounds: Bool {
        UserDefaults.standard.bool(forKey: UserDefaults.Key.playSounds)
    }
    private var playDialogue: Bool { true }
    private var playMusic: Bool { true }
    private var playablePlayers: [PlayableSound: AVAudioPlayer?]
    
    /// Points to the most recently played music player from `playablePlayers`
    private var musicPlayer: AVAudioPlayer?
    
    /// Points to the most recently played dialogue player from `playablePlayers`
    private var dialoguePlayer: AVAudioPlayer?
    
    private var cargoBayAmbiencePlayer: AVAudioPlayer?
    private var ambientSlot1Player: AVAudioPlayer?
    private var ambientSlot2Player: AVAudioPlayer?
    
    override init() {
        playablePlayers = Dictionary(
            uniqueKeysWithValues: PlayableSound.allCases.map({ ($0, AVAudioPlayer.make(resource: $0.resource)) })
        )
        cargoBayAmbiencePlayer = AVAudioPlayer.make(resource: .cargoBayAmbience)
        
        super.init()
        
        setShowAudioSession(isShowRunning: false)
        secondaryAudioTask = Task { [weak self] in
            for await notification in NotificationCenter.default.notifications(named: AVAudioSession.silenceSecondaryAudioHintNotification) {
                self?.handleSecondaryAudio(notification)
            }
        }
        
        // `AVAudioPlayer.volume` is documented as a 0...1 scale, but no clamping is observed on macOS 26: the
        // values above 1 below really do amplify, which is the only headroom the show's quietest mixes have —
        // several of these assets already peak within a dB of full scale. Unverified on the other platforms,
        // so anything that has to hold everywhere belongs inside 0...1.
        playablePlayers[.action]??.volume = 0.1
        playablePlayers[.button]??.volume = 0.1
        playablePlayers[.notAllowed]??.volume = 0.1
        playablePlayers[.message]??.volume = 0.1
        playablePlayers[.alarmLoop]??.volume = 0.2
        playablePlayers[.sonarLoop]??.volume = 0.1
        playablePlayers[.hyperspaceJumpInternal]??.volume = 3 // Carries the hyperspace video
        playablePlayers[.hyperspaceJumpExternal]??.volume = 2
        playablePlayers[.fighterLoop]??.volume = 0.1
        cargoBayAmbiencePlayer?.volume = 0 // Volume will fade in

        // The show's own mix. Its assets ship in the Show target only, so their cases don't exist elsewhere.
        #if STORY
        playablePlayers[.fighterBlast]??.volume = 0.1
        playablePlayers[.fighter2Blasts]??.volume = 1
        playablePlayers[.comlink]??.volume = 0.2
        playablePlayers[.dreadnoughtAlarm]??.volume = 0.1
        playablePlayers[.liftOff]??.volume = 2
        playablePlayers[.patrolYoullStandby]??.volume = 2
        playablePlayers[.mainTitle]??.volume = 0.65
        playablePlayers[.villainTheme]??.volume = 4
        playablePlayers[.preshow]??.volume = 0.8
        playablePlayers[.sienarAvenger]??.volume = 0.3
        playablePlayers[.endingAndFinale]??.volume = 1.6 // Quietest mix in the show: -31 dBFS average
        #endif

        // The theme's own action/button/alarm players. `system`'s `didSet` refreshes these on every later theme
        // change; this covers the first one, which no `didSet` runs for.
        makeSoundsForSystem()

        playablePlayers[.fighterLoop]??.numberOfLoops = -1
        playablePlayers[.alarmLoop]??.numberOfLoops = -1
        playablePlayers[.sonarLoop]??.numberOfLoops = -1
        cargoBayAmbiencePlayer?.numberOfLoops = -1
        #if STORY
        playablePlayers[.resistanceAlarmLoop]??.numberOfLoops = -1
        playablePlayers[.hangar]??.numberOfLoops = -1
        #endif
    }
    
    /// Update sounds according to the system style
    func makeSoundsForSystem() {
        playablePlayers[.action] = AVAudioPlayer.make(resource: system.actionSoundResource)
        playablePlayers[.button] = AVAudioPlayer.make(resource: system.buttonSoundResource)
        playablePlayers[.alarmLoop] = AVAudioPlayer.make(resource: system.alarmSoundResource)

        // Replacing the players above discards their volume/loop config. Re-apply it, or (e.g.) the emergency
        // alarm plays once at full volume instead of looping quietly after every theme generation.
        playablePlayers[.action]??.volume = 0.1
        playablePlayers[.button]??.volume = system.buttonSoundResource == .button ? 0.8 : 0.1
        playablePlayers[.alarmLoop]??.volume = 0.2
        playablePlayers[.alarmLoop]??.numberOfLoops = -1
    }
    
    /// Which category the app holds. `.ambient` is the polite default for a decorative app: it mixes with, and
    /// yields to, whatever the user is already listening to. A running show is the opposite case — it owns the
    /// room's audio for its whole length and must not be ducked or silenced by anything else on the Mac — so
    /// it takes `.playback` for as long as it runs and hands `.ambient` back at the end.
    func setShowAudioSession(isShowRunning: Bool) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(isShowRunning ? .playback : .ambient, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("failed to set audio category: \(error)")
        }
    }

    /// Readies a sound's audio queue ahead of the instant it is needed, so its first frame isn't waiting on a
    /// buffer allocation and a decode. `play` returns `true` before a cold player is actually audible.
    ///
    /// Call this per play, never once at startup: `AVAudioPlayer.stop()` explicitly undoes `prepareToPlay`,
    /// and the show stops players constantly — `fadeOutMusic`, `stopSound`, and every dialogue line
    /// superseding the last. Only worth calling where the beat has real lead time before the cue.
    ///
    /// Only for sounds played *immediately* at the end of that lead time. `play(_:delay:)` carries its own
    /// lead time and prepares itself, so pairing this with a delayed play is redundant.
    func prepare(_ playableSound: PlayableSound) {
        playablePlayers[playableSound]??.prepareToPlay()
    }

    /// Plays a sound. Returns whether playback actually started — it silently no-ops when the sound's mix group is
    /// disabled or the player failed to load, so `playAndAwaitFinish` must check this to avoid hanging forever.
    @discardableResult
    func play(_ playableSound: PlayableSound, delay: TimeInterval = 0) -> Bool {
        switch playableSound.mixGroup {
        case .ui where playUISounds:
            break
        case .dialogue where playDialogue:
            break
        case .ambience where playAmbience:
            break
        case .environmental where playEnvironmental:
            break
        case .music where playMusic:
            break
        default:
            return false // Not allowed
        }

        guard let player = playablePlayers[playableSound], let player else { return false }

        // Playing a sound supersedes a fade-out already running on it. Without this, replaying a beat that
        // fades its own sound out (the show's resistance alarm) restarted the player under the old fade, which
        // then muted it on the way down and stopped it a few seconds in.
        cancelFadeOut(playableSound)

        if !delay.isZero {
            player.delegate = self
            // A delayed play is scheduled against the *output device's* clock, and `playAtTime:` "starts the
            // audio hardware synchronously (if not already running)" — so on a cold player we would be reading
            // a clock before the hardware it belongs to is running, then blocking to start it as we schedule.
            // Preparing first starts the hardware, which makes `deviceCurrentTime` a meaningful thing to add a
            // delay to. Unlike the immediate path below there is nothing to weigh this against: a delayed play
            // is by definition one with lead time, so the warm-up is free.
            player.prepareToPlay()
            return player.play(atTime: player.deviceCurrentTime + delay)
        } else if player.isPlaying {
            player.currentTime = 0.0
            return true
        } else {
            switch playableSound.mixGroup {
            case .dialogue:
                stopAndResume(dialoguePlayer)
                dialoguePlayer = player
            case .music:
                stopAndResume(musicPlayer)
                musicPlayer = player
            default:
                break
            }

            player.delegate = self
            return player.play()
        }
    }

    func playAndAwaitFinish(_ playableSound: PlayableSound) async {
        guard play(playableSound) else { return } // Don't await a sound that never started, or we hang forever
        await awaitFinish(playableSound)
    }

    /// Awaits the natural finish of a sound that is *already* playing, without (re)starting it. Pair with a
    /// prior `play(...)` when you need the exact play instant as a timing anchor (e.g. choreography locked to a
    /// music track) but still want to cue follow-on sounds off its end. Returns immediately if it isn't playing.
    func awaitFinish(_ playableSound: PlayableSound) async {
        guard isPlaying(playableSound) else { return }
        await withCheckedContinuation { continuation in
            finishedPlayingContinuations[playableSound, default: []].append(continuation)
        }
    }
    
    func stopSound(_ playableSound: PlayableSound) {
        playablePlayers[playableSound]??.rewindAndStop()
        resumeFinishedContinuations(for: playableSound)
    }

    /// Stops a player and resumes any awaiting continuations. Use this instead of a bare `player.stop()` so a
    /// `playAndAwaitFinish` caller never hangs — `stop()` does not fire `audioPlayerDidFinishPlaying`.
    private func stopAndResume(_ player: AVAudioPlayer?) {
        guard let player else { return }
        player.rewindAndStop()
        if let sound = playablePlayers.first(where: { $0.value == player })?.key {
            resumeFinishedContinuations(for: sound)
        }
    }

    /// Resumes and clears any continuations awaiting the given sound. `stop()` never fires
    /// `audioPlayerDidFinishPlaying`, so anything that stops a player early must funnel through here.
    private func resumeFinishedContinuations(for playableSound: PlayableSound) {
        if let continuations = finishedPlayingContinuations.removeValue(forKey: playableSound) {
            for continuation in continuations {
                continuation.resume()
            }
        }
    }

    func isPlaying(_ playableSound: PlayableSound) -> Bool {
        playablePlayers[playableSound]??.isPlaying ?? false
    }

    func duration(of playableSound: PlayableSound) -> TimeInterval? {
        playablePlayers[playableSound]??.duration
    }

    /// How far into a sound playback has reached, or `nil` if it isn't playing.
    ///
    /// The anchor for a beat that has to land on a moment *inside* a track. Every other clock in the show
    /// counts from when it believed a track began — a peer message, or a `play` that returns before a cold
    /// player is audible (see `prepare`) — and both of those run early. The playhead is the track itself.
    func currentTime(of playableSound: PlayableSound) -> TimeInterval? {
        guard let player = playablePlayers[playableSound] ?? nil, player.isPlaying else { return nil }
        return player.currentTime
    }

    /// Fades a sound out, then stops it and restores its volume — the single-sound counterpart to `fadeOutMusic`.
    /// A bare `setVolume(0, …)` is not enough: a looping sound (the resistance alarm) would keep running
    /// inaudibly for the rest of the show, and parking the volume at 0 leaves the *next* pass through the beat
    /// silent, since `play` only rewinds a player that is already playing.
    func fadeOutSound(_ playableSound: PlayableSound, duration: TimeInterval) {
        guard let player = playablePlayers[playableSound] ?? nil, player.isPlaying else { return }
        // A fade already in flight has the real pre-fade volume; the player's own is partway to zero by now.
        let originalVolume = pendingFadeOuts[playableSound]?.restoreVolume ?? player.volume
        pendingFadeOuts[playableSound]?.task.cancel()

        player.setVolume(0, fadeDuration: duration)
        let task = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled, let self else { return }
            pendingFadeOuts[playableSound] = nil
            stopAndResume(player)
            player.volume = originalVolume // Restore so a later replay isn't silent
        }
        pendingFadeOuts[playableSound] = (task, originalVolume)
    }

    /// Abandons a fade-out mid-flight and puts the volume back where the fade started. A cancelled fade would
    /// otherwise leave the player parked near zero — silent for the rest of the launch, since `play` only
    /// rewinds a player, it doesn't reset its volume.
    private func cancelFadeOut(_ playableSound: PlayableSound) {
        guard let pending = pendingFadeOuts.removeValue(forKey: playableSound) else { return }
        pending.task.cancel()
        playablePlayers[playableSound]??.volume = pending.restoreVolume
    }
    
    func startAmbience() {
        let playingAudio = AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint
        guard playAmbience, !playingAudio else { return }

        // Cancel any existing chains first so a second start (e.g. secondary-audio resume) doesn't leave orphans.
        invalidateAmbientSoundTimers()
        cargoBayAmbiencePlayer?.play()
        cargoBayAmbiencePlayer?.setVolume(0.1, fadeDuration: 1)
        scheduleNextAmbientSound(slot: 1)
        scheduleNextAmbientSound(slot: 2)
    }
    
    func stopAmbience() {
        cargoBayAmbiencePlayer?.setVolume(0, fadeDuration: 1)
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            self?.cargoBayAmbiencePlayer?.stop()
        }
        invalidateAmbientSoundTimers()
    }
    
    func fadeOutMusic(duration: TimeInterval = 5) {
        // Fade every music-group player, not just `musicPlayer`: that pointer isn't updated for delayed
        // plays or replays of an already-playing track, so relying on it can leave the climax blaring.
        let players = PlayableSound.allCases
            .filter { $0.mixGroup == .music }
            .compactMap { playablePlayers[$0] ?? nil }
            .filter { $0.isPlaying }
        let originalVolumes = players.map(\.volume)
        for player in players {
            player.setVolume(0, fadeDuration: duration)
        }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard let self else { return }
            for (player, volume) in zip(players, originalVolumes) {
                self.stopAndResume(player)
                player.volume = volume // Restore so a later replay isn't silent
            }
        }
    }
    
    func invalidateAmbientSoundTimers() {
        ambientSoundTimer1?.cancel()
        ambientSoundTimer2?.cancel()
    }
    
    /// One ambient draw per clip. R2-D2's voice is Lucasfilm's, so only the Show target carries it.
    #if STORY
    private static let droidChatter: [Resource] = [.r2Talk1, .r2Talk2, .r2Talk3, .r2Talk4, .r2Talk5, .r2Talk6, .r2Talk7, .r2Talk8, .r2Talk9, .r2Talk10, .r2Talk11, .r2Talk12, .r2Talk13, .r2Talk14, .r2Talk15, .r2Talk16]
    #else
    private static let droidChatter: [Resource] = []
    #endif
    
    func scheduleNextAmbientSound(slot: Int) {
        let roll = Int.random(in: 0..<(30 + Self.droidChatter.count))
        let resource: (Resource, Float) = switch roll {
        case ..<5:
            (.beeps, 0.05)
        case ..<10:
            (.shipPassBy10, 0.1)
        case ..<15:
            (.cyberChime2, 0.05)
        case ..<20:
            (.hullBreach2, 0.05)
        case ..<25:
            (.dataStream, 0.01)
        case ..<30:
            (.powerDown, 0.06)
        default:
            (Self.droidChatter[roll - 30], 0.1)
        }
        
        // Store the reschedule task in the matching slot so `invalidateAmbientSoundTimers()` can actually stop the
        // chain — otherwise cancellation is a no-op and every foreground spawns another infinite chain.
        let rescheduleTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(TimeInterval.random(in: 10..<300)))
            guard !Task.isCancelled else { return }
            self?.scheduleNextAmbientSound(slot: slot)
        }
        if slot == 1 {
            ambientSoundTimer1 = rescheduleTask
        } else {
            ambientSoundTimer2 = rescheduleTask
        }

        let chapter = ShipState.shared.storyChapter
        guard chapter == nil || chapter == .ending else { return }

        if slot == 1 {
            self.ambientSlot1Player = AVAudioPlayer.make(resource: resource.0)
            self.ambientSlot1Player?.volume = resource.1
            self.ambientSlot1Player?.play()
        } else {
            self.ambientSlot2Player = AVAudioPlayer.make(resource: resource.0)
            self.ambientSlot2Player?.volume = resource.1
            self.ambientSlot2Player?.play()
        }
    }
    
    func handleSecondaryAudio(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt,
            let type = AVAudioSession.SilenceSecondaryAudioHintType(rawValue: typeValue) else {
                return
        }
        if type == .begin {
            // Other app started playing audio
            stopAmbience()
        } else {
            startAmbience()
        }
    }
    
    func setFighterVolume(_ volume: Float) {
        playablePlayers[.fighterLoop]??.volume = volume
    }
    
}

extension AudioController: @MainActor AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let sound = playablePlayers.first(where: { $0.value == player })?.key {
            resumeFinishedContinuations(for: sound)
        }
    }
    
}

extension AVAudioPlayer {

    /// Stops playback and puts the playhead back at the start.
    ///
    /// `stop()` alone leaves it where it was, so the next `play()` resumes from the middle of the line. The
    /// show cuts lines constantly — a skip or a step back stops the dialogue player, as does the next line
    /// superseding it — and a line the director comes back to has to start from its first word. Rewinding
    /// here rather than in `play` also keeps it ahead of `prepare`, whose pre-roll a later seek would undo.
    func rewindAndStop() {
        stop()
        currentTime = 0
    }

    static func make(resource: AudioController.Resource, volume: Float = 1.0) -> AVAudioPlayer? {
        let name = "\(resource.rawValue).\(resource.fileType.rawValue)"
        guard let url = Bundle.main.url(forResource: resource.rawValue, withExtension: resource.fileType.rawValue) else {
            // A missing bundled asset is a build/rename mistake — trap loudly in DEBUG, degrade gracefully in release.
            assertionFailure("Missing audio resource: \(name)")
            return nil
        }
        do {
            let player = try self.init(contentsOf: url, fileTypeHint: resource.fileType.rawValue)
            player.volume = volume
            return player
        } catch {
            assertionFailure("Failed to load audio resource \(name): \(error)")
            return nil
        }
    }
    
}
