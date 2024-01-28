//
//  AppController.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2024-01-16.
//  Copyright © 2024 256 Arts Developer. All rights reserved.
//

import SwiftUI

var seed: UInt64 = {
    let savedSeed = UserDefaults.standard.integer(forKey: UserDefaults.Key.seed)
    if savedSeed == 0 {
        let newSeed = UInt64(arc4random())
        UserDefaults.standard.set(Int(newSeed), forKey: UserDefaults.Key.seed)
        return newSeed
    } else {
        return UInt64(savedSeed)
    }
}()

final class AppController: ObservableObject {
    
    static let shared = AppController()
    
    var iwindow: UIWindow?
    var externalWindow: UIWindow?
    
    var savedPage = Page.lockScreen
    
    @Published var nextEmergencyTimer: Timer?
    @Published var visiblePage = Page.lockScreen
    @Published var showingDebugControls = false
    
    #if DEBUG
    var debugShowingExternalDisplay = false
    #endif
    
    func reloadRootView() {
        objectWillChange.send()
    }
    
}
