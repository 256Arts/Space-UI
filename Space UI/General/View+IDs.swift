import SwiftUI

/// Generates DID and VIDs. Only use this in Page files.
///
/// **The IDs it returns are deliberately not stable across devices or launches, and that is a feature.**
/// They are mixed from `page.hashValue`, which Swift randomizes per process, so the same page on two
/// screens — or on the same screen after a relaunch — decorates itself differently. That variety is the
/// point: a room of screens sharing one theme still shouldn't be a row of identical panels.
///
/// So this is not a bug to fix. The cross-device contract is the *theme* (`SystemStyles`/`ScreenStyles`,
/// generated from `seed`); everything a `did`/`vid` picks is a decorative choice made underneath it, and
/// still obeys it. Making these deterministic would flatten the variety without making anything more
/// correct. See "Global theme vs. per-widget seeds" in `AGENTS.md`.
@propertyWrapper struct IDGen: DynamicProperty {

    @Environment(\.system) private var system
    @Environment(\.page) private var page

    var wrappedValue: (Int) -> Int {
        get {
            return { suffix in
                // `Int(bitPattern:)` avoids trapping on seeds above `Int.max`, and `&+` / the `.min` guard avoid
                // overflow traps in the combine and in `abs`.
                let combined = Int(bitPattern: UInt(truncatingIfNeeded: system.seed)) &+ page.hashValue &+ suffix
                return combined == .min ? .max : abs(combined)
            }
        }
    }
}

// DID = Design ID. The seed used to generate the view's style.
// VID = Value ID. The seed used to generate the view's state.
