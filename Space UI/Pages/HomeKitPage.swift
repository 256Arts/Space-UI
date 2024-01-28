//
//  HomeKitPage.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2023-05-14.
//  Copyright © 2023 256 Arts Developer. All rights reserved.
//

#if canImport(HomeKit)
import SwiftUI

struct HomeKitPage: View {
    
    @AppStorage(UserDefaults.Key.syncHomeLights) private var syncHomeLights = false
    @AppStorage(UserDefaults.Key.turnOnHomeLights) private var turnOnHomeLights = false
    @AppStorage(UserDefaults.Key.setHomeLightsBrightness) private var setHomeLightsBrightness = false
    
    @IDGen private var idGen
    
    @ObservedObject private var homeStore = HomeStore.shared
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                NavigationButton(to: .lockScreen)
                NavigationButton(to: .customText) {
                    Image(systemName: "line.3.horizontal")
                }
                NavigationButton(to: .music) {
                    Image(systemName: "waveform")
                }
                
                Spacer()
                
                Button("Next") {
                    if let currentHome = homeStore.currentHome, let currentIndex = homeStore.homes.firstIndex(of: currentHome), homeStore.homes.indices.contains(currentIndex + 1) {
                        homeStore.currentHome = homeStore.homes[currentIndex + 1]
                    } else {
                        homeStore.currentHome = homeStore.homes.first
                    }
                }
            }
            
            Text("Home Control")
            
            if let currentHome = homeStore.currentHome {
                if currentHome.lights.isEmpty, currentHome.outlets.isEmpty {
                    Text("No lights or outlets found in \(currentHome.name)")
                } else {
                    Grid(alignment: .leading) {
                        ForEach(currentHome.lights) { light in
                            GridRow {
                                Text(light.accessory.name)
                                
                                Slider(insetInnerBar: idGen(0) % 2 == 0, value: Binding(get: {
                                    light.brightness / 100
                                }, set: { newValue in
                                    light.brightness = newValue * 100
                                }))
                                .frame(maxWidth: 200)
                            }
                            
                            GridRow {
                                Button("Sync") {
                                    homeStore.objectWillChange.send()
                                    light.setColorMode(light.colorMode == nil ? .primary : nil)
                                }
                                .buttonStyle(FlexButtonStyle(isSelected: light.colorMode != nil))
                                
                                HStack {
                                    Button(HomeLight.ColorMode.primary.rawValue) {
                                        homeStore.objectWillChange.send()
                                        light.setColorMode(.primary)
                                    }
                                    .buttonStyle(GroupedButtonStyle(segmentPosition: .leading, width: 110, isSelected: light.colorMode == .primary))
                                    
                                    Button(HomeLight.ColorMode.secondary.rawValue) {
                                        homeStore.objectWillChange.send()
                                        light.setColorMode(.secondary)
                                    }
                                    .buttonStyle(GroupedButtonStyle(segmentPosition: .middle, width: 110, isSelected: light.colorMode == .secondary))
                                    
                                    Button(HomeLight.ColorMode.white.rawValue) {
                                        homeStore.objectWillChange.send()
                                        light.setColorMode(.white)
                                    }
                                    .buttonStyle(GroupedButtonStyle(segmentPosition: .middle, width: 110, isSelected: light.colorMode == .white))
                                    
                                    Button(HomeLight.ColorMode.off.rawValue) {
                                        homeStore.objectWillChange.send()
                                        light.setColorMode(.off)
                                    }
                                    .buttonStyle(GroupedButtonStyle(segmentPosition: .trailing, width: 110, isSelected: light.colorMode == .off))
                                }
                            }
                        }
                        ForEach(currentHome.outlets) { outlet in
                            GridRow {
                                Button(outlet.accessory.name) {
                                    homeStore.objectWillChange.send()
                                    outlet.isOn.toggle()
                                }
                                .buttonStyle(FlexButtonStyle(isSelected: outlet.isOn))
                            }
                        }
                    }
                }
                
                ForEach(currentHome.actionSets) { actionSet in
                    Button(actionSet.name) {
                        Task {
                            try? await currentHome.executeActionSet(actionSet)
                        }
                    }
                    .buttonStyle(FlexButtonStyle(isSelected: actionSet.isExecuting))
                }
            }
        }
        .font(.english())
    }
}

#Preview {
    HomeKitPage()
}
#endif
