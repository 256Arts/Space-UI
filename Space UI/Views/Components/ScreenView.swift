import SwiftUI

// Thicken the screen border during an emergency to reinforce the alarm across the room
private let emergencyBorderMultiplier: CGFloat = 2.0

struct ScreenView<Content: View>: View {
    
    #if !os(tvOS)
    let connectedWindowType: ConnectedWindowType?
    #endif

    @ViewBuilder var content: Content
    
    @AppStorage(UserDefaults.Key.externalDisplaySeemlessMode) private var externalDisplaySeemlessMode = false
    
    @Environment(\.page) private var visiblePage: Page
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var hSizeClass
    private var regularHSizeClass: Bool {
        hSizeClass == .regular
    }
    #else
    private let regularHSizeClass = true
    #endif
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    
    @Environment(\.system) private var system
    @Environment(\.screen) private var injectedScreen

    /// One read path for the screen treatment. Everything below reads `screen` and gets the injected value;
    /// the fallback covers being rendered outside the root's subtree (a `#Preview`, a directly-hosted view),
    /// which is where the old implicitly-unwrapped environment entry used to trap.
    private var screen: ScreenStyles { injectedScreen ?? Space_UI.screen }
    
    @State private var maskOffset: CGSize = CGSize(width: 100.0 / 2.0, height: 100.0 / 2.0)
    
    private let startDate = Date.now
    private var shadersEnabled: Bool {
        // iOS 18.1 issue: Disable shaders on pages with UIKit-backed views.
        // https://developer.apple.com/documentation/swiftui/view/coloreffect(_:isenabled:)
        #if os(tvOS)
        !reducedMotion && visiblePage != .coms && visiblePage != .settings
        #else
        !reducedMotion && !visiblePage.usesUIKit
        #endif
    }
    private var hLinesShaderEnabled: Bool {
        screen.filter == .hLines && shadersEnabled
    }
    private var vLinesShaderEnabled: Bool {
        screen.filter == .vLines && shadersEnabled
    }
    private var signalNoiseShaderEnabled: Bool {
        screen.filter == .signalNoise && shadersEnabled
    }
    private var ledGrilleShaderEnabled: Bool {
        screen.filter == .ledGrille && shadersEnabled
    }
    private var filterShaderEnabled: Bool {
        screen.filter != .none && shadersEnabled
    }
    // Ambient distortion is one mutually-exclusive effect per seed. `wave` is a geometry
    // distortion applied above the background; the rest are colour/layer effects applied below.
    private var waveDistortionEnabled: Bool {
        screen.distortion == .wave && shadersEnabled
    }
    private var interferenceShaderEnabled: Bool {
        screen.distortion == .interference && shadersEnabled
    }
    private var chromaticAberrationShaderEnabled: Bool {
        screen.distortion == .chromaticAberration && shadersEnabled
    }
    private var vignetteShaderEnabled: Bool {
        screen.distortion == .vignette && shadersEnabled
    }
    private var bloomShaderEnabled: Bool {
        screen.distortion == .bloom && shadersEnabled
    }
    // Only animated shaders need the per-frame clock. Pause the TimelineView whenever the active
    // shaders are all static (or none), so wall-mounted screens stop re-rendering the whole page
    // tree every frame. chromatic/vignette are static; bloom is driven by @Observable emergency
    // state, not the clock; the flags already imply shadersEnabled.
    private var isAnyShaderAnimating: Bool {
        #if os(visionOS)
        false
        #elseif DEBUG
        // The `wave` distortion is compiled out in DEBUG; the remaining animated shaders are colour effects.
        interferenceShaderEnabled || hLinesShaderEnabled || vLinesShaderEnabled || signalNoiseShaderEnabled
        #else
        waveDistortionEnabled || interferenceShaderEnabled || hLinesShaderEnabled || vLinesShaderEnabled || signalNoiseShaderEnabled
        #endif
    }
    private var screenStrokeStyle: StrokeStyle? {
        guard let width = system.screenBorderWidth else { return nil }

        let emergencyMultiplier = (system.prefersThickEmergencyBorder && ShipState.shared.useEmergencyColors) ? emergencyBorderMultiplier : 1.0
        return StrokeStyle(lineWidth: width * emergencyMultiplier, lineCap: system.lineCap, dash: system.lineDash(lineWidth: system.thickLineWidth))
    }
    private var waveAmplitude: Float {
        #if os(tvOS)
        Float(screen.waveAmplitude) * 3
        #else
        Float(screen.waveAmplitude)
        #endif
    }
    
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(paused: !isAnyShaderAnimating)) { _ in
                Group {
                    // Customize subview layout when circular edges are present
//                    if !screen.circularEdges(screenSize: geometry.size).isEmpty {
//                        Group(subviews: content) { subviews in
//                            let circularEdges = screen.circularEdges(screenSize: geometry.size)
//                            let roundSubviews = subviews.filter({ $0.containerValues.isRoundElement })
//                            // Only customize if there is a circular edge for every round subview we have
//                            if !roundSubviews.isEmpty, roundSubviews.count <= circularEdges.count {
//                                HStack {
//                                    // If the left edge is circular, place the 1st round element there
//                                    if circularEdges.contains(.left) {
//                                        roundSubviews[0]
//                                    }
//                                    
//                                    // Place all other subviews in the middle
//                                    ForEach(subviews.filter({ !$0.containerValues.isRoundElement })) { subview in
//                                        subview
//                                    }
//                                    
//                                    // If the right edge is circular, place the last round element there
//                                    if circularEdges.contains(.right), !circularEdges.contains(.left) || subviews.count(where: { $0.containerValues.isRoundElement }) == 2 {
//                                        roundSubviews.last
//                                    }
//                                }
//                            } else {
//                                ForEach(subviews) { subview in
//                                    subview
//                                }
//                            }
//                        }
//                    } else {
                        content
//                    }
                }
//                    #if DEBUG
//                    .overlay {
//                        Rectangle()
//                            .strokeBorder(Color.white, lineWidth: 1)
//                    }
//                    .overlay(alignment: .topLeading) {
//                        Color.white
//                            .frame(width: 5, height: 5)
//                            .offset(screen.safeCornerOffsets(screenSize: geometry.size).topLeading)
//                    }
//                    .overlay(alignment: .topTrailing) {
//                        Color.white
//                            .frame(width: 5, height: 5)
//                            .offset(screen.safeCornerOffsets(screenSize: geometry.size).topTrailing)
//                    }
//                    .overlay(alignment: .bottomLeading) {
//                        Color.white
//                            .frame(width: 5, height: 5)
//                            .offset(screen.safeCornerOffsets(screenSize: geometry.size).bottomLeading)
//                    }
//                    .overlay(alignment: .bottomTrailing) {
//                        Color.white
//                            .frame(width: 5, height: 5)
//                            .offset(screen.safeCornerOffsets(screenSize: geometry.size).bottomTrailing)
//                    }
//                    #endif
                    .padding(screen.mainContentInsets(screenSize: geometry.size, connectedEdges: connectedEdges, system: system))
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    #if !DEBUG && !os(visionOS)
                    // `wave` is a geometry distortion, so it must be applied here — above the background
                    // and clipShape — to warp only the content and not bend the screen shape itself.
                    // iOS 17.5 bug: `if` required to remove effects when UIKit view is visible
                    .if(waveDistortionEnabled) {
                        $0.distortionEffect(
                            MyShaders.occasionalWave(time: startDate.timeIntervalSinceNow * screen.waveSpeed, waveLength: screen.waveLength, amplitude: waveAmplitude, cycleCount: screen.waveCycleCount),
                            maxSampleOffset: CGSize(width: Double(waveAmplitude), height: 0.0),
                            isEnabled: waveDistortionEnabled)
                    }
                    #endif
                    .background {
                        if screen.backgroundStyle == .color {
                            system.colors.screenBackground
                        } else {
                            LinearGradient(gradient: Gradient(colors: screenBackgroundGradientColors), startPoint: .top, endPoint: .bottom)
                        }
                    }
                    .clipShape(
                        ScreenShape(
                            system: system,
                            screenStyles: screen,
                            screenShapeType: screen.resolvedScreenShapeType(screenSize: geometry.size),
                            connectedEdges: connectedEdges
                        )
                    )
                    #if !os(visionOS)
                    // iOS 17.5 bug: `if` required to remove effects when UIKit view is visible
                    .if(filterShaderEnabled) {
                        $0.colorEffect(
                            MyShaders.hLines(time: startDate.timeIntervalSinceNow * 2, barHeight: 2),
                            isEnabled: hLinesShaderEnabled)
                        .colorEffect(
                            MyShaders.vLines(time: startDate.timeIntervalSinceNow * 2, barHeight: 2),
                            isEnabled: vLinesShaderEnabled)
                        .colorEffect(
                            MyShaders.signalNoise(
                                time: startDate.timeIntervalSinceNow,
                                intensity: screen.signalNoiseIntensity * (ShipState.shared.useEmergencyColors ? 3 : 1)),
                            isEnabled: signalNoiseShaderEnabled)
                        .colorEffect(
                            MyShaders.ledGrille(cellSize: screen.ledGrilleCellSize),
                            isEnabled: ledGrilleShaderEnabled)
                    }
                    // Ambient distortion (mutually exclusive; `wave` is applied above instead).
                    // interference animates; chromatic/vignette are static and let the clock pause.
                    .if(interferenceShaderEnabled || chromaticAberrationShaderEnabled || vignetteShaderEnabled) {
                        $0.colorEffect(
                            MyShaders.interference(size: geometry.size, time: -startDate.timeIntervalSinceNow),
                            isEnabled: interferenceShaderEnabled)
                        .layerEffect(
                            MyShaders.chromaticAberration(size: geometry.size, strength: screen.chromaticAberrationStrength),
                            maxSampleOffset: CGSize(width: screen.chromaticAberrationStrength, height: screen.chromaticAberrationStrength),
                            isEnabled: chromaticAberrationShaderEnabled)
                        .colorEffect(
                            MyShaders.vignette(size: geometry.size, strength: screen.vignetteStrength),
                            isEnabled: vignetteShaderEnabled)
                    }
                    // Bloom: 16-tap layer pass that glows bright elements. Static given static
                    // content, so it doesn't need the animation clock.
                    .if(bloomShaderEnabled) {
                        $0.layerEffect(
                            MyShaders.bloomGlow(radius: 8, intensity: 1),
                            maxSampleOffset: CGSize(width: 8, height: 8),
                            isEnabled: bloomShaderEnabled)
                    }
                    #endif
                    .environment(\.colorScheme, system.colors.useLightAppearance ? .light : .dark)
                    .background(alignment: .top) {
                        if let cutoutFrame = screen.cutoutFrame(screenSize: geometry.size, forTop: true, system: system), regularHSizeClass {
                            DecorativeStatusView(data: ShipState.shared.topStatusState)
                                .frame(width: cutoutFrame.size.width, height: cutoutFrame.size.height)
                                .offset(x: cutoutFrame.origin.x)
                        }
                    }
                    .background(alignment: .bottom) {
                        if let cutoutFrame = screen.cutoutFrame(screenSize: geometry.size, forTop: false, system: system) {
                            DecorativeStatusView(data: ShipState.shared.bottomStatusState)
                                .frame(width: cutoutFrame.size.width, height: cutoutFrame.size.height)
                                .offset(x: cutoutFrame.origin.x)
                        }
                    }
                    .environment(
                        \.safeCornerOffsets,
                         screen
                            .safeCornerOffsets(
                                screenSize: geometry.size,
                                connectedCorners: screen.connectedCorners(for: connectedEdges),
                                system: system
                            )
                    )
            }
            .overlay {
                if let style = screenStrokeStyle {
                    ScreenShape(
                        system: system,
                        screenStyles: screen,
                        screenShapeType: screen.resolvedScreenShapeType(screenSize: geometry.size),
                        connectedEdges: connectedEdges
                    )
                    .inset(by: system.screenBorderInsetAmount)
                    .strokeBorder(system.colors.color(.primary, opacity: system.colors.useLightAppearance ? .medium : .max), style: style)
                    .padding(.top, seemlessBorderOffset(.top))
                    .padding(.bottom, seemlessBorderOffset(.bottom))
                    .padding(.leading, seemlessBorderOffset(.left))
                    .padding(.trailing, seemlessBorderOffset(.right))
                }
            }
        }
    }
    
    #if os(tvOS)
    @inlinable public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    #else
    @inlinable public init(connectedWindowType: ConnectedWindowType?, @ViewBuilder content: () -> Content) {
        self.connectedWindowType = connectedWindowType
        self.content = content()
    }
    #endif
    
    private var screenBackgroundGradientColors: [Color] {
        #if os(visionOS)
        screen.backgroundStyle == .gradientDown ? [
            system.colors.color(.primary, opacity: 0.2),
            system.colors.color(.primary, opacity: 0.1)
        ] : [
            system.colors.color(.primary, opacity: 0.1),
            system.colors.color(.primary, opacity: 0.2)
        ]
        #else
        screen.backgroundStyle == .gradientDown ? [
            system.colors.color(.primary, brightnessMultiplier: 0.05),
            system.colors.color(.primary, brightnessMultiplier: -0.05)
        ] : [
            system.colors.color(.primary, brightnessMultiplier: -0.05),
            system.colors.color(.primary, brightnessMultiplier: 0.05)
        ]
        #endif
    }
    
    private var connectedEdges: [RectEdge] {
        #if os(tvOS)
        screen.defaultConnectedEdges
        #else
        connectedWindowType?.connectedEdges ?? screen.defaultConnectedEdges
        #endif
    }
    
    private func seemlessBorderOffset(_ edge: RectEdge) -> CGFloat {
        connectedEdges.contains(edge) ? -system.screenBorderInsetAmount - (system.screenBorderWidth ?? 0) : 0
    }
}

#Preview {
    #if os(tvOS)
    ScreenView {
        Text("Hello")
    }
    #else
    ScreenView(connectedWindowType: nil) {
        Text("Hello")
    }
    #endif
}
