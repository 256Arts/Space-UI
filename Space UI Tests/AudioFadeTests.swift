//
//  Created by 256 Arts Developer on 2026-08-02.
//

import Foundation
import Testing
@testable import Space_UI

/// `fadeOutSound` finishes with a stop, several seconds after the call that started it. Those seconds are long
/// enough for the show to be somewhere else — a director replaying the beat that owns the sound is exactly the
/// case — so the pending stop has to know it has been superseded.
/// Serialized: these share `AudioController.shared` and would stop each other's player.
@MainActor
@Suite(.serialized)
struct AudioFadeTests {

    /// The alarm only starts when its mix group (UI sounds) is enabled. `register()` alone can't promise that: a
    /// saved `false` outranks it, and the test host shares its container with the copy of the app in real use.
    /// The argument domain is read ahead of saved settings and never written, so this can't touch them.
    init() {
        let defaults = UserDefaults.standard
        defaults.register()
        var arguments = defaults.volatileDomain(forName: UserDefaults.argumentDomain)
        arguments[UserDefaults.Key.playSounds] = true
        defaults.setVolatileDomain(arguments, forName: UserDefaults.argumentDomain)
    }

    /// The show's `.hyperspaceAlarm` fades its own looping alarm out partway through the beat, so replaying
    /// that beat calls `play` on a player a fade is already running on. Left in place, the fade muted the
    /// replayed alarm and stopped it a few seconds in — the beat's alarm simply vanished on the second pass.
    @Test
    func replayingASoundMidFadeSurvivesTheFade() async throws {
        let audio = AudioController.shared
        audio.play(.resistanceAlarmLoop)
        #expect(audio.isPlaying(.resistanceAlarmLoop), "the sound under test never started")

        audio.fadeOutSound(.resistanceAlarmLoop, duration: 0.2)
        audio.play(.resistanceAlarmLoop) // The replay
        try await Task.sleep(for: .seconds(0.5)) // Past the fade's own stop

        #expect(audio.isPlaying(.resistanceAlarmLoop), "the superseded fade stopped the replayed sound")
        audio.stopSound(.resistanceAlarmLoop)
    }

    /// A fade that is allowed to finish still has to stop its sound, or the show's alarms play on under the
    /// beats after them.
    @Test
    func anUninterruptedFadeStillStops() async throws {
        let audio = AudioController.shared
        audio.play(.resistanceAlarmLoop)
        #expect(audio.isPlaying(.resistanceAlarmLoop), "the sound under test never started")

        audio.fadeOutSound(.resistanceAlarmLoop, duration: 0.2)
        try await Task.sleep(for: .seconds(0.5))

        #expect(!audio.isPlaying(.resistanceAlarmLoop))
    }
}
