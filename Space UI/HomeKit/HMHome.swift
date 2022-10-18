//
//  HMHome.swift
//  Space UI
//
//  Created by Jayden Irwin on 2022-10-15.
//  Copyright © 2022 Jayden Irwin. All rights reserved.
//

import HomeKit

extension HMHome: Identifiable {
    
    public var id: UUID { uniqueIdentifier }
    
    var lights: [HomeLight] {
        accessories
            .filter { $0.services.contains(where: { $0.serviceType == HMServiceTypeLightbulb }) }
            .map { HomeLight(accessory: $0) }
    }
    
}
