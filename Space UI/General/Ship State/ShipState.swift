import SwiftUI

enum EmergencyReason: UInt8, Codable {
    case internalIssue
    case proximityAlert
}

/// The puzzle an emergency pops, chosen once by the host and announced with the emergency so every screen in
/// the room opens the *same* one — the room solves one puzzle together, not one puzzle each.
///
/// Its own type rather than a `Page` because it crosses the wire, and `Page` differs per target — the Show build
/// adds `.story`, and the tvOS variant declares only the handful of pages it renders. Wire types must decode in
/// every target (see `PeerSessionController.Message`), so this one names no page at all; the mapping to a `Page`
/// lives beside the full `Page` in `Views/Components/UIRootView.swift`.
enum EmergencyPuzzle: UInt8, Codable, Sendable, CaseIterable {
    case sudoku
    case lightsOut
    case unlabeledKeypad
}

@MainActor @Observable
final class ShipState {

    @Observable
    final class StatusState {
        var binary1: Int
        var circleIconName1: String
        var circleIconName2: String
        var circleIconName3: String
        var binary2: Int
        
        init(binary1: Int, circleIconName1: String, circleIconName2: String, circleIconName3: String, binary2: Int) {
            self.binary1 = binary1
            self.circleIconName1 = circleIconName1
            self.circleIconName2 = circleIconName2
            self.circleIconName3 = circleIconName3
            self.binary2 = binary2
        }
    }
    
    @Observable
    final class PowerState {
        var mainPowerOn = true
        var shield1HasPower = true
        var shield2HasPower = true
        var comsHavePower = true
        var engineHasPower = true
        var weaponsHavePower = true
    }
    
    static let commandShipIconNames = (1...5).map({ "Cmd Ship \($0)" })
    static let starshipIconNames = (1...6).map({ "Starship \($0)" })
    
    /// The App Store build has no show to run, so it starts — and stays — in the ambient mode the Space Window
    /// was always the public half of. Only the Show target can hand `true` here. See `AGENTS.md`.
    #if STORY
    static var shared = ShipState(seed: seed, inStoryMode: true)
    #else
    static var shared = ShipState(seed: seed, inStoryMode: false)
    #endif
    
    // Misc
    let icon: Image
    let enemyCommandShipIconNames: [String]
    let enemyStarshipIconNames: [String]
    var emergencyReason: EmergencyReason?
    var isInEmergency: Bool {
        emergencyReason != nil
    }
    var emergencyColorsFlash = true
    var emergencyColorsTask: Task<Void, Never>?
    var useEmergencyColors = false
    var isInHyperspace = false
    
    // State
    var topStatusState: StatusState
    var bottomStatusState: StatusState
    var targetState: TargetState
    var powerState = PowerState()
    var nearbyShipsState: NearbyShipsState
    var messagesState = MessagesState()
    #if STORY
    var storyState: StoryState?
    #endif
    var shieldAngle = 0.0
    var weaponsInLaserMode = true

    /// Whether the scripted show owns this device, rather than the ambient screensaver the app otherwise is.
    ///
    /// The three accessors here are what let shared code ask about the show without naming `StoryState`, which
    /// only the Show target builds — so the `#if STORY` for the whole app lives in this one place rather than
    /// at every call site. Always `false`/`nil` in the App Store build.
    var isRunningStory: Bool {
        #if STORY
        storyState != nil
        #else
        false
        #endif
    }

    /// The beat the show is on, or `nil` when no chapter is running (which includes story mode sitting idle
    /// before the director starts it).
    var storyChapter: StoryChapter? {
        #if STORY
        storyState?.chapter
        #else
        nil
        #endif
    }

    /// Which line of the patrol exchange the show is on. See `storyChapter`.
    var storyPatrolLine: StoryPatrolLine? {
        #if STORY
        storyState?.patrolLine
        #else
        nil
        #endif
    }

    /// Follows a story position announced by a peer. A public build joined to a Show host decodes the message
    /// and drops it here, which is the whole of its story handling — see `StoryChapter`.
    func applyStoryFromPeer(chapter: StoryChapter?, patrolLine: StoryPatrolLine?) {
        #if STORY
        storyState?.applyFromPeer(chapter: chapter, patrolLine: patrolLine)
        #endif
    }

    init(seed: UInt64, inStoryMode: Bool) {
        #if STORY
        storyState = inStoryMode ? StoryState() : nil
        #endif
        // One seeded generator for the whole ship. Everything drawn from it is *shared simulation content* —
        // which ship we are, who is around us, what we are tracking — so every device rebuilt from the same
        // `Config` reads as the same vessel. The ambient churn that runs afterwards is deliberately unseeded;
        // see `changeRandomStatus`.
        let random = SeededRandom(seed: seed)

        var shipIcons = Self.starshipIconNames
        let shipIconIndex = random.nextInt(in: 0..<shipIcons.count)
        icon = inStoryMode ? Image("Cargo Ship Up") : Image(shipIcons.remove(at: shipIconIndex))
        enemyCommandShipIconNames = Self.commandShipIconNames
        enemyStarshipIconNames = shipIcons

        topStatusState = StatusState(binary1: 0, circleIconName1: "", circleIconName2: "", circleIconName3: "", binary2: 0)
        bottomStatusState = StatusState(binary1: 0, circleIconName1: "", circleIconName2: "", circleIconName3: "", binary2: 0)

        nearbyShipsState = NearbyShipsState(
            random: random,
            inStoryMode: inStoryMode,
            enemyCommandShipIconNames: enemyCommandShipIconNames,
            enemyStarshipIconNames: enemyStarshipIconNames
        )
        targetState = TargetState(random: random)
        
        changeRandomStatus()
    }
    
    /// Setting `isInHyperspace` is all the room's lights need: `HomeStore` observes it and recomputes the whole
    /// palette itself. It used to also be pushed at `HomeStore` from here, which raced its own observer and lost —
    /// the push ran before the observer had recomputed anything, so it wrote the *pre*-jump colors under the
    /// *pre*-jump lighting mode, and the room only went blue once the observer caught up behind it.
    func hyperspaceJump(intoHyperspace: Bool) async throws {
        if intoHyperspace {
            #if !os(tvOS)
            // Nothing is committed until the renderer has the video running, because `isInHyperspace` is one-way:
            // only the video reaching its end clears it again. A jump with no Space Window to play it, or whose
            // video can't be read, would otherwise strand the ship — and the room's lights — in hyperspace until
            // the app relaunched. `jumpToHyperspace()` opens the video before it touches the scene, so a failure
            // here means the jump never visibly started.
            guard let renderer = MetalRenderer.shared else { return }
            try await renderer.jumpToHyperspace()
            #endif

            // Also dismisses the emergency's puzzle — jumping out of trouble solves it. See `endEmergency`.
            ShipState.shared.endEmergency()
        }

        isInHyperspace = intoHyperspace
    }
    
    /// Jump requested by an ambient (non-story) affordance: the window tap, the menu command, seed
    /// regeneration, or the scene's idle timer. No-ops while the scripted story owns the scene or while a jump
    /// is already in flight; a missing Space Window is `hyperspaceJump`'s to refuse, not this one's.
    func ambientHyperspaceJump() {
        #if !os(tvOS)
        guard !isRunningStory, !isInHyperspace else { return }
        Task { [weak self] in
            try? await self?.hyperspaceJump(intoHyperspace: true)
        }
        #endif
    }

    /// - Parameters:
    ///   - puzzle: The puzzle to pop on every screen, or `nil` for an emergency with no puzzle — which is the
    ///     story's case, since the show scripts its own beats over the top and must not be interrupted. It
    ///     travels with the emergency rather than being picked per device, which is what makes the room open
    ///     one shared puzzle. See `EmergencyPuzzle`.
    ///   - source: `.peer` when applying an emergency another device announced, which is what stops it
    ///     being announced a second time. See `ChangeSource`.
    func beginEmergency(reason: EmergencyReason, puzzle: EmergencyPuzzle? = nil, source: ChangeSource = .local) {
        if source == .local {
            PeerSessionController.shared.send(message: .emergencyBegan(reason: reason, puzzle: puzzle))
        }

        emergencyReason = reason
        if !isRunningStory {
            AudioController.shared.play(.alarmLoop)
        }
        useEmergencyColors = true

        if emergencyColorsFlash {
            // Cancel any in-flight flash loop first — a double-begin would otherwise orphan the old task,
            // leaving it strobing `useEmergencyColors` forever.
            emergencyColorsTask?.cancel()
            emergencyColorsTask = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(0.5))
                    if Task.isCancelled { return }
                    self?.useEmergencyColors.toggle()
                }
            }
        }

        // Last, so the puzzle opens over a ship already in its emergency state. The tvOS variant renders
        // external pages only and has no modal path, so it takes the colours and alarm and ignores the puzzle —
        // it still relays the message on unchanged.
        #if !os(tvOS)
        if let puzzle {
            AppController.shared.openPageModally(puzzle.page)
        }
        #endif
    }

    /// Ending an emergency also dismisses its puzzle, on this device and — because the end is announced — on
    /// every other screen in the room, so whoever solves it clears the room. Doing it here rather than at each
    /// call site is what gets the peers and the hyperspace path (which used to leave the puzzle up) for free.
    ///
    /// - Parameter source: `.peer` when applying an end another device announced. See `ChangeSource`.
    func endEmergency(source: ChangeSource = .local) {
        if source == .local {
            PeerSessionController.shared.send(message: .emergencyEnded)
        }

        // Only ever closes the emergency's own puzzle: a settings page opened over an emergency belongs to
        // whoever opened it, not to us. No puzzle on tvOS to close — see `beginEmergency`.
        #if !os(tvOS)
        if AppController.shared.multiWindowFullscreenModalPage?.isEmergencyPuzzle == true {
            AppController.shared.closeModalPage()
        }
        #endif

        emergencyReason = nil
        AudioController.shared.stopSound(.alarmLoop)
        emergencyColorsTask?.cancel()
        emergencyColorsTask = nil
        useEmergencyColors = false
    }
    
    /// Deliberately unseeded. This is ambient liveliness on a timer, not simulation content: there is no shared
    /// clock between devices, so seeding it would only make every screen start from the same value and then
    /// drift apart anyway. Screens are meant to flicker independently. The same reasoning covers the drift in
    /// `TargetState.simulateTargetMovement` and the generators in `NumberGenerators`.
    private func changeRandomStatus() {
        switch Int.random(in: 0..<10) {
        case 0:
            topStatusState.binary1 = Int.random(in: 0...31)
        case 1:
            topStatusState.circleIconName1 = CircleIcon.allCases.randomElement()!.rawValue
        case 2:
            topStatusState.circleIconName2 = CircleIcon.allCases.randomElement()!.rawValue
        case 3:
            topStatusState.circleIconName3 = CircleIcon.allCases.randomElement()!.rawValue
        case 4:
            topStatusState.binary2 = Int.random(in: 0...31)
        case 5:
            bottomStatusState.binary1 = Int.random(in: 0...31)
        case 6:
            bottomStatusState.circleIconName1 = CircleIcon.allCases.randomElement()!.rawValue
        case 7:
            bottomStatusState.circleIconName2 = CircleIcon.allCases.randomElement()!.rawValue
        case 8:
            bottomStatusState.circleIconName3 = CircleIcon.allCases.randomElement()!.rawValue
        default:
            bottomStatusState.binary2 = Int.random(in: 0...31)
        }
        
        // Keep repeating
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            self?.changeRandomStatus()
        }
    }
    
}
