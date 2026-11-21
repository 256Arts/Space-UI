import SwiftUI

struct UIRootView: View {
    
    init(connectedWindowType: ConnectedWindowType?, isExternal: Bool) {
        self.connectedWindowType = connectedWindowType
        self.isExternal = isExternal
    }
    
    let connectedWindowType: ConnectedWindowType?
    let isExternal: Bool
    
    @SceneStorage(SceneStorageKey.stackBottomPage) private var persistedStackBottomPage: Page = .defaultPage
    @State private var pageNavigator = PageNavigator()

    private var visiblePage: Page {
        appController.multiWindowFullscreenModalPage ?? pageNavigator.stackBottomPage
    }
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    private var elementSize: ElementSize {
        #if targetEnvironment(macCatalyst)
        .large
        #else
        if (vSizeClass == .regular && hSizeClass == .regular),
            screen.screenShapeType != .circle, screen.screenShapeType != .triangle {
            .regular
        } else {
            .small
        }
        #endif
    }
    private var shadersEnabled: Bool { false }
    
    // The root is the one view that reads the `system` / `screen` globals, because it is the bridge that puts
    // them into the environment for everything below. Every other view reads them back out via
    // `@Environment(\.system)` / `@Environment(\.screen)` rather than reaching for the globals again.
    private var appController: AppController = .shared

    /// The theme as everything below it should see it: the generated theme, with the emergency palette resolved
    /// in while the alarm is strobing. Resolving it once here is what lets `SystemColors` stay pure seed-derived
    /// data instead of consulting live ship state from inside every colour lookup.
    private var injectedSystem: SystemStyles {
        ShipState.shared.useEmergencyColors ? system.resolvingEmergencyColors() : system
    }
    
    // Onboarding, so never in an App Store shot — the first capture is the lock screen it covers.
    @State private var showingQuickStart = !ScreenshotMode.isActive
    /// The root's own width, so the settings swipe can tell "started at the trailing edge" from anywhere else.
    /// Not the screen's — in Split View or a paired window the two differ.
    @State private var rootWidth: CGFloat = 0
    /// What the hardware covers — the iPhone Duo's outer camera — in the window's coordinates. Read from geometry
    /// rather than snapshotted in `ScreenInfo`, because the regions arrive a moment after the window appears.
    @State private var occludedRegions: [CGRect] = []

    var body: some View {
        VStack {
            #if !os(visionOS)
            if vSizeClass == .regular, let segs = screen.topMorseCodeSegments {
                MorseCodeLine(segments: segs)
                    .padding(.horizontal, 20)
                    #if targetEnvironment(macCatalyst)
                    // Avoid window controls
                    .padding(.leading, 60)
                    #endif
            }
            #endif
            ScreenView(connectedWindowType: connectedWindowType) {
                switch visiblePage {
                case .extOrbits:
                    OrbitsExtPage()
                case .extCircularProgressLeft:
                    CircularProgressExtPageLeft()
                case .extCircularProgressRight:
                    CircularProgressExtPageLeft()
                        .scaleEffect(x: -1, y: 1)
                case .lockScreen:
                    LockScreenPage()
                case .settings:
                    AppSettingsPage()
                case .powerManagement:
                    PowerManagementPage()
                case .targeting:
                    TargetingPage()
                case .coms:
                    ComsPage()
                case .nearby:
                    NearbyPage()
                case .planet:
                    PlanetPage()
                case .galaxy:
                    GalaxyPage()
                case .customText:
                    CustomTextPage()
                case .ticTacToe:
                    TicTacToePage()
                case .dotsAndBoxes:
                    DotsAndBoxesPage()
                case .shield:
                    ShieldPage()
                case .squad:
                    SquadPage()
                case .music:
                    MusicPage()
                case .homeKit:
                    HomeKitPage()
                case .sudokuPuzzle:
                    SudokuPage()
                case .lightsOutPuzzle:
                    LightsOutPage()
                case .unlabeledKeypadPuzzle:
                    UnlabeledKeypadPage()
                #if STORY
                case .story:
                    StoryPage()
                #endif
                }
            }
            .id(visiblePage)
            #if !os(visionOS)
            if vSizeClass == .regular, let segs = screen.bottomMorseCodeSegments {
                MorseCodeLine(segments: segs)
                    .padding(.horizontal, 20)
            }
            #endif
        }
        #if !os(visionOS)
        #if !DEBUG || targetEnvironment(macCatalyst)
        .if(shadersEnabled) {
            $0.compositingGroup()
            .distortionEffect(
                MyShaders.crtCurve(radius: 2, size: CGPoint(x: ScreenInfo.current.bounds.size.width, y: ScreenInfo.current.bounds.size.height)),
                maxSampleOffset: .zero,
                isEnabled: shadersEnabled)
        }
        #endif
        .padding(screen.hardwareCornerPadding(screenSize: ScreenInfo.current.bounds.size, traitCollection: ScreenInfo.current.traitCollection, safeAreaInsets: ScreenInfo.current.safeAreaInsets, occludedRegions: occludedRegions, system: system))
        .ignoresSafeArea(edges: screen.edgesIgnoringSafeAreaForScreenShape(screenSize: ScreenInfo.current.bounds.size, traitCollection: ScreenInfo.current.traitCollection, safeAreaInsets: ScreenInfo.current.safeAreaInsets, system: system))
        .onOccludedRegionsChange { occludedRegions = $0 }
        #endif
        
        #if DEBUG
        .overlay(alignment: .leading) {
            if !isExternal, appController.showingDebugControls {
                DebugControls()
                    .padding()
                    .transition(.move(edge: .leading))
                    .environment(appController)
                    .environment(\.colorScheme, system.colors.useLightAppearance ? .light : .dark)
                    .onAppear {
                        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { (_) in // Animation with delay will prevent taps
                            Task { @MainActor in
                                withAnimation {
                                    appController.showingDebugControls = false
                                }
                            }
                        }
                    }
            }
        }
        #endif

        #if !os(visionOS)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { rootWidth = $0 }
        .gesture(edgeSwipeGesture)
        // Inside the inspector, not around it: `.inspector` wraps its content in a container that paints the
        // system background (white or gray), so black set any further out never shows.
        .background(Color.black, ignoresSafeAreaEdges: .all)
        #endif
        // The unthemed escape hatch: the same settings as the `.settings` page, in plain system controls, for
        // when the generated chrome makes a control unrecognizable. `.inspector` is a side panel where there
        // is room for one and adapts to a sheet where there isn't.
        #if os(visionOS)
        // `.inspector` is unavailable on visionOS, where a sheet is the platform's own answer regardless.
        .sheet(isPresented: settingsInspectorPresented) {
            settingsInspector
        }
        #else
        .inspector(isPresented: settingsInspectorPresented) {
            settingsInspector
        }
        #endif
        .navigationTitle(Text(connectedWindowType?.title ?? "Space UI"))
        #if !os(visionOS)
        .statusBar(hidden: true)
        .persistentSystemOverlays(.hidden)
        #endif
        .font(Font.spaceFont(size: system.defaultFontSize))
        .buttonStyle(ShapeButtonStyle(shapeDirection: system.shapeDirection))
        .lineSpacing(10)
        .foregroundColor(system.colors.color(.secondary, opacity: .max))
        .environment(\.system, injectedSystem)
        .environment(appController)
        .environment(ShipState.shared)
        .environment(\.screen, screen)
        .environment(\.elementSize, elementSize)
        .environment(\.page, visiblePage)
        .environment(pageNavigator)
        .onChange(of: pageNavigator.stackBottomPage) {
            persistedStackBottomPage = pageNavigator.stackBottomPage
        }
        .overlay(alignment: .bottom) {
            // The quick-start popup is public-build onboarding; the story show never wants it on screen.
            if showingQuickStart, !ShipState.shared.isRunningStory {
                QuickStartView(currentWindowID: .ui)
                    .environment(appController)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(5))
            withAnimation {
                showingQuickStart = false
            }
        }
        .onAppear {
            if ScreenshotMode.isActive {
                // The run names the page it wants; a restored scene, or a modal left over from the last
                // session, is not what it came to photograph.
                pageNavigator.stackBottomPage = ScreenshotMode.page.flatMap(Page.init(rawValue:)) ?? .defaultPage
                appController.multiWindowFullscreenModalPage = nil
            } else {
                pageNavigator.stackBottomPage = persistedStackBottomPage
            }
            ScreenInfo.refresh()
            #if targetEnvironment(macCatalyst)
            ScreenshotMode.prepareMacWindows()
            #endif
        }
        .onChange(of: vSizeClass) { ScreenInfo.refresh() }
        .onChange(of: hSizeClass) { ScreenInfo.refresh() }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                ScreenInfo.refresh()
            }
            switch scenePhase {
            case .active:
                appController.startEmergencyCountdown()
            case .inactive:
                appController.cancelEmergencyCountdown()
            default:
                break
            }
        }
        // Rebuild the whole subtree when the theme/config is regenerated (e.g. a peer receives a new `Config`),
        // so the injected `system` / `ShipState.shared` and any seed-derived child state are re-read from the
        // swapped globals instead of pinning to the previous instances. See `AppController.configID`.
        //
        // Discarding the subtree's identity is blunt — it resets every child `@State` — and that is deliberate,
        // not an oversight waiting for finer-grained invalidation. Around sixteen views pick a design variant
        // *once*, in `init` or a `@State` default, reading `Space_UI.system` explicitly (`Knobs`,
        // `FlowingArrowsView`, `CircularProgressView`, `MorseCodeLine`, `RandomWidget`, the seeded-generator
        // pages…). Precise invalidation only re-runs `body`, so those would keep the previous theme's choice and
        // fail quietly, as a wrong-looking widget. Anything narrower has to convert all of them to derive in
        // `body` first. A seed change is a total re-roll of the look, so the child state being reset with it is
        // no loss.
        //
        // `configID` would also survive the change regardless: `HomeStore`, `SpaceWindowView` and
        // `ConsoleController` read it to re-arm observation across a `ShipState` swap, which is not a theme
        // concern at all.
        .id(appController.configID)
//        .onChange(of: appController.multiWindowFullscreenModalPage) { _, newValue in
//            if let newValue {
//                stackBottomPage = visiblePage
//                visiblePage = newValue
//            } else if let stackBottomPage {
//                visiblePage = stackBottomPage
//                self.stackBottomPage = nil
//            }
//        }
    }
    
    #if !os(visionOS)
    /// The root's edge swipes: the trailing edge reveals the settings inspector, and in DEBUG the leading edge
    /// reveals the debug menu.
    ///
    /// Deliberately one gesture rather than two `.gesture` modifiers — of two drag gestures attached at the
    /// same level only the outer is recognized, so the other would silently never fire. Both are filtered by
    /// where the drag *started*: a hit-testable strip overlaid on the edge would read more clearly, but it
    /// would swallow taps on whatever the page happened to put underneath it.
    private var edgeSwipeGesture: some Gesture {
        DragGesture()
            .onEnded { gesture in
                // A screenshot run's taps are synthesized, and one read as a drag would open settings over
                // the shot.
                guard !ScreenshotMode.isActive else { return }

                let isLeftward = gesture.translation.width < 0
                    && abs(gesture.translation.width) > abs(gesture.translation.height)

                #if DEBUG && !targetEnvironment(macCatalyst)
                if gesture.startLocation.x < 10 {
                    withAnimation {
                        appController.showingDebugControls = true
                    }
                } else if isLeftward {
                    withAnimation {
                        appController.showingDebugControls = false
                    }
                }
                #endif

                // Not on an external screen (nobody is touching it) and not during the show, which runs
                // unattended — a stray swipe must not open settings over a live scene.
                guard !isExternal, !visiblePage.isStory,
                      gesture.startLocation.x > rootWidth - 20, isLeftward else { return }
                appController.showingSettingsInspector = true
            }
    }
    #endif

    /// Whether the settings panel is showing.
    ///
    /// Constant during a screenshot run, because the panel comes back by itself on a Mac launch — SwiftUI
    /// restores the inspector's presented state and writes it back through this binding, after the root's
    /// `onAppear` has had its say. A run is unattended, so there is nobody to close it; discarding the write
    /// is what keeps it out of the shots.
    private var settingsInspectorPresented: Binding<Bool> {
        ScreenshotMode.isActive ? .constant(false) : Bindable(appController).showingSettingsInspector
    }

    private var settingsInspector: some View {
        SettingsInspector(isPresented: Bindable(appController).showingSettingsInspector)
            .environment(appController)
    }
}

#Preview {
    UIRootView(connectedWindowType: nil, isExternal: false)
}

private extension View {
    /// Reports the hardware-occluded regions in this view's coordinates. Only the iPhone Duo has any, and it ships
    /// on 27.1, so earlier systems report nothing. Catalyst and visionOS don't have the API at all.
    @ViewBuilder
    func onOccludedRegionsChange(_ action: @escaping ([CGRect]) -> Void) -> some View {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        if #available(iOS 27.1, *) {
            onGeometryChange(for: [CGRect].self) { $0.reservedRegions(kind: .occlusion).map(\.frame) } action: { action($0) }
        } else {
            self
        }
        #else
        self
        #endif
    }
}
