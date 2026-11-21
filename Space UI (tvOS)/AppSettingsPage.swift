import SwiftUI

struct AppSettingsPage: View {
    
    var screenShapeOverride: ScreenShapeType? {
        ScreenShapeType(rawValue: screenShapeOverrideValue)
    }
    var isLocked: Bool {
        !peerSessionController.connectedPeerIDs.isEmpty && !PeerSessionController.shared.isHost
    }
    var syncOverNetworkBody: LocalizedStringResource {
        if peerSessionController.connectedPeerIDs.isEmpty {
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
            return "Hosting \(peerSessionController.connectedPeerIDs.count) Peers"
        } else {
            return "Connected To Peers"
        }
    }
    
    @State var seedCopy = String(system.seed)
    
    @AppStorage(UserDefaults.Key.screenShapeOverride) private var screenShapeOverrideValue = ""
    @AppStorage(UserDefaults.Key.extraFonts) private var extraFonts = false
    var peerSessionController = PeerSessionController.shared
    
    @Namespace var mainNamespace
    
    var body: some View {
        NavigationStack {
            HStack {
                Image(systemName: "switch.2")
                    .font(.system(size: 400))
                    .foregroundColor(.secondary)
                    .frame(width: 1000)
                Form {
                    Section {
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
                            Label("Randomize", systemImage: "slider.horizontal.2.arrow.trianglehead.counterclockwise")
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
                    Toggle(isOn: $extraFonts) {
                        Label("Extra Fonts", systemImage: "textformat")
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
        .onChange(of: screenShapeOverrideValue) {
            AppController.shared.applyLocalAppearance()
        }
        .onChange(of: extraFonts) {
            AppController.shared.applyLocalAppearance()
        }
    }

    func saveSeed() {
        guard let newSeed = UInt64(self.seedCopy), newSeed != system.seed else { return }
        
        let newConfig = Config(
            seed: newSeed,
            designPrinciples: savedDesignPrinciples,
            primaryHue: savedPrimaryHue,
            primarySaturation: savedPrimarySaturation
        )
        AppController.shared.applyConfig(newConfig, broadcast: true)
    }
}

#Preview {
    AppSettingsPage()
}
