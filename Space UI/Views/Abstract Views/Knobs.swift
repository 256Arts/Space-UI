//
//  Knobs.swift
//  Space UI
//
//  Created by Jayden Irwin on 2022-10-07.
//  Copyright © 2022 Jayden Irwin. All rights reserved.
//

import SwiftUI
import GameplayKit

struct Knobs: View {
    
    enum Design {
        case circle, line
    }
    
    let design: Design
    let angles: [Angle]
    
    @Environment(\.elementSize) private var elementSize
    var knobCount: Int {
        switch elementSize {
        case .mini:
            return 1
        case .small:
            return 2
        case .regular, .large:
            return 3
        }
    }
    
    var body: some View {
        HStack {
            ForEach(angles.prefix(knobCount), id: \.radians) { angle in
                ZStack {
                    if system.prefersBorders {
                        Circle()
                            .strokeBorder(style: system.strokeStyle(.thin))
                            .foregroundColor(Color(color: .primary, brightness: .medium))
                    } else {
                        Circle()
                            .foregroundColor(Color(color: .primary, brightness: .min))
                    }
                    Capsule()
                        .foregroundColor(Color(color: .secondary, brightness: .max))
                        .frame(width: design == .circle ? 13 : system.mediumLineWidth, height: design == .circle ? 13 : 20)
                        .offset(y: -11)
                }
                .frame(width: 44, height: 44)
                .rotationEffect(angle)
            }
        }
    }
    
    init(did: Int, vid: Int) {
        let allDesigns: [WeightedDesignElement<Design>] = [
            .init(baseWeight: 1, design: .init(simplicity: 1, sharpness: 0), element: .circle),
            .init(baseWeight: 1, design: .init(simplicity: 0.7, sharpness: 0.7), element: .line)
        ]
        let random: GKRandom = {
            let source = GKMersenneTwisterRandomSource(seed: seed)
            return GKRandomDistribution(randomSource: source, lowestValue: 0, highestValue: Int.max)
        }()
        design = random.nextWeightedElement(in: allDesigns, with: system.design)!
        angles = (0..<3).map { index in
            Angle(degrees: random.nextDouble(in: 0..<360))
        }
    }
}

struct Knobs_Previews: PreviewProvider {
    static var previews: some View {
        Knobs(did: 0, vid: 0)
    }
}
