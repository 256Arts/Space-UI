//
//  Created by 256 Arts Developer on 2026-08-16.
//

/// The show's beats, as they travel between devices.
///
/// Deliberately outside `StoryState` and outside the Show target, because `PeerSessionController.Message`
/// carries them and the App Store build has to keep decoding that case. A public screen joined to a Show host
/// applies the config it is sent and ignores the story position, which it can only do if the position still
/// parses — a joiner that failed to decode one message would drop the connection and desync the room.
///
/// Everything these beats *mean* — their names, their dialogue, the audio they cue — lives with `StoryState`
/// in the Show target. This file is the wire format and nothing else, so the raw values are fixed: changing
/// one is a protocol change (`PeerSessionController.protocolVersion`).
enum StoryChapter: String, Codable, CaseIterable {
    case preshow, crawl, reyIntro, hyperspaceAlarm, patrol, huxHologram, tractorBeam, hangar, runningOutOfTime, liftOff, hyperspaceJump, ending
}

/// Which line of the patrol exchange the show is on, inside `StoryChapter.patrol`. See `StoryChapter`.
enum StoryPatrolLine: String, Codable, CaseIterable {
    case patrolIntro, patrolIntro2, patrolStandby, patrolPiracyZone, patrolYoullStandby, patrolTractorBeam, patrolDisengagePropulsion, patrolPowerDown, patrolConfirmRequest, patrolPrepareBoarding, patrolFinalWarning
}
