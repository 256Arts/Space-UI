//
//  Trapezoid.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-01-02.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct Trapezoid: Shape {
    
    @Environment(\.shapeDirection) var direction: ShapeDirection
    
    let overrideDirection: ShapeDirection?
    
    init(overrideDirection: ShapeDirection? = nil) {
        self.overrideDirection = overrideDirection
    }
    
    func roundedTrapezoidPathPoints(in rect: CGRect, topSideLength: CGFloat? = nil, cornerRadius: CGFloat) -> [CGPoint] {
        var points = [CGPoint]()
        let topSideLength = topSideLength ?? rect.size.width/2
        let topLeadingSpace = (rect.size.width - topSideLength)/2
        let riseOverRun = rect.size.height / topLeadingSpace
        let angle = atan(riseOverRun)
        let topOffset = cornerRadius * abs(tan(angle / 2.0))
        let bottomOffset = cornerRadius * abs(tan((.pi + angle) / 2.0))
        
        let topOffsetXComponent = topOffset * cos(angle)
        let topOffsetYComponent = topOffset * sin(angle)
        let bottomOffsetXComponent = bottomOffset * cos(angle)
        let bottomOffsetYComponent = -bottomOffset * sin(angle)
        
        // Start at bottom right and go up
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        if !cornerRadius.isZero {
            points.append(CGPoint(x: bottomRight.x - bottomOffset - cornerRadius, y: bottomRight.y))
            points.append(bottomRight)
            points.append(CGPoint(x: bottomRight.x - bottomOffsetXComponent, y: bottomRight.y + bottomOffsetYComponent))
        } else {
            points.append(bottomRight)
        }
        
        let topRight = CGPoint(x: rect.maxX - topLeadingSpace, y: rect.minY)
        if !cornerRadius.isZero {
            points.append(CGPoint(x: topRight.x + topOffsetXComponent, y: topRight.y + topOffsetYComponent))
            points.append(topRight)
            points.append(CGPoint(x: topRight.x - topOffset, y: topRight.y))
        } else {
            points.append(topRight)
        }
        
        let topLeft = CGPoint(x: rect.minX + topLeadingSpace, y: rect.minY)
        if !cornerRadius.isZero {
            points.append(CGPoint(x: topLeft.x + topOffset, y: topLeft.y))
            points.append(topLeft)
            points.append(CGPoint(x: topLeft.x - topOffsetXComponent, y: topLeft.y + topOffsetYComponent))
        } else {
            points.append(topLeft)
        }
        
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        if !cornerRadius.isZero {
            points.append(CGPoint(x: bottomLeft.x + bottomOffsetXComponent, y: bottomLeft.y + bottomOffsetYComponent))
            points.append(bottomLeft)
            points.append(CGPoint(x: bottomLeft.x + bottomOffset + cornerRadius, y: bottomLeft.y))
        } else {
            points.append(bottomLeft)
        }
        
        if overrideDirection ?? direction == .down {
            return points.map({ CGPoint(x: $0.x, y: rect.maxY - $0.y) }) // Flip
        }
        return points
    }
    
    func path(in rect: CGRect) -> Path {
        let cornerRadius = system.cornerRadius(forLength: rect.width/2, cornerStyle: .rounded)
        var points = roundedTrapezoidPathPoints(in: rect, cornerRadius: cornerRadius)
        
        return Path { path in
            path.move(to: points.last!)
            for _ in 0..<4 {
                path.addLine(to: points.removeFirst())
                if !cornerRadius.isZero {
                    path.addArc(tangent1End: points.removeFirst(), tangent2End: points.removeFirst(), radius: cornerRadius)
                }
            }
            path.closeSubpath()
        }
    }
    
}

#Preview {
    Trapezoid().stroke()
}
