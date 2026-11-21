#if canImport(HomeKit)
import HomeKit
import SwiftUI

struct HomeSettingsView: View {
    
    @AppStorage(UserDefaults.Key.roomID) private var roomID: String?
    @AppStorage(UserDefaults.Key.syncHomeLights) private var syncHomeLights = false
    @AppStorage(UserDefaults.Key.turnOnHomeLights) private var turnOnHomeLights = false
    @AppStorage(UserDefaults.Key.setHomeLightsBrightness) private var setHomeLightsBrightness = false
    
    @Environment(\.dismiss) private var dismiss
    /// Computed, not stored: `NavigationLink` builds this view as soon as the settings inspector's body runs —
    /// which it does while hidden — and creating the store asks for Home access on a launch that never opened it.
    private var homeStore: HomeStore { .shared }
    
    private var lightingModesWithValidActionSets: [LightingMode] {
        LightingMode.allCases.compactMap {
            homeStore.currentHome?.actionSet(for: $0) != nil ? $0 : nil
        }
    }
    
    var body: some View {
        List {
            Section {
                Toggle("Sync Lights", isOn: $syncHomeLights)
                Toggle("Turn On Lights", isOn: $turnOnHomeLights)
                if turnOnHomeLights {
                    Toggle("Set Brightness to 100%", isOn: $setHomeLightsBrightness)
                }
                
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
                    Picker("Room", selection: $roomID) {
                        ForEach(homeStore.currentHome?.rooms ?? []) { room in
                            Text(room.name)
                                .tag(room.uniqueIdentifier.uuidString)
                        }
                    }
                }
            }
            
            Section {
                if homeStore.homes.isEmpty {
                    Text("No homes found")
                } else {
                    if let selectedRoom = homeStore.currentHome?.rooms.first(where: { $0.uniqueIdentifier.uuidString == roomID }) {
                        if selectedRoom.accessories.lights.isEmpty {
                            Text("No lights found in \(selectedRoom.name)")
                        } else {
                            ForEach(selectedRoom.accessories.lights) { light in
                                LabeledContent {
                                    VStack(alignment: .trailing) {
                                        Toggle("Sync", isOn: Binding(get: {
                                            light.colorMode != nil
                                        }, set: { newValue in
                                            light.colorMode = newValue ? light.availableColorModes.first! : nil
                                        }))
                                        
                                        if light.colorMode != nil {
                                            Picker("Color Mode", selection: Binding(get: {
                                                light.colorMode
                                            }, set: { newValue in
                                                light.colorMode = newValue
                                            })) {
                                                ForEach(light.availableColorModes) { mode in
                                                    Text(mode.rawValue)
                                                        .tag(mode as HomeLight.ColorMode?)
                                                }
                                            }
                                        }
                                    }
                                    .labelsHidden()
                                } label: {
                                    Label(light.accessory.name, systemImage: light.accessory.imageName)
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
            
            if !lightingModesWithValidActionSets.isEmpty {
                Section("Scenes") {
                    HStack {
                        ForEach(LightingMode.allCases, id: \.rawValue) { mode in
                            Label(mode.rawValue, systemImage: lightingModesWithValidActionSets.contains(mode) ? "checkmark" : "xmark")
                                .frame(idealWidth: .infinity, maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .navigationTitle("Sync Lights")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", systemImage: "checkmark") {
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
