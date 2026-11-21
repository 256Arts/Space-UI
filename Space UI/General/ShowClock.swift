import OSLog
import QuartzCore

/// The show's clock: a `Task.sleep` replacement whose wake-ups can't be coalesced away.
///
/// Every timed beat of the show — the staggered destroyer jumps, Rey's lead-in, the hologram fan's spin-up —
/// is a sleep in the middle of a `@MainActor` task. Written with `Task.sleep` those wake on a *dispatch
/// timer*, and dispatch timers are coalesced: the system is free to slide them by seconds when the app isn't
/// frontmost, the Mac is on battery, or the director has been standing still watching the show. It is
/// invisible in testing — you have to be idle for it — and it is what put the destroyers and Rey's line
/// seconds late while the scene kept rendering a smooth 60fps throughout, because `CADisplayLink` is a
/// run-loop source and is *not* coalesced.
///
/// So the show is clocked off a display link instead. `sleep(for:)` resumes from the frame tick, giving a
/// worst case of one frame rather than seconds. `Task.sleep` stays on as a per-sleeper backstop for the one
/// case a link can't cover — a backgrounded app, where it stops — so a stalled link runs the show late
/// instead of stopping it dead.
///
/// This is the same fix `MetalRenderer` already made for the same reason; see its `displayLink` in
/// `SpaceMetalView.swift`.
///
/// **This did not close the bug, and the reason is now known to be outside this type.** A bad run captured on
/// 2026-08-10 shows the main thread going silent for 11 seconds while audio played on, taking a destroyer cue
/// 11.6s late with it. A display link is a main-run-loop source, so it stops when the main thread does; no
/// clock built on one can cover this. The cause is `CAMetalLayer.nextDrawable()` blocking the main thread from
/// `SpaceMetalUIView.draw(_:)`: a sample over a reproduced stall has 42% of the main thread's wall time parked
/// in that one semaphore wait, in roughly one-second timeouts, against 3 samples for this whole type.
///
/// **So re-clocking this type cannot fix the show.** A cue's body has to run on the main actor, and a blocked
/// main thread can't run it whatever wakes it. **Read `Show/Docs/Late Cues.md` before changing anything here**, and
/// spend the effort on the renderer instead.
@MainActor
final class ShowClock: NSObject {

    static let shared = ShowClock()

    /// The unified log, not `print`. A Catalyst app launched normally has its stderr discarded, so every
    /// lateness report this type has ever made was thrown away unless the show happened to be running under
    /// Xcode — which on the night it never is. `Logger` survives the run and can be pulled afterwards with
    /// `log show --predicate 'subsystem == "com.jaydenirwin.spaceui"'`.
    private static let log = Logger(subsystem: "com.jaydenirwin.spaceui", category: "ShowClock")

    /// A wake-up later than this is reported. Set well above a frame so ordinary jitter stays silent and only
    /// slips big enough to be visible in the room reach the log.
    private static let latenessToReport: Duration = .milliseconds(100)

    private struct Sleeper {
        let deadline: ContinuousClock.Instant
        let continuation: CheckedContinuation<Void, any Error>
        /// Where the sleep was written, so a late cue names itself in the log instead of leaving the next bad
        /// show to be reconstructed from memory.
        let origin: String
        /// Fires the deadline even when the display link isn't running. Cancelled with the sleeper, so a tick
        /// and a backstop can't both try to resume one continuation.
        var backstop: Task<Void, Never>?
        /// How the link behaved *across this sleep* — the pair that says whether the clock source failed or
        /// the wake-up did. One timestamp at the end can't: `tick()` runs on the main run loop, so a parked
        /// loop and a blocked main thread both leave the same stale `lastTick`.
        var ticks = 0
        var longestTickGap: Duration = .zero
    }

    private var sleepers: [Int: Sleeper] = [:]
    private var nextID = 0
    private var displayLink: CADisplayLink?

    /// When the display link last fired.
    private(set) var lastTick: ContinuousClock.Instant?

    private override init() {
        super.init()
    }

    /// Suspends for `duration`, resuming on the first frame at or after the deadline.
    ///
    /// A drop-in for `Task.sleep(for:)`, cancellation included, so the `Task.isCancelled` and position
    /// re-checks that follow every one of these calls keep working unchanged.
    func sleep(for duration: Duration, fileID: String = #fileID, line: Int = #line) async throws {
        try await sleep(until: .now + duration, fileID: fileID, line: line)
    }

    /// Suspends until `deadline`.
    ///
    /// Prefer this to `sleep(for:)` for the later legs of a staggered sequence: deadlines measured from one
    /// captured instant can't accumulate the drift that chained durations do, so a leg that slips anyway
    /// doesn't take the legs after it with it.
    func sleep(until deadline: ContinuousClock.Instant, fileID: String = #fileID, line: Int = #line) async throws {
        try Task.checkCancellation()
        guard ContinuousClock.now < deadline else { return }

        let id = nextID
        nextID += 1
        let origin = "\(fileID):\(line)"

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                sleepers[id] = Sleeper(deadline: deadline, continuation: continuation, origin: origin)
                sleepers[id]?.backstop = Task { [weak self] in
                    try? await Task.sleep(until: deadline, clock: .continuous)
                    self?.fireDueSleepers()
                }
                setTicking(true)
            }
        } onCancel: {
            // `onCancel` is nonisolated, so this has to hop. It can't lose a race with the store above: that
            // runs synchronously on the main actor with nothing to suspend on, so the hop lands after it.
            Task { @MainActor [weak self] in
                self?.resume(id, throwing: CancellationError())
            }
        }
    }

    @objc private func tick() {
        let now = ContinuousClock.now
        let gap = lastTick?.duration(to: now)
        lastTick = now

        // Charge the tick to everything currently waiting, so a late cue can say what the link was doing for
        // the whole of *its* sleep rather than only at the end of it. Over a snapshot of the keys: holding
        // `sleepers.keys` live across the mutation keeps a second reference to the storage, so every write
        // would copy the whole dictionary.
        for id in Array(sleepers.keys) {
            sleepers[id]?.ticks += 1
            if let gap, let sleeper = sleepers[id], sleeper.longestTickGap < gap {
                sleepers[id]?.longestTickGap = gap
            }
        }

        fireDueSleepers()
    }

    private func fireDueSleepers() {
        let now = ContinuousClock.now
        // Earliest deadline first, so cues that come due on the same frame still fire in the order they were
        // scheduled to. Iterating the sorted copy leaves `resume` free to mutate `sleepers`.
        for (id, sleeper) in sleepers.sorted(by: { $0.value.deadline < $1.value.deadline }) {
            guard sleeper.deadline <= now else { break }
            let lateness = sleeper.deadline.duration(to: now)
            if Self.latenessToReport < lateness {
                // Read these together. A `longestGap` the size of `late` means the link itself stopped and the
                // backstop had to cover. A link that ticked all the way through a late cue means the clock
                // source was fine and the fault is in the wake-up — which is the answer that would move the
                // search out of `CADisplayLink` entirely. See `Show/Docs/Late Cues.md`.
                Self.log.error("""
                    cue at \(sleeper.origin, privacy: .public) fired \(lateness.description, privacy: .public) late \
                    (link ticked \(sleeper.ticks) times, longest gap \(sleeper.longestTickGap.description, privacy: .public))
                    """)
            }
            resume(id, throwing: nil)
        }
    }

    /// Resumes a sleeper exactly once. Removing before resuming is what lets a display-link tick, a backstop,
    /// and a cancellation all race for the same deadline safely.
    private func resume(_ id: Int, throwing error: (any Error)?) {
        guard let sleeper = sleepers.removeValue(forKey: id) else { return }
        sleeper.backstop?.cancel()
        if let error {
            sleeper.continuation.resume(throwing: error)
        } else {
            sleeper.continuation.resume()
        }
        setTicking(!sleepers.isEmpty)
    }

    /// Ticks only while something is waiting — an idle show shouldn't wake the CPU 60×/s to check an empty
    /// list. Paused rather than torn down and rebuilt, because cues come in chains (one destroyer after the
    /// next, the mini-game's beat), and a link per link of the chain is churn for nothing.
    private func setTicking(_ isTicking: Bool) {
        if let displayLink {
            displayLink.isPaused = !isTicking
            return
        }
        guard isTicking else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick))
        // `.common`, so menu tracking or a window resize on the director's Mac can't park the show's clock.
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

}
