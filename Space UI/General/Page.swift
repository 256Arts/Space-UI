// Created by 256 Arts Developer on 2026-08-23.

import SwiftUI

// The tvOS variant declares its own, much smaller `Page` — it renders only the external pages — so this one
// compiles out there rather than being carried as a target membership exception in the project file.
#if !os(tvOS)

enum Page: String {
    case lockScreen, settings, powerManagement, targeting, coms, nearby, planet, galaxy, ticTacToe, dotsAndBoxes, shield, squad, music, homeKit, customText, sudokuPuzzle, lightsOutPuzzle, unlabeledKeypadPuzzle
    #if STORY
    case story
    #endif

    // External
    case extOrbits, extCircularProgressLeft, extCircularProgressRight

    /// The show opens on its own page; the App Store build, which has no show, opens on the lock screen.
    /// A persisted `"story"` left by a Show build simply fails to decode there and falls back to this.
    #if STORY
    static var defaultPage: Page { .story }
    #else
    static var defaultPage: Page { .lockScreen }
    #endif

    /// Whether this is the show's own page — false throughout the App Store build, so the affordances that
    /// stand down for a live show (the settings edge swipe) are simply always on there.
    var isStory: Bool {
        #if STORY
        self == .story
        #else
        false
        #endif
    }

    /// Whether this page is a puzzle the emergency itself owns, and so should be dismissed when the emergency
    /// ends. See `EmergencyPuzzle`.
    var isEmergencyPuzzle: Bool {
        EmergencyPuzzle.allCases.contains { $0.page == self }
    }

    var usesUIKit: Bool {
        switch self {
        case .coms, .settings, .homeKit, .customText:
            true
        default:
            false
        }
    }
}

extension EmergencyPuzzle {

    /// The page this puzzle opens. Lives here rather than on `EmergencyPuzzle` itself, which is a wire type and
    /// so must stay free of the per-target `Page` — the tvOS variant declares neither these pages nor a modal
    /// path to show them on.
    var page: Page {
        switch self {
        case .sudoku:
            .sudokuPuzzle
        case .lightsOut:
            .lightsOutPuzzle
        case .unlabeledKeypad:
            .unlabeledKeypadPuzzle
        }
    }

}

extension EnvironmentValues {

    @Entry var page: Page = .defaultPage

}

#endif
