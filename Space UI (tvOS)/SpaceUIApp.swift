//
//  SpaceUIApp.swift
//  Space UI (tvOS)
//
//  Created by 256 Arts Developer on 2024-01-27.
//  Copyright © 2024 256 Arts Developer. All rights reserved.
//

import SwiftUI

@main
struct SpaceUIApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject var appController = AppController.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .background(Color.black, ignoresSafeAreaEdges: .all)
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
    }
    
    init() {
        UserDefaults.standard.register()
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
