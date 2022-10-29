//
//  UserDefaults.swift
//  Space UI
//
//  Created by Jayden Irwin on 2020-02-17.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
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
        
        static let externalDisplayOnLeft = "externalDisplayOnLeft"
        static let externalDisplayOnRight = "externalDisplayOnRight"
        static let externalDisplayOnTop = "externalDisplayOnTop"
        static let externalDisplayOnBottom = "externalDisplayOnBottom"
        
        static let syncHomeLights = "syncHomeLights"
        static let turnOnHomeLights = "turnOnHomeLights"
        static let syncedHomeLights = "syncedHomeLights"
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
            
            Key.syncHomeLights: false,
            Key.turnOnHomeLights: false
        ])
        
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        setValue(version, forKey: Key.appVersion)
    }
    
}
