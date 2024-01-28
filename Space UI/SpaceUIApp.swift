//
//  SpaceUIApp.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2024-01-14.
//  Copyright © 2024 256 Arts Developer. All rights reserved.
//

import SwiftUI

@main
struct SpaceUIApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    #if os(visionOS)
    @Environment(\.openImmersiveSpace) private var openSpace
    #endif
    
    @StateObject var appController = AppController.shared
    
    var body: some Scene {
        #if os(visionOS)
        WindowGroup {
            RootView(isExternal: false)
        }
        .windowStyle(.volumetric)
        ImmersiveSpace(id: "1") {
            RootView(isExternal: false)
        }
        #else
        WindowGroup {
            RootView(isExternal: false)
                .background(Color.black, ignoresSafeAreaEdges: .all)
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        #endif
        .commandsReplaced {
            CommandGroup(after: .windowSize) {
                Button("Show Settings") {
                    appController.visiblePage = .settings
                }
                .keyboardShortcut("s")
            }
            #if DEBUG
            CommandGroup(after: .windowSize) {
                Button("Show Debug Menu") {
                    appController.showingDebugControls.toggle()
                }
                .keyboardShortcut("d")
            }
            CommandGroup(replacing: .pasteboard) {
                Button("Regenerate Seed") {
                    system = SystemStyles(seed: UInt64(arc4random()))
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
                        try? await HomeStore.shared.updateLights()
                    }
                }
                
                if UserDefaults.standard.bool(forKey: UserDefaults.Key.keepAwake) {
                    UIApplication.shared.isIdleTimerDisabled = true
                }
                
                startEmergencyCountdown()
            case .inactive:
                appController.nextEmergencyTimer?.invalidate()
            case .background:
                PeerSessionController.shared.stopLookingToHost()
                PeerSessionController.shared.stopLookingToJoin()
                AudioController.shared.invalidateAmbientSoundTimers()
            @unknown default:
                break
            }
        }
        #endif
    }
    
    init() {
        UserDefaults.standard.register()
        
//        #if DEBUG
//        for family in UIFont.familyNames.sorted() {
//            let names = UIFont.fontNames(forFamilyName: family)
//            print("Family: \(family) Font names: \(names)")
//        }
//        #endif
    }
    
    private func startEmergencyCountdown() {
        guard UserDefaults.standard.bool(forKey: UserDefaults.Key.randomEmergencies), PeerSessionController.shared.isHost else { return }
        
        appController.nextEmergencyTimer?.invalidate()
        appController.nextEmergencyTimer = Timer.scheduledTimer(withTimeInterval: 1000, repeats: true) { (_) in
            PeerSessionController.shared.send(message: .emergencyBegan)
            ShipData.shared.beginEmergency()
            Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { (_) in
                if ShipData.shared.isInEmergency {
                    PeerSessionController.shared.send(message: .emergencyEnded)
                    ShipData.shared.endEmergency()
                }
            }
        }
    }
    
}
