#if os(visionOS)
import SwiftUI
import RealityKit

/// Full immersive space: the Space Window's scene in true 3D around the viewer. The scene stays camera-driven
/// (story/ambient choreography animates the RealityKit camera, which can't drive the user's head), so the
/// world is parented under a pivot that mirrors the camera inversely every frame — settle pans, hyperspace
/// jumps, and shake all play out around you.
struct SpaceImmersiveView: View {

    /// Approximate eye height, so the camera's path plays out at head height instead of on the floor.
    private static let eyeHeight: Float = 1.4

    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow

    /// Keeps the shared renderer alive while the immersive space is open (`MetalRenderer.shared` is weak).
    @State private var renderer: MetalRenderer?
    @State private var updateSubscription: EventSubscription?
    /// The full scene has no keyboard/window controls, so a tap anywhere reveals this floating panel — the
    /// only way to advance the scripted story or exit the space from inside the immersion. It auto-hides a
    /// few seconds later so a stray tap can't leave it lingering in the scene.
    @State private var showingControls = false
    /// Auto-hide countdown, re-armed on every reveal / button press so the panel stays up while it's in use.
    @State private var dismissTask: Task<Void, Never>?
    /// Invisible sphere the viewer sits inside; its `InputTargetComponent` catches gaze-taps on empty space so
    /// the spatial-tap gesture below has something to land on (a bare pinch with nothing to gaze at doesn't
    /// register). Its input target is removed whenever the panel is up (see the `update` closure) — a RealityKit
    /// hit target behind the panel would otherwise swallow taps meant for the panel's SwiftUI buttons.
    @State private var tapCatcher = Entity()

    var body: some View {
        RealityView { content, attachments in
            let renderer = MetalRenderer.shared ?? MetalRenderer(cameraWidthMode: .single)
            MetalRenderer.shared = renderer
            self.renderer = renderer
            let scene = renderer.scene

            let pivot = Entity()
            scene.moveSceneRoot(to: pivot)
            content.add(pivot)

            // Match the RealityRenderer scene's minimum-brightness environment lighting
            if let environment = try? await EnvironmentResource(equirectangular: Self.minBrightnessImage()) {
                let light = Entity()
                light.components.set(ImageBasedLightComponent(source: .single(environment)))
                content.add(light)
                scene.sceneRoot.components.set(ImageBasedLightReceiverComponent(imageBasedLight: light))
            }

            // Tap-anywhere catcher: the viewer is inside this sphere, so any gaze ray hits its inner wall.
            tapCatcher.name = "tapCatcher"
            tapCatcher.position = [0, Self.eyeHeight, 0]
            tapCatcher.components.set(CollisionComponent(shapes: [.generateSphere(radius: 6)]))
            tapCatcher.components.set(InputTargetComponent())
            content.add(tapCatcher)

            // Control panel floats just below eye level, in front of the viewer's start orientation. It stays
            // mounted (shown/hidden via opacity + hit-testing) rather than conditionally, so its SwiftUI
            // interactivity is fully wired up by the time a tap arrives.
            if let controls = attachments.entity(for: "controls") {
                controls.position = [0, Self.eyeHeight - 0.35, -1.3]
                content.add(controls)
            }

            Self.updatePivot(pivot, camera: scene.camera)
            updateSubscription = content.subscribe(to: SceneEvents.Update.self) { _ in
                Self.updatePivot(pivot, camera: scene.camera)
            }
        } update: { content, attachments in
            // The panel's SwiftUI buttons are interactive on their own, but a gaze-tap only reaches them if
            // nothing else is a hit target under the gaze: an InputTargetComponent on the attachment itself, or
            // on the catcher sphere behind it, swallows the tap first (that's why tapping the panel used to just
            // dismiss it). So the panel gets no components of its own, and while it's up we silence the sphere.
            // While it's hidden the sphere regains its input target to catch the next reveal tap on empty space.
            if showingControls {
                tapCatcher.components.remove(InputTargetComponent.self)
            } else {
                tapCatcher.components.set(InputTargetComponent())
            }
        } attachments: {
            Attachment(id: "controls") {
                controlPanel
                    .opacity(showingControls ? 1 : 0)
                    .allowsHitTesting(showingControls)
            }
        }
        // The tap-catcher only *reveals* the panel. It can't also dismiss on a tap: the sphere has to be
        // silenced while the panel is up (above) for the buttons to work, so there's nothing to catch a
        // dismiss tap then — the panel auto-hides on its own timer instead.
        .gesture(
            SpatialTapGesture()
                .targetedToEntity(tapCatcher)
                .onEnded { _ in
                    revealControls()
                }
        )
        .onAppear {
            AppController.shared.isImmersiveSpaceOpen = true
        }
        .onDisappear {
            dismissTask?.cancel()
            dismissTask = nil
            updateSubscription?.cancel()
            updateSubscription = nil
            renderer?.scene.sceneRoot.components.remove(ImageBasedLightReceiverComponent.self)
            renderer?.scene.restoreSceneRoot()
            AppController.shared.isImmersiveSpaceOpen = false
            // Restore the flat UI window that was dismissed when the space opened, so exiting never leaves the
            // app with no visible scene.
            openWindow(id: WindowID.ui.rawValue)
        }
    }

    private var controlPanel: some View {
        HStack(spacing: 30) {
            Button("Exit", systemImage: "arrow.down.forward.and.arrow.up.backward") {
                AudioController.shared.play(.action)
                Task { await dismissImmersiveSpace() }
            }
            
            Button("Advance Scene", systemImage: "play") {
                advance()
                revealControls()
            }
            .controlSize(.large)
        }
        .labelStyle(.iconOnly)
        .scenePadding()
        .glassBackgroundEffect()
    }

    /// Reveals the control panel and (re)arms the auto-hide countdown. Called on any empty-space tap and after
    /// a button press, so the panel stays up while it's being used but never lingers after the viewer stops.
    private func revealControls() {
        withAnimation { showingControls = true }
        dismissTask?.cancel()
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            withAnimation { showingControls = false }
        }
    }

    /// The play button advances the scripted story, or triggers an ambient hyperspace jump when no story is
    /// running — mirroring the window tap / keyboard advance on other platforms.
    private func advance() {
        AudioController.shared.play(.action)
        #if STORY
        if let storyState = ShipState.shared.storyState {
            storyState.next()
            return
        }
        #endif
        ShipState.shared.ambientHyperspaceJump()
    }

    /// Positions the world so the viewer stands at the scene camera's pose
    @MainActor
    private static func updatePivot(_ pivot: Entity, camera: Entity) {
        let eye = Transform(translation: .init(0, eyeHeight, 0)).matrix
        pivot.transform = Transform(matrix: eye * camera.transform.matrix.inverse)
    }

    private static func minBrightnessImage() -> CGImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        return renderer.image { context in
            UIColor(white: 0.5, alpha: 1.0).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }.cgImage!
    }
}

#endif
