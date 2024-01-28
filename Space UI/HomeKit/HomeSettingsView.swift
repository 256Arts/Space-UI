//
//  HomeSettingsView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2022-10-15.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

#if canImport(HomeKit)
import HomeKit
import SwiftUI

struct HomeSettingsView: View {
    
    @AppStorage(UserDefaults.Key.syncHomeLights) private var syncHomeLights = false
    @AppStorage(UserDefaults.Key.turnOnHomeLights) private var turnOnHomeLights = false
    @AppStorage(UserDefaults.Key.setHomeLightsBrightness) private var setHomeLightsBrightness = false
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var homeStore = HomeStore.shared
    
    var body: some View {
        List {
            SwiftUI.Section {
                Toggle("Sync Lights", isOn: $syncHomeLights)
                Toggle("Turn On Lights", isOn: $turnOnHomeLights)
                if turnOnHomeLights {
                    Toggle("Set Brightness to 100%", isOn: $setHomeLightsBrightness)
                }
            }
            SwiftUI.Section {
                if homeStore.homes.isEmpty {
                    Text("No homes found")
                } else {
                    if 1 < homeStore.homes.count {
                        Picker("Home", selection: Binding(get: {
                            homeStore.currentHome
                        }, set: { newValue in
                            homeStore.currentHome = newValue
                            UserDefaults.standard.setValue(newValue?.uniqueIdentifier.uuidString, forKey: UserDefaults.Key.homeID)
                        })) {
                            ForEach(homeStore.homes) { home in
                                Text(home.name)
                                    .tag(home as HMHome?)
                            }
                        }
                    }
                    if let currentHome = homeStore.currentHome {
                        if currentHome.lights.isEmpty {
                            Text("No lights found in \(currentHome.name)")
                        } else {
                            ForEach(currentHome.lights) { light in
                                HStack {
                                    Text(light.accessory.name)
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Toggle("Sync", isOn: Binding(get: {
                                            light.colorMode != nil
                                        }, set: { newValue in
                                            light.setColorMode(newValue ? .primary : nil)
                                        }))
                                        
                                        if light.colorMode != nil {
                                            Picker("Color Mode", selection: Binding(get: {
                                                light.colorMode
                                            }, set: { newValue in
                                                homeStore.objectWillChange.send()
                                                light.setColorMode(newValue)
                                            })) {
                                                ForEach(HomeLight.ColorMode.allCases) { mode in
                                                    Text(mode.rawValue)
                                                        .tag(mode as HomeLight.ColorMode?)
                                                }
                                            }
                                        }
                                    }
                                    .labelsHidden()
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Lights")
            } footer: {
                Text("Emergencies will override the color of all synced lights.")
            }
        }
        .navigationTitle("Sync Lights")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .font(.body)
    }
}

#Preview {
    HomeSettingsView()
}
#endif
