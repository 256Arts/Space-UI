//
//  UserDefaults.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-02-17.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    struct Key {
        static let appVersion = "appVersion"
        static let playAmbience = "playAmbience"
        static let playSounds = "playSounds"
        static let keepAwake = "keepAwake"
        static let showAlbumArtwork = "showAlbumArtwork"
        static let randomEmergencies = "randomEmergencies"
        static let seed = "seed"
        static let displayOrientation = "displayOrientation"
        static let screenShapeOverride = "screenShapeOverride"
        static let tutorialShown = "tutorialShown"
        static let canHostSession = "canHostSession"
        static let canJoinSession = "canJoinSession"
        static let customTextMarkdown = "customTextMarkdown"
        
        // External Displays
        static let externalDisplayOnLeft = "externalDisplayOnLeft"
        static let externalDisplayOnRight = "externalDisplayOnRight"
        static let externalDisplayOnTop = "externalDisplayOnTop"
        static let externalDisplayOnBottom = "externalDisplayOnBottom"
        static let externalDisplaySeemlessMode = "externalDisplaySeemlessMode"
        
        // HomeKit
        static let homeID = "homeID"
        static let syncHomeLights = "syncHomeLights"
        static let turnOnHomeLights = "turnOnHomeLights"
        static let setHomeLightsBrightness = "setHomeLightsBrightness"
        static let homeLightsColorModes = "homeLightsColorModes"
    }
    
    func register() {
        register(defaults: [
            Key.playAmbience: true,
            Key.playSounds: true,
            Key.keepAwake: false,
            Key.showAlbumArtwork: true,
            Key.randomEmergencies: true,
            Key.displayOrientation: "default",
            Key.tutorialShown: false,
            Key.canHostSession: true,
            Key.canJoinSession: true,
            
            Key.externalDisplayOnLeft: false,
            Key.externalDisplayOnRight: false,
            Key.externalDisplayOnTop: false,
            Key.externalDisplayOnBottom: false,
            Key.externalDisplaySeemlessMode: false,
            
            Key.syncHomeLights: false,
            Key.turnOnHomeLights: false,
            Key.setHomeLightsBrightness: false
        ])
        
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        setValue(version, forKey: Key.appVersion)
    }
    
}
