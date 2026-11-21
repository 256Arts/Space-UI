import SwiftUI

struct Target: Identifiable {
    var coord: CGPoint
    let isHostile: Bool
    var id: UUID { UUID() }
}

@MainActor @Observable
final class TargetState {
    
    var targetingSegment1 = false
    var targetingSegment2 = false
    var targetingSegment3 = false
    var targetingSegment4 = false
    var targets: [Target]
    
    /// Fully seeded: what we are tracking is shared simulation content, so the `targeting` page opens on the
    /// same targets — same count, same hostility — on every screen in the room.
    init(random: SeededRandom) {
        let targetCoords = PoissonDiskSampling.takeSamples(in: CGRect(x: -0.5, y: -0.5, width: 1, height: 1), inCircle: true, existingPoints: [], tryCount: random.nextInt(in: 0...20), minRadius: 0.1, random: random)
        targets = targetCoords.map({ Target(coord: $0, isHostile: random.nextBool()) })
    }

    /// Deliberately unseeded — ambient drift on a timer, with no shared clock to sync it to. See
    /// `ShipState.changeRandomStatus`.
    func simulateTargetMovement() {
        guard 0 < targets.count else { return }
        let index = Int.random(in: 0..<targets.count)
        targets[index].coord.x += CGFloat.random(in: -0.05...0.05)
        targets[index].coord.y += CGFloat.random(in: -0.05...0.05)
        
        let coord = targets[index].coord
        if coord.x < 0, 1 < coord.x, coord.y < 0, 1 < coord.y {
            targets.remove(at: index)
        }
        
        if ShipState.shared.powerState.weaponsHavePower {
            loop:
            for index in 0..<targets.count {
                if !targets[index].isHostile {
                    continue
                }
                switch targets[index].coord.x {
                case 0.0..<0.25:
                    if targetingSegment1 {
                        targets.remove(at: index) // Kill target
                        break loop
                    }
                case 0.25..<0.5:
                    if targetingSegment2 {
                        targets.remove(at: index) // Kill target
                        break loop
                    }
                case 0.5..<0.75:
                    if targetingSegment3 {
                        targets.remove(at: index) // Kill target
                        break loop
                    }
                default:
                    if targetingSegment4 {
                        targets.remove(at: index) // Kill target
                        break loop
                    }
                }
            }
        }
    }
}
