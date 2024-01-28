//
//  PieSlice.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-01-18.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct PieSlice: Shape {
    
    let deltaAngle: Double
    let hasRadialLines: Bool
    
    func path(in rect: CGRect) -> Path {
        let startAngle = .pi*3/2 - deltaAngle/2.0
        let radius = min(rect.width, rect.height)/2
        let hypotX = radius * CGFloat(sin(deltaAngle/2.0))
        let hypotY = radius * CGFloat(cos(deltaAngle/2.0))
        let circleCenter = CGPoint(x: rect.midX, y: rect.maxY)
        
        return Path { path in
            path.move(to: circleCenter)
            path.addLine(to: CGPoint(x: circleCenter.x - hypotX, y: circleCenter.y - hypotY))
            path.addRelativeArc(center: circleCenter, radius: radius, startAngle: Angle(radians: startAngle), delta: Angle(radians: deltaAngle))
            path.addLine(to: circleCenter)
            path.closeSubpath()
            
            if hasRadialLines {
                path.addRelativeArc(center: circleCenter, radius: radius * 0.75, startAngle: Angle(radians: startAngle), delta: Angle(radians: deltaAngle))
                path.closeSubpath()
                path.addRelativeArc(center: circleCenter, radius: radius * 0.5, startAngle: Angle(radians: startAngle), delta: Angle(radians: deltaAngle))
                path.closeSubpath()
                path.addRelativeArc(center: circleCenter, radius: radius * 0.25, startAngle: Angle(radians: startAngle), delta: Angle(radians: deltaAngle))
                path.closeSubpath()
            }
        }
    }
}

#Preview {
    PieSlice(deltaAngle: .pi/2, hasRadialLines: false)
}
