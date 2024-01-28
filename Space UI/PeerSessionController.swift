//
//  PeerSessionController.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2018-03-31.
//  Copyright © 2018 256 Arts Developer. All rights reserved.
//

import MultipeerConnectivity

final class PeerSessionController: NSObject, ObservableObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    
    enum Message: Codable {
        case seed(UInt64), emergencyBegan, emergencyEnded
    }
    
    static let shared = PeerSessionController()
    static let serviceType = "ji-spaceui"
    
    let peerID = MCPeerID(displayName: UIDevice.current.name)
    var mcSession: MCSession
    var mcAdvertiser: MCNearbyServiceAdvertiser
    var mcBrowser: MCNearbyServiceBrowser
    var receivedInvitationSeed: UInt64?
    
    @Published var canHost = UserDefaults.standard.bool(forKey: UserDefaults.Key.canHostSession) {
        didSet {
            if !canHost, isHost {
                stopLookingToHost()
                mcSession.disconnect()
            }
            UserDefaults.standard.set(canHost, forKey: UserDefaults.Key.canHostSession)
        }
    }
    @Published var canJoin = UserDefaults.standard.bool(forKey: UserDefaults.Key.canJoinSession) {
        didSet {
            if !canJoin, !isHost {
                stopLookingToJoin()
                mcSession.disconnect()
            }
            UserDefaults.standard.set(canJoin, forKey: UserDefaults.Key.canJoinSession)
        }
    }
    var isHost = true
    
    override init() {
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .optional)
        mcAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: Self.serviceType)
        mcBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
        
        super.init()
        
        mcSession.delegate = self
        mcAdvertiser.delegate = self
        mcBrowser.delegate = self
    }
    
    func lookToJoin() {
        guard canJoin else { return }
        mcAdvertiser.startAdvertisingPeer()
    }
    func stopLookingToJoin() {
        mcAdvertiser.stopAdvertisingPeer()
    }
    
    func lookToHost() {
        guard canHost else { return }
        mcBrowser.startBrowsingForPeers()
    }
    func stopLookingToHost() {
        mcBrowser.stopBrowsingForPeers()
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            if !isHost, let seed = receivedInvitationSeed {
                receiveSeed(seed)
                receivedInvitationSeed = nil
            }
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            if isHost {
                stopLookingToJoin()
            }
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
        @unknown default:
            print("Unknown State: \(peerID.displayName)")
        }
    }
    
    func send(message: Message) {
        do {
            let data = try JSONEncoder().encode(message)
            try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
        } catch {
            print(error)
        }
    }
    
    func receiveSeed(_ seed: UInt64) {
        system = SystemStyles(seed: seed)
        AppController.shared.nextEmergencyTimer?.invalidate()
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = try? JSONDecoder().decode(Message.self, from: data) else {
            print("Failed to decode message")
            return
        }
        switch message {
        case .seed(let seed):
            receiveSeed(seed)
        case .emergencyBegan:
            ShipData.shared.beginEmergency()
        case .emergencyEnded:
            ShipData.shared.endEmergency()
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        isHost = false
        if let context = context {
            receivedInvitationSeed = try? JSONDecoder().decode(UInt64.self, from: context)
        }
        invitationHandler(true, mcSession)
        stopLookingToHost()
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        let contextData = try? JSONEncoder().encode(system.seed)
        browser.invitePeer(peerID, to: mcSession, withContext: contextData, timeout: 0)
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
    }
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print(error.localizedDescription)
        print("\"Jump to definition\" of \"CFNetServicesError\" to see the error reason.")
    }
    
}
