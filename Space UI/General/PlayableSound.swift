extension AudioController {

    /// A container for one or more sounds that represent the same concept
    /// Raw values mirror `Resource` so identity mappings need no per-case switch arm; only the theme-dependent sounds differ.
    ///
    /// The show's own dialogue and music are `#if STORY`, because their files live in the Show target. Leaving
    /// the cases in the App Store build would not just be dead code: `init` makes a player for every case, and
    /// a case whose file isn't bundled trips `AVAudioPlayer.make`'s missing-resource assertion on launch.
    @MainActor
    enum PlayableSound: String, CaseIterable {
        // UI
        case action, button, notAllowed, message
        // UI Loops
        case alarmLoop, sonarLoop
        // Environmental
        case hyperspaceJumpInternal = "jumpInternal", hyperspaceJumpExternal = "jumpExternal", fighterLoop
        #if STORY
        case fighterBlast, fighter2Blasts
        case resistanceAlarmLoop
        case tractorBeamLong, hangar, dreadnoughtAlarm, liftOff
        // Dialogue
        // `comlink` is the channel-opening blip rather than a voice, but it belongs to the dialogue group so
        // it plays in the show regardless of the UI-sounds setting, and so the voice it announces displaces it.
        case patrolConfirmRequest, patrolDisengagePropulsion, patrolFinalWarning, patrolIntro, patrolIntro2, patrolPiracyZone, patrolPowerDown, patrolPrepareBoarding, patrolStandby, patrolTractorBeam, patrolYoullStandby, reyIntro, huxHologram, comlink
        // Music
        case preshow, mainTitle, villainTheme, sienarAvenger, ultimateClimax, endingAndFinale
        #endif

        var mixGroup: MixGroup {
            switch self {
            case .action, .button, .notAllowed, .message:
                .ui
            case .alarmLoop, .sonarLoop:
                .ui
            case .hyperspaceJumpInternal, .hyperspaceJumpExternal, .fighterLoop:
                .environmental
            #if STORY
            case .fighterBlast, .fighter2Blasts:
                .environmental
            case .resistanceAlarmLoop:
                .ui
            case .tractorBeamLong, .hangar, .dreadnoughtAlarm, .liftOff:
                .environmental
            case .patrolConfirmRequest, .patrolDisengagePropulsion, .patrolFinalWarning, .patrolIntro, .patrolIntro2, .patrolPiracyZone, .patrolPowerDown, .patrolPrepareBoarding, .patrolStandby, .patrolTractorBeam, .patrolYoullStandby, .reyIntro, .huxHologram, .comlink:
                .dialogue
            case .preshow, .mainTitle, .villainTheme, .sienarAvenger, .ultimateClimax, .endingAndFinale:
                .music
            #endif
            }
        }

        var resource: Resource {
            switch self {
            case .action:
                return system.actionSoundResource
            case .button:
                return system.buttonSoundResource
            case .alarmLoop:
                return system.alarmSoundResource
            // The fleet flies an original fighter in the App Store build and the authentic one in the show,
            // and each sounds like the ship on screen.
            case .fighterLoop:
                #if STORY
                return .imperialFighterLoop
                #else
                return .fighterEngineLoop
                #endif
            #if STORY
            case .fighterBlast:
                return .imperialFighterBlast
            case .fighter2Blasts:
                return .imperialFighter2Blasts
            #endif
            default:
                // Identity mapping: every non-themed case mirrors a `Resource` of the same raw value.
                // A miss is a programming error, so trap it in debug but stay quiet in the show build rather than crash.
                guard let resource = Resource(rawValue: rawValue) else {
                    assertionFailure("PlayableSound.\(self) has no Resource with raw value \"\(rawValue)\"")
                    return .notAllowed
                }
                return resource
            }
        }
    }

    /// An actual audio file
    enum Resource: String {

        enum FileType: String {
            case acc, m4a, mp3, wav
        }

        // UI
        case action, action2, button, button2, button3, notAllowed, message
        // UI Loops
        case alarmLoop, alarmHighLoop, sonarLoop
        // Ambience
        case cargoBayAmbience, shipPassBy10, beeps, dataStream, powerDown, cyberChime2, hullBreach2
        // Environmental
        case hyperspaceJumpInternal = "jumpInternal"
        case hyperspaceJumpExternal = "jumpExternal"
        case fighterEngineLoop
        // The show's own files, which ship in the Show target only. See `PlayableSound`.
        #if STORY
        case imperialFighterLoop, imperialFighterBlast, imperialFighter2Blasts
        case resistanceAlarmLoop
        // R2-D2's voice is Lucasfilm's, so the droid chatter stays out of the public build.
        case r2Talk1, r2Talk2, r2Talk3, r2Talk4, r2Talk5, r2Talk6, r2Talk7, r2Talk8, r2Talk9, r2Talk10, r2Talk11, r2Talk12, r2Talk13, r2Talk14, r2Talk15, r2Talk16
        case tractorBeamLong, hangar, dreadnoughtAlarm, liftOff
        // Dialogue
        case patrolConfirmRequest, patrolDisengagePropulsion, patrolFinalWarning, patrolIntro, patrolIntro2, patrolPiracyZone, patrolPowerDown, patrolPrepareBoarding, patrolStandby, patrolTractorBeam, patrolYoullStandby, reyIntro, huxHologram, comlink
        // Music
        case preshow, mainTitle, villainTheme, sienarAvenger, ultimateClimax, endingAndFinale
        #endif

        var fileType: FileType {
            switch self {
            #if STORY
            case .tractorBeamLong, .hangar, .resistanceAlarmLoop, .dreadnoughtAlarm, .liftOff, .patrolConfirmRequest, .patrolDisengagePropulsion, .patrolFinalWarning, .patrolIntro, .patrolIntro2, .patrolPiracyZone, .patrolPowerDown, .patrolPrepareBoarding, .patrolStandby, .patrolTractorBeam, .patrolYoullStandby, .reyIntro, .huxHologram, .comlink, .preshow, .mainTitle, .villainTheme, .sienarAvenger, .ultimateClimax, .endingAndFinale: .m4a
            case .imperialFighterLoop, .imperialFighterBlast, .imperialFighter2Blasts: .mp3
            #endif
            case .hyperspaceJumpInternal, .hyperspaceJumpExternal, .cargoBayAmbience: .m4a
            case .message, .fighterEngineLoop, .shipPassBy10, .cyberChime2, .hullBreach2: .mp3
            default: .wav
            }
        }
    }

}
