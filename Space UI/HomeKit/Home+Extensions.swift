#if canImport(HomeKit)
import HomeKit

extension HMHome: @retroactive Identifiable {
    
    public var id: UUID { uniqueIdentifier }
    
    /// A HomeKit scene optionally setup by the user for a specific lighting mode
    func actionSet(for lightingMode: LightingMode) -> HMActionSet? {
        actionSets.first(where: { $0.name.localizedCaseInsensitiveContains(lightingMode.rawValue) })
    }
    
}

extension HMRoom: @retroactive Identifiable {
    
    public var id: UUID { uniqueIdentifier }
    
}

extension HMActionSet: @retroactive Identifiable {
    
    public var id: UUID { uniqueIdentifier }
    
}

extension HMAccessory {
    
    var imageName: String {
        switch category.categoryType {
        case HMAccessoryCategoryTypeBridge:
            "cooktop"
        case HMAccessoryCategoryTypeLightbulb:
            name.localizedCaseInsensitiveContains("downlight") ? "light.recessed" : "lightbulb"
        case HMAccessoryCategoryTypeOutlet:
            "poweroutlet.type.b"
        case HMAccessoryCategoryTypeFan:
            "fan"
        default:
            "questionmark"
        }
    }

    #if STORY
    /// Whether this is the show's console. The console publishes all seven of its elements as services on one
    /// accessory, so this is an accessory-level question that only its services can answer.
    var isConsole: Bool {
        services.contains { ConsoleAccessory(service: $0) != nil }
    }
    #endif

}

extension HMService {

    /// The first characteristic of `characteristicType` on this service.
    ///
    /// Deliberately scoped to a service rather than an accessory. The console carries five Lightbulb services
    /// at once, so the accessory-level equivalent would resolve every one of them to whichever came first —
    /// writing the green indicator would silently drive the ambient lights instead.
    func characteristic(_ characteristicType: String) -> HMCharacteristic? {
        characteristics.first(where: { $0.characteristicType == characteristicType })
    }

    /// The name HomeSpan gives a service, for the services that carry one instead of relying on `name`.
    var configuredName: String? {
        characteristic(HMCharacteristicTypeConfiguredName)?.value as? String
    }

}

extension [HMAccessory] {
    @MainActor
    var lights: [HomeLight] {
        // Five of the console's seven services are Lightbulbs — including the two button *inputs*. Left in, the
        // show's hardware would appear as an assignable room light, and a color-mode write could silently
        // change the console flash rate or write to an input. See `Show/Docs/Console Hardware.md`.
        return filter { accessory in
            guard accessory.services.contains(where: { $0.serviceType == HMServiceTypeLightbulb }) else { return false }
            #if STORY
            if ShipState.shared.isRunningStory, accessory.isConsole { return false }
            #endif
            return true
        }
        .map { HomeLight(accessory: $0) }
    }
    
    @MainActor
    var outlets: [HomeOutlet] {
        filter { $0.services.contains(where: { $0.serviceType == HMServiceTypeOutlet }) }
            .map { HomeOutlet(accessory: $0) }
    }
}
#endif
