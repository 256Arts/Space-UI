//
//  HMHome.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2022-10-15.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

#if canImport(HomeKit)
import HomeKit

extension HMHome: Identifiable {
    
    public var id: UUID { uniqueIdentifier }
    
    var lights: [HomeLight] {
        accessories
            .filter { $0.services.contains(where: { $0.serviceType == HMServiceTypeLightbulb }) }
            .map { HomeLight(accessory: $0) }
    }
    var outlets: [HomeOutlet] {
        accessories
            .filter { $0.services.contains(where: { $0.serviceType == HMServiceTypeOutlet }) }
            .map { HomeOutlet(accessory: $0) }
    }
    
}

extension HMActionSet: Identifiable {
    
    public var id: UUID { uniqueIdentifier }
    
}
#endif
