//
//  ScreenShape.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-19.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct ScreenShape: InsettableShape {
    
    struct LayoutConfig: Hashable {
        let rect: CGRect
        let insetAmount: CGFloat
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(rect.origin.x)
            hasher.combine(rect.origin.y)
            hasher.combine(rect.size.width)
            hasher.combine(rect.size.height)
            hasher.combine(insetAmount)
        }
    }
    
    static let cutoutHeight: CGFloat = 50.0
    static let hardwareCornerRadius: CGFloat = 44.0
    static let hardwareFaceIDWidth: CGFloat = 200.0
    static var pathCache: [LayoutConfig: Path] = [:]
    
    static func cornerRadius(rect: CGRect, insetAmount: CGFloat, screenShapeType: ScreenShapeType) -> CGFloat {
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
    
    var screenShapeType: ScreenShapeType
    var insetAmount: CGFloat = 0.0
    
    func cutoutPoints(style: CutoutStyle, length: CGFloat, cutoutHeight: CGFloat) -> [CGPoint] {
        
        let totalTransitionLength: CGFloat = {
            switch style {
            case .angle45:
                return cutoutHeight * 2.0
            case .roundedAngle45:
                let radius = cutoutHeight
                let betweenCenters = (1 + cos(.pi/4)) * radius
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
        }()
        let straightLength = length - totalTransitionLength
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
    
    // MARK: - Top Cutout
    
    func addTopCutout(path: inout Path, point: inout CGPoint, screenSize: CGSize, replacableWidth: CGFloat, topTrailingLengthAfterCutout: CGFloat, cutoutContentWidth: CGFloat, totalTransitionWidth: CGFloat, cutoutHeight: CGFloat, topLeadingLengthBeforeCutout: CGFloat) {
        point = path.currentPoint!
        point.x -= topTrailingLengthAfterCutout
        path.addLine(to: point)
        
        let topCutoutStyle = system.screen.topCutoutStyle(screenSize: screenSize, availableWidth: replacableWidth, insetAmount: insetAmount)
        let topCutoutPoints = cutoutPoints(style: topCutoutStyle, length: cutoutContentWidth + totalTransitionWidth, cutoutHeight: cutoutHeight).map({
            CGPoint(x: point.x - $0.x, y: point.y + $0.y)
        })
        switch topCutoutStyle {
        case .angle45:
            path.addLine(to: topCutoutPoints[0])
            path.addLine(to: topCutoutPoints[1])
            path.addLine(to: topCutoutPoints[2])
        case .roundedAngle45:
            let radius = cutoutHeight
            path.addRelativeArc(center: topCutoutPoints[0], radius: radius, startAngle: Angle(degrees: -90), delta: Angle(radians: -Double.pi/4))
            path.addRelativeArc(center: topCutoutPoints[1], radius: radius, startAngle: Angle(radians: .pi*5/4 - .pi), delta: Angle(radians: Double.pi/4))
            path.addLine(to: topCutoutPoints[2])
            path.addRelativeArc(center: topCutoutPoints[3], radius: radius, startAngle: Angle(radians: .pi*3/2 - .pi), delta: Angle(radians: Double.pi/4))
            path.addRelativeArc(center: topCutoutPoints[4], radius: radius, startAngle: Angle(radians: .pi*3/4 - .pi), delta: Angle(radians: -Double.pi/4))
        case .halfRounded:
            let radius = cutoutHeight
            path.addRelativeArc(center: topCutoutPoints[0], radius: radius, startAngle: Angle(radians: -.pi*2), delta: Angle(radians: Double.pi/2.0))
            path.addLine(to: topCutoutPoints[1])
            path.addRelativeArc(center: topCutoutPoints[2], radius: radius, startAngle: Angle(radians: -.pi*3/2), delta: Angle(radians: Double.pi/2.0))
        case .roundedRectangle:
            let radius = cutoutHeight / 2.0
            path.addRelativeArc(center: topCutoutPoints[0], radius: radius, startAngle: Angle(radians: -.pi/2), delta: Angle(radians: -Double.pi/2.0))
            path.addRelativeArc(center: topCutoutPoints[1], radius: radius, startAngle: Angle(radians: 0), delta: Angle(radians: Double.pi/2.0))
            path.addLine(to: topCutoutPoints[2])
            path.addRelativeArc(center: topCutoutPoints[3], radius: radius, startAngle: Angle(radians: .pi*3/2 - .pi), delta: Angle(radians: Double.pi/2.0))
            path.addRelativeArc(center: topCutoutPoints[4], radius: radius, startAngle: Angle(radians: 0), delta: Angle(radians: -Double.pi/2.0))
        case .curved:
            path.addQuadCurve(to: topCutoutPoints[0], control: topCutoutPoints[1])
            path.addLine(to: topCutoutPoints[2])
            path.addQuadCurve(to: topCutoutPoints[3], control: topCutoutPoints[4])
        case .none:
            path.addLine(to: topCutoutPoints[0])
        }
        point.x -= cutoutContentWidth + totalTransitionWidth

        point = path.currentPoint!
        point.x -= topLeadingLengthBeforeCutout
        path.addLine(to: point)
    }
    
    // MARK: - Path
    
    func path(in rect: CGRect) -> Path {
        if let path = Self.pathCache[LayoutConfig(rect: rect, insetAmount: insetAmount)] {
            return path
        }
        
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        
        switch screenShapeType {
        case .circle:
            return Circle().path(in: insetRect)
        case .triangle:
            return Triangle(overrideDirection: system.shapeDirection).path(in: insetRect)
        default:
            break
        }
        
        let cornerRadius = Self.cornerRadius(rect: rect, insetAmount: insetAmount, screenShapeType: screenShapeType)
        let screenTrapezoidOrHexagonCornerOffset = Self.screenTrapezoidOrHexagonCornerOffset(screenSize: rect.size, insetAmount: insetAmount)
        
        // Straight width that could be replaced by a cutout
        let replacableWidth: CGFloat = {
            switch screenShapeType {
            case .croppedCircle:
                return insetRect.width - screenTrapezoidOrHexagonCornerOffset*2.0
            case .horizontalHexagon:
                let riseOverRun = (insetRect.height/2) / screenTrapezoidOrHexagonCornerOffset
                let angle = atan(riseOverRun)
                let offset = cornerRadius * abs(tan(angle / 2.0))
                return insetRect.width - (screenTrapezoidOrHexagonCornerOffset + offset)*2.0
            case .trapezoid:
                let topSideLength = insetRect.width - screenTrapezoidOrHexagonCornerOffset*2
                let topLeadingSpace = (insetRect.width - topSideLength)/2
                let riseOverRun = insetRect.height / topLeadingSpace
                let angle = atan(riseOverRun)
                let topOffset = cornerRadius * abs(tan(angle / 2.0))
                return insetRect.width - (screenTrapezoidOrHexagonCornerOffset + topOffset)*2.0
            default:
                return insetRect.width - cornerRadius*2.0
            }
        }()
        
        // Straight height that could be replaced by a cutout
        let replacableHeight: CGFloat = {
            if screenShapeType == .croppedCircle {
                return insetRect.height - screenTrapezoidOrHexagonCornerOffset*2.0
            } else {
                return insetRect.height - cornerRadius*2.0
            }
        }()
        
        let cutoutHeight = ScreenShape.cutoutHeight
        
        let totalTransitionWidth: CGFloat = {
            switch system.screen.generalCutoutStyle {
            case .angle45:
                return cutoutHeight * 2.0
            case .roundedAngle45:
                let radius = cutoutHeight
                let betweenCenters = (1 + cos(.pi/4)) * radius
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
        }()
        let maxCutoutContentWidth = replacableWidth - totalTransitionWidth
        let absoluteMaxCutoutContentWidth = 600.0 + insetAmount
        let preferedCutoutContentWidth = max(system.screen.preferedCutoutContentWidth(screenSize: rect.size), Self.hardwareFaceIDWidth) + insetAmount
        let cutoutContentWidth = min(preferedCutoutContentWidth, maxCutoutContentWidth, absoluteMaxCutoutContentWidth)
        let totalLengthAroundCutout = (replacableWidth - cutoutContentWidth - totalTransitionWidth)
        let topLeadingLengthBeforeCutout: CGFloat
        let topTrailingLengthAfterCutout: CGFloat
        let bottomLeadingLengthBeforeCutout: CGFloat
        let bottomTrailingLengthAfterCutout: CGFloat
        
        if 200 < totalLengthAroundCutout {
            switch system.screen.getTopCutoutPosition(screenSize: rect.size) {
            case .leading:
                topLeadingLengthBeforeCutout = totalLengthAroundCutout * 0.333333
                topTrailingLengthAfterCutout = totalLengthAroundCutout * 0.666666
            case .trailing:
                topLeadingLengthBeforeCutout = totalLengthAroundCutout * 0.666666
                topTrailingLengthAfterCutout = totalLengthAroundCutout * 0.333333
            default:
                topLeadingLengthBeforeCutout = totalLengthAroundCutout/2
                topTrailingLengthAfterCutout = totalLengthAroundCutout/2
            }
            switch system.screen.bottomCutoutPosition {
            case .leading:
                bottomLeadingLengthBeforeCutout = totalLengthAroundCutout * 0.333333
                bottomTrailingLengthAfterCutout = totalLengthAroundCutout * 0.666666
            case .trailing:
                bottomLeadingLengthBeforeCutout = totalLengthAroundCutout * 0.666666
                bottomTrailingLengthAfterCutout = totalLengthAroundCutout * 0.333333
            default:
                bottomLeadingLengthBeforeCutout = totalLengthAroundCutout/2
                bottomTrailingLengthAfterCutout = totalLengthAroundCutout/2
            }
        } else {
            topLeadingLengthBeforeCutout = totalLengthAroundCutout/2
            topTrailingLengthAfterCutout = totalLengthAroundCutout/2
            bottomLeadingLengthBeforeCutout = totalLengthAroundCutout/2
            bottomTrailingLengthAfterCutout = totalLengthAroundCutout/2
        }
        
        // MARK: Return
        let path = Path { path in
            // Start at bottom left and go counter-clockwise
            let startXOffset: CGFloat = {
                switch screenShapeType {
                case .croppedCircle:
                    if insetRect.width < insetRect.height {
                        return 0
                    } else {
                        return screenTrapezoidOrHexagonCornerOffset
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
            var point = CGPoint(x: insetAmount + startXOffset, y: insetAmount + insetRect.height)
            path.move(to: point)
            
            let horizontalStraightLengthIsZero: Bool = {
                switch screenShapeType {
                case .verticalHexagon:
                    return true
                case .croppedCircle, .capsule:
                    return insetRect.width < insetRect.height
                default:
                    return false
                }
            }()
            
            if !horizontalStraightLengthIsZero {
                point.x += bottomLeadingLengthBeforeCutout
                path.addLine(to: point)
                
                // MARK: Bottom Cutout
                
                let bottomCutoutStyle = system.screen.bottomCutoutStyle(screenSize: rect.size, availableWidth: replacableWidth, insetAmount: insetAmount)
                let bottomCutoutPoints = cutoutPoints(style: bottomCutoutStyle, length: cutoutContentWidth + totalTransitionWidth, cutoutHeight: cutoutHeight).map({
                    CGPoint(x: point.x + $0.x, y: point.y - $0.y)
                })
                switch bottomCutoutStyle {
                case .angle45:
                    path.addLine(to: bottomCutoutPoints[0])
                    path.addLine(to: bottomCutoutPoints[1])
                    path.addLine(to: bottomCutoutPoints[2])
                case .roundedAngle45:
                    let radius = cutoutHeight
                    path.addRelativeArc(center: bottomCutoutPoints[0], radius: radius, startAngle: Angle(degrees: 90), delta: Angle(radians: -Double.pi/4))
                    path.addRelativeArc(center: bottomCutoutPoints[1], radius: radius, startAngle: Angle(radians: .pi*5/4), delta: Angle(radians: Double.pi/4))
                    path.addLine(to: bottomCutoutPoints[2])
                    path.addRelativeArc(center: bottomCutoutPoints[3], radius: radius, startAngle: Angle(radians: .pi*3/2), delta: Angle(radians: Double.pi/4))
                    path.addRelativeArc(center: bottomCutoutPoints[4], radius: radius, startAngle: Angle(radians: .pi*3/4), delta: Angle(radians: -Double.pi/4))
                case .halfRounded:
                    let radius = cutoutHeight
                    path.addRelativeArc(center: bottomCutoutPoints[0], radius: radius, startAngle: Angle(radians: .pi), delta: Angle(radians: Double.pi/2.0))
                    path.addLine(to: bottomCutoutPoints[1])
                    path.addRelativeArc(center: bottomCutoutPoints[2], radius: radius, startAngle: Angle(radians: -.pi/2), delta: Angle(radians: Double.pi/2.0))
                case .roundedRectangle:
                    let radius = cutoutHeight / 2.0
                    path.addRelativeArc(center: bottomCutoutPoints[0], radius: radius, startAngle: Angle(radians: .pi/2), delta: Angle(radians: -Double.pi/2.0))
                    path.addRelativeArc(center: bottomCutoutPoints[1], radius: radius, startAngle: Angle(radians: .pi), delta: Angle(radians: Double.pi/2.0))
                    path.addLine(to: bottomCutoutPoints[2])
                    path.addRelativeArc(center: bottomCutoutPoints[3], radius: radius, startAngle: Angle(radians: .pi*3/2), delta: Angle(radians: Double.pi/2.0))
                    path.addRelativeArc(center: bottomCutoutPoints[4], radius: radius, startAngle: Angle(radians: .pi), delta: Angle(radians: -Double.pi/2.0))
                case .curved:
                    path.addQuadCurve(to: bottomCutoutPoints[0], control: bottomCutoutPoints[1])
                    path.addLine(to: bottomCutoutPoints[2])
                    path.addQuadCurve(to: bottomCutoutPoints[3], control: bottomCutoutPoints[4])
                case .none:
                    path.addLine(to: bottomCutoutPoints[0])
                }
                point.x += cutoutContentWidth + totalTransitionWidth
                
                point = path.currentPoint!
                point.x += bottomTrailingLengthAfterCutout
                path.addLine(to: point)
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
                var points = [CGPoint]()
                let riseOverRun = (modifiedInsetRect.height/2) / screenTrapezoidOrHexagonCornerOffset
                let angle = atan(riseOverRun)
                let offset = cornerRadius * abs(tan(angle / 2.0))
                
                let offsetXComponent = offset * cos(angle)
                let offsetYComponent = offset * sin(angle)
                
                let sharpPoint0 = sharpPoints[0]
                if !cornerRadius.isZero {
                    points.append(CGPoint(x: sharpPoint0.x - offset, y: sharpPoint0.y))
                    points.append(sharpPoint0)
                    points.append(CGPoint(x: sharpPoint0.x + offsetXComponent, y: sharpPoint0.y - offsetYComponent))
                } else {
                    points.append(sharpPoint0)
                }
                
                let sharpPoint1 = sharpPoints[1]
                if !cornerRadius.isZero {
                    points.append(CGPoint(x: sharpPoint1.x - offsetXComponent, y: sharpPoint1.y + offsetYComponent))
                    points.append(sharpPoint1)
                    points.append(CGPoint(x: sharpPoint1.x - offsetXComponent, y: sharpPoint1.y - offsetYComponent))
                } else {
                    points.append(sharpPoint1)
                }
                
                let sharpPoint2 = sharpPoints[2]
                if !cornerRadius.isZero {
                    points.append(CGPoint(x: sharpPoint2.x + offsetXComponent, y: sharpPoint2.y + offsetYComponent))
                    points.append(sharpPoint2)
                    points.append(CGPoint(x: sharpPoint2.x - offset, y: sharpPoint2.y))
                } else {
                    points.append(sharpPoint2)
                }
                
                let sharpPoint3 = sharpPoints[3]
                if !cornerRadius.isZero {
                    points.append(CGPoint(x: sharpPoint3.x + offset, y: sharpPoint3.y))
                    points.append(sharpPoint3)
                    points.append(CGPoint(x: sharpPoint3.x - offsetXComponent, y: sharpPoint3.y + offsetYComponent))
                } else {
                    points.append(sharpPoint3)
                }
                
                let sharpPoint4 = sharpPoints[4]
                if !cornerRadius.isZero {
                    points.append(CGPoint(x: sharpPoint4.x + offsetXComponent, y: sharpPoint4.y - offsetYComponent))
                    points.append(sharpPoint4)
                    points.append(CGPoint(x: sharpPoint4.x + offsetXComponent, y: sharpPoint4.y + offsetYComponent))
                } else {
                    points.append(sharpPoint4)
                }
                
                let sharpPoint5 = sharpPoints[5]
                if !cornerRadius.isZero {
                    points.append(CGPoint(x: sharpPoint5.x - offsetXComponent, y: sharpPoint5.y - offsetYComponent))
                    points.append(sharpPoint5)
                    points.append(CGPoint(x: sharpPoint5.x + offset, y: sharpPoint5.y))
                } else {
                    points.append(sharpPoint5)
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
                    addTopCutout(path: &path, point: &point, screenSize: rect.size, replacableWidth: replacableWidth, topTrailingLengthAfterCutout: topTrailingLengthAfterCutout, cutoutContentWidth: cutoutContentWidth, totalTransitionWidth: totalTransitionWidth, cutoutHeight: cutoutHeight, topLeadingLengthBeforeCutout: topLeadingLengthBeforeCutout)
                }
                for _ in 0..<3 {
                    path.addLine(to: points.removeFirst())
                    if !cornerRadius.isZero {
                        path.addArc(tangent1End: points.removeFirst(), tangent2End: points.removeFirst(), radius: cornerRadius)
                    }
                }
            case .trapezoid:
                let topSideLength = insetRect.width - screenTrapezoidOrHexagonCornerOffset*2
                var points = Trapezoid().roundedTrapezoidPathPoints(in: insetRect, topSideLength: topSideLength, cornerRadius: cornerRadius)
                
                if system.shapeDirection == .down {
                    let flipped = points.map({ CGPoint(x: $0.x, y: rect.maxY - $0.y) }) // Flip
                    points = Array(flipped[0..<flipped.count/2].reversed()) + Array(flipped[flipped.count/2..<flipped.count].reversed())
                }
                
                // Right side
                if system.screen.connectedEdges.contains(.right) {
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
                addTopCutout(path: &path, point: &point, screenSize: rect.size, replacableWidth: replacableWidth, topTrailingLengthAfterCutout: topTrailingLengthAfterCutout, cutoutContentWidth: cutoutContentWidth, totalTransitionWidth: totalTransitionWidth, cutoutHeight: cutoutHeight, topLeadingLengthBeforeCutout: topLeadingLengthBeforeCutout)
                
                // Left side
                if system.screen.connectedEdges.contains(.left) {
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
            case .croppedCircle:
                if insetRect.height <= insetRect.width {
                    var c1a = point
                    c1a.x += screenTrapezoidOrHexagonCornerOffset
                    point.y -= insetRect.height
                    var c2a = point
                    c2a.x += screenTrapezoidOrHexagonCornerOffset
                    path.addCurve(to: point, control1: c1a, control2: c2a)
                    addTopCutout(path: &path, point: &point, screenSize: rect.size, replacableWidth: replacableWidth, topTrailingLengthAfterCutout: topTrailingLengthAfterCutout, cutoutContentWidth: cutoutContentWidth, totalTransitionWidth: totalTransitionWidth, cutoutHeight: cutoutHeight, topLeadingLengthBeforeCutout: topLeadingLengthBeforeCutout)
                    var c1b = point
                    c1b.x -= screenTrapezoidOrHexagonCornerOffset
                    point.y += insetRect.height
                    var c2b = point
                    c2b.x -= screenTrapezoidOrHexagonCornerOffset
                    path.addCurve(to: point, control1: c1b, control2: c2b)
                } else {
                    point.y -= screenTrapezoidOrHexagonCornerOffset
                    path.move(to: point)
                    
                    var c1a = point
                    c1a.y += screenTrapezoidOrHexagonCornerOffset
                    point.x += insetRect.width
                    var c2a = point
                    c2a.y += screenTrapezoidOrHexagonCornerOffset
                    path.addCurve(to: point, control1: c1a, control2: c2a)
                    
                    point.y -= replacableHeight
                    path.addLine(to: point)
                    
                    var c1b = point
                    c1b.y -= screenTrapezoidOrHexagonCornerOffset
                    point.x -= insetRect.width
                    var c2b = point
                    c2b.y -= screenTrapezoidOrHexagonCornerOffset
                    path.addCurve(to: point, control1: c1b, control2: c2b)
                    
                    point.y += replacableHeight
                    path.addLine(to: point)
                }
            default:
                if !system.screen.connectedCorners.contains(.bottomRight) {
                    point.y -= cornerRadius
                    path.addRelativeArc(center: point, radius: cornerRadius, startAngle: Angle(radians: .pi/2), delta: Angle(radians: -Double.pi/2.0))
                    point = path.currentPoint!
                } else {
                    point.x += cornerRadius
                    path.addLine(to: point)
                    point.y -= cornerRadius
                }
                point.y -= replacableHeight
                path.addLine(to: point)
                if !system.screen.connectedCorners.contains(.topRight) {
                    point.x -= cornerRadius
                    path.addRelativeArc(center: point, radius: cornerRadius, startAngle: Angle.zero, delta: Angle(radians: -.pi/2.0))
                    point = path.currentPoint!
                } else {
                    point.y -= cornerRadius
                    path.addLine(to: point)
                    point.x -= cornerRadius
                    path.addLine(to: point)
                }
                addTopCutout(path: &path, point: &point, screenSize: rect.size, replacableWidth: replacableWidth, topTrailingLengthAfterCutout: topTrailingLengthAfterCutout, cutoutContentWidth: cutoutContentWidth, totalTransitionWidth: totalTransitionWidth, cutoutHeight: cutoutHeight, topLeadingLengthBeforeCutout: topLeadingLengthBeforeCutout)
                path.addLine(to: point)
                if !system.screen.connectedCorners.contains(.topLeft) {
                    point.y += cornerRadius
                    path.addRelativeArc(center: point, radius: cornerRadius, startAngle: Angle(radians: -.pi/2), delta: Angle(radians: -.pi/2.0))
                    point = path.currentPoint!
                } else {
                    point.x -= cornerRadius
                    path.addLine(to: point)
                    point.y += cornerRadius
                }
                point.y += replacableHeight
                path.addLine(to: point)
                if !system.screen.connectedCorners.contains(.bottomLeft) {
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
        
        Self.pathCache[LayoutConfig(rect: rect, insetAmount: insetAmount)] = path
        
        return path
    }
    
    func inset(by amount: CGFloat) -> some InsettableShape {
        var arc = self
        arc.insetAmount += amount
        return arc
    }
}
