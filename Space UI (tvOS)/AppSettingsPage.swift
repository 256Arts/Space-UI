//
//  SeedView.swift
//  Space UI (tvOS)
//
//  Created by 256 Arts Developer on 2020-03-29.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct AppSettingsPage: View {
    
    var screenShapeOverride: ScreenShapeType? {
        ScreenShapeType(rawValue: screenShapeOverrideValue)
    }
    var isLocked: Bool {
        !peerSessionController.mcSession.connectedPeers.isEmpty && !PeerSessionController.shared.isHost
    }
    var syncOverNetworkBody: String {
        if peerSessionController.mcSession.connectedPeers.isEmpty {
            switch (peerSessionController.canHost, peerSessionController.canJoin) {
            case (true, true):
                return "Looking to host/join..."
            case (true, false):
                return "Looking to host..."
            case (false, true):
                return "Looking to join..."
            case (false, false):
                return "Disabled"
            }
        } else if peerSessionController.isHost {
            return "Hosting \(peerSessionController.mcSession.connectedPeers.count) Peers"
        } else {
            return "Connected To Peers"
        }
    }
    
    @State var seedCopy = String(system.seed)
    
    @AppStorage(UserDefaults.Key.screenShapeOverride) private var screenShapeOverrideValue = ""
    @ObservedObject var peerSessionController = PeerSessionController.shared
    
    @Namespace var mainNamespace
    
    var body: some View {
        NavigationStack {
            HStack {
                Image(systemName: "switch.2")
                    .font(.system(size: 400))
                    .foregroundColor(.secondary)
                    .frame(width: 1000)
                Form {
                    SwiftUI.Section {
                        TextField("Seed", text: self.$seedCopy, onCommit: {
                            self.saveSeed()
                        })
                        .keyboardType(.numberPad)
                        .disabled(isLocked)
                        
                        Button {
                            AudioController.shared.play(.action)
                            self.seedCopy = String(arc4random())
                            self.saveSeed()
                        } label: {
                            Label("Randomize", systemImage: "arrow.2.circlepath")
                        }
                        .disabled(isLocked)
                        .prefersDefaultFocus(in: mainNamespace)
                    } header: {
                        Text("Seed")
                    }
                    
                    Picker(selection: $screenShapeOverrideValue) {
                        Text("Automatic")
                            .tag("")
                        ForEach(ScreenShapeType.allCases) { shapeCase in
                            Text(shapeCase.name)
                                .tag(shapeCase.rawValue)
                        }
                    } label: {
                        Label("Screen Shape", systemImage: "rectangle.dashed")
                    }
                    LabeledContent {
                        Text(syncOverNetworkBody)
                    } label: {
                        Label("Sync Displays", systemImage: "display.2")
                    }
                    NavigationLink {
                        HomeSettingsView()
                    } label: {
                        Label("Sync Lights", systemImage: "lightbulb")
                    }
                    Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                        Label("Open Settings", systemImage: "gear")
                    }
                    #if DEBUG
                    NavigationLink {
                        FontTestView()
                    } label: {
                        Label("Test Fonts", systemImage: "f.square")
                    }
                    #endif
                }
                // Prevent rows from being clipped horizontally when focused
                .scrollClipDisabled()
            }
            .navigationTitle("Quick Settings")
        }
        .font(.body)
        .foregroundColor(.primary)
    }
    
    func saveSeed() {
        guard let newSeed = UInt64(self.seedCopy), newSeed != system.seed else { return }
        
        if peerSessionController.isHost {
            peerSessionController.send(message: .seed(newSeed))
        }
        system = SystemStyles(seed: newSeed)
        
        UserDefaults.standard.set(newSeed, forKey: UserDefaults.Key.seed)
    }
}

#Preview {
    AppSettingsPage()
}
