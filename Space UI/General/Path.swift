//
//  CGPath.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-15.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

extension Path {
    
    static func roundedPolygonPathPoints(in rect: CGRect, sides: Int, cornerRadius: CGFloat) -> [CGPoint] {
        // how much to turn at every corner
        let angle = 2.0 * CGFloat.pi / CGFloat(sides)
        // offset from which to start rounding corners
        let offset = cornerRadius * abs(tan(angle / 2.0))
        var points = [CGPoint]()
        let length = min(rect.size.width, rect.size.height)
        
        let triangleSizeCompensation = (sides == 3) ? length*0.16 : 0
        let triangleVerticalCenterCompensation = (sides == 3) ? -length*0.1 : 0
        let cornerRadiusSizeCompensation = cornerRadius * (2/CGFloat(sides))
        
        let circumradius = (length + cornerRadiusSizeCompensation + triangleSizeCompensation) / 2.0
        let center = CGPoint(x: rect.midX, y: rect.midY + triangleVerticalCenterCompensation)

        for side in 0..<sides {
            let angleToPoint = CGFloat(side) * angle
            let sharpX = center.x + circumradius * sin(angleToPoint)
            let sharpY = center.y + circumradius * cos(angleToPoint)
            if !cornerRadius.isZero {
                let angleFromPoint = (.pi - angle) / 2.0
                let roundedStartX = sharpX + offset * sin(.pi + angleToPoint + angleFromPoint)
                let roundedStartY = sharpY + offset * cos(.pi + angleToPoint + angleFromPoint)
                let roundedEndX = sharpX + offset * sin(.pi + angleToPoint - angleFromPoint)
                let roundedEndY = sharpY + offset * cos(.pi + angleToPoint - angleFromPoint)
            
                points.append(CGPoint(x: roundedStartX, y: roundedStartY))
                points.append(CGPoint(x: sharpX, y: sharpY))
                points.append(CGPoint(x: roundedEndX, y: roundedEndY))
            } else {
                points.append(CGPoint(x: sharpX, y: sharpY))
            }
        }
        return points
    }

    static func roundedPolygonPath(in rect: CGRect, sides: Int, cornerRadius: CGFloat, direction: ShapeDirection = system.shapeDirection) -> Path {
        var points = roundedPolygonPathPoints(in: rect, sides: sides, cornerRadius: cornerRadius)
//            let angle = CGFloat.pi/4
//            let pivot = CGPoint(x: length/2.0, y: length/2.0)
//            points = points.map({
//                let x = cos(angle) * ($0.x-pivot.x) - sin(angle) * ($0.y-pivot.y) + pivot.x
//                let y = sin(angle) * ($0.x-pivot.x) + cos(angle) * ($0.y-pivot.y) + pivot.x
//                return CGPoint(x: x, y: y)
//            }) // Rotate 45
        if direction == .down {
            switch sides {
            case 6: //.hexagon
                points = points.map({ CGPoint(x: $0.y, y: $0.x) }) // Rotate 90
            case 4: //.trapezoid, .triangle
                points = points.map({ CGPoint(x: $0.x, y: rect.maxY - $0.y) }) // Flip
            default:
                break
            }
        } else if sides == 3 {
            points = points.map({ CGPoint(x: $0.x, y: rect.maxY - $0.y) }) // Flip
        }
        return Path { path in
            path.move(to: points.last!)
            for _ in 0..<sides {
                path.addLine(to: points.removeFirst())
                if !cornerRadius.isZero {
                    path.addArc(tangent1End: points.removeFirst(), tangent2End: points.removeFirst(), radius: cornerRadius)
                }
            }
            path.closeSubpath()
        }
    }
    
    static func roundedRectPath(in rect: CGRect, leadingCornerRadius: CGFloat, trailingCornerRadius: CGFloat) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX + leadingCornerRadius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - trailingCornerRadius, y: rect.minY))
            path.addRelativeArc(center: CGPoint(x: rect.maxX - trailingCornerRadius, y: rect.minY + trailingCornerRadius), radius: trailingCornerRadius, startAngle: Angle(degrees: -90), delta: Angle(degrees: 90))
            
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - trailingCornerRadius))
            path.addRelativeArc(center: CGPoint(x: rect.maxX - trailingCornerRadius, y: rect.maxY - trailingCornerRadius), radius: trailingCornerRadius, startAngle: Angle.zero, delta: Angle(degrees: 90))
            
            path.addLine(to: CGPoint(x: rect.minX + leadingCornerRadius, y: rect.maxY))
            path.addRelativeArc(center: CGPoint(x: rect.minX + leadingCornerRadius, y: rect.maxY - leadingCornerRadius), radius: leadingCornerRadius, startAngle: Angle(degrees: 90), delta: Angle(degrees: 90))
            
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + leadingCornerRadius))
            path.addRelativeArc(center: CGPoint(x: rect.minX + leadingCornerRadius, y: rect.minY + leadingCornerRadius), radius: leadingCornerRadius, startAngle: Angle(degrees: 180), delta: Angle(degrees: 90))
        }
    }
    
}
