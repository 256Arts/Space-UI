import SwiftUI

struct PieSlice: Shape {
    
    let deltaAngle: Double
    let hasRadialLines: Bool
    
    func path(in rect: CGRect) -> Path {
        let startAngle = .pi*3/2 - deltaAngle/2.0
        let radius = min(rect.width, rect.height)/2
        let hypotX = radius * CGFloat(sin(deltaAngle/2.0))
        let hypotY = radius * CGFloat(cos(deltaAngle/2.0))
        let circleCenter = CGPoint(x: rect.midX, y: rect.midY)
        
        return Path { path in
            path.move(to: circleCenter)
            path.addLine(to: CGPoint(x: circleCenter.x - hypotX, y: circleCenter.y - hypotY))
            path.addRelativeArc(center: circleCenter, radius: radius, startAngle: Angle(radians: startAngle), delta: Angle(radians: deltaAngle))
            path.addLine(to: circleCenter)
            path.closeSubpath()
            
            if hasRadialLines {
                // Open arcs: closing them would draw a chord across the slice
                for fraction in [0.75, 0.5, 0.25] {
                    let arcRadius = radius * fraction
                    path.move(to: CGPoint(x: circleCenter.x - arcRadius * CGFloat(sin(deltaAngle/2.0)), y: circleCenter.y - arcRadius * CGFloat(cos(deltaAngle/2.0))))
                    path.addRelativeArc(center: circleCenter, radius: arcRadius, startAngle: Angle(radians: startAngle), delta: Angle(radians: deltaAngle))
                }
            }
        }
    }
}

#Preview {
    PieSlice(deltaAngle: .pi/2, hasRadialLines: false)
}
