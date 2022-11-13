//
//  AppDelegate.swift
//  Space UI
//
//  Created by Jayden Irwin on 2019-10-04.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UserDefaults.standard.register()
        
//        #if DEBUG
//        for family in UIFont.familyNames.sorted() {
//            let names = UIFont.fontNames(forFamilyName: family)
//            print("Family: \(family) Font names: \(names)")
//        }
//        #endif
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        builder.remove(menu: .file)
        builder.remove(menu: .edit)
        builder.remove(menu: .services)
        builder.remove(menu: .format)
        builder.remove(menu: .toolbar)
        builder.remove(menu: .help)
        
        let viewSeedCommand = UIKeyCommand(input: "S", modifierFlags: [], action: #selector(viewSeed))
        viewSeedCommand.title = "Show Settings"
        builder.insertChild(UIMenu(title: "Show Settings", image: nil, identifier: .init(rawValue: "settings"), options: .displayInline, children: [viewSeedCommand]), atEndOfMenu: .view)
        
        #if DEBUG
        let showDebugMenuCommand = UIKeyCommand(input: "D", modifierFlags: [], action: #selector(showHideDebugMenu))
        showDebugMenuCommand.title = "Show Debug Menu"
        builder.insertChild(UIMenu(title: "Show Debug Menu", image: nil, identifier: .init(rawValue: "showHideDebugMenu"), options: .displayInline, children: [showDebugMenuCommand]), atEndOfMenu: .view)
        
        let regenerateSeedCommand = UIKeyCommand(input: "R", modifierFlags: [], action: #selector(regenerateSeed))
        regenerateSeedCommand.title = "Regenerate Seed"
        builder.insertChild(UIMenu(title: "Regenerate Seed", image: nil, identifier: .init(rawValue: "regenerateSeed"), options: .displayInline, children: [regenerateSeedCommand]), atEndOfMenu: .view)
        #endif
    }
    
    @objc func viewSeed() {
        visiblePage = .settings
        NotificationCenter.default.post(name: NSNotification.Name("navigate"), object: nil)
    }
    
    #if DEBUG
    @objc func showHideDebugMenu() {
        NotificationCenter.default.post(name: NSNotification.Name("showHideDebugMenu"), object: nil)
    }
    
    @objc func regenerateSeed() {
        system = SystemAppearance(seed: UInt64(arc4random()))
        replaceRootView()
    }
    #endif

}

