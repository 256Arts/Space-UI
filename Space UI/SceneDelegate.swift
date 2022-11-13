//
//  SceneDelegate.swift
//  Space UI
//
//  Created by Jayden Irwin on 2019-10-04.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import UIKit
import SwiftUI

var iwindow: UIWindow?
var externalWindow: UIWindow?
var rootHostingController: HostingController?
var nextEmergencyTimer: Timer?
var visiblePage = Page.lockScreen
var savedPage = Page.lockScreen
#if DEBUG
var debugShowingExternalDisplay = false
#endif

func replaceRootView() {
    if UserDefaults.standard.bool(forKey: UserDefaults.Key.syncHomeLights) {
        HomeStore.shared.updateLights()
    }
    
    rootHostingController = HostingController(rootView: RootView(isExternal: false, currentPage: visiblePage))
    rootHostingController?.overrideUserInterfaceStyle = .dark
    rootHostingController?.view.backgroundColor = .black
    iwindow?.rootViewController = rootHostingController
    let tintColor = UIColor(Color(color: .primary, brightness: .max))
    iwindow?.tintColor = tintColor
    
    if let exWindow = externalWindow {
        exWindow.rootViewController = HostingController(rootView: RootView(isExternal: true, currentPage: system.screen.externalDisplayPage))
        exWindow.rootViewController?.overrideUserInterfaceStyle = .dark
        exWindow.rootViewController?.view.backgroundColor = .black
        exWindow.tintColor = tintColor
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        let isExternalDisplay = (session.role == .windowExternalDisplayNonInteractive)

        // Create the SwiftUI view that provides the window contents.
        let rootView = RootView(isExternal: isExternalDisplay, currentPage: isExternalDisplay ? system.screen.externalDisplayPage : visiblePage)

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            windowScene.sizeRestrictions?.minimumSize = CGSize(width: 1600, height: 900)
            windowScene.sizeRestrictions?.maximumSize = CGSize(width: 9999, height: 9999)
            
            if UserDefaults.standard.bool(forKey: UserDefaults.Key.syncHomeLights) {
                HomeStore.shared.updateLights()
            }
            
            let window = UIWindow(windowScene: windowScene)
            rootHostingController = HostingController(rootView: rootView)
            rootHostingController?.overrideUserInterfaceStyle = .dark
            rootHostingController?.view.backgroundColor = .black
            window.rootViewController = rootHostingController
            window.tintColor = UIColor(Color(color: .primary, brightness: .max))
            self.window = window
            if isExternalDisplay {
                externalWindow = window
            } else {
                iwindow = window
            }
            window.makeKeyAndVisible()
            
            #if targetEnvironment(macCatalyst)
            if let titlebar = windowScene.titlebar {
                titlebar.titleVisibility = .hidden
                titlebar.toolbar = nil
            }
            #endif
        }
        
        if UserDefaults.standard.bool(forKey: UserDefaults.Key.keepAwake) {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        startEmergencyCountdown()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        PeerSessionController.shared.lookToHost()
        PeerSessionController.shared.lookToJoin()
        AudioController.shared.startAmbience()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        startEmergencyCountdown()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        nextEmergencyTimer?.invalidate()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        PeerSessionController.shared.stopLookingToHost()
        PeerSessionController.shared.stopLookingToJoin()
        AudioController.shared.invalidateAmbientSoundTimers()
    }
    
    func startEmergencyCountdown() {
        guard UserDefaults.standard.bool(forKey: UserDefaults.Key.randomEmergencies), PeerSessionController.shared.isHost else { return }
        nextEmergencyTimer?.invalidate()
        nextEmergencyTimer = Timer.scheduledTimer(withTimeInterval: 1000, repeats: true) { (_) in
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

