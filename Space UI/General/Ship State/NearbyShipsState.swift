import SwiftUI

final class NearbyShip: Identifiable {
    var coord: CGPoint
    var rotation: Angle
    var isApproachingViaHyperspace: Bool
    var isHostile: Bool
    let isLarge: Bool
    let imageName: String
    var id: UUID { UUID() }
    
    init(coord: CGPoint, rotation: Angle, isApproachingViaHyperspace: Bool, isHostile: Bool, isLarge: Bool, imageName: String) {
        self.coord = coord
        self.rotation = rotation
        self.isApproachingViaHyperspace = isApproachingViaHyperspace
        self.isHostile = isHostile
        self.isLarge = isLarge
        self.imageName = imageName
    }
}

@MainActor @Observable
final class NearbyShipsState {
    
    var nearbyShips: [NearbyShip]
    
    init(random: SeededRandom, inStoryMode: Bool, enemyCommandShipIconNames: [String], enemyStarshipIconNames: [String]) {
        if inStoryMode {
            let nearbyShipCoords = [
                CGPoint(x: 0, y: -0.25),
                CGPoint(x: -0.25, y: -0.4),
                CGPoint(x: 0.25, y: -0.35)
            ]
            nearbyShips = nearbyShipCoords.map({ NearbyShip(coord: $0, rotation: .degrees(180), isApproachingViaHyperspace: true, isHostile: true, isLarge: true, imageName: "Destroyer Up") })
        } else {
            let nearbyShipCoords = PoissonDiskSampling.takeSamples(in: CGRect(x: -0.5, y: -0.5, width: 1, height: 1), inCircle: true, existingPoints: [.zero], tryCount: 3, minRadius: 0.2, random: random)
            // Seeded, like the coordinates above: the ships around us are shared simulation content, so the
            // `nearby` page shows the same neighbours in the same attitude on every screen in the room.
            nearbyShips = nearbyShipCoords
                .map {
                    let isLarge = random.nextInt(in: 0..<3) == 0
                    return NearbyShip(
                        coord: $0,
                        rotation: Angle(degrees: random.nextDouble(in: 0..<360)),
                        isApproachingViaHyperspace: false,
                        isHostile: false,
                        isLarge: isLarge,
                        imageName: random.nextElement(
                            in: isLarge ? enemyCommandShipIconNames : enemyStarshipIconNames
                        )!
                    )
                }
        }
    }
    
    /// Creates an approaching ship
    func spawn(hostile: Bool) {
        let enemy: NearbyShip? = {
            let random = SeededRandom(seed: seed)

            // Bound the search: once the radar disk is full, no free coordinate exists and an unbounded loop
            // would freeze the main thread. Give up and skip this spawn rather than hang the show.
            for _ in 0..<100 {
                if let coord = PoissonDiskSampling.takeSample(in: CGRect(x: -0.5, y: -0.5, width: 1, height: 1), inCircle: true, existingPoints: nearbyShips.map({ $0.coord }), minRadius: 0.2, random: random) {
                    let isLarge = Int.random(in: 0..<3) == 0
                    return NearbyShip(
                        coord: coord,
                        rotation: Angle(degrees: Double.random(in: 0..<360)),
                        isApproachingViaHyperspace: true,
                        isHostile: hostile,
                        isLarge: isLarge,
                        imageName: (
                            isLarge ? ShipState.shared.enemyCommandShipIconNames : ShipState.shared.enemyStarshipIconNames
                        )
                        .randomElement()!
                    )
                }
            }
            return nil
        }()
        guard let enemy else { return }
        nearbyShips.append(enemy)
        #if !os(tvOS)
        MetalRenderer.shared?.scene.enterEnemies()
        #endif
    }
    
    /// Update approaching ships, to now arrived
    func finishJumps() {
        for ship in nearbyShips {
            ship.isApproachingViaHyperspace = false
        }
    }
    
    func hostilesExit() {
        nearbyShips = nearbyShips.filter({ !$0.isHostile })
        #if !os(tvOS)
        MetalRenderer.shared?.scene.exitEnemies(animated: true)
        #endif
    }
}
