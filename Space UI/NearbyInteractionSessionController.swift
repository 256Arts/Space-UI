#if !os(macOS) && !os(visionOS)
import NearbyInteraction

final class NearbyInteractionSessionController: NSObject, NISessionDelegate {
    
    enum DeviceRole: String, Identifiable, CaseIterable {
        case user, sensor
        
        var id: Self { self }
        var title: LocalizedStringResource {
            self == .user ? "User" : "Sensor"
        }
    }
    
    @MainActor
    static let shared = NearbyInteractionSessionController()
    
    override init() {
        super.init()
        start()
    }
    
    private var session: NISession?
    private var connectedPeerID: String?
    
    var peerDiscoveryToken: NIDiscoveryToken?
    
    /// If local device doesn't support direction, it should not have a `NISession`, and only listens to directions sent via `PeerSessionController`
    var myDeviceIsSupported: Bool {
        NISession.deviceCapabilities.supportsDirectionMeasurement
    }
    
    var role: DeviceRole? {
        guard let roleValue = UserDefaults.standard.string(forKey: UserDefaults.Key.nearbyInteractionRole) else { return nil }
        
        return DeviceRole(rawValue: roleValue)
    }
    
    /// If this device should participate in nearby interactions
    var isEnabled: Bool {
        myDeviceIsSupported && role != nil
    }
    
    var myDiscoveryTokenData: Data? {
        guard let myToken = session?.discoveryToken, connectedPeerID == nil, isEnabled else { return nil }
        
        return try? NSKeyedArchiver.archivedData(withRootObject: myToken, requiringSecureCoding: true)
    }

    func start() {
        guard isEnabled else { return }
        
        session = NISession()
        session?.delegate = self
        
        if let peerDiscoveryToken {
            let config = NINearbyPeerConfiguration(peerToken: peerDiscoveryToken)
            session?.run(config)
        }
    }
    
    func receiveDiscoveryTokenData(_ data: Data, fromPeer peerID: String) {
        guard isEnabled, let discoveryToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) else { return }
        
        connectedPeerID = peerID
        peerDiscoveryToken = discoveryToken
        let config = NINearbyPeerConfiguration(peerToken: discoveryToken)
        session?.run(config)
    }
    
    func disconnectedFromPeer(_ peerID: String) {
        if peerID == connectedPeerID {
            connectedPeerID = nil
        }
    }

    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let peerToken = peerDiscoveryToken else {
            return // No token yet — ignore this update rather than crash an auxiliary parallax feature
        }

        // Find the right peer.
        guard let peerObj = nearbyObjects.first(where: { $0.discoveryToken == peerToken }) else { return }
        
        // Ignore if angle is between PI and 2PI, because the peer will have (and send) the target angle instead
        if (peerObj.horizontalAngle ?? 0) < .pi {
            // Create these constants since `peerObj` cannot be sent to main actor
            let distance = peerObj.distance
            let horizontalAngle = peerObj.horizontalAngle
            Task { @MainActor in
                SpaceWindowCameraManager.shared.nearbyDeviceDirection = (distance: distance, angle: horizontalAngle)
                PeerSessionController.shared.send(message: .deviceDirection(distance: distance, angle: horizontalAngle))
            }
        }
    }

    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        switch reason {
        case .peerEnded:
            // The peer token is no longer valid.
            peerDiscoveryToken = nil
            
            // The peer stopped communicating, so invalidate the session because
            // it's finished.
            session.invalidate()
            
            // Restart the sequence to see if the peer comes back.
            start()
        case .timeout:
            
            // The peer timed out, but the session is valid.
            // If the configuration is valid, run the session again.
            if let config = session.configuration {
                session.run(config)
            }
        default:
            // A future OS adding a RemovalReason case must not crash the app; treat it like a timeout and retry.
            if let config = session.configuration {
                session.run(config)
            }
        }
    }

    func sessionSuspensionEnded(_ session: NISession) {
        // Session suspension ended. The session can now be run again.
        if let config = self.session?.configuration {
            session.run(config)
        } else {
            // Create a valid configuration.
            start()
        }
    }

    func session(_ session: NISession, didInvalidateWith error: Error) {
        // If the app lacks user approval for Nearby Interaction, present
        // an option to go to Settings where the user can update the access.
        if case NIError.userDidNotAllow = error {
            return
        }

        // Recreate a valid session.
        start()
    }
    
}
#endif
