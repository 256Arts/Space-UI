//
//  NearbyShipsState.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-08-10.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI
import GameplayKit

struct NearbyShip: Identifiable {
    var coord: CGPoint
    var rotation: Angle
    let isLarge: Bool
    var id: UUID { UUID() }
}
final class NearbyShipsState: ObservableObject {
    @Published var nearbyShips: [NearbyShip]
    
    init(random: GKRandom) {
        let nearbyShipCoords = PoissonDiskSampling.samples(in: CGRect(x: -0.5, y: -0.5, width: 1, height: 1), inCircle: true, staticPoint: .zero, candidatePointCount: 3, rejectRadius: 0.2, random: random).filter({ $0 != .zero })
        nearbyShips = nearbyShipCoords.map({ NearbyShip(coord: $0, rotation: Angle(degrees: Double.random(in: 0..<360)), isLarge: Int.random(in: 0..<3) == 0) })
    }
}
