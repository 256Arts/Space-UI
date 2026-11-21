import Foundation

extension UserDefaults {
    
    enum Key {
        static let appLaunchCount = "appLaunchCount"
        static let appVersion = "appVersion"
        static let playAmbience = "playAmbience"
        static let playEnvironmental = "playEnvironmental"
        static let playSounds = "playSounds"
        static let keepAwake = "keepAwake"
        static let showAlbumArtwork = "showAlbumArtwork"
        static let randomEmergencies = "randomEmergencies"
        static let displayOrientation = "displayOrientation"
        static let screenShapeOverride = "screenShapeOverride"
        static let tutorialShown = "tutorialShown"
        static let canHostSession = "canHostSession"
        static let canJoinSession = "canJoinSession"
        static let peerDeviceID = "peerDeviceID"
        static let customTextMarkdown = "customTextMarkdown"

        // Story
        static let storyChapter = "storyChapter"
        static let storyPatrolLine = "storyPatrolLine"
        
        // Design
        static let applyDesignPrinciples = "applyDesignPrinciples"
        static let primaryHue = "primaryHue"
        static let primarySaturation = "primarySaturation"
        static let designPrinciples = "designPrinciples"
        static let seed = "seed"
        static let extraFonts = "extraFonts"
        
        // Space Window
        static let nearbyInteractionRole = "nearbyInteractionRole"
        static let windowDisplayPhysicalWidth = "windowDisplayPhysicalWidth"
        
        // External Displays
        static let externalDisplayOnLeft = "externalDisplayOnLeft"
        static let externalDisplayOnRight = "externalDisplayOnRight"
        static let externalDisplayOnTop = "externalDisplayOnTop"
        static let externalDisplayOnBottom = "externalDisplayOnBottom"
        static let externalDisplaySeemlessMode = "externalDisplaySeemlessMode"
        
        // HomeKit
        static let homeID = "homeID"
        static let roomID = "roomID"
        static let syncHomeLights = "syncHomeLights"
        static let turnOnHomeLights = "turnOnHomeLights"
        static let setHomeLightsBrightness = "setHomeLightsBrightness"
        static let homeLightsColorModes = "homeLightsColorModes"
    }
    
    /// The current theme seed.
    ///
    /// Stored as an `Int64` bit pattern so that any `UInt64` — including values above `Int64.max` — round-trips
    /// without trapping. `UserDefaults.integer(forKey:)` returns an `Int`, so a raw `UInt64` write would come back
    /// negative and crash `UInt64(_:)` on the next launch (a persistent crash loop).
    var seed: UInt64 {
        get { UInt64(bitPattern: Int64(integer(forKey: Key.seed))) }
        set { set(Int64(bitPattern: newValue), forKey: Key.seed) }
    }

    func register() {
        register(defaults: [
            Key.appLaunchCount: 1,
            Key.playAmbience: true,
            Key.playEnvironmental: true,
            Key.playSounds: true,
            Key.keepAwake: false,
            Key.showAlbumArtwork: true,
            Key.randomEmergencies: true,
            Key.displayOrientation: "default",
            Key.tutorialShown: false,
            Key.canHostSession: true,
            Key.canJoinSession: true,
            
            // Design
            Key.seed: Int(UInt64(arc4random())),
            Key.extraFonts: false,
            
            // Space Window
            Key.windowDisplayPhysicalWidth: 1.44, // 65" TV
            
            // External Displays
            Key.externalDisplayOnLeft: false,
            Key.externalDisplayOnRight: false,
            Key.externalDisplayOnTop: false,
            Key.externalDisplayOnBottom: false,
            Key.externalDisplaySeemlessMode: false,
            
            // HomeKit
            Key.syncHomeLights: false,
            Key.turnOnHomeLights: false,
            Key.setHomeLightsBrightness: false
        ])
        
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        setValue(version, forKey: Key.appVersion)
    }
    
}

enum SceneStorageKey {
    static let stackBottomPage = "stackBottomPage"
    static let debugShowingExternalDisplay = "debugShowingExternalDisplay"
}
