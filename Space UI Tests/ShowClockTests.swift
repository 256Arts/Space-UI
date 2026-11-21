//
//  Created by 256 Arts Developer on 2026-07-28.
//

import Foundation
import Testing
@testable import Space_UI

/// `ShowClock` replaced `Task.sleep` for every timed beat of the show, so it now owns the timing that the late
/// destroyers and the late Rey line were traced to. These cover the three properties the show depends on: a cue
/// never fires early, a cancelled beat stops rather than firing under the next one, and chained legs measured
/// from one instant don't accumulate the drift that put a whole fleet off the music.
///
/// Timing tests, so the bounds are one-sided where it matters: the lower bound is exact (firing early would be a
/// bug), the upper bound is loose enough that a busy machine can't make them flap.
@MainActor
struct ShowClockTests {

    /// Generous enough to survive a loaded CI machine, far tighter than the multi-second slips being fixed.
    private static let tolerance: Duration = .milliseconds(400)

    @Test
    func sleepingWaitsAtLeastTheFullDuration() async throws {
        let start = ContinuousClock.now
        try await ShowClock.shared.sleep(for: .milliseconds(300))
        let elapsed = start.duration(to: .now)

        #expect(.milliseconds(300) <= elapsed)
        #expect(elapsed < .milliseconds(300) + Self.tolerance)
    }

    /// Cancellation has to propagate, because every converted call site is followed by a `Task.isCancelled` or
    /// position re-check that only runs if the sleep actually returns.
    @Test
    func cancellingTheTaskEndsTheSleep() async throws {
        let task = Task { @MainActor in
            try await ShowClock.shared.sleep(for: .seconds(30))
        }
        // Let it reach the suspension before cancelling, so this exercises the cancellation handler rather than
        // the already-cancelled check at the top.
        try await ShowClock.shared.sleep(for: .milliseconds(50))
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    /// The whole point of the class: the clock is driven by frame ticks, not by the `Task.sleep` backstop it
    /// keeps for a backgrounded app. Break the display link setup and everything still *works* — it just
    /// silently reverts to the coalesced dispatch timers that were putting the show's cues seconds late, which
    /// is the kind of regression nothing else here would catch.
    @Test
    func theDisplayLinkDrivesTheClock() async throws {
        let before = ShowClock.shared.lastTick
        try await ShowClock.shared.sleep(for: .milliseconds(100))

        #expect(ShowClock.shared.lastTick != before, "the display link never fired during the sleep")
    }

    /// The destroyer stagger, in miniature: the second leg is pinned to the same instant as the first, so a slow
    /// first leg can't push it. Chaining durations instead is what made destroyers 2 and 3 late together.
    @Test
    func absoluteDeadlinesDoNotAccumulateDrift() async throws {
        let start = ContinuousClock.now
        try await ShowClock.shared.sleep(until: start + .milliseconds(200))
        // Stand in for a beat that overruns — chained durations would carry all of this into the next leg.
        try await Task.sleep(for: .milliseconds(150))
        try await ShowClock.shared.sleep(until: start + .milliseconds(400))
        let elapsed = start.duration(to: .now)

        #expect(.milliseconds(400) <= elapsed)
        #expect(elapsed < .milliseconds(400) + Self.tolerance)
    }

}
