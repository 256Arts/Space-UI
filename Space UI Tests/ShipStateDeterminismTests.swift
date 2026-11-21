//
//  Created by 256 Arts Developer on 2026-08-17.
//

import Testing
@testable import Space_UI

/// The simulation half of the cross-device invariant that `SeedDeterminismTests` covers for the theme: a room of
/// screens rebuilt from one `Config` must be looking at the *same ship* — same neighbours on the `nearby` page,
/// same targets on `targeting`. These are drawn from `ShipState`'s single seeded generator, and every one of them
/// used to come from `Int.random`, so each screen invented its own. A regression here is invisible on one device.
@MainActor
struct ShipStateDeterminismTests {

    @Test(arguments: TestSeeds.representative)
    func nearbyShipsAreDeterministic(seed: UInt64) {
        let a = ShipState(seed: seed, inStoryMode: false).nearbyShipsState.nearbyShips
        let b = ShipState(seed: seed, inStoryMode: false).nearbyShipsState.nearbyShips

        #expect(a.count == b.count)
        for (shipA, shipB) in zip(a, b) {
            #expect(shipA.coord == shipB.coord)
            #expect(shipA.rotation == shipB.rotation)
            #expect(shipA.isLarge == shipB.isLarge)
            #expect(shipA.imageName == shipB.imageName)
        }
    }

    @Test(arguments: TestSeeds.representative)
    func targetsAreDeterministic(seed: UInt64) {
        let a = ShipState(seed: seed, inStoryMode: false).targetState.targets
        let b = ShipState(seed: seed, inStoryMode: false).targetState.targets

        #expect(a.count == b.count)
        for (targetA, targetB) in zip(a, b) {
            #expect(targetA.coord == targetB.coord)
            #expect(targetA.isHostile == targetB.isHostile)
        }
    }

    /// `icon` is an `Image` and can't be compared, but the ship removes its own icon from the pool it hands the
    /// enemies, so the remaining list is a faithful proxy for which icon was picked.
    @Test(arguments: TestSeeds.representative)
    func shipIconIsDeterministic(seed: UInt64) {
        let a = ShipState(seed: seed, inStoryMode: false)
        let b = ShipState(seed: seed, inStoryMode: false)

        #expect(a.enemyStarshipIconNames == b.enemyStarshipIconNames)
        #expect(a.enemyStarshipIconNames.count == ShipState.starshipIconNames.count - 1)
    }

    /// Different seeds must actually diverge — a generator that ignored its seed would pass every test above.
    @Test
    func differentSeedsProduceDifferentShips() {
        let ships = TestSeeds.representative.map {
            ShipState(seed: $0, inStoryMode: false).nearbyShipsState.nearbyShips.map(\.coord)
        }
        #expect(Set(ships.map(String.init(describing:))).count > 1)
    }
}
