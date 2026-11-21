import SwiftUI

enum WindowID: String {
    case ui, spaceWindow, immersiveSpace
}

/// Which half of the paired-window layout a UI window is, for the two-window Mac setup whose screens meet at a
/// shared edge. `nil` throughout the single-window case. Carried as the `WindowGroup`'s value, so it is a
/// window identity like `WindowID` rather than anything the root view owns.
enum ConnectedWindowType: Codable {
    case left, right

    var title: LocalizedStringResource {
        switch self {
        case .left:
            "Space UI - Left"
        case .right:
            "Space UI - Right"
        }
    }

    var connectedEdges: [RectEdge] {
        switch self {
        case .left:
            [.right]
        case .right:
            [.left]
        }
    }
}

@main
struct SpaceUIApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some Scene {
        #if os(visionOS)
        WindowGroup(id: WindowID.ui.rawValue) {
            UIRootView(connectedWindowType: nil, isExternal: false)
                // A screenshot run hangs what it prepared here, where the walk can read it back.
                .screenshotModeStatus()
        }
        .windowStyle(.plain)
        #else
        WindowGroup(id: WindowID.ui.rawValue, for: ConnectedWindowType.self) { $windowType in
            UIRootView(connectedWindowType: windowType, isExternal: false)
                // A screenshot run hangs what it prepared here, where the walk can read it back.
                .screenshotModeStatus()
                .cursorAutoHide()
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowFullScreenBehavior(.enabled)
        #endif
        .commandsReplaced {
            CommandGroup(replacing: .newItem) {
                Menu("New UI Window", systemImage: "plus.rectangle") {
                    Button("Single Window") {
                        dismissWindow(id: WindowID.ui.rawValue)
                        openWindow(id: WindowID.ui.rawValue)
                    }
                    Button("Left & Right Windows") {
                        dismissWindow(id: WindowID.ui.rawValue)
                        openWindow(id: WindowID.ui.rawValue, value: ConnectedWindowType.left)
                        openWindow(id: WindowID.ui.rawValue, value: ConnectedWindowType.right)
                    }
                }
                Menu("New Space Window", systemImage: "sparkles") {
                    Button("Single Window") {
                        dismissWindow(id: WindowID.spaceWindow.rawValue)
                        openWindow(id: WindowID.spaceWindow.rawValue)
                    }
                    Button("Left & Right Windows") {
                        dismissWindow(id: WindowID.spaceWindow.rawValue)
                        openWindow(id: WindowID.spaceWindow.rawValue, value: CameraAngle.dualLeft)
                        openWindow(id: WindowID.spaceWindow.rawValue, value: CameraAngle.dualRight)
                    }
                }
            }
            CommandGroup(before: .toolbar) {
                Button("Show Settings", systemImage: "gear") {
                    AppController.shared.openPageModally(.settings)
                }
                .keyboardShortcut("s")
                // The Mac has no screen edge to swipe in from, so the inspector needs a command of its own.
                Button("Show Settings Inspector", systemImage: "sidebar.right") {
                    AppController.shared.showingSettingsInspector.toggle()
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
                // Ambient Space Window control — no-ops while the scripted story owns the scene.
                Button("Hyperspace Jump", systemImage: "sparkles") {
                    ShipState.shared.ambientHyperspaceJump()
                }
                .keyboardShortcut("j")
            }
            // The director's menu. Catalyst because the Mac is the show's director (see `Show/Docs/Show Setup.md`),
            // and STORY because there is no show to direct in the App Store build.
            #if targetEnvironment(macCatalyst) && STORY
            CommandMenu("Story") {
                Button("Story Forward", systemImage: "arrowtriangle.forward.fill") {
                    ShipState.shared.storyState?.next()
                }
                .keyboardShortcut(.rightArrow, modifiers: [])
                // Back requires a confirming second press (see StoryState.previous), so a stray press can't
                // rewind the live show.
                Button("Story Back", systemImage: "arrowtriangle.backward.fill") {
                    ShipState.shared.storyState?.previous()
                }
                .keyboardShortcut(.leftArrow, modifiers: [])
                // Recovers the show after a host crash/relaunch by restoring the last persisted chapter.
                Button("Resume Story", systemImage: "arrow.clockwise") {
                    ShipState.shared.storyState?.resumeFromPersisted()
                }
                .keyboardShortcut("r", modifiers: [.command, .option])
                // Puts the show back on a chosen beat when it has come off one. The arrows move a single beat
                // at a time and a skip needs a confirming second press, so walking from a wrong beat to the
                // right one can otherwise take a dozen presses in front of the room. No confirmation here:
                // picking a named beat out of a menu is deliberate in a way a stray arrow key isn't.
                Menu("Jump to Beat") {
                    ForEach(StoryState.Position.all, id: \.self) { position in
                        Button(position.displayName) {
                            guard let chapter = position.chapter else { return }
                            ShipState.shared.storyState?.jump(to: chapter, patrolLine: position.patrolLine)
                        }
                    }
                }
            }
            #endif
            #if DEBUG
            CommandGroup(before: .toolbar) {
                Button("Show Debug Menu", systemImage: "ant") {
                    AppController.shared.showingDebugControls.toggle()
                }
                .keyboardShortcut("d")
            }
            CommandGroup(replacing: .pasteboard) {
                Button("Regenerate Seed", systemImage: "slider.horizontal.2.arrow.trianglehead.counterclockwise") {
                    AppController.shared.applyConfig(randomConfig, broadcast: true, persist: false)
                }
                .keyboardShortcut("r")
            }
            #endif
        }
        .onChange(of: scenePhase) { _, newValue in
            switch newValue {
            case .active:
                PeerSessionController.shared.lookToHost()
                PeerSessionController.shared.lookToJoin()
                AudioController.shared.startAmbience()
                
                if UserDefaults.standard.bool(forKey: UserDefaults.Key.syncHomeLights) {
                    Task {
                        try? await HomeStore.shared.updateLights(sourceFilter: .lightPanel)
                    }
                }

                #if targetEnvironment(macCatalyst) && STORY
                // The director's Mac is the sole owner of the show's physical console hardware.
                ConsoleController.shared.start()
                #endif

                if UserDefaults.standard.bool(forKey: UserDefaults.Key.keepAwake) || ShipState.shared.storyChapter != nil {
                    UIApplication.shared.isIdleTimerDisabled = true
                }

                // Re-force full brightness if we return to a live show that was backgrounded mid-story.
                if ShipState.shared.storyChapter != nil {
                    UIScreen.forceFullBrightnessForStory()
                }
            case .background:
                PeerSessionController.shared.stopLookingToHost()
                PeerSessionController.shared.stopLookingToJoin()
                AudioController.shared.invalidateAmbientSoundTimers()

                // Restore the user's original brightness when they leave the app, so story mode
                // never leaves the device stuck at 100%.
                UIScreen.restoreUserBrightness()
            default:
                break
            }
        }
        #endif
        
        WindowGroup("Space Window", id: WindowID.spaceWindow.rawValue, for: CameraAngle.self) { $cameraAngle in
            SpaceWindowView(cameraAngle: cameraAngle)
                .cursorAutoHide()
        } defaultValue: {
            .singleCenter
        }
        #if DEBUG
        .defaultSize(width: 1920/2, height: 1080/2)
        #endif
        #if os(macOS)
        .windowFullScreenBehavior(.enabled)
        #endif

        #if os(visionOS)
        ImmersiveSpace(id: WindowID.immersiveSpace.rawValue) {
            SpaceImmersiveView()
        }
        .immersionStyle(selection: .constant(.full), in: .full)
        #endif
    }
    
    init() {
        let userDefaults = UserDefaults.standard
        userDefaults.register()

        // Force the lazy `system` global to initialize now, which also assigns the `screen` global as a side
        // effect (see SystemStyles.init). Views read `screen` (a force-unwrapped `ScreenStyles!`) directly in
        // their body, so it must be non-nil before the first render.
        _ = system
        
        userDefaults
            .set(
                userDefaults.integer(forKey: UserDefaults.Key.appLaunchCount) + 1,
                forKey: UserDefaults.Key.appLaunchCount
            )
        
//        #if DEBUG
//        for family in UIFont.familyNames.sorted() {
//            let names = UIFont.fontNames(forFamilyName: family)
//            print("Family: \(family) Font names: \(names)")
//        }
//        #endif
    }
    
}
