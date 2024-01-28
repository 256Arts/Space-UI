//
//  HomeStore.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2022-10-15.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

#if canImport(HomeKit)
import HomeKit

class HomeStore: NSObject, ObservableObject {
    
    static let shared = HomeStore()
    
    override init() {
        super.init()
        homeManager.delegate = self
        
        Task {
            try? await Task.sleep(for: .seconds(0.1))
            autoSelectHome()
        }
    }
    
    private let homeManager = HMHomeManager()
    
    @Published var currentHome: HMHome?
    
    var homes: [HMHome] {
        homeManager.homes
    }
    
    func autoSelectHome() {
        guard currentHome == nil else { return }
        
        let currentHomeID = UUID(uuidString: UserDefaults.standard.string(forKey: UserDefaults.Key.homeID) ?? "")
        currentHome = homeManager.homes.first(where: { $0.uniqueIdentifier == currentHomeID }) ??
            homeManager.homes.first(where: { $0.isPrimary && !$0.lights.isEmpty }) ??
            homeManager.homes.max(by: { $0.lights.count < $1.lights.count })
    }
    
    func updateLights() async throws {
        guard UserDefaults.standard.bool(forKey: UserDefaults.Key.syncHomeLights) else { return }
        
        for home in homeManager.homes {
            for light in home.lights {
                try await light.updateColor()
            }
        }
    }
    
}

extension HomeStore: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        objectWillChange.send()
    }
}
#endif
