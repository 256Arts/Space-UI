#if canImport(HomeKit)
import HomeKit

/// A lighting state for the whole home
enum LightingMode: String, CaseIterable {
    case normal, danger, hyperspace
}

@MainActor @Observable
final class HomeStore {
    
    @MainActor
    static let shared = HomeStore()
    
    init() {
        // Runs `autoSelectHome()` once HomeKit finishes loading homes, instead of racing it behind a fixed sleep.
        let delegate = HomeManagerDelegate { [weak self] in
            self?.autoSelectHome()
        }
        managerDelegate = delegate
        homeManager.delegate = delegate
        observeStatusChanges()
    }

    private let homeManager = HMHomeManager()
    @ObservationIgnored private var managerDelegate: HomeManagerDelegate?
    @ObservationIgnored private var statusObservationTask: Task<Void, Never>?

    var currentHome: HMHome?
    
    var currentLightingMode: LightingMode = .normal {
        didSet {
            if let actionSet = currentHome?.actionSet(for: currentLightingMode) {
                Task {
                    try? await currentHome?.executeActionSet(actionSet)
                }
            }
        }
    }
    
    private(set) var colorsByMode: [HomeLight.ColorMode: HomeLight.LightColor] = [:]

    var homes: [HMHome] {
        homeManager.homes
    }
    
    func autoSelectHome() {
        guard currentHome == nil else { return }
        
        let currentHomeID = UUID(uuidString: UserDefaults.standard.string(forKey: UserDefaults.Key.homeID) ?? "")
        currentHome = homeManager.homes.first(where: { $0.uniqueIdentifier == currentHomeID }) ??
        homeManager.homes.first(where: { $0.isPrimary && !$0.accessories.lights.isEmpty }) ??
        homeManager.homes.max(by: { $0.accessories.lights.count < $1.accessories.lights.count })
    }
    
    func refreshLightColors() {
        let mainPowerOn = ShipState.shared.powerState.mainPowerOn
        let isInEmergency = ShipState.shared.isInEmergency
        let isInHyperspace = ShipState.shared.isInHyperspace
        
        currentLightingMode = if isInHyperspace {
            .hyperspace
        } else if isInEmergency || !mainPowerOn {
            .danger
        } else {
            .normal
        }

        let emergencyColor = HomeLight.LightColor(
            hue: Int(system.colors.dangerHue * 360),
            saturation: Int(system.colors.dangerSaturation * 100),
            brightness: 100
        )
        let environmentSceneColor: HomeLight.LightColor = {
            #if !os(tvOS)
            if let spaceScene = MetalRenderer.shared?.scene {
                return HomeLight.LightColor(hue: spaceScene.lightColor.hue, saturation: spaceScene.lightColor.sat, brightness: spaceScene.lightColor.bright)
            }
            #endif
            return HomeLight.LightColor(hue: nil, saturation: nil, brightness: nil)
        }()

        colorsByMode = [
            .primary: isInEmergency || !mainPowerOn ? emergencyColor : HomeLight.LightColor(
                hue: Int(system.colors.primaryHue * 360),
                saturation: Int(system.colors.primarySaturation * 100),
                brightness: 100
            ),
            .secondary: isInEmergency || !mainPowerOn ? emergencyColor : HomeLight.LightColor(
                hue: Int(system.colors.secondaryHue * 360),
                saturation: Int(system.colors.secondarySaturation * 100),
                brightness: 100
            ),
            .white: isInEmergency ? emergencyColor : HomeLight.LightColor(hue: 0, saturation: 0, brightness: mainPowerOn ? 100 : 0),
            .off: isInEmergency ? emergencyColor : HomeLight.LightColor(hue: nil, saturation: nil, brightness: 0),
            .environmental: isInHyperspace ? HomeLight.LightColor(hue: 240, saturation: 60, brightness: 100) : environmentSceneColor
        ]
        
        Task { try? await updateLights() }
    }

    /// The room the show is performed in, and the light in it that ends the show — matched by HomeKit name.
    /// Hard-coded because it is one fixture in one basement (see `Show/Docs/Show Setup.md`), not a setting.
    private static let roomLightName = "Downlights"
    private static let roomName = "Basement"

    /// Brings the show's room back up at the finale.
    ///
    /// Deliberately outside everything else in this file: it is the real room light rather than a decorative
    /// one, so it ignores `colorsByMode`, the lighting modes, and the `syncHomeLights` setting the same way
    /// the console does — the room has to come back up however those are set.
    ///
    /// Searched across every home and preferring the basement's fixture, but any light of that name beats
    /// leaving the audience in the dark.
    func turnOnRoomLight() async {
        let matches = homes.flatMap(\.accessories).filter {
            $0.name.localizedCaseInsensitiveCompare(Self.roomLightName) == .orderedSame
        }
        let light = matches.first { $0.room?.name.localizedCaseInsensitiveContains(Self.roomName) == true } ?? matches.first
        guard let service = light?.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }) else { return }

        // Brightness first, then power, so the room can't come up at whatever level it was last left at.
        try? await service.characteristic(HMCharacteristicTypeBrightness)?.writeValue(100)
        try? await service.characteristic(HMCharacteristicTypePowerState)?.writeValue(true)
    }

    private func observeStatusChanges() {
        statusObservationTask = Task { [weak self] in
            // Re-reads `ShipState.shared` each iteration, so tracking survives the wholesale instance replacement on
            // config receive (the old `withObservationTracking` one-shot bound to the first instance and never re-armed).
            // Re-reading is only half of it: the swap itself isn't observable, so a replacement made while the ship
            // was idle left this armed on an instance that would never change again — and the room stayed lit
            // through every emergency after it. `configID` changes with the swap, which re-arms us on the new
            // instance. Entering story mode is one of those swaps, so the show was squarely in the blast radius.
            let changes = Observations {
                _ = AppController.shared.configID
                let ship = ShipState.shared
                return [ship.isInEmergency, ship.isInHyperspace, ship.powerState.mainPowerOn]
            }
            for await _ in changes {
                self?.refreshLightColors()
            }
        }
    }

    func updateLights(sourceFilter: HomeLight.ColorMode.ColorSource? = nil) async throws {
        guard UserDefaults.standard.bool(forKey: UserDefaults.Key.syncHomeLights), let currentHome else { return }

        try await withThrowingTaskGroup(of: Void.self) { group in

            var relevantLights = currentHome.accessories.lights
            if let sourceFilter {
                relevantLights = relevantLights.filter({ $0.colorMode?.colorSource == sourceFilter })
            }
            for light in relevantLights {
                guard let mode = light.colorMode, let color = colorsByMode[mode], !light.existsInActionSet(for: currentLightingMode) else { continue }
                group.addTask {
                    try await light.setColor(color)
                }
            }

            try await group.waitForAll()
        }
    }

}

/// Bridges HomeKit's `NSObject`-based delegate to a plain callback, so `HomeStore` can stay a clean `@Observable`.
@MainActor
private final class HomeManagerDelegate: NSObject, HMHomeManagerDelegate {
    private let didUpdateHomes: () -> Void

    init(didUpdateHomes: @escaping () -> Void) {
        self.didUpdateHomes = didUpdateHomes
    }

    nonisolated func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        MainActor.assumeIsolated {
            didUpdateHomes()
        }
    }
}
#endif
