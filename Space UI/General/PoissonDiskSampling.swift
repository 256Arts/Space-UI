import CoreGraphics

/// Generate points in a circle/rect that are a minimum distance from other existing points
enum PoissonDiskSampling {
    
    static func takeSample(in rect: CGRect, inCircle: Bool, existingPoints: [CGPoint], minRadius: CGFloat, random: SeededRandom) -> CGPoint? {
        let circleRadius = min(rect.width, rect.height)/2
        let candidate = CGPoint(x: CGFloat(random.nextDouble(in: Double(rect.minX)...Double(rect.maxX))), y: CGFloat(random.nextDouble(in: Double(rect.minY)...Double(rect.maxY))))
        
        if inCircle {
            let distanceFromCenter = sqrt(pow(rect.midX - candidate.x, 2) + pow(rect.midY - candidate.y, 2))
            if circleRadius < distanceFromCenter {
                return nil
            }
        }
        for existingPoint in existingPoints {
            let distance = sqrt(pow(existingPoint.x - candidate.x, 2) + pow(existingPoint.y - candidate.y, 2))
            if distance < minRadius {
                return nil
            }
        }
        
        return candidate
    }
    
    static func takeSamples(in rect: CGRect, inCircle: Bool, existingPoints: [CGPoint], tryCount: Int, minRadius: CGFloat, random: SeededRandom) -> [CGPoint] {
        var samples: [CGPoint] = []
        var existingPoints = existingPoints

        // Bound the attempts: once the disk saturates, no candidate ever clears `minRadius` and an unbounded
        // loop freezes the main thread. Return whatever we managed to place.
        var attemptsRemaining = tryCount * 100
        while samples.count < tryCount, attemptsRemaining > 0 {
            attemptsRemaining -= 1
            if let sample = takeSample(in: rect, inCircle: inCircle, existingPoints: existingPoints, minRadius: minRadius, random: random) {
                samples.append(sample)
                existingPoints.append(sample)
            }
        }

        return samples
    }
    
}
