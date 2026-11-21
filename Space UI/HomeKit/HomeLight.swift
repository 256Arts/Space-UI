#if canImport(HomeKit)
import HomeKit

/// Model that represents a light device
@MainActor @Observable
final class HomeLight: Identifiable {
    
    /// What color a HomeKit light should sync to
    enum ColorMode: String, Identifiable {
        case primary = "Primary Color"
        case secondary = "Secondary Color"
        case white = "White"
        case environmental = "Environmental" // Matches space window scene
        case off = "Off"
        
        enum ColorSource {
            case environment, lightPanel
        }
        
        var id: Self { self }
        
        var colorSource: ColorSource {
            switch self {
            case .primary: .lightPanel
            case .secondary: .lightPanel
            case .white: .lightPanel
            case .environmental: .environment
            case .off: .lightPanel
            }
        }
    }
    
    /// Color that can be set on a HomeKit light
    struct LightColor {
        let hue: Int?
        let saturation: Int?
        let brightness: Int?
    }
    
    init(accessory: HMAccessory) {
        self.accessory = accessory
        self.brightness = 0

        let characteristics = accessory.services.first(where: { $0.serviceType == HMServiceTypeLightbulb })?.characteristics
        let brightState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness })
        let powerState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypePowerState })

        let lights = UserDefaults.standard.dictionary(forKey: UserDefaults.Key.homeLightsColorModes) ?? [:]
        self.colorMode = ColorMode(rawValue: lights[id.uuidString] as? String ?? "")

        // Read the characteristics, then apply — the values aren't populated until the async reads finish
        // (previously `brightness` was always 0 because it was read before `readValue()` completed).
        Task { [weak self] in
            try? await brightState?.readValue()
            try? await powerState?.readValue()
            guard let self else { return }
            let poweredOn = (powerState?.value as? NSNumber)?.boolValue ?? false
            let level = (brightState?.value as? NSNumber)?.doubleValue ?? 0
            isApplyingRemoteState = true
            brightness = poweredOn ? level : 0
            isApplyingRemoteState = false
        }
    }

    let accessory: HMAccessory

    /// Suppresses the `brightness` write-back while we're mirroring the device's own current value into the model.
    private var isApplyingRemoteState = false

    var brightness: Double {
        didSet {
            guard !isApplyingRemoteState else { return }
            Task { [weak self] in
                guard let self else { return }

                do {
                    try await setBrightness(brightness)
                } catch {
                    brightness = oldValue
                }
            }
        }
    }
    
    var availableColorModes: [ColorMode] {
        guard let characteristics = accessory.services.first(where: { $0.serviceType == HMServiceTypeLightbulb })?.characteristics else {
            return []
        }
        
        return if characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeHue }) != nil,
           characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeSaturation }) != nil
        {
            [.primary, .secondary, .white, .environmental, .off]
        } else {
            [.white, .off]
        }
    }
    
    var colorMode: ColorMode? {
        didSet {
            var lights = UserDefaults.standard.dictionary(forKey: UserDefaults.Key.homeLightsColorModes) ?? [:]
            lights[id.uuidString] = colorMode?.rawValue
            UserDefaults.standard.set(lights, forKey: UserDefaults.Key.homeLightsColorModes)
            
            Task { [weak self] in
                guard let self, let colorMode, let color = HomeStore.shared.colorsByMode[colorMode] else { return }
                try? await setColor(color)
            }
        }
    }
    
    nonisolated var id: UUID { accessory.uniqueIdentifier }
    
    private func setBrightness(_ brightness: Double) async throws {
        let characteristics = accessory.services.first(where: { $0.serviceType == HMServiceTypeLightbulb })?.characteristics
        let brightState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness })
        try await brightState?.writeValue(brightness)
        
        let powerState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypePowerState })
        try await powerState?.writeValue(true)
    }
    
    enum SetColorError: Error {
        case deviceNotFound
    }
    
    func setColor(_ color: LightColor) async throws {
        guard let characteristics = accessory.services.first(where: { $0.serviceType == HMServiceTypeLightbulb })?.characteristics else {
            throw SetColorError.deviceNotFound
        }
        
        let hueState = characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeHue })
        let satState = characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeSaturation })
        let brightState = characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness })
        let powerState = characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState })
        // Reason about the *target* color's brightness (0...100), not the bulb's current level.
        let targetBrightness = color.brightness ?? 0
        let lightCannotDisplayTargetHue = (color.saturation ?? 0 > 0) && (hueState == nil || satState == nil)
        let lightCannotDisplayTargetBrightness = targetBrightness != 0 && targetBrightness != 100 && brightState == nil

        if lightCannotDisplayTargetHue || lightCannotDisplayTargetBrightness {
            // If the light does not support the target color just turn it off
            try await powerState?.writeValue(false)
        } else if brightState == nil {
            // If the light can only display the target brightness using power on/off, do it
            try await powerState?.writeValue(targetBrightness == 100)
        } else {
            try await withThrowingTaskGroup(of: Void.self) { group in
                if let hue = color.hue {
                    group.addTask {
                        try await hueState?.writeValue(hue)
                    }
                }
                if let saturation = color.saturation {
                    group.addTask {
                        try await satState?.writeValue(saturation)
                    }
                }
                if let brightness = color.brightness, UserDefaults.standard.bool(forKey: UserDefaults.Key.setHomeLightsBrightness) {
                    group.addTask {
                        try await brightState?.writeValue(brightness)
                    }
                }
                if UserDefaults.standard.bool(forKey: UserDefaults.Key.turnOnHomeLights) {
                    group.addTask {
                        try await powerState?.writeValue(true)
                    }
                }
                try await group.waitForAll()
            }
        }
    }
    
    /// Whether the user's HomeKit scene for `lightingMode` already drives this light, in which case the app leaves
    /// it alone and lets the scene own it.
    ///
    /// Answers for the mode it is *asked* about. It used to ignore the argument and read
    /// `HomeStore.currentLightingMode` instead, which happened to agree with every caller — so the parameter read
    /// as if it were honoured while a caller asking about any other mode would have been silently answered about
    /// the current one.
    func existsInActionSet(for lightingMode: LightingMode) -> Bool {
        HomeStore.shared.currentHome?
            .actionSet(for: lightingMode)?.actions
            .compactMap { $0 as? HMCharacteristicWriteAction<NSNumber> }
            .contains(where: { $0.characteristic.service?.accessory == self.accessory }) == true
    }
    
}
#endif
