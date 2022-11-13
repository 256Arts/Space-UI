//
//  ScreenAppearance.swift
//  Space UI
//
//  Created by Jayden Irwin on 2022-10-20.
//  Copyright © 2022 Jayden Irwin. All rights reserved.
//

import SwiftUI
import GameplayKit

enum ScreenShapeType: String, Identifiable, CaseIterable {
    case rectangle, capsule, circle, croppedCircle, verticalHexagon, horizontalHexagon, trapezoid, triangle
    
    var id: Self { self }
    var name: String {
        switch self {
        case .croppedCircle:
            return "Cropped Circle"
        case .verticalHexagon:
            return "Hexagon (V)"
        case .horizontalHexagon:
            return "Hexagon (H)"
        default:
            return rawValue.capitalized
        }
    }
    var supportsCutouts: Bool {
        switch self {
        case .circle, .triangle:
            return false
        default:
            return true
        }
    }
    var supportsMorseCodeEdges: Bool {
        switch self {
        case .circle, .triangle, .verticalHexagon:
            return false
        default:
            return true
        }
    }
    var canConnectToAdjacent: Bool {
        switch self {
        case .rectangle, .capsule, .trapezoid:
            return true
        default:
            return false
        }
    }
}

final class ScreenAppearance {
    
    var seedScreenShapeType: ScreenShapeType
    var overrideScreenShapeType: ScreenShapeType? {
        ScreenShapeType(rawValue: UserDefaults.standard.string(forKey: UserDefaults.Key.screenShapeOverride) ?? "")
    }
    var screenShapeType: ScreenShapeType {
        overrideScreenShapeType ?? seedScreenShapeType
    }
    
    var filter: ScreenFilter
    var backgroundStyle: BackgroundStyle
    var generalCutoutStyle: CutoutStyle
    private var seedCutoutEdges: Set<CutoutEdge>
    private var preferedCutoutEdges: Set<CutoutEdge> {
        screenShapeType.supportsCutouts ? seedCutoutEdges : []
    }
    private var topCutoutPosition: CutoutPosition
    var bottomCutoutPosition: CutoutPosition
    
    private var seedTopMorseCodeSegments: [MorseCodeLine.Segment]?
    var topMorseCodeSegments: [MorseCodeLine.Segment]? {
        screenShapeType.supportsMorseCodeEdges ? seedTopMorseCodeSegments : nil
    }
    private var seedBottomMorseCodeSegments: [MorseCodeLine.Segment]?
    var bottomMorseCodeSegments: [MorseCodeLine.Segment]? {
        screenShapeType.supportsMorseCodeEdges ? seedBottomMorseCodeSegments : nil
    }
    
    var connectedEdges: [UIRectEdge] {
        guard screenShapeType.canConnectToAdjacent else { return [] }
        
        var edges: [UIRectEdge] = []
        if UserDefaults.standard.bool(forKey: UserDefaults.Key.externalDisplayOnTop) {
            edges.append(.top)
        }
        if UserDefaults.standard.bool(forKey: UserDefaults.Key.externalDisplayOnBottom) {
            edges.append(.bottom)
        }
        if UserDefaults.standard.bool(forKey: UserDefaults.Key.externalDisplayOnLeft) {
            edges.append(.left)
        }
        if UserDefaults.standard.bool(forKey: UserDefaults.Key.externalDisplayOnRight) {
            edges.append(.right)
        }
        return edges
    }
    
    var connectedCorners: [UIRectCorner] {
        guard screenShapeType.canConnectToAdjacent else { return [] }
        
        var corners: [UIRectCorner] = []
        if connectedEdges.contains(.top) || connectedEdges.contains(.left) {
            corners.append(.topLeft)
        }
        if connectedEdges.contains(.top) || connectedEdges.contains(.right) {
            corners.append(.topRight)
        }
        if connectedEdges.contains(.bottom) || connectedEdges.contains(.left) {
            corners.append(.bottomLeft)
        }
        if connectedEdges.contains(.bottom) || connectedEdges.contains(.right) {
            corners.append(.bottomRight)
        }
        return corners
    }
    
    var externalDisplayPage: Page {
        guard screenShapeType.canConnectToAdjacent else { return .extOrbits }
        
        if connectedEdges.contains(.right), !connectedEdges.contains(.left) {
            return .extCircularProgressLeft
        } else if connectedEdges.contains(.left), !connectedEdges.contains(.right) {
            return .extCircularProgressRight
        } else {
            return .extOrbits
        }
    }
    
    init(random: GKRandom, design: DesignPrinciples, basicShape: BasicShape, cornerStyle: CornerStyle) {
        backgroundStyle = random.nextElement(in: [BackgroundStyle.gradientUp, .gradientDown, .color])!
        filter = random.nextElement(in: [ScreenFilter.hLines, .vLines, .none])!
        
        let allScreenShapeCases: [WeightedDesignElement<ScreenShapeType>] = [
            .init(baseWeight: 0.1 * (cornerStyle == .circular ? 20 : 1), design: .init(simplicity: 1, sharpness: 0), element: .circle),
            .init(baseWeight: 0.05, design: .init(simplicity: 0.9, sharpness: 1), element: .triangle),
            .init(baseWeight: 1 * (cornerStyle == .circular ? 20 : 1), design: .init(simplicity: 0.9, sharpness: 0.1), element: .capsule),
            .init(baseWeight: 1, design: .init(simplicity: 0.5, sharpness: 0.2), element: .croppedCircle),
            .init(baseWeight: 1, design: .init(simplicity: 0.0, sharpness: 0.7), element: .verticalHexagon),
            .init(baseWeight: 1, design: .init(simplicity: 0.0, sharpness: 0.7), element: .horizontalHexagon),
            .init(baseWeight: 1, design: .init(simplicity: 0.0, sharpness: 0.8), element: .trapezoid),
            .init(baseWeight: 1, design: .init(simplicity: 0.6, sharpness: 0.5), element: .rectangle)
        ]
        seedScreenShapeType = random.nextWeightedElement(in: allScreenShapeCases, with: design)!
        
        if basicShape == .circle {
            generalCutoutStyle = random.nextElement(in: [CutoutStyle.roundedRectangle, .halfRounded, .curved])!
        } else {
            if case .sharp = cornerStyle {
                generalCutoutStyle = .angle45
            } else {
                generalCutoutStyle = random.nextElement(in: [CutoutStyle.roundedRectangle, .halfRounded, .roundedAngle45, .curved])!
            }
        }
        
        seedTopMorseCodeSegments = random.nextBool(chance: 0.25) ? MorseCodeLine.generateMorseCodeSegments(vid: 1, width: 1920, cornerStyle: cornerStyle) : nil
        seedBottomMorseCodeSegments = random.nextBool(chance: 0.25) ? MorseCodeLine.generateMorseCodeSegments(vid: 2, width: 1920, cornerStyle: cornerStyle) : nil
        
        let allCutoutEdges: [WeightedElement<Set<CutoutEdge>>] = [
            .init(weight: 0.333, element: []),
            .init(weight: 0.333, element: [.top, .bottom]),
            .init(weight: 1, element: [.top]),
            .init(weight: 1, element: [.bottom])
        ]
        seedCutoutEdges = random.nextWeightedElement(in: allCutoutEdges)!
        
        let allCutoutPositions: [WeightedElement<CutoutPosition>] = [
            .init(weight: 1, element: .leading),
            .init(weight: 1, element: .trailing),
            .init(weight: 12, element: .center)
        ]
        topCutoutPosition = random.nextWeightedElement(in: allCutoutPositions)!
        bottomCutoutPosition = random.nextWeightedElement(in: allCutoutPositions)!
    }
    
    func actualScreenShapeType(screenSize: CGSize) -> ScreenShapeType {
        switch screenShapeType {
        case .verticalHexagon, .horizontalHexagon:
            switch (500 < screenSize.height, 500 < screenSize.width) {
            case (true, false):
                return .verticalHexagon
            case (false, true):
                return .horizontalHexagon
            default:
                return screenShapeType
            }
        case .circle:
            if screenSize.height < 500 || screenSize.width < 500 {
                return .capsule
            } else {
                return .circle
            }
        case .triangle:
            if screenSize.height < 500 || screenSize.width < 500 {
                return .trapezoid
            } else {
                return .triangle
            }
        default:
            return screenShapeType
        }
    }
    
    func edgesIgnoringSafeAreaForScreenShape(screenSize: CGSize, traitCollection: UITraitCollection) -> Edge.Set {
        #if targetEnvironment(macCatalyst)
        return .all
        #else
        if traitCollection.verticalSizeClass == .compact {
            // Horizontal iPhone; Ignore vertical, and keep horizontal safe area for simplicity
            return .vertical
        } else {
            switch actualScreenShapeType(screenSize: screenSize) {
            case .rectangle:
                if case .sharp = system.cornerStyle {
                    return []
                }
            case .trapezoid:
                let screenTrapezoidHexagonCornerOffset = max(ScreenShape.hardwareCornerRadius, screenSize.width/8)
                let cornerRadius = system.cornerRadius(forLength: min(screenSize.width, screenSize.height))
                
                if case .sharp = system.cornerStyle {
                    if system.shapeDirection == .up {
                        return .top
                    } else {
                        return .bottom
                    }
                } else if (screenSize.width - (screenTrapezoidHexagonCornerOffset + cornerRadius)*2) < 200 {
                    return .bottom
                }
            default:
                break
            }
            return (topMorseCodeSegments == nil && traitCollection.horizontalSizeClass == .regular) ? .all : [.leading, .trailing, .bottom]
        }
        #endif
    }
    
    private func faceIDOverlapsScreenShape(screenSize: CGSize) -> Bool {
        #if os(tvOS)
        false
        #else
        edgesIgnoringSafeAreaForScreenShape(screenSize: screenSize, traitCollection: UIScreen.main.traitCollection).contains(.top) && screenSize.width < 500 && topMorseCodeSegments == nil
        #endif
    }
    
    /// Insets so that content is not obscured by the screen shape and cutouts
    func mainContentInsets(screenSize: CGSize) -> EdgeInsets {
        let screenShapeType = actualScreenShapeType(screenSize: screenSize)
        
        let topOnly = {
            let cutoutOffset = topCutoutStyle(screenSize: screenSize, availableWidth: screenSize.width, insetAmount: 0) == .none ? 0.0 : ScreenShape.cutoutHeight
            let triangleOffset = {
                guard screenShapeType == .triangle else { return 0.0 }
                if system.shapeDirection == .up {
                    return min(screenSize.width, screenSize.height)*0.2
                } else {
                    return 0.0
                }
            }()
            return cutoutOffset + triangleOffset
        }()
        let bottomOnly = {
            let cutoutOffset = bottomCutoutStyle(screenSize: screenSize, availableWidth: screenSize.width, insetAmount: 0) == .none ? 0.0 : ScreenShape.cutoutHeight
            let triangleOffset = {
                guard screenShapeType == .triangle else { return 0.0 }
                if system.shapeDirection == .up {
                    return 0.0
                } else {
                    return min(screenSize.width, screenSize.height)*0.2
                }
            }()
            return cutoutOffset + triangleOffset
        }()
        
        let borderInset = system.prefersBorders ? (system.thickLineWidth + system.borderInsetAmount) : 0
        
        #if targetEnvironment(macCatalyst)
        let normalShape = (screenShapeType != .circle && screenShapeType != .triangle)
        let platformVertical = normalShape ? 50 : 0.0
        let platformHorizontal = normalShape ? 100 : 0.0
        #else
        let platformVertical: CGFloat = 0.0
        let platformHorizontal: CGFloat = 0.0
        #endif
        
        let screenShapeVertical: CGFloat = {
            switch screenShapeType {
            case .capsule:
                return screenSize.height <= screenSize.width ? 0.0 : screenSize.width/4
            case .verticalHexagon:
                return ScreenShape.screenTrapezoidOrHexagonCornerOffset(screenSize: screenSize)
            case .croppedCircle:
                let screenTrapezoidHexagonCornerOffset = ScreenShape.screenTrapezoidOrHexagonCornerOffset(screenSize: screenSize) * 0.75
                return screenSize.height <= screenSize.width ? 0.0 : screenTrapezoidHexagonCornerOffset
            case .circle:
                return screenSize.height/2 - min(screenSize.width, screenSize.height)*0.4
            case .triangle:
                return screenSize.height/2 - min(screenSize.width, screenSize.height)*0.4
            default:
                return 0.0
            }
        }()
        let screenShapeHorizontal: CGFloat = {
            switch screenShapeType {
            case .capsule:
                return screenSize.height <= screenSize.width ? screenSize.height/4 : 0.0
            case .trapezoid:
                return ScreenShape.screenTrapezoidOrHexagonCornerOffset(screenSize: screenSize) - 12
            case .horizontalHexagon:
                return ScreenShape.screenTrapezoidOrHexagonCornerOffset(screenSize: screenSize) - 25
            case .croppedCircle:
                let screenTrapezoidOrHexagonCornerOffset = ScreenShape.screenTrapezoidOrHexagonCornerOffset(screenSize: screenSize) * 0.75
                return screenSize.height <= screenSize.width ? screenTrapezoidOrHexagonCornerOffset : 0.0
            case .circle:
                return screenSize.width/2 - min(screenSize.width, screenSize.height)*0.4
            case .triangle:
                return screenSize.width/2 - min(screenSize.width, screenSize.height)*0.3
            default:
                return 0.0
            }
        }()
        
        let vertical: CGFloat = (500 < screenSize.height ? 16 : 8) + borderInset + platformVertical + screenShapeVertical
        let horizontal: CGFloat = 8 + borderInset + platformHorizontal
        
        let top = topOnly + vertical
        let leading = (screenShapeType.canConnectToAdjacent && connectedEdges.contains(.left)) ? horizontal : horizontal + screenShapeHorizontal
        let bottom = bottomOnly + vertical
        let trailing = (screenShapeType.canConnectToAdjacent && connectedEdges.contains(.right)) ? horizontal : horizontal + screenShapeHorizontal
        return EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
    }
    
    /// Offsets for views in screen corners, to help them fit a bit better
    func safeCornerOffsets(screenSize: CGSize) -> SafeCornerOffsets {
        let cornerRadiusAvoidance: CGFloat = {
            switch actualScreenShapeType(screenSize: screenSize) {
            case .triangle, .capsule:
                return 0.0
            case .circle:
                return min(screenSize.width, screenSize.height) / 24
            default:
                return min(system.cornerRadius(forLength: 600)/8, (screenSize.width + screenSize.height) / 24)
            }
        }()
        var topLeading = connectedCorners.contains(.topLeft) ? .zero : CGSize(width: cornerRadiusAvoidance, height: cornerRadiusAvoidance)
        var topTrailing = connectedCorners.contains(.topRight) ? .zero : CGSize(width: -cornerRadiusAvoidance, height: cornerRadiusAvoidance)
        var bottomLeading = connectedCorners.contains(.bottomLeft) ? .zero : CGSize(width: cornerRadiusAvoidance, height: -cornerRadiusAvoidance)
        var bottomTrailing = connectedCorners.contains(.bottomRight) ? .zero : CGSize(width: -cornerRadiusAvoidance, height: -cornerRadiusAvoidance)
        
        // Push views vertically to the edges of the screen to fill areas beside cutouts
        if 500 < screenSize.width {
            if topCutoutStyle(screenSize: screenSize, availableWidth: screenSize.width, insetAmount: 0) != .none {
                topLeading.height -= ScreenShape.cutoutHeight
                topTrailing.height -= ScreenShape.cutoutHeight
            }
            if bottomCutoutStyle(screenSize: screenSize, availableWidth: screenSize.width, insetAmount: 0) != .none {
                bottomLeading.height += ScreenShape.cutoutHeight
                bottomTrailing.height += ScreenShape.cutoutHeight
            }
        }
        
        // Screen shape compensation
        switch actualScreenShapeType(screenSize: screenSize) {
        case .capsule:
            let capsuleAvoidance = min(screenSize.width, screenSize.height) / 16
            if screenSize.width < screenSize.height {
                // Portrait; Push views horizontally toward the center
                topLeading.width += capsuleAvoidance
                topTrailing.width -= capsuleAvoidance
                bottomLeading.width += capsuleAvoidance
                bottomTrailing.width -= capsuleAvoidance
            } else {
                // Landscape; Push views vertically toward the center
                topLeading.height += capsuleAvoidance
                topTrailing.height += capsuleAvoidance
                bottomLeading.height -= capsuleAvoidance
                bottomTrailing.height -= capsuleAvoidance
            }
        case .horizontalHexagon:
            let hexagonAvoidance = screenSize.width / 32
            // Push views horizontally toward the center
            topLeading.width += hexagonAvoidance
            topTrailing.width -= hexagonAvoidance
            bottomLeading.width += hexagonAvoidance
            bottomTrailing.width -= hexagonAvoidance
        case .triangle:
            let offset = min(screenSize.width, screenSize.height) / 12
            if system.shapeDirection == .up {
                topLeading.width += offset * 1.5
                topTrailing.width -= offset * 1.5
                bottomLeading.width -= offset
                bottomTrailing.width += offset
                
                topLeading.height -= offset * 0.5
                topTrailing.height -= offset * 0.5
            } else {
                topLeading.width -= offset
                topTrailing.width += offset
                bottomLeading.width += offset * 1.5
                bottomTrailing.width -= offset * 1.5
                
                bottomLeading.height += offset * 0.5
                bottomTrailing.height += offset * 0.5
            }
        case .trapezoid:
            // Push views horizontally into corners
            let offset = ScreenShape.screenTrapezoidOrHexagonCornerOffset(screenSize: screenSize) * 0.7
            if system.shapeDirection == .up || connectedCorners.contains(.bottomLeft) {
                bottomLeading.width -= offset
            }
            if system.shapeDirection == .up || connectedCorners.contains(.bottomRight) {
                bottomTrailing.width += offset
            }
            if system.shapeDirection == .down || connectedCorners.contains(.topLeft) {
                topLeading.width -= offset
            }
            if system.shapeDirection == .down || connectedCorners.contains(.topRight) {
                topTrailing.width += offset
            }
        default:
            break
        }
        
        return SafeCornerOffsets(topLeading: topLeading, topTrailing: topTrailing, bottomLeading: bottomLeading, bottomTrailing: bottomTrailing)
    }
    
    func topCutoutStyle(screenSize: CGSize, availableWidth: CGFloat, insetAmount: CGFloat) -> CutoutStyle {
        if availableWidth + insetAmount*2 < 210 || screenShapeType == .verticalHexagon {
            return .none
        } else if (screenShapeType == .capsule || screenShapeType == .croppedCircle || screenShapeType == .horizontalHexagon) && screenSize.width < screenSize.height {
            return .none
        } else if preferedCutoutEdges.contains(.top) || faceIDOverlapsScreenShape(screenSize: screenSize) {
            return generalCutoutStyle
        } else {
            return .none
        }
    }
    
    func bottomCutoutStyle(screenSize: CGSize, availableWidth: CGFloat, insetAmount: CGFloat) -> CutoutStyle {
        if availableWidth + insetAmount*2 < 210 || screenShapeType == .verticalHexagon {
            return .none
        } else if (screenShapeType == .capsule || screenShapeType == .croppedCircle || screenShapeType == .horizontalHexagon) && screenSize.width < screenSize.height {
            return .none
        } else if preferedCutoutEdges.contains(.bottom) {
            return generalCutoutStyle
        } else {
            return .none
        }
    }
    
    func cutoutFrame(screenSize: CGSize, forTop: Bool) -> CGRect? {
        if forTop {
            guard topCutoutStyle(screenSize: screenSize, availableWidth: 999, insetAmount: 0) != .none else { return nil }
        } else {
            guard bottomCutoutStyle(screenSize: screenSize, availableWidth: 999, insetAmount: 0) != .none else { return nil }
        }
        
        let rect = CGRect(origin: .zero, size: screenSize)
        let insetRect = rect
        let insetAmount: CGFloat = 0.0
        
        let cornerRadius: CGFloat = {
            if system.cornerStyle == .sharp {
                return 0.0
            } else if screenShapeType == .capsule {
                return system.cornerRadius(forLength: min(insetRect.width, insetRect.height), cornerStyle: .circular)
            } else if system.cornerStyle == .circular {
                return system.cornerRadius(forLength: min(rect.width, rect.height), cornerStyle: .rounded)
            } else {
                let regularRadius = system.cornerRadius(forLength: min(rect.width, rect.height))
                return max(40.0, (regularRadius - insetAmount) / 2.0)
            }
        }()
        let screenTrapezoidHexagonCornerOffset = max(ScreenShape.hardwareCornerRadius, rect.width/8)
        let replacableWidth: CGFloat = {
            switch screenShapeType {
            case .croppedCircle:
                return insetRect.width - screenTrapezoidHexagonCornerOffset*2.0
            case .verticalHexagon, .horizontalHexagon:
                let riseOverRun = (insetRect.height/2) / screenTrapezoidHexagonCornerOffset
                let angle = atan(riseOverRun)
                let offset = cornerRadius * abs(tan(angle / 2.0))
                return insetRect.width - (screenTrapezoidHexagonCornerOffset + offset)*2.0
            case .trapezoid:
                let topSideLength = insetRect.width - screenTrapezoidHexagonCornerOffset*2
                let topLeadingSpace = (insetRect.size.width - topSideLength)/2
                let riseOverRun = insetRect.size.height / topLeadingSpace
                let angle = atan(riseOverRun)
                let topOffset = cornerRadius * abs(tan(angle / 2.0))
                return insetRect.width - (screenTrapezoidHexagonCornerOffset + topOffset)*2.0
            default:
                return insetRect.width - cornerRadius*2.0
            }
        }()
        let cutoutHeight: CGFloat = 50.0
        
        let totalTransitionWidth: CGFloat = {
            switch generalCutoutStyle {
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
        let maxCutoutContentWidth = min(replacableWidth - totalTransitionWidth, 600.0)
        let preferedCutoutContentWidth = insetRect.width*0.35
        let cutoutContentWidth = min(preferedCutoutContentWidth, maxCutoutContentWidth)
        let totalLengthAroundCutout = (replacableWidth - cutoutContentWidth - totalTransitionWidth)
        var topLeadingLengthBeforeCutout = totalLengthAroundCutout/2
        var bottomLeadingLengthBeforeCutout = totalLengthAroundCutout/2
        
        if 200 < totalLengthAroundCutout {
            if getTopCutoutPosition(screenSize: UIScreen.main.bounds.size) == .leading {
                topLeadingLengthBeforeCutout = totalLengthAroundCutout * 0.333333
            } else if getTopCutoutPosition(screenSize: UIScreen.main.bounds.size) == .trailing {
                topLeadingLengthBeforeCutout = totalLengthAroundCutout * 0.666666
            }
            if bottomCutoutPosition == .leading {
                bottomLeadingLengthBeforeCutout = totalLengthAroundCutout * 0.333333
            } else if bottomCutoutPosition == .trailing {
                bottomLeadingLengthBeforeCutout = totalLengthAroundCutout * 0.666666
            }
        }
        
        if forTop {
            // x value is an offset from the center, not an actual origin.x
            return CGRect(x: topLeadingLengthBeforeCutout - totalLengthAroundCutout/2, y: rect.minY, width: cutoutContentWidth, height: cutoutHeight)
        } else {
            return CGRect(x: bottomLeadingLengthBeforeCutout - totalLengthAroundCutout/2, y: rect.maxY - cutoutHeight, width: cutoutContentWidth, height: cutoutHeight)
        }
    }
    
    func getTopCutoutPosition(screenSize: CGSize) -> CutoutPosition {
        faceIDOverlapsScreenShape(screenSize: screenSize) ? .center : topCutoutPosition
    }
    
}
