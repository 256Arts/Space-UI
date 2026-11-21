import SwiftUI

var seed: UInt64 {
    UserDefaults.standard.seed
}

@MainActor @Observable
final class AppController {
    
    static let shared = AppController()
    
    /// A fullscreen page that will appear on every window of the app
    var multiWindowFullscreenModalPage: Page?
    
    private var nextEmergencyTimer: Task<(), any Error>?
    var showingDebugControls = false

    /// Whether the native settings inspector is open. Here rather than in the root's `@State` so the Mac menu
    /// can open it — the Mac has no screen edge to swipe in from.
    var showingSettingsInspector = false

    #if os(visionOS)
    /// Whether the space-scene immersive space is open. Updated by `SpaceImmersiveView` itself so it stays
    /// correct even when the system dismisses the space (e.g. Digital Crown).
    var isImmersiveSpaceOpen = false
    #endif

    /// Regenerated whenever the global theme is rebuilt (`system` reassigned) so the root view can rebuild its
    /// subtree and re-read the swapped `system` / `ShipState.shared` globals. Reassigning those globals is
    /// not itself observable, so without this a peer that receives a new `Config` keeps rendering the previous
    /// `ShipState` instance — only the emergency tint (which reads `ShipState.shared` directly) would update.
    private(set) var configID = UUID()
    
    #if DEBUG
    var debugShowingExternalDisplay = false
    #endif
    
    func openPageModally(_ page: Page) {
        multiWindowFullscreenModalPage = page
    }
    
    func closeModalPage() {
        multiWindowFullscreenModalPage = nil
    }

    /// Resolves the active emergency puzzle. Clearing the emergency is the whole of it: that tells the room, and
    /// dismissing the puzzle — here and on every other screen — falls out of `ShipState.endEmergency`.
    func solveEmergencyPuzzle() {
        ShipState.shared.endEmergency()
    }
    
    func reloadRootView() {
        configID = UUID()
    }

    /// Never during the show: the story scripts its own emergencies, and an unscripted one would open a puzzle
    /// modal over a live beat, restyle the room's lights, and flip the console's ambient lights to their fast
    /// flash off-script (`Show/Docs/Console Hardware.md`, section A). Story mode owns the emergency state outright.
    func startEmergencyCountdown() {
        guard !ShipState.shared.isRunningStory,
              UserDefaults.standard.bool(forKey: UserDefaults.Key.randomEmergencies),
              PeerSessionController.shared.isHost else { return }
        
        cancelEmergencyCountdown()
        nextEmergencyTimer = Task {
            try await Task.sleep(for: .seconds(10))
            
            // Re-read the global rather than the value captured above: a config receive replaces
            // `ShipState.shared` wholesale, so a show that started inside this delay is only visible here.
            // Do not start an emergency if we are already in one
            guard !ShipState.shared.isRunningStory, !ShipState.shared.isInEmergency else { return }
            
            // Unseeded on purpose, and correctly so: this is a live event the host decides in the moment, not
            // seed-derived content. It reaches the other screens by being announced (`beginEmergency` sends the
            // reason *and* the puzzle), which is what keeps the room on one puzzle without making the same seed
            // always throw the same emergency.
            let reason: EmergencyReason = Bool.random() ? .internalIssue : .proximityAlert
            ShipState.shared.beginEmergency(reason: reason, puzzle: EmergencyPuzzle.allCases.randomElement()!)

            // Spawn a new `Task` so that the sequence always completes
            Task {
                if reason == .proximityAlert {
                    ShipState.shared.nearbyShipsState.spawn(hostile: true)
                    try? await Task.sleep(for: .seconds(3))
                    ShipState.shared.nearbyShipsState.finishJumps()
                }

                try? await Task.sleep(for: .seconds(30))
                if ShipState.shared.isInEmergency {
                    // Closes the puzzle here and on every peer — see `endEmergency`.
                    ShipState.shared.endEmergency()

                    if reason == .proximityAlert {
                        ShipState.shared.nearbyShipsState.hostilesExit()
                    }
                }
            }
        }
    }

    /// Stops a pending emergency from firing. Called when this device goes inactive, and when it stops being
    /// the host — a joiner never drives emergencies.
    func cancelEmergencyCountdown() {
        nextEmergencyTimer?.cancel()
        nextEmergencyTimer = nil
    }

    /// The single path for adopting a theme `Config`. Rebuilds the generated `system` theme *and* the
    /// seed-derived `ShipState` together, so "one seed → everything" holds no matter which affordance
    /// triggered the change. Reassigning `system` fires its `didSet` (root-view reload + cache reset).
    ///
    /// `broadcast` and `persist` are deliberately separate from network role: `broadcast` is *intent*
    /// ("this change originated here — propagate it"), which is only meaningful when we are the host, so
    /// the actual send is still gated on `isHost` here. Pass `broadcast: false` on the receive path so an
    /// applied config is never echoed back to its sender.
    ///
    /// - Parameters:
    ///   - config: The theme configuration to adopt.
    ///   - broadcast: Whether to forward this config to connected peers (only sent when we are the host).
    ///   - persist: Whether to save the seed as the launch default. Defaults to `true`; pass `false` for
    ///     transient applies such as a config received from the host, which shouldn't outlive the session.
    func applyConfig(_ config: Config, broadcast: Bool, persist: Bool = true) {
        if broadcast, PeerSessionController.shared.isHost {
            PeerSessionController.shared.send(message: .config(config))
        }
        // Preserve story vs. ambient mode across seed changes — a config swap restyles the ship, it doesn't
        // start (or abandon) the show.
        let inStoryMode = ShipState.shared.isRunningStory
        system = SystemStyles(config: config)
        ShipState.shared = ShipState(seed: config.seed, inStoryMode: inStoryMode)
        if persist {
            UserDefaults.standard.seed = config.seed
        }
        // Ambient windows tie "new theme" to "new sky": adopting a config also jumps to a fresh planet system.
        ShipState.shared.ambientHyperspaceJump()
    }

    /// The single path for a *local* appearance override — a per-device setting such as the screen-shape
    /// picker or Extra Fonts, which every settings surface (iOS and tvOS) reaches through here.
    ///
    /// Deliberately not `applyConfig`: the seed is unchanged, so this must not rebuild `ShipState`, persist a
    /// seed, or broadcast to the room's peers — it is only what this one screen looks like. The seed comes from
    /// the *live* theme rather than `savedConfig`, so a transient config received from the host survives an
    /// override made while joined. Reassigning `system` fires its `didSet` (root-view reload + path cache reset).
    func applyLocalAppearance() {
        system = SystemStyles(config: Config(
            seed: system.seed,
            designPrinciples: savedDesignPrinciples,
            primaryHue: savedPrimaryHue,
            primarySaturation: savedPrimarySaturation
        ))
    }

}
