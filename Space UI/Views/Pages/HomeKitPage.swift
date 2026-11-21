#if canImport(HomeKit)
import SwiftUI

struct HomeKitPage: View {
    
    @AppStorage(UserDefaults.Key.syncHomeLights) private var syncHomeLights = false
    @AppStorage(UserDefaults.Key.turnOnHomeLights) private var turnOnHomeLights = false
    @AppStorage(UserDefaults.Key.setHomeLightsBrightness) private var setHomeLightsBrightness = false
    
    @Environment(\.system) private var system
    
    @IDGen private var idGen
    
    private var homeStore = HomeStore.shared
    
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
            
            ScrollView(showsIndicators: false) {
                Text("Home Control")
                
                if let currentHome = homeStore.currentHome {
                    if currentHome.accessories.lights.isEmpty, currentHome.accessories.outlets.isEmpty {
                        Text("No lights or outlets found in \(currentHome.name)")
                    } else {
                        Grid(alignment: .leading) {
                            ForEach(currentHome.accessories.lights) { light in
                                HomeLightView(light: light, did: idGen(0))
                            }
                            ForEach(currentHome.accessories.outlets) { outlet in
                                HomeOutletView(outlet: outlet)
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
        }
        .font(.english())
    }
}

#Preview {
    HomeKitPage()
}
#endif
