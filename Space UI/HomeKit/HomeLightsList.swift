//
//  HomeLightsList.swift
//  Space UI
//
//  Created by Jayden Irwin on 2022-10-15.
//  Copyright © 2022 Jayden Irwin. All rights reserved.
//

import HomeKit
import SwiftUI

struct HomeLightsList: View {
    
    let home: HMHome
    
    @ObservedObject private var homeStore = HomeStore.shared
    
    var body: some View {
        List {
            if home.lights.isEmpty {
                Text("No lights found in \(home.name)")
            } else {
                ForEach(home.lights) { light in
                    Picker(light.accessory.name, selection: Binding(get: {
                        light.syncMode
                    }, set: { newValue in
                        homeStore.objectWillChange.send()
                        light.setSyncMode(newValue)
                    })) {
                        ForEach(HomeLight.Mode.allCases) { mode in
                            Text(mode.rawValue)
                                .tag(mode)
                        }
                    }
                }
            }
        }
        .navigationTitle("Synced Lights")
    }
}
