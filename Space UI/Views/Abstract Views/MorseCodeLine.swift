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
        MorseCodeLine(segments: system.topMorseCodeSegments ?? [])
    }
}
