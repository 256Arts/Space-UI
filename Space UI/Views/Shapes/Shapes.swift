import SwiftUI

struct Triangle: Shape {

    @Environment(\.shapeDirection) var direction: ShapeDirection

    let roundedCornerFraction: CGFloat
    let overrideDirection: ShapeDirection?

    init(roundedCornerFraction: CGFloat, overrideDirection: ShapeDirection? = nil) {
        self.roundedCornerFraction = roundedCornerFraction
        self.overrideDirection = overrideDirection
    }

    func path(in rect: CGRect) -> Path {
        let cornerRadius = min(rect.width, rect.height) * roundedCornerFraction
        return Path.roundedPolygonPath(in: rect, sides: 3, cornerRadius: cornerRadius, direction: overrideDirection ?? direction)
    }
}

struct Hexagon: Shape {

    let roundedCornerFraction: CGFloat
    let shapeDirection: ShapeDirection

    func path(in rect: CGRect) -> Path {
        let cornerRadius = (min(rect.width, rect.height) / 2) * roundedCornerFraction
        return Path.roundedPolygonPath(in: rect, sides: 6, cornerRadius: cornerRadius, direction: shapeDirection)
    }
}

struct Diamond: Shape {

    let roundedCornerFraction: CGFloat
    let shapeDirection: ShapeDirection

    func path(in rect: CGRect) -> Path {
        let cornerRadius = (min(rect.width, rect.height) * 0.7) * roundedCornerFraction
        return Path.roundedPolygonPath(in: rect, sides: 4, cornerRadius: cornerRadius, direction: shapeDirection)
    }
}

struct AutoShape: InsettableShape {

    let system: SystemStyles
    let direction: ShapeDirection
    var insetAmount: CGFloat = 0.0

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        switch system.basicShape {
        case .circle:
            return Circle().path(in: insetRect)
        case .diamond:
            return Diamond(roundedCornerFraction: system.roundedCornerFraction, shapeDirection: system.shapeDirection).path(in: insetRect)
        case .hexagon:
            return Hexagon(roundedCornerFraction: system.roundedCornerFraction, shapeDirection: system.shapeDirection).path(in: insetRect)
        case .square:
            let cornerStyle = system.changeSquareButtonToRect ? system.cornerStyle : CornerStyle.rounded
            let cornerRadius = system.cornerRadius(forLength: min(insetRect.width, insetRect.height), cornerStyle: cornerStyle)
            return RoundedRectangle(cornerRadius: cornerRadius).path(in: insetRect)
        case .trapezoid:
            return Trapezoid(system: system, overrideDirection: direction).path(in: insetRect)
        case .triangle:
            return Triangle(roundedCornerFraction: system.roundedCornerFraction, overrideDirection: direction).path(in: insetRect)
        }
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var arc = self
        arc.insetAmount += amount
        return arc
    }
}

#Preview {
    AutoShape(system: system, direction: .up).frame(width: 100, height: 100, alignment: .center)
}
