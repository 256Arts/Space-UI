//
//  Shape.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-15.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct Triangle: Shape {
    
    @Environment(\.shapeDirection) var direction: ShapeDirection
    
    let overrideDirection: ShapeDirection?
    
    init(overrideDirection: ShapeDirection? = nil) {
        self.overrideDirection = overrideDirection
    }
    
    func path(in rect: CGRect) -> Path {
        let cornerRadius = system.cornerRadius(forLength: min(rect.width, rect.height), cornerStyle: .rounded)
        return Path.roundedPolygonPath(in: rect, sides: 3, cornerRadius: cornerRadius, direction: overrideDirection ?? direction)
    }
}

struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let cornerRadius = system.cornerRadius(forLength: min(rect.width, rect.height)/2, cornerStyle: .rounded)
        return Path.roundedPolygonPath(in: rect, sides: 6, cornerRadius: cornerRadius)
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        let cornerRadius = system.cornerRadius(forLength: min(rect.width, rect.height)*0.7, cornerStyle: .rounded)
        return Path.roundedPolygonPath(in: rect, sides: 4, cornerRadius: cornerRadius)
    }
}

struct AutoShape: InsettableShape {
    
    let direction: ShapeDirection
    var insetAmount: CGFloat = 0.0
    
    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        switch system.basicShape {
        case .circle:
            return Circle().path(in: insetRect)
        case .diamond:
            return Diamond().path(in: insetRect)
        case .hexagon:
            return Hexagon().path(in: insetRect)
        case .square:
            let cornerStyle = system.changeSquareButtonToRect ? system.cornerStyle : CornerStyle.rounded
            let cornerRadius = system.cornerRadius(forLength: min(insetRect.width, insetRect.height), cornerStyle: cornerStyle)
            return RoundedRectangle(cornerRadius: cornerRadius).path(in: insetRect)
        case .trapezoid:
            return Trapezoid(overrideDirection: direction).path(in: insetRect)
        case .triangle:
            return Triangle(overrideDirection: direction).path(in: insetRect)
        }
    }
    
    func inset(by amount: CGFloat) -> some InsettableShape {
        var arc = self
        arc.insetAmount += amount
        return arc
    }
}

#Preview {
    AutoShape(direction: .up).frame(width: 100, height: 100, alignment: .center)
}
