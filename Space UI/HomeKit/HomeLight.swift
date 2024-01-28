//
//  HomeLight.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2022-10-15.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

#if canImport(HomeKit)
import HomeKit

/// Model that represents a light device
class HomeLight: ObservableObject, Identifiable {
    
    enum ColorMode: String, Identifiable, CaseIterable {
        case primary = "Primary Color"
        case secondary = "Secondary Color"
        case white = "White"
        case off = "Off"
        
        var id: Self { self }
    }
    
    init(accessory: HMAccessory) {
        self.accessory = accessory
        
        let characteristics = accessory.services.first(where: { $0.serviceType == HMServiceTypeLightbulb })?.characteristics
        let brightState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness })
        let powerState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypePowerState })
        Task {
            try? await brightState?.readValue()
            try? await powerState?.readValue()
        }
        if let value = (brightState?.value as? NSNumber)?.doubleValue, (powerState?.value as? NSNumber)?.boolValue ?? false {
            self.brightness = value
        } else {
            self.brightness = 0
        }
    }
    
    let accessory: HMAccessory
    @Published var brightness: Double {
        didSet {
            Task {
                try? await setBrightness(brightness)
            }
        }
    }
    var id: UUID { accessory.uniqueIdentifier }
    
    func setBrightness(_ brightness: Double) async throws {
        let characteristics = accessory.services.first(where: { $0.serviceType == HMServiceTypeLightbulb })?.characteristics
        let brightState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness })
        try await brightState?.writeValue(brightness)
        
        let powerState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypePowerState })
        try await powerState?.writeValue(true)
    }
    
    var colorMode: ColorMode? {
        let lights = UserDefaults.standard.dictionary(forKey: UserDefaults.Key.homeLightsColorModes) ?? [:]
        return ColorMode(rawValue: lights[id.uuidString] as? String ?? "")
    }
    
    func setColorMode(_ mode: ColorMode?) {
        var lights = UserDefaults.standard.dictionary(forKey: UserDefaults.Key.homeLightsColorModes) ?? [:]
        lights[id.uuidString] = mode?.rawValue
        UserDefaults.standard.set(lights, forKey: UserDefaults.Key.homeLightsColorModes)
        
        Task {
            try? await updateColor()
        }
    }
    
    func updateColor() async throws {
        guard colorMode != nil, (colorMode != .off || ShipData.shared.isInEmergency) else { return }
        
        let characteristics = accessory.services.first(where: { $0.serviceType == HMServiceTypeLightbulb })?.characteristics
        let hueState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypeHue })
        let satState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypeSaturation })
        
        let hue: CGFloat
        let sat: CGFloat
        switch colorMode {
        case .secondary:
            hue = system.colors.secondaryHue
            sat = system.colors.secondarySaturation
        case .white, .off:
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
        
        try await hueState?.writeValue(hue)
        try await satState?.writeValue(sat)
        
        if UserDefaults.standard.bool(forKey: UserDefaults.Key.setHomeLightsBrightness) {
            let brightState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness })
            try await brightState?.writeValue(100)
        }
        
        if UserDefaults.standard.bool(forKey: UserDefaults.Key.turnOnHomeLights) {
            let powerState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypePowerState })
            try await powerState?.writeValue(true)
        }
    }
    
}
#endif
