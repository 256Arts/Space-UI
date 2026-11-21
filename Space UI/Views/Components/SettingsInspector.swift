import SwiftUI

// tvOS has its own settings page and no pointer/touch to swipe with, so it never presents this.
#if !os(tvOS)

/// The plain, system-styled counterpart to `AppSettingsPage`.
///
/// The generated sci-fi chrome is the point of the app, but it also makes the settings hard to *read* — a
/// toggle is a themed shape, a picker is a themed shape. This renders exactly the same state (see
/// `AppSettingsModel`, which both surfaces own jointly) as an ordinary `Form`, so anything can be found
/// without decoding the theme first. Presented with `.inspector`, so it sits beside the UI on a wide screen
/// and adapts to a sheet when there isn't room for a side panel.
struct SettingsInspector: View {

    #if os(visionOS)
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow
    #endif

    @Environment(AppController.self) private var appController

    @Bindable private var settings = AppSettingsModel.shared

    /// Bound by the presenting root so the toolbar's Done button can close the panel.
    @Binding var isPresented: Bool

    private var cameraManager: SpaceWindowCameraManager { .shared }

    var body: some View {
        NavigationStack {
            Form {
                designPrinciplesSection
                seedSection
                appearanceSection
                #if os(visionOS)
                immersiveSpaceSection
                #else
                externalDisplaySection
                #endif
                syncDisplaysSection
                syncLightsSection
                linksSection
            }
            .navigationTitle("Settings")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isPresented = false }
                }
            }
        }
        // The app themes its whole environment — font, colours, button style, line spacing; the inspector is
        // deliberately not themed, so each of those is handed back to the system. A `nil` font in particular
        // lets every control keep its own default text style instead of inheriting one generated size.
        .font(nil)
        .buttonStyle(.automatic)
        .lineSpacing(0)
        .foregroundColor(.primary)
        .tint(.accentColor)
    }

    // MARK: - Sections

    private var designPrinciplesSection: some View {
        Section {
            Toggle("Apply Design Principles", isOn: $settings.applyDesignPrinciples)
            ColorPicker("Primary Color", selection: $settings.primaryColor)

            ForEach(DesignPrinciples.axes) { axis in
                // Fully qualified: the app declares its own themed `Slider`, which shadows this one.
                SwiftUI.Slider(value: settings.principleBinding(axis), in: 0...1) {
                    Text(axis.title)
                } onEditingChanged: { isEditing in
                    // Commit on release rather than per-value, so a drag doesn't rebuild the theme every frame.
                    if !isEditing { settings.commitDesignPrinciples() }
                }
                .accessibilityLabel(Text(axis.title))
            }
            .disabled(!settings.applyDesignPrinciples)
        } header: {
            Text("Design Principles")
        } footer: {
            Text("Bias the generated theme instead of leaving it fully random.")
        }
    }

    private var seedSection: some View {
        Section {
            TextField("Seed", text: $settings.seedCopy)
                #if !os(macOS)
                .keyboardType(.numberPad)
                #endif
                .onSubmit { settings.saveSeed() }
                .disabled(settings.isLocked)

            Button("Random Seed", systemImage: "slider.horizontal.2.arrow.trianglehead.counterclockwise") {
                settings.randomizeSeed()
            }
            .disabled(settings.isLocked)

            #if !os(tvOS)
            Button("Copy Seed", systemImage: "doc.on.doc") {
                UIPasteboard.general.string = settings.seedCopy
            }
            #endif
        } header: {
            Text("Seed")
        } footer: {
            Text(settings.isLocked
                 ? "The seed is set by the host while this device is joined to a session."
                 : "Devices sharing a seed render the same theme.")
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Screen Shape", selection: $settings.screenShapeOverrideValue) {
                Text("Automatic").tag("")
                ForEach(ScreenShapeType.allCases) { shapeCase in
                    Text(shapeCase.name).tag(shapeCase.rawValue)
                }
            }
            Toggle("Extra Fonts", isOn: $settings.extraFonts)
            SettingsLinkView(link: .alienFont)
        }
    }

    #if os(visionOS)
    private var immersiveSpaceSection: some View {
        Section("Immersive Space") {
            Button(appController.isImmersiveSpaceOpen ? "Exit Space Scene" : "Enter Space Scene", systemImage: "sparkles") {
                Task {
                    if appController.isImmersiveSpaceOpen {
                        await dismissImmersiveSpace()
                    } else if case .opened = await openImmersiveSpace(id: WindowID.immersiveSpace.rawValue) {
                        dismissWindow(id: WindowID.ui.rawValue)
                    }
                }
            }
        }
    }
    #else
    private var externalDisplaySection: some View {
        Section {
            Toggle("Display Above", isOn: $settings.externalDisplayOnTop)
            Toggle("Display Below", isOn: $settings.externalDisplayOnBottom)
            Toggle("Display to the Left", isOn: $settings.externalDisplayOnLeft)
            Toggle("Display to the Right", isOn: $settings.externalDisplayOnRight)
            Toggle("Seemless Mode", isOn: $settings.externalDisplaySeemlessMode)
        } header: {
            Text("External Display Positions")
        } footer: {
            Text("Tell this screen which edges another screen sits against, so the frame joins up.")
        }
    }
    #endif

    private var syncDisplaysSection: some View {
        Section("Sync Displays") {
            LabeledContent("Status") {
                Text(settings.syncOverNetworkBody)
            }

            #if !os(visionOS)
            if !settings.isSyncDisabled, NearbyInteractionSessionController.shared.myDeviceIsSupported {
                Picker("Device Position Role", selection: $settings.nearbyInteractionRoleValue) {
                    Text("Disabled").tag("")
                    ForEach(NearbyInteractionSessionController.DeviceRole.allCases) { deviceRole in
                        Text(deviceRole.title).tag(deviceRole.rawValue)
                    }
                }

                if NearbyInteractionSessionController.shared.isEnabled {
                    if NearbyInteractionSessionController.shared.peerDiscoveryToken == nil {
                        LabeledContent("Peer Token", value: "Missing")
                    } else if let pos = cameraManager.nearbyDevicePosition {
                        LabeledContent("Position", value: "\(pos.x), \(pos.y), \(pos.z)")
                    }
                }
            }
            #endif
        }
    }

    private var syncLightsSection: some View {
        Section("Sync Lights") {
            NavigationLink("HomeKit Lights") {
                HomeSettingsView()
            }
        }
    }

    private var linksSection: some View {
        Section {
            ForEach(SettingsLink.general) { SettingsLinkView(link: $0) }
            Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                Label("System Settings", systemImage: "gear")
            }
        }
    }
}

#Preview {
    SettingsInspector(isPresented: .constant(true))
        .environment(AppController.shared)
}

#endif
