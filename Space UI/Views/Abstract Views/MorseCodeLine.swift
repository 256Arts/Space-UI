import SwiftUI

// Example of what this looks like:
// [-----------]       [----]   [--]         [--------]

struct MorseCodeLine: View {
    
    @MainActor
    struct Segment: Identifiable {
        let id = UUID()
        let length: CGFloat
        let colorRole: ColorRole?
        let opacity: Opacity
        
        /// Takes the theme rather than reaching for the `system` global: a `Segment` is a plain value, so it has
        /// no environment of its own — the view that renders it does.
        func color(from system: SystemStyles) -> Color? {
            guard let sysColor = colorRole else { return nil }
            return system.colors.color(sysColor, opacity: opacity)
        }
    }
    
    nonisolated static func generateMorseCodeSegments(vid: Int, width: CGFloat, cornerStyle: CornerStyle) -> [MorseCodeLine.Segment] {
        let random = SeededRandom(seed: UInt64(vid))
        
        let useColorShades = random.nextBool()
        let shades: [Opacity] = [.low, .medium, .high, .max]
        var nodeLengths: [CGFloat] = [20, 20, 20, 40, 80, 120].filter { $0 < width }
        if cornerStyle != .circular {
            nodeLengths.append(10)
        }
        let spaceLengths: [CGFloat] = [20, 40, 80, 120, 160, 200].filter { $0 < width }
        
        var segs = [MorseCodeLine.Segment]()
        var sum: CGFloat = 0.0
        while sum < width {
            let opacity = useColorShades ? random.nextElement(in: shades)! : Opacity.max
            let colorRole: ColorRole = {
                // Intentionally non-deterministic: morse segments represent unreadable
                // temporary state, so the color roles don't need to be seeded or synced.
                switch Int.random(in: 0..<4) {
                case 0:
                    return .secondary
                case 1:
                    return .tertiary
                default:
                    return .primary
                }
            }()
            let nl = MorseCodeLine.Segment(length: random.nextElement(in: nodeLengths)!, colorRole: colorRole, opacity: opacity)
            let sl = MorseCodeLine.Segment(length: random.nextElement(in: spaceLengths)!, colorRole: nil, opacity: .min)
            segs.append(nl)
            segs.append(sl)
            sum += nl.length + sl.length
        }
        return segs
    }
    
    let height: CGFloat = 20.0
    let segments: [Segment]
    
    @Environment(\.system) private var system
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                ForEach(reduceSegments(forWidth: geometry.size.width)) { segment in
                    if let color = segment.color(from: system) {
                        RoundedRectangle(cornerRadius: system.cornerRadius(forLength: height))
                            .foregroundColor(system.prefersBorders ? .clear : color)
                            .frame(width: segment.length)
                            .overlay {
                                if system.prefersBorders {
                                    RoundedRectangle(cornerRadius: system.cornerRadius(forLength: height))
                                        .strokeBorder(color, style: system.strokeStyle(.thin))
                                        .frame(width: segment.length, height: height)
                                }
                            }
                    } else {
                        Spacer()
                            .frame(width: segment.length)
                    }
                }
            }
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
        .frame(height: height)
    }
    
    init(segments: [Segment]) {
        self.segments = segments
    }
    init(vid: Int) {
        self.segments = MorseCodeLine.generateMorseCodeSegments(vid: vid, width: 500, cornerStyle: Space_UI.system.cornerStyle)
    }
    
    func reduceSegments(forWidth width: CGFloat) -> [Segment] {
        var reducedSegments = [Segment]()
        var totalLength: CGFloat = 0.0
        for segment in segments {
            if totalLength + segment.length <= width {
                reducedSegments.append(segment)
                totalLength += segment.length
            } else {
                break
            }
        }
        return reducedSegments
    }
    
}

#Preview {
    MorseCodeLine(segments: screen.topMorseCodeSegments ?? [])
}
