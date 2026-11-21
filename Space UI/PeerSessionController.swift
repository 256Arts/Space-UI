import Foundation
import Network
import Observation

/// Where a shared state change came from, and so whether this device owes the room an announcement.
///
/// A `.local` change is ours to send. A `.peer` change has already been announced by whoever made it, and
/// re-announcing it is the echo that used to bounce the story position between two screens forever. The one
/// device that forwards a peer's change is the host, which relays it to the rest of the room — see
/// `PeerSessionController.relay(_:from:)`. Every synced piece of state follows this one rule.
enum ChangeSource {
    case local, peer
}

/// Syncs the theme and story/emergency events across devices on the local network.
/// The host runs a `NetworkListener` accepting any number of peers; joiners browse for a host and connect.
@MainActor @Observable
final class PeerSessionController {

    enum Message: Codable, Sendable {
        case config(Config)
        case nearbyDiscoveryToken(Data)
        case deviceDirection(distance: Float?, angle: Float?)
        /// `puzzle` is the host's single choice for the whole room, so every screen opens the same one. `nil`
        /// means an emergency with no puzzle (the debug menu's, the story's). See `EmergencyPuzzle`.
        case emergencyBegan(reason: EmergencyReason, puzzle: EmergencyPuzzle?)
        case emergencyEnded
        case story(StoryChapter?, StoryPatrolLine?)
    }

    typealias PeerConnection = NetworkConnection<Coder<Message, Message, NetworkJSONCoder>>

    static let shared = PeerSessionController()
    static let serviceType = "_ji-spaceui._tcp"
    /// Bump when the wire format (`Message`) changes incompatibly, so mixed-version peers skip each other at browse time.
    /// 2: `emergencyBegan` gained the room's shared `puzzle`, so a v1 peer can no longer decode it.
    static let protocolVersion = 2
    /// Stable per-device identifier, persisted so the host/join role tie-break is consistent across launches.
    static let deviceID: String = {
        if let existing = UserDefaults.standard.string(forKey: UserDefaults.Key.peerDeviceID) {
            return existing
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: UserDefaults.Key.peerDeviceID)
        return new
    }()
    /// Bonjour service name: `v<version>-<deviceID>`. The version prefix lets peers skip incompatible builds,
    /// and the stable device ID gives two host-capable devices a deterministic winner.
    static let localServiceName = "v\(protocolVersion)-\(deviceID)"

    /// The device ID portion of a peer's Bonjour name (everything after the first `-`; device IDs are UUIDs).
    private static func deviceID(ofServiceName name: String) -> Substring {
        name.split(separator: "-", maxSplits: 1).dropFirst().first ?? ""
    }
    /// The version token (e.g. `v1`) portion of a peer's Bonjour name.
    private static func versionToken(ofServiceName name: String) -> Substring {
        name.split(separator: "-", maxSplits: 1).first ?? ""
    }

    private static var connectionParameters: NWParametersBuilder<Coder<Message, Message, NetworkJSONCoder>> {
        .parameters {
            Coder(Message.self, using: .json) {
                TCP()
                    .noDelay(true) // Low latency for high-frequency deviceDirection messages
                    .keepalive(idleTimeInSeconds: 10, count: 3, intervalInSeconds: 3) // Detect vanished peers, so they can re-pair
                    .connectionTimeout(5) // Fail fast on stale Bonjour endpoints, so we re-browse
            }
        }
        .peerToPeerIncluded(true)
    }

    private struct Peer {
        let connection: PeerConnection
        let outbox: AsyncStream<Message>.Continuation // Serializes sends to preserve message order
        let tasks: [Task<Void, Never>]
    }

    @ObservationIgnored private var peers: [String: Peer] = [:]
    @ObservationIgnored private var listenerTask: Task<Void, Never>?
    @ObservationIgnored private var browserTask: Task<Void, Never>?
    private(set) var connectedPeerIDs: [String] = []

    var canHost = UserDefaults.standard.bool(forKey: UserDefaults.Key.canHostSession) {
        didSet {
            if !canHost, isHost {
                stopLookingToHost()
                disconnectAll()
            }
            UserDefaults.standard.set(canHost, forKey: UserDefaults.Key.canHostSession)
        }
    }
    var canJoin = UserDefaults.standard.bool(forKey: UserDefaults.Key.canJoinSession) {
        didSet {
            if !canJoin, !isHost {
                stopLookingToJoin()
                disconnectAll()
            }
            UserDefaults.standard.set(canJoin, forKey: UserDefaults.Key.canJoinSession)
        }
    }
    var isHost = true

    /// Publishes this device as a potential host, accepting any number of joiners.
    func lookToHost() {
        guard canHost, listenerTask == nil, isHost || peers.isEmpty else { return }
        listenerTask = Task {
            defer { listenerTask = nil }
            do {
                try await NetworkListener(
                    for: .bonjour(name: Self.localServiceName, type: Self.serviceType),
                    using: Self.connectionParameters
                )
                .run { connection in
                    self.acceptConnection(connection)
                }
            } catch {
                print("Listener stopped: \(error)")
            }
        }
    }
    func stopLookingToHost() {
        listenerTask?.cancel()
    }

    /// Browses for a host to join.
    func lookToJoin() {
        guard canJoin, browserTask == nil, peers.isEmpty else { return }
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        // Capture outside the (non-isolated) browser closure. If we can also host, we only join a peer whose
        // device ID sorts below ours, so exactly one of two host-capable devices ends up connecting.
        let canHostToo = canHost
        let ourVersionToken = "v\(Self.protocolVersion)"
        browserTask = Task {
            defer { browserTask = nil }
            do {
                let endpoint = try await NetworkBrowser(for: .bonjour(Self.serviceType), using: parameters)
                    .run { endpoints in
                        let host = endpoints.first { endpoint in
                            guard endpoint.name != Self.localServiceName else { return false } // Ignore our own listener
                            guard Self.versionToken(ofServiceName: endpoint.name) == ourVersionToken[...] else { return false } // Skip incompatible builds
                            guard canHostToo else { return true } // Pure joiners take any compatible host
                            return String(Self.deviceID(ofServiceName: endpoint.name)) < Self.deviceID // Tie-break: the lower device ID hosts
                        }
                        if let host {
                            return .finish(host)
                        }
                        return .continue
                    }
                joinConnection(NetworkConnection(to: endpoint, using: Self.connectionParameters))
            } catch {
                print("Browser stopped: \(error)")
            }
        }
    }
    func stopLookingToJoin() {
        browserTask?.cancel()
    }

    private func acceptConnection(_ connection: PeerConnection) {
        guard isHost || peers.isEmpty else { return } // Already joined another host; dropping the connection closes it
        print("Hosting peer: \(connection.id)")
        isHost = true
        stopLookingToJoin()
        addPeer(connection)
        // Send the current theme so the new screen matches the room
        peers[connection.id]?.outbox.yield(.config(Config(
            seed: system.seed,
            designPrinciples: system.design,
            primaryHue: system.colors.primaryHue,
            primarySaturation: system.colors.primarySaturation
        )))
        // ...then the current story position, so a device that (re)joins mid-show lands on the right chapter
        // instead of sitting on the default story screen until the next transition. Ordered after `.config`,
        // which rebuilds `ShipState` (and its story state) on the receiver before this applies.
        if let chapter = ShipState.shared.storyChapter {
            peers[connection.id]?.outbox.yield(.story(chapter, ShipState.shared.storyPatrolLine))
        }
    }

    private func joinConnection(_ connection: PeerConnection) {
        print("Joined host: \(connection.id)")
        isHost = false
        stopLookingToHost()
        addPeer(connection)
    }

    private func addPeer(_ connection: PeerConnection) {
        guard peers[connection.id] == nil else { return }

        let (outbox, outboxContinuation) = AsyncStream.makeStream(of: Message.self)
        let sendTask = Task {
            do {
                for await message in outbox {
                    try await connection.send(message)
                }
            } catch {
                removePeer(id: connection.id)
            }
        }
        let receiveTask = Task {
            do {
                for try await (message, _) in connection.messages {
                    receive(message: message, fromPeer: connection.id)
                }
            } catch {
                print("Peer connection ended: \(error)")
            }
            removePeer(id: connection.id)
        }
        connection.onStateUpdate { connection, state in
            switch state {
            case .failed, .cancelled, .waiting: // Waiting means the connect attempt failed; drop it and re-browse fresh endpoints
                self.removePeer(id: connection.id)
            default:
                break
            }
        }
        // Stale Bonjour endpoints can hang in .preparing forever; drop them so we re-browse
        let watchdogTask = Task {
            try? await Task.sleep(for: .seconds(10))
            if !Task.isCancelled, connection.state != .ready {
                removePeer(id: connection.id)
            }
        }
        peers[connection.id] = Peer(connection: connection, outbox: outboxContinuation, tasks: [sendTask, receiveTask, watchdogTask])
        connectedPeerIDs = Array(peers.keys)

        #if !os(tvOS) && !os(visionOS)
        if let tokenData = NearbyInteractionSessionController.shared.myDiscoveryTokenData {
            outboxContinuation.yield(.nearbyDiscoveryToken(tokenData))
        }
        #endif
    }

    private func removePeer(id: String) {
        guard let peer = peers.removeValue(forKey: id) else { return }
        print("Disconnected peer: \(id)")
        peer.outbox.finish()
        peer.tasks.forEach { $0.cancel() }
        connectedPeerIDs = Array(peers.keys)
        #if !os(tvOS) && !os(visionOS)
        NearbyInteractionSessionController.shared.disconnectedFromPeer(id)
        #endif
        if peers.isEmpty {
            // Look to re-pair, in case the host restarts or a new one appears
            lookToHost()
            lookToJoin()
        }
    }

    private func disconnectAll() {
        for id in Array(peers.keys) {
            removePeer(id: id)
        }
    }

    func send(message: Message) {
        for peer in peers.values {
            peer.outbox.yield(message)
        }
    }

    /// Passes a peer's message on to the rest of the room.
    ///
    /// Only the host relays, because it is the only device every other one is connected to — and never back to
    /// the sender, which is already there. Without this a change originating on a joiner (the story page's
    /// Start Engine press) would reach the host and stop. With one joiner there is nothing to relay to; this
    /// is what keeps a larger rig correct. See `Show/Docs/Show Setup.md`.
    private func relay(_ message: Message, from senderID: String) {
        guard isHost else { return }
        for (id, peer) in peers where id != senderID {
            peer.outbox.yield(message)
        }
    }

    func receiveConfig(_ config: Config) {
        // Apply without echoing back to the host, and without persisting — a received theme is the host's
        // for this session, not this device's launch default.
        AppController.shared.applyConfig(config, broadcast: false, persist: false)
        // A joiner never drives emergencies; drop any timer left over from when this device was hosting.
        AppController.shared.cancelEmergencyCountdown()
    }

    /// Applies a peer's message locally, then relays it onward if we are the host.
    ///
    /// Every case that changes shared state passes `source: .peer`, which is what stops the applying device
    /// announcing it again — the single rule described on `ChangeSource`. `.config` says the same thing in its
    /// own vocabulary (`broadcast: false`).
    private func receive(message: Message, fromPeer peerID: String) {
        switch message {
        case .config(let config):
            receiveConfig(config)
        case .nearbyDiscoveryToken(let data):
            #if !os(tvOS) && !os(visionOS)
            NearbyInteractionSessionController.shared.receiveDiscoveryTokenData(data, fromPeer: peerID)
            #endif
            return // Point-to-point pairing data, meaningless to a third device
        case .deviceDirection(let distance, let angle):
            #if !os(tvOS) && !os(visionOS)
            SpaceWindowCameraManager.shared.nearbyDeviceDirection = (distance: distance, angle: angle)
            #endif
            return // As above: this is the sender's bearing relative to us
        case .emergencyBegan(let reason, let puzzle):
            ShipState.shared.beginEmergency(reason: reason, puzzle: puzzle, source: .peer)
        case .emergencyEnded:
            ShipState.shared.endEmergency(source: .peer)
        case .story(let chapter, let patrolLine):
            ShipState.shared.applyStoryFromPeer(chapter: chapter, patrolLine: patrolLine)
        }
        relay(message, from: peerID)
    }

}
