//
//  HomeOutlet.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2023-06-17.
//  Copyright © 2023 256 Arts Developer. All rights reserved.
//

#if canImport(HomeKit)
import HomeKit

/// Model that represents a outlet device
class HomeOutlet: ObservableObject, Identifiable {
    
    init(accessory: HMAccessory) {
        self.accessory = accessory
        
        let characteristics = accessory.services.first(where: { $0.serviceType == HMServiceTypeOutlet })?.characteristics
        let powerState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypePowerState })
        Task {
            try? await powerState?.readValue()
        }
        self.isOn = (powerState?.value as? NSNumber)?.boolValue ?? false
    }
    
    let accessory: HMAccessory
    @Published var isOn: Bool {
        didSet {
            Task {
                try? await setPower(isOn)
            }
        }
    }
    var id: UUID { accessory.uniqueIdentifier }
    
    func setPower(_ isOn: Bool) async throws {
        let characteristics = accessory.services.first(where: { $0.serviceType == HMServiceTypeOutlet })?.characteristics
        let powerState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypePowerState })
        try await powerState?.writeValue(isOn)
    }
    
}
#endif
