//
//  AppDelegate.swift
//  Space UI (tvOS)
//
//  Created by Jayden Irwin on 2019-12-27.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import UIKit
import SwiftUI

var iwindow: UIWindow?
var rootHostingController: HostingController?
var nextEmergencyTimer: Timer?

func replaceRootView() {
    rootHostingController = HostingController(rootView: RootView(currentPage: system.screen.externalDisplayPage))
    iwindow?.rootViewController = rootHostingController
    let tintColor = UIColor(Color(color: .primary, brightness: .max))
    iwindow?.tintColor = tintColor
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UserDefaults.standard.register()

        // Create the SwiftUI view that provides the window contents.
        let rootView = RootView(currentPage: system.screen.externalDisplayPage)

        // Use a UIHostingController as window root view controller.
        let window = UIWindow(frame: UIScreen.main.bounds)
        rootHostingController = HostingController(rootView: rootView)
        window.rootViewController = rootHostingController
        window.tintColor = UIColor(Color(color: .primary, brightness: .max))
        iwindow = window
        window.makeKeyAndVisible()
        
        if UserDefaults.standard.bool(forKey: UserDefaults.Key.keepAwake) {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        PeerSessionController.shared.lookToHost()
        PeerSessionController.shared.lookToJoin()
        AudioController.shared.startAmbience()
        startEmergencyCountdown()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        PeerSessionController.shared.stopLookingToHost()
        PeerSessionController.shared.stopLookingToJoin()
        AudioController.shared.invalidateAmbientSoundTimers()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        PeerSessionController.shared.lookToHost()
        PeerSessionController.shared.lookToJoin()
        AudioController.shared.startAmbience()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func startEmergencyCountdown() {
        guard UserDefaults.standard.bool(forKey: UserDefaults.Key.randomEmergencies) else { return }
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

