//
//  HomeLight.swift
//  Space UI
//
//  Created by Jayden Irwin on 2022-10-15.
//  Copyright © 2022 Jayden Irwin. All rights reserved.
//

import HomeKit

struct HomeLight: Identifiable {
    
    enum Mode: String, Identifiable, CaseIterable {
        case syncPrimaryColor = "Sync Primary Color"
        case syncSecondaryColor = "Sync Secondary Color"
        case syncEmergency = "Emergency Only"
        case off = "Off"
        
        var id: Self { self }
    }
    
    let accessory: HMAccessory
    var id: UUID { accessory.uniqueIdentifier }
    
    var syncMode: Mode {
        let lights = UserDefaults.standard.dictionary(forKey: UserDefaults.Key.syncedHomeLights) ?? [:]
        return Mode(rawValue: lights[id.uuidString] as? String ?? "") ?? .off
    }
    
    func setSyncMode(_ mode: Mode) {
        var lights = UserDefaults.standard.dictionary(forKey: UserDefaults.Key.syncedHomeLights) ?? [:]
        if mode == .off {
            lights[id.uuidString] = nil
        } else {
            lights[id.uuidString] = mode.rawValue
        }
        UserDefaults.standard.set(lights, forKey: UserDefaults.Key.syncedHomeLights)
    }
    
    func updateColor() {
        guard syncMode != .off else { return }
        
        let characteristics = accessory.services.first(where: { $0.serviceType == HMServiceTypeLightbulb })?.characteristics
        let hueState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypeHue })
        let satState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypeSaturation })
        
        let hue: CGFloat
        let sat: CGFloat
        switch syncMode {
        case .syncSecondaryColor:
            hue = system.colors.secondaryHue
            sat = system.colors.secondarySaturation
        case .syncEmergency:
            if ShipData.shared.isInEmergency {
                fallthrough
            } else {
                hue = 0
                sat = 0
            }
        default:
            hue = system.colors.primaryHue * 360
            sat = system.colors.primarySaturation * 100
        }
        
        hueState?.writeValue(hue, completionHandler: { error in
            print(error)
        })
        satState?.writeValue(sat, completionHandler: { error in
            print(error)
        })
        
        if UserDefaults.standard.bool(forKey: UserDefaults.Key.turnOnHomeLights) {
            let powerState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypePowerState })
            powerState?.writeValue(true, completionHandler: { error in
                print(error)
            })
        }
    }
    
}
