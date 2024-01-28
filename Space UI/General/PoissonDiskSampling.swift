//
//  PoissonDiskSampling.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-01-01.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import CoreGraphics
import GameplayKit

struct PoissonDiskSampling {
    
    static func samples(in rect: CGRect, inCircle: Bool, staticPoint: CGPoint?, candidatePointCount: Int, rejectRadius: CGFloat, random: GKRandom) -> [CGPoint] {
        let circleRadius = min(rect.width, rect.height)/2
        var candidatePoints = [CGPoint]()
        var acceptedPoints = [CGPoint]()
        if let sp = staticPoint {
            acceptedPoints.append(sp)
        }
        for _ in 0..<candidatePointCount {
            candidatePoints.append(CGPoint(x: CGFloat(random.nextDouble(in: Double(rect.minX)...Double(rect.maxX))), y: CGFloat(random.nextDouble(in: Double(rect.minY)...Double(rect.maxY)))))
        }
        
        loop:
        for candidate in candidatePoints {
            if inCircle {
                let distance = sqrt(pow(rect.midX - candidate.x, 2) + pow(rect.midY - candidate.y, 2))
                if circleRadius < distance {
                    continue loop
                }
            }
            for accepted in acceptedPoints {
                let distance = sqrt(pow(accepted.x - candidate.x, 2) + pow(accepted.y - candidate.y, 2))
                if distance < rejectRadius {
                    continue loop
                }
            }
            acceptedPoints.append(candidate)
        }
        
        return acceptedPoints
    }
    
}
