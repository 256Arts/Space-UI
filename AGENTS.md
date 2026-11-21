# Space UI

A SwiftUI app that turns Apple devices into authentic-looking sci-fi control panels. The goal is **immersion**: run it on phones, tablets, Macs, TVs, and Vision Pro mounted around a sci-fi-themed room so the screens look like the working consoles of a starship. There is no "real" functionality being controlled — the interfaces are decorative, procedurally generated, and reactive, designed to feel believable rather than to do anything.

## What makes this app unusual

The entire visual design is **procedurally generated from a seed**. There is no fixed look. A single `UInt64` seed deterministically produces a complete, internally-consistent UI theme: shapes, corner styles, fonts, colors, line weights, sounds, screen border treatment, etc. Two devices with the same seed render the same theme, which is how multiple screens in a room stay visually coherent.

Because of this, when changing UI code:
- Don't hardcode colors, fonts, shapes, or sizes. Pull them from the generated style objects.
- Changes must hold up across *all* seeds, not just the one you happen to be looking at. A change that looks good under one seed may break under another (different base shape, light vs. dark appearance, borders on/off, etc.).
- Use the Regenerate Seed debug command (see below) to spot-check variety.

## Core architecture

### Style generation (`Space UI/System Appearance/`)
This is the heart of the app. Read these before touching any UI.
- `Config.swift` — the inputs to generation: `seed` plus optional design overrides.
- `SystemStyles.swift` — `system`, the global generated theme. Built from a seed via a `SeededRandom`. Holds the chosen `basicShape`, `cornerStyle`, fonts, line widths, button sizing, sounds, all the `prefers*` flags, and the `ScreenStyles` drawn from the same stream. **Mutating `system` regenerates everything.**
- `DesignPrinciples.swift` — five 0...1 axes (simplicity, sharpness, order, balance, boldness) that bias the weighted random choices, so a theme feels cohesive instead of arbitrary. Elements are picked with `nextWeightedElement(in:with:)` against these principles.
- `SystemColors.swift` / `Color.swift` — color palette generation (monochrome / limited / colorful), light vs. dark appearance, primary hue/saturation. An emergency is an *input*, not a lookup: the root injects `system.resolvingEmergencyColors()` while the alarm strobes, so `.primary` reads red everywhere without any color lookup consulting `ShipState`.
- `ScreenStyles.swift`, `ScreenShape.swift` — the outer screen shape/frame treatment (the "bezel" the UI sits inside).
- `Font.swift` — the bundled sci-fi font families (AlienFontKit's generated scripts now cover the Aurebesh/ring-glyph looks) and their weighting by design principles. The Star Wars-named faces are marked `isExtra` and are excluded from generation unless the user turns on Extra Fonts (`UserDefaults.Key.extraFonts`, off by default), so the shipping look uses only real-world scripts and generic sci-fi faces. `Font.english()` is one of the extra faces and falls back to the system font. Like the screen shape override, the setting is per-device and is not part of the `Config` peers share.

The three theme types (`SystemStyles`, `SystemColors`, `ScreenStyles`) are immutable `Sendable` structs — pure seed-derived data, generated once and then only read. Generation is the whole of their `init`; anything a new theme has to *do* (reload the root, clear the path cache, rebuild the UI sound players) hangs off the `system` global's `didSet`, so tests and the environment's default value can generate a theme without side effects. `SystemStyles`/`ScreenStyles` compare by `generationID`, which is what keeps environment writes cheap.

One piece of global mutable state lives at file scope, `@MainActor`: `system`. `screen` is a computed accessor for `system.screen`. Debug-only overrides of the theme (the font override) live in `DebugSettings`, not on the theme types.

#### One read path: views use the environment, not the globals
`UIRootView` (and its tvOS twin) is the **only** view that reads the globals — it is the bridge that injects them. Everything below reads them back out:

```swift
@Environment(\.system) private var system            // never `systemStyles`, never the global
@Environment(\.screen) private var injectedScreen    // optional; see ScreenView for the resolve
```

Name the property `system`, so it shadows the global inside the type and every `system.foo` in the body goes through the environment. Shapes and other non-`View` types take it as a `let system: SystemStyles` instead.

Two kinds of site legitimately can't, because they run before the view has an environment: `@State` defaults (`AppSettingsPage`, `RandomWidget`) and the `init` bodies that pick a design variant from the seed (a dozen views, e.g. `GalaxyView`, `LockScreenPage`, `Knobs`). They read the global **explicitly qualified as `Space_UI.system`** so the shadowing is visible. All are safe because the root rebuilds the subtree on a theme change (`AppController.configID`). Assignments to the global are qualified for the same reason — an unqualified `system = …` inside a view silently means the global while `system.foo` on the line above means the environment.

A nested type inside a view is a third trap, and the compiler doesn't always catch it: `system` in there resolves to the *outer view's* property, not the global. Non-`View` nested types take the theme as a parameter instead — see `MorseCodeLine.Segment.color(from:)`.

#### Global theme (`system`/`screen`) vs. per-widget seeds (`did`/`vid`)
- **`system` / `screen`** — the shared, seed-derived theme (palette, fonts, shapes, sizing, borders). Use for anything that must match across screens and devices. Never hardcode these values; pull them from `system`/`screen`.
- **`@IDGen` → `did` / `vid`** — decorative style/value choices confined to a single screen that still obey the theme (e.g. `RandomWidget` picking sliders vs. knobs; the variant's colors/fonts still come from `system`). Intentionally non-deterministic across devices — that variety is deliberate, don't make it deterministic.

#### When plain `Int.random` is correct
`Int.random`/`Bool.random`/`randomElement()` are fine, and used on purpose, in two places:
- **Decoration** — anything whose only job is to look alive on one screen: `OrbitsExtPage`'s layout flags, `DecorativeRays`/`DecorativeRingView`, `RadarScanView`, `GalaxyView`, `CircularSegmentedView`, `NavigationMapData`, `AudioVisualizer`'s size-derived waveform. Two screens differing here is the point.
- **Ambient churn on a timer** — `ShipState.changeRandomStatus`, `TargetState.simulateTargetMovement`, `NumberGenerators`. There is no shared clock, so seeding these would only align their first value and then drift apart.

They are wrong for **shared simulation content** — what the room is collectively looking at. That is `ShipState` and everything it builds in its `init` (the ship's own icon, `NearbyShipsState`, `TargetState`), which draws from one `SeededRandom(seed:)` so every device rebuilt from a `Config` reads as the same vessel. Live events that can't be seed-derived (an emergency and its puzzle) reach the room by being **announced** over `PeerSessionController.Message` instead.

### App + windows (`Space UI/`)
- `SpaceUIApp.swift` — `@main`. Two `WindowGroup`s: the UI windows (`WindowID.ui`) and the Space Window (`WindowID.spaceWindow`). Supports single window or paired left/right windows that visually connect at a shared edge (`ConnectedWindowType`). Mac/Catalyst menu commands and keyboard shortcuts live here.
- `AppController.swift` — app-wide coordination (modal fullscreen page shared across windows, debug controls, emergency timer).
- `NearbyInteractionSessionController.swift` — per-device bearing/distance for the peers found below. General peer plumbing, not story.
- `PeerSessionController.swift` — Network framework (Bonjour + TCP via the structured-concurrency `NetworkListener`/`NetworkBrowser`/`NetworkConnection` API). Lets multiple devices in the room sync: a host accepts any number of joiners and broadcasts the `Config` (seed) and story/emergency events so all screens share one theme and stay in sync. Messages are in the `Message` enum. Peers auto-rediscover and re-pair when a connection drops (e.g. the host app restarts).

### Pages (`Space UI/Views/Pages/`)
The UI is organized into "pages" (`Page` enum in `General/Page.swift`, with a smaller tvOS-only copy in that target's `UIRootView.swift`) — e.g. `targeting`, `coms`, `nearby`, `planet`, `galaxy`, `shield`, `music`, `homeKit`, plus mini-games/puzzles (`ticTacToe`, `sudokuPuzzle`, `lightsOutPuzzle`, `unlabeledKeypadPuzzle`). `UIRootView` is the root that picks the visible page and injects the environment (`system`, `screen`, `ShipState`, element size, page navigation). Most pages are pure SwiftUI; a few are flagged `usesUIKit`. A page draws; it does not simulate — the two mini-games' rules live in `General/Games/` as plain structs (`TicTacToeGame`, `DotsAndBoxesGame`) so they can be played in a test without a view, and the page is left with the sounds and the timing.

### Ship state (`Space UI/General/Ship State/`)
- `ShipState.swift` — the shared "fake" simulation state the UI reacts to: status indicators, power, targets, nearby ships, messages, emergencies, hyperspace. `ShipState.shared` is rebuilt from the seed. Drives ambient liveliness (e.g. status fields randomly change on a timer).
- Emergencies: the host can trigger random emergencies that flash colors, play alarms, and pop a puzzle modal across windows.

### Reusable view library (`Space UI/Views/`)
- `Components/`, `Abstract Views/`, `Shapes/`, `Layouts/`, `Buttons/` — a large catalog of sci-fi widgets (radar scans, orbits, wireframes, compasses, knobs, decorative boxes, binary/morse readouts, circular/segmented layouts). Prefer reusing/extending these over building one-off views. Layout helpers like `AutoStack`, `StackThatFits`, `CircularStack`, `LayoutThatFits` handle the adaptive sizing across very different screen shapes and device sizes.

### Other subsystems
- `HomeKit/` — optional integration that drives real HomeKit lights to match the on-screen state (e.g. emergency color, hyperspace), for room immersion.
- `Sounds/` + `AudioController.swift` / `MusicController.swift` — ambient sound and per-theme UI sounds (action/button/alarm) chosen by the seed.
- `Shaders/` (`.metal`, `MyShaders.swift`) — effects such as the optional CRT screen-curve distortion.

## Show mode — private submodule

A private build, **`Space UI (Show)`**, adds a scripted story to the Space Window for in-person events. Its code, assets, story tests and docs live in the private **`Show/`** git submodule — read `Show/AGENTS.md` before touching anything story-related. A clone without it builds `Space UI` and `Space UI (tvOS)`; the Show target and `Space UI Tests` (hosted on it) don't.
- The App Store build keeps the ambient Space Window (planet, stars, fleet, idle/manual hyperspace jumps) and ships none of the script.
- Shared code reaches the show only through `#if STORY` (defined by the Show target), and mostly through the `ShipState` façade instead (`isRunningStory`, `storyChapter`, `storyPatrolLine`, `applyStoryFromPeer(chapter:patrolLine:)`). Prefer the façade over new `#if STORY`.
- `StoryChapter` / `StoryPatrolLine` stay in every target because `PeerSessionController.Message.story` carries them; their raw values are the wire protocol (changing one bumps `protocolVersion`).
- Strings only the show uses go in `Show/Space UI (Show)/Show.xcstrings` (`tableName: "Show"`), not `Localizable.xcstrings`.

## Targets / platforms
Multiplatform from one codebase. **`Space UI`** is the App Store app (iOS/iPadOS, Mac Catalyst, visionOS); **`Space UI (Show)`** is the same app plus the private story half (see above); **`Space UI (tvOS)`** (`Space UI (tvOS)/`) is a lighter standalone variant — parallax title scene, its own settings — and never builds the story. Use the `#if os(...)` / `#if targetEnvironment(macCatalyst)` / `#if canImport(UIKit)` conditionals already used throughout rather than introducing new platform assumptions.

> Deployment targets and which simulators/devices to build for change with OS updates — don't rely on or document specific versions here; check the Xcode project settings at build time.

## Builds

TestFlight builds come from Xcode Cloud, triggered by pushing a `tf/<version>` tag. Xcode Cloud stamps its own per-product counter as the build number when it prepares the upload, so `CURRENT_PROJECT_VERSION` in the project has no effect on a cloud build and no CI script can override it. That counter started at 1, below the manual builds already uploaded (up to 47), which macOS rejects because it requires build numbers to increase across the whole app. The counter's starting value is set in App Store Connect → the app → Xcode Cloud → Settings → Build Number → Next Build Number.

## App Store screenshots

`Scripts/screenshots.sh [iphone|ipad|mac|vision]` — a wrapper onto the runner shared by every app (`Repos/Scripts/screenshots` in iCloud), which boots simulators, freezes the status bar, and composites the Mac window onto a wallpaper. This repo owns only `.screenshots.conf`, `ScreenshotMode.swift`, and `Space UI UITests/ScreenshotTests.swift` (the `Screenshots` scheme's only test target). Shots land in `Raw Assets/Screenshots/` as `Phone 6.9 1.png`, `Pad 13 1.png`, `Mac 1.png`, `Vision 1.png` — a symlink out to iCloud, so nothing lands in the repo, next to the `Old (Manual)/` archive of the hand-made ones. `--upload` sends the results to the App Store version being prepared.

Slot 5 on iPhone, iPad and Mac is a hand-made HomeKit lights shot, and the three `TV` shots are all hand-made (the runner has no tvOS platform); `.screenshots.conf`'s `*_MANUAL_SHOTS` keeps a run off them. visionOS shots are taken in Living Room (Night) (`VISION_ENVIRONMENT`).

The shots are Galaxy, Lock Screen, Planet and Nearby — one launch per page, each with **its own seed**, so the product page shows four different generated interfaces rather than four views of one. Mac shots are taken in full screen and fitted onto black (`MAC_FILL_CANVAS`), no wallpaper. The page comes from `-screenshotPage <Page rawValue>`; every other setting rides in as a launch argument, which lands in `UserDefaults`' argument domain — read ahead of the app's own defaults and never written. That last part is not optional: the Mac build shares its container with the copy of the app you actually use, so a run that *set* these would overwrite your saved seed and settings.

To shop for a different set of looks without an edit: `TEST_RUNNER_SCREENSHOT_SEEDS=<four,comma,separated> Scripts/screenshots.sh mac`, then keep the winners in `ScreenshotTests.seeds`.

Two things are set from inside the app because the runner cannot reach them (`ENABLE_APP_SANDBOX = YES` hides the defaults domain from it): the Mac window's full screen (made non-restorable, so your own copy doesn't reopen in it), and the settings inspector — which SwiftUI restores as presented on a Catalyst launch, writing it back through the binding after `onAppear`.

## Conventions
- Pure Swift + SwiftUI, `@Observable` / `@MainActor` for shared controllers, singletons via `static let shared`.
- Randomness for theming uses `SeededRandom` (SplitMix64 into xoshiro256\*\*, `General/SeededRandom.swift`) so output is deterministic across devices, OS versions and framework updates — it is pure integer math with no framework behind it. Don't use `Int.random`/`arc4random` for anything that must match across synced devices; see also `General/Ship State/NumberGenerators.swift`.
- File header comment style: `// Created by 256 Arts Developer on YYYY-MM-DD.` Match it on new files.

## Backlog

TODO items for this app live in the shared Apple Reminders lists `Dev Ready` (approved work), `Dev Ideas` (proposals), and `Dev Testing` (manual QA), tagged `[Space UI]` — see the `dev-backlog` skill for conventions and scripts. There is no backlog or QA file in this repo. Items are often terse shorthand: treat them as candidate work, not a spec, and clarify cryptic ones with the user before acting.

## Tests
`Space UI (Show)` runs its tests **serially** (`parallelizable = "NO"` in the scheme); don't pass `-parallel-testing-enabled YES`. Most suites are `@MainActor` and share `AudioController.shared`/`ShipState.shared`, so in parallel a heavy suite starves `ShowClockTests`' timing bounds and the story suites stop `AudioFadeTests`' alarm. Mac Catalyst and the iOS Simulator are both valid destinations.

## Debugging (DEBUG builds)
- **Regenerate Seed** — Mac menu / `⌘R`: makes a new random seed and rebuilds `system` + `ShipState`. Use this constantly to verify changes survive theme variety.
- **Show Debug Menu** — `⌘D`, or swipe in from the left screen edge on touch devices. `DebugControls.swift` lets you jump pages, trigger emergencies, step the story, etc.
- **Show Settings** — `⌘S`, or the last icon in the lock screen's bottom row (deliberately drawn as decoration, so exploring taps don't land on it). Settings let the user lock in design principles / hue (`applyDesignPrinciples`) instead of fully random.
- **Ambient Scene toggle** — Show target only, in the debug menu: flips `ShipState` between story mode and the ambient mode, so the public build's path (idle/manual/seed-change hyperspace jumps, camera settle) can be checked without switching targets. The App Store build is only ever ambient.
