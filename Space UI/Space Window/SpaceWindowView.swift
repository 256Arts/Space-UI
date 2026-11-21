import SwiftUI
import RealityKit
import AVKit

enum CameraWidthMode {
    case single, dual
}

enum CameraAngle: Codable {
    case singleCenter, dualLeft, dualRight
    
    var title: LocalizedStringResource {
        switch self {
        case .singleCenter:
            "Space Window"
        case .dualLeft:
            "Space Window - Left"
        case .dualRight:
            "Space Window - Right"
        }
    }
}

struct SpaceWindowView: View {

    /// How solid the director's prompts sit over the scene — the ones asking for a decision, which have to be
    /// read rather than glanced at. The blips below them stay fainter on purpose: those only report that the
    /// show is waiting, and at this weight they compete with the scene the room is watching.
    private static let hintOpacity = 0.5

    init(cameraAngle: CameraAngle) {
        self.cameraAngle = cameraAngle
    }
    
    private var cameraManager: SpaceWindowCameraManager = .shared
    #if STORY
    /// Re-reads the globals rather than capturing them, so tracking survives `ShipState.shared` being replaced
    /// wholesale by a config change (a seed regenerate, the settings page, a config received from the host).
    /// Reassigning that static isn't observable, so a body that had only registered on the *previous*
    /// instance's `storyState` was never invalidated again: this window kept rendering the show as it stood at
    /// the swap — most visibly the "Start Preshow" cue below, left on screen through a show that had started.
    /// Reading `configID`, which changes with the swap, re-arms the observation on the new instance.
    /// Same fix as `ConsoleController.currentState`; the UI windows get it from `UIRootView`'s `.id`.
    private var storyState: StoryState? {
        _ = AppController.shared.configID
        return ShipState.shared.storyState
    }
    #endif
    
    let cameraAngle: CameraAngle
    
    #if !targetEnvironment(macCatalyst)
    @State private var showingQuickStart = true
    #endif

    #if STORY
    @State private var boardingFlashOpacity = 1.0
    @State private var boardingProgress: Double = 0.0
    #endif

    #if targetEnvironment(macCatalyst) && STORY
    /// Whole seconds left of the `.liftOff` hold, or `nil` when the show isn't holding.
    @State private var secondsUntilHyperdriveReady: Int?
    #endif

    @FocusState private var isFocused: Bool

    #if STORY
    /// The boarding announcement, mirrored from the UI page onto the 3D scene so room screens showing
    /// the Space Window carry the warning too. Shown during the hangar/boarding chapters.
    private var isBoarding: Bool {
        storyState?.chapter == .hangar || storyState?.chapter == .runningOutOfTime
    }

    private var boardingAnnouncement: some View {
        VStack(spacing: 20) {
            Text(BoardingChoreography.scanningLine)
                .font(.english(scale: 1.4))
            Text(BoardingChoreography.boardingLine)
                .font(.english(scale: 1.6))
                .opacity(boardingFlashOpacity) // Only the second line flashes for urgency
        }
        .multilineTextAlignment(.center)
        .font(.english())
        .foregroundStyle(system.colors.color(.danger, brightness: .medium))
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                boardingFlashOpacity = 0.25
            }
        }
    }

    #if targetEnvironment(macCatalyst) && STORY
    private func confirmationHint(_ systemImage: String, _ title: LocalizedStringKey) -> some View {
        Label(title, systemImage: systemImage)
            .foregroundStyle(.white.opacity(Self.hintOpacity))
            .padding()
    }

    /// Counts the `.liftOff` hold down to the green console button coming live — see
    /// `StoryState.hyperdriveReadyInstant` for why the wait is a different length every run.
    ///
    /// The bare number, no label: the director already knows what the show is holding for by the time they
    /// are standing on this beat, and the window behind it is the scene the room is watching. Whole seconds,
    /// because it answers "how long am I standing here", not "press on this" — the press is cued by the button
    /// lighting, which happens as this reaches zero and goes away.
    private func hyperdriveCountdown(_ seconds: Int) -> some View {
        Text(seconds, format: .number)
            .monospacedDigit() // Or it shuffles sideways each time the number changes width
            .foregroundStyle(.white.opacity(Self.hintOpacity))
            .padding()
    }
    #endif

    private var boardingProgressBar: some View {
        CapsuleProgressView(value: $boardingProgress, role: .danger)
            .frame(height: 40)
            .frame(maxWidth: 800) // Keep it from spanning the full width of a widescreen display
            .padding(.horizontal)
            .padding(.top, 60) // Room for the trooper standing on top of the capsule
    }
    #endif

    var body: some View {
        SpaceMetalView(cameraAngle: cameraAngle)
            #if STORY
            .overlay(alignment: .bottom) {
                if cameraAngle == .dualLeft {
                    HStack {
                        if storyState?.isAwaitingInput == true {
                            if storyState?.chapter == nil {
                                Text("""
                                    Turn on fog
                                    Set Home lights animations
                                    Enable Do Not Disturb
                                    Start video recording
                                    Check both windows are shown
                                    Park the cursor in the left corner
                                    Get ready to turn off stair lights
                                    \(Image(systemName: "arrowtriangle.forward.fill")) Start Preshow
                                    """, tableName: "Show")
                            } else {
                                Image(systemName: storyState?.chapter == .hangar ? "music.note" : "arrowtriangle.forward.fill")
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                        }
                        if let button = storyState?.simultaneousButtonInput {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(button.color.opacity(0.3))
                        }
                    }
                    .font(.system(size: 8))
                    .padding()
                }
            }
            #endif
            // The left/single screen carries the text warning; the right screen shows the boarding progress bar
            // with the trooper running across it, so a dual setup splits the announcement across both halves.
            #if STORY
            .overlay(alignment: .top) {
                if isBoarding {
                    if cameraAngle == .dualRight {
                        boardingProgressBar
                    } else {
                        boardingAnnouncement
                    }
                }
            }
            #endif
            .navigationTitle(Text(cameraAngle.title))
            // Ambient manual control: tap the window to jump to a fresh planet system. Guarded inside so a
            // stray tap during a live show does nothing.
            .onTapGesture {
                ShipState.shared.ambientHyperspaceJump()
            }
            .focusable()
            .focusEffectDisabled()
            .focused($isFocused)
            .onAppear {
                isFocused = true
            }
            // Drives the boarding progress on the right screen — the trooper runs across it at the pace the UI
            // page's staircase fills, on the other device, off the shared timings in `BoardingChoreography`.
            // Keyed on the chapter so a step re-runs it, and cancelled with the window on the way out.
            #if STORY
            .task(id: storyState?.chapter) {
                guard cameraAngle == .dualRight else { return }
                await BoardingChoreography.run(for: storyState?.chapter, progress: $boardingProgress)
            }
            #endif
            #if targetEnvironment(macCatalyst) && STORY
            // The director's own lines, which only their screen carries: how long `.liftOff` is still holding,
            // and — for a rewind, or a skip past a beat still playing, which only arm on the first press — a
            // hint to press the same way again to go through with it. Kept off the right half of a dual setup
            // so they appear once, not twice.
            .overlay(alignment: .bottom) {
                if cameraAngle != .dualRight {
                    VStack(spacing: 0) {
                        if let secondsUntilHyperdriveReady {
                            hyperdriveCountdown(secondsUntilHyperdriveReady)
                        }
                        switch storyState?.pendingStep {
                        case .backward:
                            confirmationHint("arrowtriangle.backward.fill", "Back?")
                        case .forward:
                            confirmationHint("arrowtriangle.forward.fill", "Skip?")
                        case nil:
                            EmptyView()
                        }
                    }
                }
            }
            // Ticks the countdown above. Re-armed by the deadline itself, so entering the beat starts it and
            // the beat's own hand-off — which clears the instant — ends it, as does any move out.
            .task(id: storyState?.hyperdriveReadyInstant) {
                defer { secondsUntilHyperdriveReady = nil }
                guard let deadline = storyState?.hyperdriveReadyInstant else { return }

                while true {
                    let remaining = ContinuousClock.now.duration(to: deadline)
                    guard remaining > .zero else { return }
                    // Rounded up, so the readout only ever shows a second it is actually inside: a tenth of a
                    // second left still reads "1", and it never sits on 0 with the button still dark.
                    let components = remaining.components
                    let seconds = Int(components.seconds) + (components.attoseconds > 0 ? 1 : 0)
                    secondsUntilHyperdriveReady = seconds

                    // Sleep to the instant the number changes rather than one second on from the last tick, so
                    // twenty ticks' worth of wake-up jitter can't accumulate and drag the last of them past
                    // the deadline the green light is on.
                    try? await ShowClock.shared.sleep(until: deadline - .seconds(seconds - 1))
                    guard !Task.isCancelled else { return }
                }
            }
            // Only the Catalyst director drives the show — the `chapter`/`patrolLine` didSets that broadcast to
            // the room are compiled out elsewhere, so a stray keyboard on an iPad peer would desync silently.
            .onKeyPress(.rightArrow) {
                storyState?.next()
                return .handled
            }
            .onKeyPress(.leftArrow) {
                storyState?.previous()
                return .handled
            }
            #endif
            #if !targetEnvironment(macCatalyst)
            .overlay(alignment: .bottom) {
                if showingQuickStart, !ShipState.shared.isRunningStory {
                    QuickStartView(currentWindowID: .spaceWindow)
                }
            }
            .task {
                try? await Task.sleep(for: .seconds(4))
                withAnimation {
                    showingQuickStart = false
                }
            }
            #endif
    }
}

#Preview {
    SpaceWindowView(cameraAngle: .singleCenter)
}
