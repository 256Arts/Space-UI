//
//  HomesList.swift
//  Space UI
//
//  Created by Jayden Irwin on 2022-10-15.
//  Copyright © 2022 Jayden Irwin. All rights reserved.
//

import SwiftUI

struct HomesList: View {
    
    @AppStorage(UserDefaults.Key.syncHomeLights) private var syncHomeLights = false
    @AppStorage(UserDefaults.Key.turnOnHomeLights) private var turnOnHomeLights = false
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var homeStore = HomeStore.shared
    
    var body: some View {
        List {
            SwiftUI.Section {
                Toggle("Sync Lights", isOn: $syncHomeLights)
                Toggle("Turn On Lights", isOn: $turnOnHomeLights)
            }
            SwiftUI.Section {
                if homeStore.homeManager.homes.isEmpty {
                    Text("No homes found")
                } else {
                    ForEach(homeStore.homeManager.homes) { home in
                        NavigationLink(home.name) {
                            HomeLightsList(home: home)
                        }
                    }
                }
            }
        }
        .navigationTitle("Homes")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct HomesList_Previews: PreviewProvider {
    static var previews: some View {
        HomesList()
    }
}
