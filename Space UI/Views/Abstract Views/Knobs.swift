//
//  Knobs.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2022-10-07.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
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
        let dRandom: GKRandom = {
            let source = GKMersenneTwisterRandomSource(seed: UInt64(did))
            return GKRandomDistribution(randomSource: source, lowestValue: 0, highestValue: Int.max)
        }()
        design = dRandom.nextWeightedElement(in: allDesigns, with: system.design)!
        
        let vRandom: GKRandom = {
            let source = GKMersenneTwisterRandomSource(seed: UInt64(vid))
            return GKRandomDistribution(randomSource: source, lowestValue: 0, highestValue: Int.max)
        }()
        angles = (0..<3).map { index in
            Angle(degrees: vRandom.nextDouble(in: 0..<360))
        }
    }
}

#Preview {
    Knobs(did: 0, vid: 0)
}
