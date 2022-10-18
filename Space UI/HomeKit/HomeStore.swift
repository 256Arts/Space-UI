//
//  HomeStore.swift
//  Space UI
//
//  Created by Jayden Irwin on 2022-10-15.
//  Copyright © 2022 Jayden Irwin. All rights reserved.
//

import HomeKit

class HomeStore: NSObject, ObservableObject {
    
    static let shared = HomeStore()
    
    let homeManager = HMHomeManager()
    
    override init() {
        super.init()
        homeManager.delegate = self
    }
    
    func updateLights() {
        guard UserDefaults.standard.bool(forKey: UserDefaults.Key.syncHomeLights) else { return }
        
        for home in homeManager.homes {
            for light in home.lights {
                light.updateColor()
            }
        }
    }
    
}

extension HomeStore: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        objectWillChange.send()
    }
}
