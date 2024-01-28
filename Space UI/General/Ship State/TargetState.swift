//
//  Target.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-08-10.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI
import GameplayKit

struct Target: Identifiable {
    var coord: CGPoint
    let isHostile: Bool
    var id: UUID { UUID() }
}
final class TargetState: ObservableObject {
    @Published var targetingSegment1 = false
    @Published var targetingSegment2 = false
    @Published var targetingSegment3 = false
    @Published var targetingSegment4 = false
    @Published var targets: [Target]
    
    init(random: GKRandom) {
        let targetCoords = PoissonDiskSampling.samples(in: CGRect(x: -0.5, y: -0.5, width: 1, height: 1), inCircle: true, staticPoint: nil, candidatePointCount: Int.random(in: 0...20), rejectRadius: 0.1, random: random)
        targets = targetCoords.map({ Target(coord: $0, isHostile: Bool.random()) })
    }
    
    func simulateTargetMovement() {
        guard 0 < targets.count else { return }
        let index = Int.random(in: 0..<targets.count)
        targets[index].coord.x += CGFloat.random(in: -0.05...0.05)
        targets[index].coord.y += CGFloat.random(in: -0.05...0.05)
        
        let coord = targets[index].coord
        if coord.x < 0, 1 < coord.x, coord.y < 0, 1 < coord.y {
            targets.remove(at: index)
        }
        
        if ShipData.shared.powerState.weaponsHavePower {
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
