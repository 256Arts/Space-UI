import Foundation
import RealityKit

/// Planet systems and the fake atmosphere shell. The show's own fixed system and text crawl live beside it in
/// `SpaceSceneController+Story.swift`, which only the Show target builds.
extension SpaceSceneController {

    enum PlanetType: String, CaseIterable {
        case saturn, venus, moon, mars

        var lightColor: (hue: Int, sat: Int, bright: Int) {
            switch self {
            case .saturn: (hue: 240, sat: 10, bright: 10)
            case .venus: (hue: 60, sat: 30, bright: 10)
            case .moon: (hue: 0, sat: 0, bright: 50)
            case .mars: (hue: 0, sat: 100, bright: 50)
            }
        }
    }

    /// Add a fresnel rim-glow shell just above the planet's surface to fake an atmosphere
    func addAtmosphere(to planet: ModelEntity) {
        #if !os(visionOS)
        guard var material = try? CustomMaterial(surfaceShader: MyMaterials.atmosphereSurfaceShader, lightingModel: .unlit) else { return }
        let lightColor = planetType.lightColor
        material.baseColor = .init(tint: .init(hue: CGFloat(lightColor.hue) / 360, saturation: CGFloat(lightColor.sat) / 100, brightness: 1, alpha: 1))
        material.blending = .transparent(opacity: 1.0)
        material.writesDepth = false
        // Planet models' bounds are 0.2 cubed, so their surface is at radius 0.1. Radius must match `atmosphereRadius` in Atmosphere.metal
        planet.addChild(ModelEntity(mesh: .generateSphere(radius: 0.12), materials: [material]))
        #endif
    }

    func spawnPlanetSystem() async {
        sun.transform = Transform(pitch: Float.random(in: -2...(-1)), yaw: Float.random(in: -2...2))

        if let planet {
            planet.removeFromParent()
        }
        planetType = inStoryMode ? .moon : PlanetType.allCases.randomElement()!
        var lightColor = planetType.lightColor
        planet = try? await ModelEntity(named: planetType.rawValue)
        planet?.transform = Transform(pitch: Float.random(in: 0..<2) * .pi, yaw: Float.random(in: 0..<2) * .pi, roll: Float.random(in: 0..<2) * .pi)
        planet?.scale = .init(repeating: planetRadius * 2 * 5) // Model's bounds are 0.2 cubed. x5 = 1.0

        let spin = SpinAction(revolutions: 1, timingFunction: .linear)
        if let animation = try? AnimationResource.makeActionAnimation(for: spin, duration: 1000, bindTarget: .transform).repeat() {
            planet?.playAnimation(animation)
        }
        guard let planet else { return } // Model load is tolerated (`try?`); degrade rather than trap the show
        addAtmosphere(to: planet)
        sceneRoot.addChild(planet)

//        if let url = Bundle.main.url(forResource: planetType.textureName, withExtension: "png"),
//           let source = CGImageSourceCreateWithURL(url as CFURL, nil),
//           let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
//           let ibl = try? await EnvironmentResource(equirectangular: image) {
//            planet.components.set(ImageBasedLightComponent(source: .single(ibl), intensityExponent: 0.0))
//        }
//        if let planet {
//            fighterPatrol1Pivot.components.set(ImageBasedLightReceiverComponent(imageBasedLight: planet))
//            fighterPatrol2Pivot.components.set(ImageBasedLightReceiverComponent(imageBasedLight: planet))
//        }

        let veryClose = Int.random(in: 0..<10) == 0
        if veryClose {
            let zDistance = Float.random(in: 0.5...1) * planetRadius
            planet.position = SIMD3(Float.random(in: -0.1...0.1) * planetRadius, (1 - zDistance) - planetRadius, -zDistance)
            lightColor.bright = min(lightColor.bright * 2, 100)
        } else {
            let horizontalDistanceLookAtTargetToPlanetCenter = Float.random(in: 1.2...2) * planetRadius
            let verticalDistanceLookAtTargetToPlanetCenter = Float.random(in: 1.1...1.3) * planetRadius
            let randomAngle = Float.random(in: 0..<2) * .pi
            planet.position = SIMD3(horizontalDistanceLookAtTargetToPlanetCenter * cos(randomAngle), verticalDistanceLookAtTargetToPlanetCenter * sin(randomAngle), Float.random(in: -6...(-3)) * planetRadius)
        }

        self.lightColor = lightColor
    }

}
