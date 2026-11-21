import Foundation
import RealityKit

/// The patrol fleet: orbiting fighter patrols and the hyperspace-jumping capital ships. Built by every
/// target — the ambient Space Window flies the same fleet in when a proximity alert spawns hostiles.
extension SpaceSceneController {

    /// The fleet's models. The one place either build names a ship, so the fleet's staging, animation and
    /// audio are the same in both and only these names (and the sounds `PlayableSound.fighterLoop` resolves
    /// to) differ.
    ///
    /// The show flies the authentic models, which live in the Show target. The App Store build flies
    /// `starShuttle` as its fighters and "Tesser" by Hax Lee (credited in Settings.bundle's Acknowledgements)
    /// as its capital ship, re-rooted to `destroyer`'s heading (nose -Z) and 21 m length so the staging below
    /// fits both.
    #if STORY
    static let fighterModelName = "imperialFighter"
    static let capitalShipModelName = "destroyer"
    #else
    static let fighterModelName = "starShuttle"
    static let capitalShipModelName = "tesser"
    #endif

    /// Loads the fleet exactly once per launch, no matter how many times the beat that needs it is entered.
    ///
    /// `.hyperspaceAlarm` is the show's most-replayed beat — a rewind, a Jump to Beat, or simply running the
    /// show twice without relaunching all re-enter it — and `loadEnemies` parents its patrol groups and
    /// destroyers into a scene it never clears first. Unguarded, each pass left the previous groups orbiting
    /// where they were, each on its own randomized axis: the duplicate fighters a few degrees apart. Same shape
    /// as `preloadHangar`, and for the same reason.
    func preloadEnemies() async throws {
        let load = enemiesLoadTask ?? Task { try await self.loadEnemies() }
        enemiesLoadTask = load
        do {
            try await load.value
        } catch {
            if enemiesLoadTask == load {
                enemiesLoadTask = nil // Allow retrying a failed load.
            }
            throw error
        }
    }

    /// Create fighter patrol and destroyer entities but do not show them
    private func loadEnemies() async throws {

        @MainActor
        func makeFighterPatrol(isLarge: Bool, flyRadius: Float, pivot: Entity, startOnRight: Bool) async throws -> ModelEntity {
            let fighterPatrol = try await ModelEntity(named: Self.fighterModelName)
            fighterPatrol.position = SIMD3((startOnRight ? 1 : -1) * flyRadius, 0, 0)

            let leftFighter = fighterPatrol.clone(recursive: false)
            leftFighter.transform = Transform(translation: SIMD3(10, 10, 10))
            fighterPatrol.addChild(leftFighter)

            let rightFighter = fighterPatrol.clone(recursive: false)
            rightFighter.transform = Transform(translation: SIMD3(-10, 0, 10))
            fighterPatrol.addChild(rightFighter)

            if isLarge {
                let backLeftFighter = fighterPatrol.clone(recursive: false)
                backLeftFighter.transform = Transform(translation: SIMD3(15, 0, -10))
                fighterPatrol.addChild(backLeftFighter)

                let backRightFighter = fighterPatrol.clone(recursive: false)
                backRightFighter.transform = Transform(translation: SIMD3(-15, 10, -10))
                fighterPatrol.addChild(backRightFighter)
            }

            let speed = 25.0 // m/s
            let orbit = OrbitAnimation(
                duration: Double(flyRadius) * .pi / speed,
                axis: [Float.random(in: -0.05...0.05), Float.random(in: 0.95...1.05), Float.random(in: -0.05...0.05)],
                startTransform: fighterPatrol.transform,
                orientToPath: true,
                bindTarget: .transform,
                repeatMode: .repeat)
            if let animation = try? AnimationResource.generate(with: orbit) {
                fighterPatrol.playAnimation(animation)
            }
            pivot.addChild(fighterPatrol)

            return fighterPatrol
        }

        fighterPatrol1 = try await makeFighterPatrol(
            isLarge: false,
            flyRadius: 500,
            pivot: fighterPatrol1Pivot,
            startOnRight: true
        )

        fighterPatrol2 = try await makeFighterPatrol(
            isLarge: true,
            flyRadius: 700,
            pivot: fighterPatrol2Pivot,
            startOnRight: false
        )

        #if STORY
        // Two lone fighters used for the liftOff strafing run.
        let flybyFighter = try await ModelEntity(named: Self.fighterModelName)
        flybyFighter.isEnabled = false
        flybyFighters = [flybyFighter, flybyFighter.clone(recursive: true)]
        for fighter in flybyFighters { sceneRoot.addChild(fighter) }
        #endif

        let destroyer = try await ModelEntity(named: Self.capitalShipModelName)
        destroyer.scale = .init(repeating: 1/3)
        //            destroyer.look(at: camera.position, from: destroyer.position, relativeTo: nil)
//            if let planet {
//                destroyer.components.set(ImageBasedLightReceiverComponent(imageBasedLight: planet))
//            }
        destroyer.isEnabled = false

        destroyers[0] = destroyer
        destroyers[1] = destroyer.clone(recursive: false)
        destroyers[2] = destroyer.clone(recursive: false)

        for index in [0, 1, 2] {
            if inStoryMode {
                destroyers[index].position = switch index {
                case 0: SIMD3(x: 750, y: -100, z: -2500)
                case 1: SIMD3(x: -900, y: 0, z: -3000)
                default: SIMD3(x: 0, y: 180, z: -1400)
                }
            } else {
                destroyers[index].position = SIMD3(Float.random(in: -1000...1000), Float.random(in: -500...500), -3000 + Float(index) * 500)
            }
        }

        for destroyer in destroyers { sceneRoot.addChild(destroyer) }

        areEnemiesLoaded = true
    }

    func enterEnemies() {
        // I don't think this works with `RealityRenderer`
//            if let audio = try? await AudioFileResource(named: "fighterEngineLoop", configuration: .init(shouldLoop: true, shouldRandomizeStartTime: true)) {
//                fighter.playAudio(audio)
//            }
        AudioController.shared.play(.fighterLoop)

        fighterPatrol1Pivot.position = SIMD3(Float.random(in: -100...100), 0, -600)
        fighterPatrol1Pivot.isEnabled = true
        fighterPatrol2Pivot.position = SIMD3(Float.random(in: -100...100), 0, -900)
        fighterPatrol2Pivot.isEnabled = true

        enterDestroyer(0)
        // One instant, two absolute deadlines off it. Chaining a second 2.7s off the first put both of these
        // late together the once the first one slipped — the whole fleet arriving off the beat of villainTheme
        // instead of just one ship. See `ShowClock`.
        let firstJump = ContinuousClock.now
        addSequenceTask { [weak self] in
            try await ShowClock.shared.sleep(until: firstJump + .seconds(2.7))
            try Task.checkCancellation()
            self?.enterDestroyer(1)

            try await ShowClock.shared.sleep(until: firstJump + .seconds(5.4))
            try Task.checkCancellation()
            self?.enterDestroyer(2)
        }
    }

    private func enterDestroyer(_ index: Int) {
        // macOS 26.4 BUG: `SetEntityEnabledAction` causes animation to look glitchy. (`fillMode` does not help.)
        // macOS 26.4 BUG: Starting a `SetEntityEnabledAction` animation paused, enables the entity immediately anyway.
        guard let jump = try? AnimationResource.generate(with: makeHyperspaceJumpAnimation(entity: destroyers[index], isCamera: false, intoHyperspace: false)) else {
            return
        }

        destroyers[index].isEnabled = true
        destroyers[index].playAnimation(jump)
        AudioController.shared.play(.hyperspaceJumpExternal)
    }

    func exitEnemies(animated: Bool) {
        cancelSequenceTasks() // A destroyer still queued to enter must not jump in after the fleet leaves.
        AudioController.shared.stopSound(.fighterLoop)
        #if STORY
        AudioController.shared.stopSound(.hangar) // The fleet leaving is also the show leaving the hangar
        #endif

        if animated {
            let away = fighterPatrol1Pivot.transform.forward(by: 2000)
            guard let jump = try? AnimationResource.generate(with: FromToByAnimation(from: fighterPatrol1Pivot.transform, to: away, duration: 5, timing: .easeIn, bindTarget: .transform)),
                  let disable = try? AnimationResource.makeActionAnimation(for: SetEntityEnabledAction(isEnabled: false)),
                  let animation = try? AnimationResource.sequence(with: [jump, disable])
            else { return }

            fighterPatrol1Pivot.playAnimation(animation)

            let away2 = fighterPatrol2Pivot.transform.forward(by: 2000)
            guard let jump = try? AnimationResource.generate(with: FromToByAnimation(from: fighterPatrol2Pivot.transform, to: away2, duration: 5, timing: .easeIn, bindTarget: .transform)),
                  let disable = try? AnimationResource.makeActionAnimation(for: SetEntityEnabledAction(isEnabled: false)),
                  let animation2 = try? AnimationResource.sequence(with: [jump, disable])
            else { return }

            fighterPatrol2Pivot.playAnimation(animation2)

            exitDestroyer(0)
            let firstJump = ContinuousClock.now
            addSequenceTask { [weak self] in
                try await ShowClock.shared.sleep(until: firstJump + .seconds(3))
                try Task.checkCancellation()
                self?.exitDestroyer(1)

                try await ShowClock.shared.sleep(until: firstJump + .seconds(6))
                try Task.checkCancellation()
                self?.exitDestroyer(2)
            }
        } else {
            fighterPatrol1Pivot.isEnabled = false
            fighterPatrol2Pivot.isEnabled = false
            for destroyer in destroyers {
                destroyer.isEnabled = false
            }
        }
    }

    private func exitDestroyer(_ index: Int) {
        guard let jump = try? AnimationResource.generate(with: makeHyperspaceJumpAnimation(entity: destroyers[index], isCamera: false, intoHyperspace: true)),
            let disable = try? AnimationResource.makeActionAnimation(for: SetEntityEnabledAction(isEnabled: false)),
            let animation = try? AnimationResource.sequence(with: [jump, disable])
        else { return }

        destroyers[index].playAnimation(animation)
        AudioController.shared.play(.hyperspaceJumpExternal)
    }

}
