import SwiftUI
import Synchronization

extension CutoutStyle {
    /// Total horizontal length the two transition curves (leading + trailing) consume around a cutout's straight
    /// content span, as a function of cutout height. Single source of truth: `ScreenShape` draws the transitions
    /// from this and `ScreenStyles.CutoutLayout` sizes the reported cutout frame from it, so the two can't drift.
    func totalTransitionWidth(cutoutHeight: CGFloat) -> CGFloat {
        switch self {
        case .angle45:
            return cutoutHeight * 2.0
        case .roundedAngle45:
            let radius = cutoutHeight
            let betweenCenters = (1 + cos(.pi / 4)) * radius
            return betweenCenters * 2.0
        case .halfRounded:
            return cutoutHeight * 2.0
        case .roundedRectangle:
            return cutoutHeight * 2.0
        case .curved:
            return cutoutHeight * 4.0
        case .none:
            return 0.0
        }
    }
}

final class PathCache: Sendable {
    // The key captures the theme generation, so entries can never go stale; this cap just
    // bounds memory during live resize, which inserts a fresh Path every frame. Sized
    // independently of AudioVisualizerModelCache — different key space, more live keys here.
    private static let maxEntries = 32
    private let storage = Mutex<[ScreenShape.LayoutConfig: Path]>([:])

    subscript(key: ScreenShape.LayoutConfig) -> Path? {
        get { storage.withLock { $0[key] } }
        set {
            storage.withLock { dictionary in
                if dictionary.count >= Self.maxEntries {
                    dictionary.removeAll(keepingCapacity: true)
                }
                dictionary[key] = newValue
            }
        }
    }

    func removeAll() {
        storage.withLock { $0.removeAll(keepingCapacity: true) }
    }
}

struct ScreenShape: InsettableShape {
    
    struct LayoutConfig: Hashable {
        let rect: CGRect
        let connectedEdges: [RectEdge]
        let insetAmount: CGFloat
        // Shape type and theme generation are part of the identity: without them a cached path
        // would be reused after a theme change that kept the same rect/edges/inset.
        let screenShapeType: ScreenShapeType
        let themeGeneration: UInt64

        public func hash(into hasher: inout Hasher) {
            hasher.combine(rect.origin.x)
            hasher.combine(rect.origin.y)
            hasher.combine(rect.size.width)
            hasher.combine(rect.size.height)
            hasher.combine(connectedEdges)
            hasher.combine(insetAmount)
            hasher.combine(screenShapeType)
            hasher.combine(themeGeneration)
        }
    }
    
    static let cutoutHeight: CGFloat = 50.0
    static let hardwareCornerRadius: CGFloat = 44.0
    static let pathCache = PathCache()
    
    static func cornerRadius(rect: CGRect, insetAmount: CGFloat, screenShapeType: ScreenShapeType, system: SystemStyles) -> CGFloat {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let regularRadius = system.cornerRadius(forLength: min(rect.width, rect.height))
        if regularRadius.isZero {
            return 0.0
        } else if screenShapeType == .capsule {
            return system.cornerRadius(forLength: min(insetRect.width, insetRect.height), cornerStyle: .circular)
        } else if system.cornerStyle == .circular {
            // Use rounded corner style instead
            return system.cornerRadius(forLength: min(rect.width, rect.height), cornerStyle: .rounded) - insetAmount * 2.0
        } else {
            return max(Self.hardwareCornerRadius, (regularRadius / 2.0)) - insetAmount * 2.0
        }
    }
    
    static func screenTrapezoidOrHexagonCornerOffset(screenSize: CGSize, insetAmount: CGFloat = 0.0) -> CGFloat {
        max(Self.hardwareCornerRadius, screenSize.width/8) - insetAmount/2
    }
    
    let system: SystemStyles
    let screenStyles: ScreenStyles
    var screenShapeType: ScreenShapeType
    var connectedEdges: [RectEdge]
    var insetAmount: CGFloat = 0.0
    
    func cutoutPoints(style: CutoutStyle, length: CGFloat, cutoutHeight: CGFloat) -> [CGPoint] {

        let straightLength = length - style.totalTransitionWidth(cutoutHeight: cutoutHeight)
        var points = [CGPoint]()
        var point = CGPoint.zero
        
        switch style {
        case .angle45:
            point.x += cutoutHeight
            point.y += cutoutHeight
            points.append(point)
            point.x += straightLength
            points.append(point)
            point.x += cutoutHeight
            point.y -= cutoutHeight
            points.append(point)
        case .roundedAngle45:
            let radius = cutoutHeight
            let betweenCenters = (1 + cos(.pi/4)) * radius
            point.y += radius
            points.append(point)
            point.x += betweenCenters
            point.y -= radius
            points.append(point)
            point.y += radius
            point.x += straightLength
            points.append(point)
            point.y -= radius
            points.append(point)
            point.x += betweenCenters
            point.y += radius
            points.append(point)
        case .halfRounded:
            let radius = cutoutHeight
            point.x += radius
            points.append(point)
            point.y += radius
            point.x += straightLength
            points.append(point)
            point.y -= radius
            points.append(point)
        case .roundedRectangle:
            let radius = cutoutHeight / 2.0
            point.y += radius
            points.append(point)
            point.x += radius * 2.0
            points.append(point)
            point.y += radius
            point.x += straightLength
            points.append(point)
            point.y -= radius
            points.append(point)
            point.x += radius * 2.0
            points.append(point)
        case .curved:
            var start = point
            point.y += cutoutHeight
            point.x += cutoutHeight
            var control = point
            point.x += cutoutHeight
            points.append(point)
            points.append(control)
            point.x += straightLength
            start.x += straightLength + 4*cutoutHeight
            control.x += straightLength + 2*cutoutHeight
            points.append(point)
            points.append(start)
            points.append(control)
        case .none:
            point.x += straightLength
            points.append(point)
        }
        return points
    }
    
    // MARK: - Cutouts

    /// Draws one edge's straight run, its cutout, and the straight run on the far side, leaving `point` at the end.
    ///
    /// The two edges are the same cutout rotated a half turn: the bottom is walked leading-to-trailing in +x/-y,
    /// the top trailing-to-leading in -x/+y, and every arc's start angle picks up that same half turn (rotation
    /// preserves the sweep direction, so the deltas are shared). Drawing both from one builder is what stops the
    /// top and bottom cutouts drifting apart.
    func addCutoutEdge(path: inout Path, point: inout CGPoint, edge: CutoutEdge, screenSize: CGSize, layout: ScreenStyles.CutoutLayout) {
        let isBottom = edge == .bottom
        let direction: CGFloat = isBottom ? 1.0 : -1.0
        let halfTurn: Double = isBottom ? 0.0 : -.pi
        let cutoutHeight = layout.cutoutHeight

        if !isBottom {
            // The top edge is entered after the corner arcs, which leave the caller's `point` stale. The bottom is
            // entered straight off the opening `move`, where `point` is still the exact start — re-reading it there
            // would round-trip through `Path`'s Float storage and shift the whole edge by an ulp.
            point = path.currentPoint!
        }
        point.x += direction * (isBottom ? layout.bottomLeadingLengthBeforeCutout : layout.topTrailingLengthAfterCutout)
        path.addLine(to: point)

        let style: CutoutStyle = switch edge {
        case .top:
            screenStyles.topCutoutStyle(screenSize: screenSize, availableWidth: layout.replaceableWidth, insetAmount: insetAmount)
        case .bottom:
            screenStyles.bottomCutoutStyle(screenSize: screenSize, availableWidth: layout.replaceableWidth, insetAmount: insetAmount)
        }
        let points = cutoutPoints(style: style, length: layout.cutoutContentWidth + layout.totalTransitionWidth, cutoutHeight: cutoutHeight).map({
            CGPoint(x: point.x + direction * $0.x, y: point.y - direction * $0.y)
        })
        // Angles below are the bottom edge's; `halfTurn` rotates them for the top.
        func addArc(_ index: Int, radius: CGFloat, startAngle: Double, delta: Double) {
            path.addRelativeArc(center: points[index], radius: radius, startAngle: Angle(radians: startAngle + halfTurn), delta: Angle(radians: delta))
        }
        switch style {
        case .angle45:
            path.addLine(to: points[0])
            path.addLine(to: points[1])
            path.addLine(to: points[2])
        case .roundedAngle45:
            let radius = cutoutHeight
            addArc(0, radius: radius, startAngle: .pi/2, delta: -.pi/4)
            addArc(1, radius: radius, startAngle: .pi*5/4, delta: .pi/4)
            path.addLine(to: points[2])
            addArc(3, radius: radius, startAngle: .pi*3/2, delta: .pi/4)
            addArc(4, radius: radius, startAngle: .pi*3/4, delta: -.pi/4)
        case .halfRounded:
            let radius = cutoutHeight
            addArc(0, radius: radius, startAngle: .pi, delta: .pi/2)
            path.addLine(to: points[1])
            addArc(2, radius: radius, startAngle: -.pi/2, delta: .pi/2)
        case .roundedRectangle:
            let radius = cutoutHeight / 2.0
            addArc(0, radius: radius, startAngle: .pi/2, delta: -.pi/2)
            addArc(1, radius: radius, startAngle: .pi, delta: .pi/2)
            path.addLine(to: points[2])
            addArc(3, radius: radius, startAngle: .pi*3/2, delta: .pi/2)
            addArc(4, radius: radius, startAngle: .pi, delta: -.pi/2)
        case .curved:
            path.addQuadCurve(to: points[0], control: points[1])
            path.addLine(to: points[2])
            path.addQuadCurve(to: points[3], control: points[4])
        case .none:
            path.addLine(to: points[0])
        }

        point = path.currentPoint!
        point.x += direction * (isBottom ? layout.bottomTrailingLengthAfterCutout : layout.topLeadingLengthBeforeCutout)
        path.addLine(to: point)
    }

    /// The controls describe the desired bulge. A cubic with equal control offsets only reaches 3/4 of
    /// that offset, so the circle needs 4/3 to touch the display. The squircle uses two fuller curves
    /// meeting at the display edge, with a shared tangent and no straight segment on the curved side.
    private func addCroppedCurve(path: inout Path, to end: CGPoint, control1: CGPoint, control2: CGPoint) {
        let start = path.currentPoint!
        let bulge = CGSize(width: control1.x - start.x, height: control1.y - start.y)
        if screenShapeType == .croppedSquircle {
            let middle = CGPoint(x: (start.x + end.x) / 2 + bulge.width, y: (start.y + end.y) / 2 + bulge.height)
            let tangent = CGSize(width: (end.x - start.x) / 4, height: (end.y - start.y) / 4)
            path.addCurve(to: middle, control1: control1,
                          control2: CGPoint(x: middle.x - tangent.width, y: middle.y - tangent.height))
            path.addCurve(to: end,
                          control1: CGPoint(x: middle.x + tangent.width, y: middle.y + tangent.height), control2: control2)
        } else {
            path.addCurve(to: end,
                          control1: CGPoint(x: start.x + bulge.width * 4 / 3, y: start.y + bulge.height * 4 / 3),
                          control2: CGPoint(x: end.x + bulge.width * 4 / 3, y: end.y + bulge.height * 4 / 3))
        }
    }

    // MARK: - Path
    
    func path(in rect: CGRect) -> Path {
        let cacheKey = LayoutConfig(rect: rect, connectedEdges: connectedEdges, insetAmount: insetAmount, screenShapeType: screenShapeType, themeGeneration: system.generationID)
        if let path = Self.pathCache[cacheKey] {
            return path
        }
        
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        
        switch screenShapeType {
        case .circle:
            return Circle().path(in: insetRect)
        case .triangle:
            return Triangle(roundedCornerFraction: system.roundedCornerFraction, overrideDirection: system.shapeDirection).path(in: insetRect)
        default:
            break
        }
        
        let cornerRadius = Self.cornerRadius(rect: rect, insetAmount: insetAmount, screenShapeType: screenShapeType, system: system)
        let screenTrapezoidOrHexagonCornerOffset = Self.screenTrapezoidOrHexagonCornerOffset(screenSize: rect.size, insetAmount: insetAmount)
        
        // Straight height that could be replaced by a cutout
        let replaceableHeight: CGFloat = {
            if screenShapeType == .croppedCircle || screenShapeType == .croppedSquircle {
                return insetRect.height - screenTrapezoidOrHexagonCornerOffset*2.0
            } else {
                return insetRect.height - cornerRadius*2.0
            }
        }()
        
        // Shared cutout metrics — the single source of truth also consumed by `ScreenStyles.cutoutFrame`, so the
        // drawn cutout and the reported cutout frame can't drift.
        let layout = screenStyles.cutoutLayout(rect: rect, insetAmount: insetAmount, screenShapeType: screenShapeType, system: system)

        // MARK: Return
        let path = Path { path in
            // Start at bottom left and go counter-clockwise
            let startXOffset: CGFloat = {
                switch screenShapeType {
                case .croppedCircle, .croppedSquircle:
                    return if insetRect.width < insetRect.height {
                        0
                    } else {
                        screenTrapezoidOrHexagonCornerOffset
                    }
                case .verticalHexagon, .horizontalHexagon:
                    let riseOverRun = (insetRect.height/2) / screenTrapezoidOrHexagonCornerOffset
                    let angle = atan(riseOverRun)
                    let offset = cornerRadius * abs(tan(angle / 2.0))
                    return screenTrapezoidOrHexagonCornerOffset + offset
                case .trapezoid:
                    let topSideLength = insetRect.width - screenTrapezoidOrHexagonCornerOffset*2
                    let topLeadingSpace = (insetRect.size.width - topSideLength)/2
                    let riseOverRun = insetRect.size.height / topLeadingSpace
                    let angle = atan(riseOverRun)
                    let topOffset = cornerRadius * abs(tan(angle / 2.0))
                    return screenTrapezoidOrHexagonCornerOffset + topOffset
                default:
                    return cornerRadius
                }
            }()
            var point = CGPoint(x: insetRect.minX + startXOffset, y: insetRect.maxY)
            path.move(to: point)
            
            let horizontalStraightLengthIsZero: Bool = {
                switch screenShapeType {
                case .verticalHexagon:
                    return true
                case .croppedCircle, .croppedSquircle, .capsule:
                    return insetRect.width < insetRect.height
                default:
                    return false
                }
            }()
            
            if !horizontalStraightLengthIsZero {
                addCutoutEdge(path: &path, point: &point, edge: .bottom, screenSize: rect.size, layout: layout)
            }
            
            // MARK: Right + Top + Left Sides
            switch screenShapeType {
            case .verticalHexagon, .horizontalHexagon:
                // Rotate the rect so we only have to draw horizontal hexagon paths
                let modifiedInsetRect: CGRect = {
                    if screenShapeType == .verticalHexagon {
                        return CGRect(x: insetRect.origin.y, y: insetRect.origin.x, width: insetRect.height, height: insetRect.width)
                    } else {
                        return insetRect
                    }
                }()
                
                let sharpPoints = [
                    CGPoint(x: modifiedInsetRect.maxX - screenTrapezoidOrHexagonCornerOffset, y: modifiedInsetRect.maxY),
                    CGPoint(x: modifiedInsetRect.maxX, y: modifiedInsetRect.midY),
                    CGPoint(x: modifiedInsetRect.maxX - screenTrapezoidOrHexagonCornerOffset, y: modifiedInsetRect.minY),
                    CGPoint(x: modifiedInsetRect.minX + screenTrapezoidOrHexagonCornerOffset, y: modifiedInsetRect.minY),
                    CGPoint(x: modifiedInsetRect.minX, y: modifiedInsetRect.midY),
                    CGPoint(x: modifiedInsetRect.minX + screenTrapezoidOrHexagonCornerOffset, y: modifiedInsetRect.maxY)
                ]
                let riseOverRun = (modifiedInsetRect.height/2) / screenTrapezoidOrHexagonCornerOffset
                let angle = atan(riseOverRun)
                let offset = cornerRadius * abs(tan(angle / 2.0))
                
                let offsetXComponent = offset * cos(angle)
                let offsetYComponent = offset * sin(angle)
                
                // How far a rounded corner backs off along each edge, in draw order (edge i runs sharpPoints[i] to
                // sharpPoints[i+1]). A corner enters against its incoming edge and leaves along its outgoing one,
                // which is the only thing that differed between the six corners.
                let edgeOffsets = [
                    CGPoint(x: offsetXComponent, y: -offsetYComponent),
                    CGPoint(x: -offsetXComponent, y: -offsetYComponent),
                    CGPoint(x: -offset, y: 0),
                    CGPoint(x: -offsetXComponent, y: offsetYComponent),
                    CGPoint(x: offsetXComponent, y: offsetYComponent),
                    CGPoint(x: offset, y: 0)
                ]
                var points = [CGPoint]()
                for (index, sharpPoint) in sharpPoints.enumerated() {
                    guard !cornerRadius.isZero else {
                        points.append(sharpPoint)
                        continue
                    }
                    let incoming = edgeOffsets[(index + edgeOffsets.count - 1) % edgeOffsets.count]
                    let outgoing = edgeOffsets[index]
                    points.append(CGPoint(x: sharpPoint.x - incoming.x, y: sharpPoint.y - incoming.y))
                    points.append(sharpPoint)
                    points.append(CGPoint(x: sharpPoint.x + outgoing.x, y: sharpPoint.y + outgoing.y))
                }
                
                if screenShapeType == .verticalHexagon {
                    points = points.map({ CGPoint(x: $0.y, y: $0.x) }) // Rotate 90
                    path.move(to: points.last!)
                }
                
                for _ in 0..<3 {
                    path.addLine(to: points.removeFirst())
                    if !cornerRadius.isZero {
                        path.addArc(tangent1End: points.removeFirst(), tangent2End: points.removeFirst(), radius: cornerRadius)
                    }
                }
                if screenShapeType == .horizontalHexagon {
                    addCutoutEdge(path: &path, point: &point, edge: .top, screenSize: rect.size, layout: layout)
                }
                for _ in 0..<3 {
                    path.addLine(to: points.removeFirst())
                    if !cornerRadius.isZero {
                        path.addArc(tangent1End: points.removeFirst(), tangent2End: points.removeFirst(), radius: cornerRadius)
                    }
                }
            case .trapezoid:
                let topSideLength = insetRect.width - screenTrapezoidOrHexagonCornerOffset*2
                var points = Trapezoid(system: system).roundedTrapezoidPathPoints(in: insetRect, topSideLength: topSideLength, cornerRadius: cornerRadius)
                
                if system.shapeDirection == .down {
                    let flipped = points.map({ CGPoint(x: $0.x, y: rect.maxY - $0.y) }) // Flip
                    points = Array(flipped[0..<flipped.count/2].reversed()) + Array(flipped[flipped.count/2..<flipped.count].reversed())
                }
                
                // Right side
                if connectedEdges.contains(.right) {
                    points.removeFirst(cornerRadius.isZero ? 1 : 5)
                    path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY))
                    path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.minY))
                    path.addLine(to: points.removeFirst())
                } else {
                    for i in 0..<2 {
                        if i == 0, !cornerRadius.isZero {
                            points.removeFirst()
                        } else {
                            path.addLine(to: points.removeFirst())
                        }
                        if !cornerRadius.isZero {
                            path.addArc(tangent1End: points.removeFirst(), tangent2End: points.removeFirst(), radius: cornerRadius)
                        }
                    }
                }
                if system.shapeDirection == .down {
                    // Add line towards middle, ensuring the right side path ends on the same point that it would if the shape direction was up.
                    point = path.currentPoint!
                    point.x -= screenTrapezoidOrHexagonCornerOffset
                    path.addLine(to: point)
                }
                addCutoutEdge(path: &path, point: &point, edge: .top, screenSize: rect.size, layout: layout)
                
                // Left side
                if connectedEdges.contains(.left) {
                    points.removeFirst(cornerRadius.isZero ? 1 : 5)
                    path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.minY))
                    path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.maxY))
                    path.addLine(to: points.removeFirst())
                } else {
                    for i in 0..<2 {
                        if i == 0, !cornerRadius.isZero {
                            points.removeFirst()
                        } else {
                            path.addLine(to: points.removeFirst())
                        }
                        if !cornerRadius.isZero {
                            path.addArc(tangent1End: points.removeFirst(), tangent2End: points.removeFirst(), radius: cornerRadius)
                        }
                    }
                }
            case .croppedCircle, .croppedSquircle:
                if insetRect.height <= insetRect.width {
                    var c1a = point
                    c1a.x += screenTrapezoidOrHexagonCornerOffset
                    point.y -= insetRect.height
                    var c2a = point
                    c2a.x += screenTrapezoidOrHexagonCornerOffset
                    addCroppedCurve(path: &path, to: point, control1: c1a, control2: c2a)
                    addCutoutEdge(path: &path, point: &point, edge: .top, screenSize: rect.size, layout: layout)
                    var c1b = point
                    c1b.x -= screenTrapezoidOrHexagonCornerOffset
                    point.y += insetRect.height
                    var c2b = point
                    c2b.x -= screenTrapezoidOrHexagonCornerOffset
                    addCroppedCurve(path: &path, to: point, control1: c1b, control2: c2b)
                } else {
                    point.y -= screenTrapezoidOrHexagonCornerOffset
                    path.move(to: point)
                    
                    var c1a = point
                    c1a.y += screenTrapezoidOrHexagonCornerOffset
                    point.x += insetRect.width
                    var c2a = point
                    c2a.y += screenTrapezoidOrHexagonCornerOffset
                    addCroppedCurve(path: &path, to: point, control1: c1a, control2: c2a)
                    
                    point.y -= replaceableHeight
                    path.addLine(to: point)
                    
                    var c1b = point
                    c1b.y -= screenTrapezoidOrHexagonCornerOffset
                    point.x -= insetRect.width
                    var c2b = point
                    c2b.y -= screenTrapezoidOrHexagonCornerOffset
                    addCroppedCurve(path: &path, to: point, control1: c1b, control2: c2b)
                    
                    point.y += replaceableHeight
                    path.addLine(to: point)
                }
            default:
                if !screenStyles.connectedCorners(for: connectedEdges).contains(.bottomRight) {
                    point.y -= cornerRadius
                    path.addRelativeArc(center: point, radius: cornerRadius, startAngle: Angle(radians: .pi/2), delta: Angle(radians: -Double.pi/2.0))
                    point = path.currentPoint!
                } else {
                    point.x += cornerRadius
                    path.addLine(to: point)
                    point.y -= cornerRadius
                }
                point.y -= replaceableHeight
                path.addLine(to: point)
                if !screenStyles.connectedCorners(for: connectedEdges).contains(.topRight) {
                    point.x -= cornerRadius
                    path.addRelativeArc(center: point, radius: cornerRadius, startAngle: Angle.zero, delta: Angle(radians: -.pi/2.0))
                    point = path.currentPoint!
                } else {
                    point.y -= cornerRadius
                    path.addLine(to: point)
                    point.x -= cornerRadius
                    path.addLine(to: point)
                }
                addCutoutEdge(path: &path, point: &point, edge: .top, screenSize: rect.size, layout: layout)
                path.addLine(to: point)
                if !screenStyles.connectedCorners(for: connectedEdges).contains(.topLeft) {
                    point.y += cornerRadius
                    path.addRelativeArc(center: point, radius: cornerRadius, startAngle: Angle(radians: -.pi/2), delta: Angle(radians: -.pi/2.0))
                    point = path.currentPoint!
                } else {
                    point.x -= cornerRadius
                    path.addLine(to: point)
                    point.y += cornerRadius
                }
                point.y += replaceableHeight
                path.addLine(to: point)
                if !screenStyles.connectedCorners(for: connectedEdges).contains(.bottomLeft) {
                    point.x += cornerRadius
                    path.addRelativeArc(center: point, radius: cornerRadius, startAngle: Angle(radians: -(.pi/2) - .pi/2.0), delta: Angle(radians: -Double.pi/2.0))
                } else {
                    point.y += cornerRadius
                    path.addLine(to: point)
                    point.x += cornerRadius
                }
            }
            
            path.closeSubpath()
        }
        
        Self.pathCache[cacheKey] = path
        
        return path
    }
    
    func inset(by amount: CGFloat) -> some InsettableShape {
        var arc = self
        arc.insetAmount += amount
        return arc
    }
}
