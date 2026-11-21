#if canImport(HomeKit)
import HomeKit

/// Model that represents a outlet device
@MainActor @Observable
final class HomeOutlet: Identifiable {
    
    init(accessory: HMAccessory) {
        self.accessory = accessory
        self.isOn = false

        let characteristics = accessory.services.first(where: { $0.serviceType == HMServiceTypeOutlet })?.characteristics
        let powerState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypePowerState })
        // Apply after the async read completes — the value isn't populated synchronously.
        Task { [weak self] in
            try? await powerState?.readValue()
            guard let self else { return }
            isApplyingRemoteState = true
            isOn = (powerState?.value as? NSNumber)?.boolValue ?? false
            isApplyingRemoteState = false
        }
    }

    let accessory: HMAccessory

    /// Suppresses the `isOn` write-back while we're mirroring the device's own current value into the model.
    private var isApplyingRemoteState = false

    var isOn: Bool {
        didSet {
            guard !isApplyingRemoteState else { return }
            Task { [weak self] in
                guard let self else { return }

                do {
                    try await setPower(isOn)
                } catch {
                    isOn.toggle()
                }
            }
        }
    }
    nonisolated var id: UUID { accessory.uniqueIdentifier }
    
    func setPower(_ isOn: Bool) async throws {
        let characteristics = accessory.services.first(where: { $0.serviceType == HMServiceTypeOutlet })?.characteristics
        let powerState = characteristics?.first(where: { $0.characteristicType == HMCharacteristicTypePowerState })
        try await powerState?.writeValue(isOn)
    }
    
}
#endif
