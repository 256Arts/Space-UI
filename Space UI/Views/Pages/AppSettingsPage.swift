import SwiftUI

/// The in-universe settings surface: the same state as `SettingsInspector`, dressed in the generated theme.
/// Both read and write `AppSettingsModel`, so this file is only the rendering — no storage, no side effects.
struct AppSettingsPage: View {

    #if os(visionOS)
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow
    #endif

    @Environment(\.shapeDirection) private var shapeDirection
    @Environment(\.elementSize) private var elementSize
    @Environment(AppController.self) private var appController
    @Environment(\.system) private var system

    @Bindable private var settings = AppSettingsModel.shared

    @State private var showingScreenShapePicker = false
    @State private var showingNearbyInteractionRolePicker = false
    @State private var showingHomeKit = false
    #if DEBUG
    @State private var showingFontTest = false
    #endif
    @FocusState var seedIsFocused: Bool

    var peerSessionController = PeerSessionController.shared
    private var cameraManager: SpaceWindowCameraManager = .shared

    var body: some View {
        AutoStack(spacing: 20) {
            AutoStack {
                Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                    Image(systemName: "gear")
                }
                .autoButtonStyle(shapeDirection: shapeDirection)

                Button {
                    appController.closeModalPage()
                } label: {
                    Image(systemName: "xmark")
                }
            }

            ScrollView(showsIndicators: false) {
                LayoutThatFits([HStackLayout(), VStackLayout()]) {
                    VStack {
                        designPrinciplesSection
                        seedSection
                        screenShapeSection
                        fontsSection
                        #if os(visionOS)
                        immersiveSpaceSection
                        #else
                        externalDisplaySection
                        #endif
                    }

                    VStack {
                        syncDisplaysSection
                        syncLightsSection
                        linksSection
                        #if DEBUG
                        debugSection
                        #endif
                    }
                }
            }
        }
        .scrollClipDisabled()
        .font(.english(scale: elementSize == .mini || elementSize == .small ? 0.75 : 1))
        .onTapGesture {
            seedIsFocused = false
            settings.saveSeed()
        }
        .sheet(isPresented: $showingHomeKit) {
            NavigationStack {
                HomeSettingsView()
            }
            .foregroundColor(.primary)
        }
        #if DEBUG
        .sheet(isPresented: $showingFontTest) {
            NavigationStack {
                FontTestView()
            }
            .foregroundColor(.primary)
        }
        #endif
    }

    // MARK: - Sections

    private var designPrinciplesSection: some View {
        section {
            VStack {
                ForEach(DesignPrinciples.axes) { axis in
                    Slider(insetInnerBar: true, value: settings.principleBinding(axis))
                        .overlay(alignment: .leading) {
                            Text(axis.title)
                        }
                }
            }
            .disabled(!settings.applyDesignPrinciples)
            .overlay(alignment: .topTrailing) {
                HStack {
                    ColorPicker("Primary Color", selection: $settings.primaryColor)
                        .labelsHidden()

                    Button {
                        AudioController.shared.play(.action)
                        settings.applyDesignPrinciples.toggle()
                    } label: { Image(systemName: settings.applyDesignPrinciples ? "checkmark" : "xmark") }
                        .buttonStyle(FlexButtonStyle(isSelected: settings.applyDesignPrinciples))
                }
                .offset(y: -30)
            }
        } header: {
            Text("Design Principles")
        }
    }

    private var seedSection: some View {
        section {
            HStack {
                TextField("Seed", text: $settings.seedCopy, onCommit: {
                    settings.saveSeed()
                })
                .foregroundColor(settings.isLocked ? system.colors.color(.primary, opacity: .high) : nil)
                .padding()
                .frame(width: elementSize == .large ? 220 : 178, height: system.flexButtonFrameHeight)
                .background(system.colors.color(.primary, opacity: settings.isLocked ? .low : .medium))
                .cornerRadius(system.cornerRadius(forLength: system.flexButtonFrameHeight))
                .keyboardType(.numberPad)
                .submitLabel(.done)
                .disabled(settings.isLocked)
                .focused($seedIsFocused)

                Button {
                    AudioController.shared.play(.action)
                    settings.randomizeSeed()
                } label: { Image(systemName: "slider.horizontal.2.arrow.trianglehead.counterclockwise") }
                    .buttonStyle(FlexButtonStyle(isDisabled: settings.isLocked))
                    .disabled(settings.isLocked)

                #if !os(tvOS)
                Button {
                    AudioController.shared.play(.action)
                    UIPasteboard.general.string = settings.seedCopy
                } label: { Image(systemName: "doc.on.doc") }
                    .buttonStyle(FlexButtonStyle())
                #endif
            }
        } header: {
            Text("Seed")
        }
    }

    private var screenShapeSection: some View {
        section {
            Button {
                showingScreenShapePicker = true
            } label: {
                HStack {
                    Text(ScreenShapeType(rawValue: settings.screenShapeOverrideValue)?.name ?? "Automatic")
                    Image(systemName: "chevron.up.chevron.down")
                }
            }
            .buttonStyle(FlexButtonStyle())
            .popover(isPresented: $showingScreenShapePicker) {
                Picker(selection: $settings.screenShapeOverrideValue) {
                    Text("Automatic")
                        .tag("")
                    ForEach(ScreenShapeType.allCases) { shapeCase in
                        Text(shapeCase.name)
                            .tag(shapeCase.rawValue)
                    }
                } label: {
                    Label("Screen Shape", systemImage: "rectangle.dashed")
                }
                .pickerStyle(.inline)
            }
            .padding(8)
        } header: {
            Text("Screen Shape")
        }
    }

    private var fontsSection: some View {
        section {
            VStack {
                Button("Extra Fonts") {
                    AudioController.shared.play(.action)
                    settings.extraFonts.toggle()
                }
                .buttonStyle(FlexButtonStyle(isSelected: settings.extraFonts))
                linkButton(.alienFont)
            }
            .padding(8)
        } header: {
            Text("Fonts")
        }
    }

    #if os(visionOS)
    private var immersiveSpaceSection: some View {
        section {
            Button {
                AudioController.shared.play(.action)
                Task {
                    if appController.isImmersiveSpaceOpen {
                        await dismissImmersiveSpace()
                    } else if case .opened = await openImmersiveSpace(id: WindowID.immersiveSpace.rawValue) {
                        // The immersive scene is self-contained (its own floating controls), so drop the flat
                        // UI window once it's up. SpaceImmersiveView reopens it when the space is dismissed.
                        dismissWindow(id: WindowID.ui.rawValue)
                    }
                }
            } label: {
                Label(appController.isImmersiveSpaceOpen ? "Exit Space Scene" : "Enter Space Scene", systemImage: "sparkles")
            }
            .buttonStyle(FlexButtonStyle(isSelected: appController.isImmersiveSpaceOpen))
            .padding(8)
        } header: {
            Label("Immersive Space", systemImage: "mountain.2")
        }
    }
    #else
    private var externalDisplaySection: some View {
        section {
            ZStack {
                Grid {
                    GridRow {
                        Spacer()
                            .gridCellUnsizedAxes([.horizontal, .vertical])
                        externalDisplayToggle($settings.externalDisplayOnTop)
                    }
                    GridRow {
                        externalDisplayToggle($settings.externalDisplayOnLeft)
                        Image(systemName: "display")
                        externalDisplayToggle($settings.externalDisplayOnRight)
                    }
                    GridRow {
                        Spacer()
                            .gridCellUnsizedAxes([.horizontal, .vertical])
                        externalDisplayToggle($settings.externalDisplayOnBottom)
                    }
                }
            }
            .frame(idealWidth: .infinity, maxWidth: .infinity)
            .overlay(alignment: .bottomTrailing) {
                Button("Seemless") {
                    settings.externalDisplaySeemlessMode.toggle()
                }
                .buttonStyle(FlexButtonStyle(isSelected: settings.externalDisplaySeemlessMode))
            }
            .padding(8)
        } header: {
            Text("External Display Positions")
        }
    }
    #endif

    private var syncDisplaysSection: some View {
        section {
            VStack {
                HStack(spacing: 8) {
                    if !settings.isSyncDisabled {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(system.colors.color(.secondary, brightness: .medium))
                    }
                    Text(settings.syncOverNetworkBody)
                        .foregroundColor(system.colors.color(.secondary, brightness: .medium))
                }

                #if !os(visionOS)
                if !settings.isSyncDisabled, NearbyInteractionSessionController.shared.myDeviceIsSupported {
                    Button {
                        showingNearbyInteractionRolePicker = true
                    } label: {
                        HStack {
                            Text(NearbyInteractionSessionController.DeviceRole(rawValue: settings.nearbyInteractionRoleValue)?.title ?? "Disabled")
                            Image(systemName: "chevron.up.chevron.down")
                        }
                    }
                    .buttonStyle(FlexButtonStyle())
                    .popover(isPresented: $showingNearbyInteractionRolePicker) {
                        Picker(selection: $settings.nearbyInteractionRoleValue) {
                            Text("Disabled")
                                .tag("")
                            ForEach(NearbyInteractionSessionController.DeviceRole.allCases) { deviceRole in
                                Text(deviceRole.title)
                                    .tag(deviceRole.rawValue)
                            }
                        } label: {
                            Text("Device Position Role")
                        }
                        .pickerStyle(.inline)
                    }

                    if NearbyInteractionSessionController.shared.isEnabled {
                        if NearbyInteractionSessionController.shared.peerDiscoveryToken == nil {
                            Text("Missing peer token")
                        } else if let pos = cameraManager.nearbyDevicePosition {
                            Text("Position: \(pos.x), \(pos.y), \(pos.z)")
                        }
                    }
                }
                #endif
            }
            .padding(8)
        } header: {
            Label("Sync Displays", systemImage: "display.2")
        }
    }

    private var syncLightsSection: some View {
        section {
            Button("Open Details") {
                showingHomeKit = true
            }
            .buttonStyle(FlexButtonStyle())
            .padding(8)
        } header: {
            Label("Sync Lights", systemImage: "lightbulb")
        }
    }

    private var linksSection: some View {
        section {
            VStack {
                ForEach(SettingsLink.general) { link in
                    linkButton(link)
                }
            }
            .padding(8)
        } header: {
            Label("Links", systemImage: "link")
        }
    }

    private func linkButton(_ link: SettingsLink) -> some View {
        SettingsLinkView(link: link)
            .buttonStyle(FlexButtonStyle())
    }

    #if DEBUG
    private var debugSection: some View {
        section {
            Button {
                showingFontTest = true
            } label: {
                Label("Test Fonts", systemImage: "checkmark.diamond")
            }
            .buttonStyle(FlexButtonStyle())
            .padding(8)
        } header: {
            Label("Debug", systemImage: "ant")
        }
    }
    #endif

    // MARK: - Helpers

    #if !os(visionOS)
    private func externalDisplayToggle(_ isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            Image(systemName: "display")
                .opacity(isOn.wrappedValue ? 1 : 0.5)
        }
        .buttonStyle(FlexButtonStyle(isSelected: isOn.wrappedValue))
    }
    #endif

    @ViewBuilder
    private func section(@ViewBuilder content: () -> some View, @ViewBuilder header: () -> some View) -> some View {
        Panel {
            content()
        } header: {
            header()
        }
        // Scroll transitions can only be used inside scroll views
        .scrollTransition { content, phase in
            content
                .scaleEffect(phase.isIdentity ? 1 : 0)
                .opacity(phase.isIdentity ? 1 : 0)
        }
    }
}

#Preview {
    AppSettingsPage()
}
