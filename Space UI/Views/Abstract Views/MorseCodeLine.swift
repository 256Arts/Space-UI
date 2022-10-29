//
//  MorseCodeLine.swift
//  Space UI
//
//  Created by Jayden Irwin on 2020-11-02.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import SwiftUI

// Example of what this looks like:
// [-----------]       [----]   [--]         [--------]

struct MorseCodeLine: View {
    
    struct Segment: Identifiable {
        let id = UUID()
        let length: CGFloat
        let systemColor: SystemColor?
        let opacity: Opacity
        
        var color: Color? {
            guard let sysColor = systemColor else { return nil }
            return Color(color: sysColor, opacity: opacity)
        }
    }
    
    static func generateMorseCodeSegments(width: CGFloat, cornerStyle: CornerStyle) -> [MorseCodeLine.Segment] {
        let useColorShades = Bool.random()
        let shades: [Opacity] = [.low, .medium, .high, .max]
        var nodeLengths: [CGFloat] = [20, 20, 20, 40, 80, 120].filter { $0 < width }
        if cornerStyle != .circular {
            nodeLengths.append(10)
        }
        let spaceLengths: [CGFloat] = [20, 40, 80, 120, 160, 200].filter { $0 < width }
        
        var segs = [MorseCodeLine.Segment]()
        var sum: CGFloat = 0.0
        while sum < width {
            let opacity = useColorShades ? shades.randomElement()! : Opacity.max
            let systemColor: SystemColor = {
                switch Int.random(in: 0..<4) {
                case 0:
                    return .secondary
                case 1:
                    return .tertiary
                default:
                    return .primary
                }
            }()
            let nl = MorseCodeLine.Segment(length: nodeLengths.randomElement()!, systemColor: systemColor, opacity: opacity)
            let sl = MorseCodeLine.Segment(length: spaceLengths.randomElement()!, systemColor: nil, opacity: .min)
            segs.append(nl)
            segs.append(sl)
            sum += nl.length + sl.length
        }
        return segs
    }
    
    let height: CGFloat = 20.0
    let segments: [Segment]
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                ForEach(reduceSegments(forWidth: geometry.size.width)) { segment in
                    if let color = segment.color {
                        RoundedRectangle(cornerRadius: system.cornerRadius(forLength: height))
                            .foregroundColor(system.prefersBorders ? .clear : color)
                            .frame(width: segment.length)
                            .overlay(
                                system.prefersBorders ?
                                    RoundedRectangle(cornerRadius: system.cornerRadius(forLength: height))
                                        .strokeBorder(color, style: system.strokeStyle(.thin))
                                        .frame(width: segment.length, height: height)
                                : nil
                            )
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
        self.segments = MorseCodeLine.generateMorseCodeSegments(width: 500, cornerStyle: system.cornerStyle)
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

struct MorseCodeLine_Previews: PreviewProvider {
    static var previews: some View {
        MorseCodeLine(segments: system.screen.topMorseCodeSegments ?? [])
    }
}
