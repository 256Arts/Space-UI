import SwiftUI

struct NavigationMapData {

    init(vid: Int) {
        // Seed generation from `vid` so the graph is deterministic: it stays identical
        // across every SwiftUI refresh (rather than regenerating a new random path each
        // body evaluation) and matches on devices sharing the seed.
        self.init(pieSlices: 10 + vid % 20, tracks: 5 + vid % 5, random: SeededRandom(seed: UInt64(bitPattern: Int64(vid))))
    }

    init(pieSlices: Int, tracks: Int, random: SeededRandom = SeededRandom(seed: 0)) {
        verticalLineSegmentsByAngle = Array(repeating: Array(repeating: false, count: tracks), count: pieSlices)

        func generateVerticalLineSegment(track: Int, outerTrackHasLine: Bool) -> Bool {
            let trackFraction = Double(track) / Double(tracks)
            // Range: 0.25..<(0.25 + 0.4)
            let chance = 0.2 + trackFraction * 0.4
            // If the outer track has a line, we have a higher change of generating a connecting line
            return random.nextFraction() < chance * (outerTrackHasLine ? 1.25 : 0.75)
        }
        
        for angleIndex in 0..<pieSlices {
            var outerTrackHasLine = true
            for trackIndex in stride(from: tracks-2, through: 0, by: -1) {
                let segmentExists = generateVerticalLineSegment(track: trackIndex, outerTrackHasLine: outerTrackHasLine)
                verticalLineSegmentsByAngle[angleIndex][trackIndex] = segmentExists
                outerTrackHasLine = segmentExists
            }
        }
        
        trackSegmentsByAngle = Array(repeating: [true] + Array(repeating: false, count: tracks - 1), count: pieSlices)
        
        for angleIndex in 0..<pieSlices {
            for trackIndex in 1..<tracks {
                let innerVertical = verticalLineSegmentsByAngle[angleIndex][trackIndex - 1]
                let outerVertical = verticalLineSegmentsByAngle[angleIndex][trackIndex]
                
                if innerVertical != outerVertical {
                    // A vertical line starts/ends here
                    // Randomly select a direction to generate a track line
                    let drawingClockwise = random.nextBool()
                    
                    // By default, track segments are drawn counter-clockwise from the angle index
                    // An adjustment is required to generate track segments going clockwise
                    let trackAngleDirectionAdjustment = drawingClockwise ? 1 : 0
                    
                    var currentAngleIndex = angleIndex
                    
                    while true {
                        var adjustedTrackAngleIndex = currentAngleIndex + trackAngleDirectionAdjustment
                        if adjustedTrackAngleIndex >= pieSlices {
                            adjustedTrackAngleIndex = 0
                        }
                        
                        trackSegmentsByAngle[adjustedTrackAngleIndex][trackIndex] = true
                        
                        currentAngleIndex += (drawingClockwise ? 1 : -1)
                        if currentAngleIndex < 0 {
                            currentAngleIndex = verticalLineSegmentsByAngle.endIndex - 1
                        } else if currentAngleIndex >= pieSlices {
                            currentAngleIndex = 0
                        }
                        
                        let neighborInnerVertical = verticalLineSegmentsByAngle[currentAngleIndex][trackIndex - 1]
                        let neighborOuterVertical = verticalLineSegmentsByAngle[currentAngleIndex][trackIndex]
                        
                        if neighborInnerVertical || neighborOuterVertical {
                            // The track ends touching another vertical line
                            // Stop generating track segments
                            break
                        }
                    }
                }
            }
        }
    }
    
    /*
     [
        // Index 0 = Pie slice 0
        // Line segments from track 0-2 and 3-4
        [true, true, false, true, false]
     ]
     */
    var verticalLineSegmentsByAngle: [[Bool]]
    
    var trackSegmentsByAngle: [[Bool]]
    
    func radius(track: Int, maxRadius: CGFloat) -> CGFloat {
        (CGFloat(track + 1) / CGFloat(verticalLineSegmentsByAngle.first!.count + 1)) * maxRadius
    }
    
    func angle(index: Int) -> CGFloat {
        2 * .pi * CGFloat(index) / CGFloat(verticalLineSegmentsByAngle.count)
    }
    
    func point(maxRadius: CGFloat, angleIndex: Int, track: Int) -> CGPoint {
        let radius = radius(track: track, maxRadius: maxRadius)
        let angle = angle(index: angleIndex)
        return CGPoint(x: radius * cos(angle), y: radius * sin(angle))
    }
    
}

/// A circular grid representing sectors of the galaxy
struct NavigationMapShape: Shape {
    
    let mapData: NavigationMapData
    
    func path(in rect: CGRect) -> Path {
        
        let bounds = min(rect.width, rect.height)
        let maxRadius = bounds / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        func point(angleIndex: Int, track: Int) -> CGPoint {
            let originRelativePoint = mapData.point(maxRadius: maxRadius, angleIndex: angleIndex, track: track)
            return CGPoint(x: originRelativePoint.x + rect.midX, y: originRelativePoint.y + rect.midY)
        }
        
        return Path { path in
            for (angleIndex, trackSegments) in mapData.trackSegmentsByAngle.enumerated() {
                for (track, segmentExists) in trackSegments.enumerated() {
                    if segmentExists {
                        let radius = mapData.radius(track: track, maxRadius: maxRadius)
                        
                        path.move(to: point(angleIndex: angleIndex - 1, track: track))
                        path.addArc(center: center, radius: radius, startAngle: .radians(mapData.angle(index: angleIndex - 1)), endAngle: .radians(mapData.angle(index: angleIndex)), clockwise: false)
                    }
                }
            }
            
            for (angleIndex, verticalLineSegments) in mapData.verticalLineSegmentsByAngle.enumerated() {
                path.move(to: point(angleIndex: angleIndex, track: 0))
                
                for (track, segmentExists) in verticalLineSegments.enumerated() {
                    if segmentExists {
                        path.addLine(to: point(angleIndex: angleIndex, track: track+1))
                    } else {
                        path.move(to: point(angleIndex: angleIndex, track: track+1))
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationMapShape(mapData: .init(vid: 1234))
}
