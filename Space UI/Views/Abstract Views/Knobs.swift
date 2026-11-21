import SwiftUI

struct Knobs: View {
    
    enum Design {
        case circle, line
    }
    
    let design: Design
    let angles: [Angle]
    
    @Environment(\.elementSize) private var elementSize
    @Environment(\.system) private var system
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
                            .foregroundColor(system.colors.color(.primary, brightness: .medium))
                    } else {
                        Circle()
                            .foregroundColor(system.colors.color(.primary, brightness: .min))
                    }
                    Capsule()
                        .foregroundColor(system.colors.color(.secondary, brightness: .max))
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
        let dRandom = SeededRandom(seed: UInt64(did))
        design = dRandom.nextWeightedElement(in: allDesigns, with: Space_UI.system.design)!
        
        let vRandom = SeededRandom(seed: UInt64(vid))
        angles = (0..<3).map { index in
            Angle(degrees: vRandom.nextDouble(in: 0..<360))
        }
    }
}

#Preview {
    Knobs(did: 0, vid: 0)
}
