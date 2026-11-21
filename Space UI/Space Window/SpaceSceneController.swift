import Foundation
import ImageIO
import RealityKit
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Owns the RealityKit scene for the Space Window: renderer, camera, sun, and all entity state.
/// Behavior lives in extensions: `+Planets` (planet systems and atmosphere) and `+Enemies` (fighter patrols
/// and destroyers), which every target builds; plus `+Story` (the show's fixed system and its text crawl),
/// `+Hangar` (tractor-beam capture and liftOff) and `+FlybyEnemies` (the liftOff strafing run and laser
/// bolts), which only the Show target builds. The state those three own is `#if STORY` below.
@MainActor
final class SpaceSceneController {

    init() {
        fighterPatrol1Pivot = Entity()
        fighterPatrol1Pivot.isEnabled = false

        fighterPatrol2Pivot = Entity()
        fighterPatrol2Pivot.isEnabled = false

        let ues = realityRenderer.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            guard let self else { return }
            self.update(event)
            #if STORY
            self.advanceFlyby(deltaTime: Float(event.deltaTime))
            #endif
        }
        subscriptions.append(ues)

        realityRenderer.entities.append(camera)
        realityRenderer.entities.append(sceneRoot)
        sceneRoot.addChild(sun)
        sceneRoot.addChild(fighterPatrol1Pivot)
        sceneRoot.addChild(fighterPatrol2Pivot)
        realityRenderer.activeCamera = camera

        Task { [weak self] in
            guard let self else { return }

            guard let resource = try? await TextureResource(named: "stars") else { return }
            var material = UnlitMaterial()
            material.color = .init(texture: .init(resource))
            material.textureCoordinateTransform = .init(scale: .init(x: 4, y: 4))
            #if !os(visionOS)
            // Skip depth write on the flat renderer so the 500,000-unit-radius backdrop doesn't consume depth
            // precision away from the near planet. On visionOS the immersive compositor needs real per-pixel
            // depth to place the starfield in 3D — without it the stars collapse onto the planet's depth
            // ("within the atmosphere") instead of sitting on the far sphere.
            material.writesDepth = false
            #endif
            let outerSpace = Entity()
            outerSpace.components.set(
                ModelComponent(
                    mesh: .generateSphere(radius: outerSpaceRadius),
                    materials: [material]))
            // Point texture image points inward at the viewer.
            outerSpace.scale *= [-1, 1, 1]

            sceneRoot.addChild(outerSpace)
        }

        // Set the minimum brightness level in the scene
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 1.0)
        UIColor(white: 0.5, alpha: 1.0).setFill()
        UIRectFill(rect)
        let whiteImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let cgImage = whiteImage?.cgImage {
            realityRenderer.lighting.resource = try? EnvironmentResource(equirectangular: cgImage)
        }

        Task { [weak self] in
            guard let self else { return }

            #if STORY
            if inStoryMode {
                await spawnStoryPlanetSystem()
                return
            }
            #endif
            await spawnPlanetSystem()
            playAmbientCameraSettle()
        }

        startAmbientJumpTimer()

//        if UserDefaults.standard.bool(forKey: UserDefaults.Key.randomEmergencies) == false {
//            Task {
//                try? await Task.sleep(for: .seconds(30))
//
//                enterEnemies()
//            }
//        }
    }

    deinit {
        Task {
            await AudioController.shared.stopSound(.fighterLoop)
        }
    }

    let realityRenderer = try! RealityRenderer()
    var lightColor: (hue: Int, sat: Int, bright: Int) = (0, 0, 0) {
        didSet {
            // Touching `HomeStore` creates the home manager, which asks for Home access — so only once the user
            // has opted into syncing, not on every Space Window open.
            guard UserDefaults.standard.bool(forKey: UserDefaults.Key.syncHomeLights) else { return }
            Task {
                HomeStore.shared.refreshLightColors()
                try? await HomeStore.shared.updateLights(sourceFilter: .environment)
            }
        }
    }
    var cameraShakeIntensity: Float = 0

    private let outerSpaceRadius: Float = 5_000_000
    var planetType: PlanetType = .moon
    let planetRadius: Float = 100_000
    let hangarPosition: SIMD3<Float> = .init(x: 0, y: 150, z: -1200)
    private var subscriptions: [EventSubscription] = []
    var inStoryMode: Bool { ShipState.shared.isRunningStory }
    var cameraShakeFadeStartDate: Date?
    /// Last frame's shake offset, undone before applying the next one so shake jitters around the true pose
    /// instead of random-walking the camera away from it.
    private var cameraShakeOffset: SIMD3<Float> = .zero

    // MARK: Entities

    /// Root for all visual content. The camera is deliberately NOT under it: `SpaceImmersiveView` moves this
    /// root into the visionOS immersive scene while the camera stays behind in the `RealityRenderer` scene as
    /// the choreography rail, mirrored onto the viewer by moving the world inversely.
    let sceneRoot = Entity()

    let camera: PerspectiveCamera = {
        let cameraEntity = PerspectiveCamera()
        cameraEntity.camera.fieldOfViewOrientation = .horizontal
        cameraEntity.camera.fieldOfViewInDegrees = 70
        cameraEntity.transform = Transform(pitch: .pi/4) // Will pan down to 0 pitch
        return cameraEntity
    }()

    let sun: DirectionalLight = {
        let entity = DirectionalLight()
        entity.light.intensity = 10_000
        entity.shadow = .init()
        return entity
    }()

    let crawl: ModelEntity = {
        let mesh = MeshResource.generatePlane(width: 5, depth: 9.37)
        return ModelEntity(mesh: mesh, materials: [])
    }()

    /// True while the opening text crawl is on screen (parented and not yet auto-disabled at the end of its
    /// animation). The renderer suppresses bloom during it — bloom smears the bright crawl text into an
    /// unreadable glow.
    var isShowingCrawl: Bool { crawl.parent != nil && crawl.isEnabled }

    /// Just for story mode - Can't figure out playing scale + spin animations at same time
    var planetRoot: Entity = .init()

    var planet: ModelEntity?
    let fighterPatrol1Pivot: Entity
    let fighterPatrol2Pivot: Entity
    var fighterPatrol1: ModelEntity = .init()
    var fighterPatrol2: ModelEntity = .init()
    var destroyers: [ModelEntity] = [.init(), .init(), .init()]
    #if STORY
    var hangar: ModelEntity?
    /// Two lone fighters that strafe the hangar opening during liftOff. Preloaded, disabled until the flyby.
    var flybyFighters: [ModelEntity] = []
    /// In-flight strafing arcs, advanced every frame in `advanceFlyby`.
    var flybyArcs: [FlybyArc] = []
    /// Bolts currently streaking through the scene, so `cancelFlyby` can remove them mid-flight.
    var liveBolts: [ModelEntity] = []

    var droidAnimation: AnimationPlaybackController?
    /// Set once the tractor-beam capture has reached (or been fast-forwarded to) its landed end state, so its
    /// deferred side-effects don't fire late after a skip.
    var tractorBeamCaptureComplete = false
    /// When the tractor-beam fly-in camera animation will end; nil until it starts.
    var captureEndDate: Date?
    /// In-flight (or completed) hangar model load, shared so concurrent preloads never duplicate entities.
    var hangarLoadTask: Task<Void, Error>?
    #endif
    /// In-flight (or completed) fleet load, shared for the same reason as `hangarLoadTask`. The fleet's load is
    /// the one a director re-runs by hand: `.hyperspaceAlarm` is the beat most likely to be replayed (a rewind,
    /// a Jump to Beat, a second run of the show in one launch), and each unguarded pass parented *another*
    /// patrol group under each pivot — visible as duplicate fighters orbiting a few degrees apart.
    var enemiesLoadTask: Task<Void, Error>?
    /// Whether the fleet's models are in the scene. Read by the show so a load that fails or runs long can be
    /// abandoned rather than holding the beat open forever.
    var areEnemiesLoaded = false

    // MARK: Sequence tasks

    /// Deferred side effects of the current scripted sequence (staggered destroyer jumps, capture stages, the
    /// delayed flyby and its shakes). Superseding transitions cancel the pool so stale effects can't fire after
    /// an operator skips ahead.
    private var sequenceTasks: [Task<Void, Never>] = []

    func addSequenceTask(_ body: @escaping @MainActor () async throws -> Void) {
        // Show-critical choreography (staggered destroyer jumps, capture stages, the flyby). Run at a raised
        // priority so the cooperative pool doesn't defer these timed beats behind lower-priority work.
        sequenceTasks.append(Task(priority: .userInitiated) { try? await body() })
    }

    func cancelSequenceTasks() {
        for task in sequenceTasks {
            task.cancel()
        }
        sequenceTasks = []
    }

    // MARK: Camera

    func playHyperspaceJumpCameraAnimation(intoHyperspace: Bool) {
        guard let animation = try? AnimationResource.generate(with: makeHyperspaceJumpAnimation(entity: camera, isCamera: true, intoHyperspace: intoHyperspace)) else { return }

        let completelyGradualEaseOut = AnimationTimingFunction.cubicBezier(controlPoint1: .init(x: 0.15, y: 0.5), controlPoint2: .init(x: 0.3, y: 1.0))
        let spin = SpinAction(
            revolutions: 1,
            localAxis: .init(x: 0, y: 0, z: 1),
            timingFunction: completelyGradualEaseOut
        )
        if !intoHyperspace,
            let spinAnimation = try? AnimationResource.makeActionAnimation(
                for: spin,
                duration: 5,
                bindTarget: .transform),
           let combined = try? AnimationResource.group(with: [animation, spinAnimation])
        {
            camera.playAnimation(combined)
        } else {
            camera.playAnimation(animation)
        }

        if intoHyperspace {
            Task { [weak self] in
                guard let self else { return }

                try? await ShowClock.shared.sleep(for: .seconds(0.5))
                planet?.removeFromParent()
                planetRoot.removeFromParent()
                #if STORY
                hangar?.isEnabled = false
                #endif
                exitEnemies(animated: false)
                resetCameraPosition()
                await spawnPlanetSystem()
            }
        }
    }

    func resetCameraPosition() {
        snapCamera(to: .identity)
    }

    /// Ambient windows have no text crawl to pan down from the pitched-up launch framing (see `camera`'s
    /// initial transform) — settle to the identity look-at with a slow reveal instead.
    private func playAmbientCameraSettle() {
        let settle = FromToByAnimation(from: camera.transform, to: Transform.identity, duration: 6, timing: .easeInOut, bindTarget: .transform)
        if let animation = try? AnimationResource.generate(with: settle) {
            camera.playAnimation(animation)
        }
    }

    // MARK: Ambient variety

    /// Keeps a non-story window from orbiting the same planet forever: occasionally jump to a fresh system.
    /// Runs for the scene's lifetime and re-checks the mode each fire, so it also covers a window that
    /// becomes ambient mid-session; `ambientHyperspaceJump` no-ops whenever the story owns the scene.
    private func startAmbientJumpTimer() {
        Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: (10 * 60)...(20 * 60))))
                guard self != nil else { return }
                ShipState.shared.ambientHyperspaceJump()
            }
        }
    }

    #if os(visionOS)
    /// Moves all visual content into the immersive space's scene. The camera entity stays behind in the
    /// `RealityRenderer` scene, where `MetalRenderer`'s display link keeps ticking its animations.
    func moveSceneRoot(to parent: Entity) {
        realityRenderer.entities.remove(sceneRoot)
        parent.addChild(sceneRoot)
    }

    /// Returns the visual content to the `RealityRenderer` scene when the immersive space closes.
    func restoreSceneRoot() {
        sceneRoot.removeFromParent()
        realityRenderer.entities.append(sceneRoot)
    }
    #endif

    /// Hard-stops any camera animation and pins the camera to `transform`.
    func snapCamera(to transform: Transform) {
        camera.stopAllAnimations(recursive: false)
        // The shake offset was baked into the old transform; left stale, update() would subtract it from the new one.
        cameraShakeOffset = .zero
        camera.transform = transform
        // RealityKit doesn't seem to like editing properties right after stopping an animation on them; reassert next tick.
        Task { [weak self] in
            try? await ShowClock.shared.sleep(for: .seconds(0.01))
            guard let self else { return }
            cameraShakeOffset = .zero
            camera.transform = transform
        }
    }

    func fadeOutCameraShake() {
        cameraShakeFadeStartDate = .now
    }

    /// Hard-cancels any shake immediately, removing the current frame's offset from the camera.
    func stopCameraShake() {
        cameraShakeIntensity = 0
        cameraShakeFadeStartDate = nil
        camera.transform.translation -= cameraShakeOffset
        cameraShakeOffset = .zero
    }

    // MARK: Per-frame update

    private func update(_ event: Event) {
        // Measured in sceneRoot space against the camera's scene coordinates (rather than relativeTo: camera),
        // so it stays correct when the immersive space hosts sceneRoot in a different scene than the camera.
        let cameraPosition = camera.transform.translation
        let fighter1Distance = abs(simd_distance(fighterPatrol1.position(relativeTo: sceneRoot), cameraPosition))
        let fighter2Distance = abs(simd_distance(fighterPatrol2.position(relativeTo: sceneRoot), cameraPosition))
        let fighterDistance = min(fighter1Distance, fighter2Distance)
        // The liftOff strafing fighters drive the fighter loop themselves, via a custom fade in `advanceFlyby`.
        #if STORY
        let flybyOwnsFighterVolume = !flybyArcs.isEmpty
        #else
        let flybyOwnsFighterVolume = false
        #endif
        if !flybyOwnsFighterVolume {
            AudioController.shared.setFighterVolume(1 - min(fighterDistance / 250, 1))
        }

        var currentCameraShake: Float = 0
        if let cameraShakeFadeStartDate {
            let fadeDuration: TimeInterval = 1
            let progress = Date.now.timeIntervalSince(cameraShakeFadeStartDate) / fadeDuration
            if progress >= 1 {
                stopCameraShake()
            } else {
                currentCameraShake = cameraShakeIntensity * Float(1 - progress)
            }
        }

        let fighterShake = 1 - min(fighterDistance / 100, 1)
        let combinedShake = max(currentCameraShake, fighterShake / 2)
        camera.transform.translation -= cameraShakeOffset
        cameraShakeOffset = combinedShake > 0 ? SIMD3<Float>(
            Float.random(in: -1...1),
            Float.random(in: -1...1),
            Float.random(in: -1...1)
        ) * combinedShake : .zero
        camera.transform.translation += cameraShakeOffset
    }

    // MARK: Hyperspace

    func makeHyperspaceJumpAnimation(entity: Entity, isCamera: Bool, intoHyperspace: Bool) -> FromToByAnimation<Transform> {
        let farAway = isCamera ? outerSpaceRadius * 0.99 : -10_000
        let duration = isCamera ? 0.5 : 0.05

        if intoHyperspace {
            // Tolerate a nil planet (model failed to load) rather than trap — ambient jumps repeat forever.
            let cameraForward = inStoryMode ? 1_000 : -((planet?.position.z ?? -4 * planetRadius) - planetRadius)
            let forward = entity.transform.forward(by: isCamera ? cameraForward : farAway)
            return FromToByAnimation(
                from: entity.transform,
                to: forward,
                duration: duration,
                timing: .easeIn,
                bindTarget: .transform)
        } else {
            var back = entity.transform
            back.matrix += Transform(translation: .init(0, 0, farAway)).matrix
            return FromToByAnimation(
                from: back,
                to: entity.transform,
                duration: duration,
                timing: .easeOut,
                bindTarget: .transform)
        }
    }

}

extension Transform {

    /// Move the entity forward in the direction of it's existing rotation
    func forward(by distance: Float) -> Self {
        var forward = self
        forward.matrix *= Transform(translation: .init(0, 0, -distance)).matrix
        return forward
    }

}
