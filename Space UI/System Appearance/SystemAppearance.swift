//
//  Color.swift
//  Space UI
//
//  Created by Jayden Irwin on 2018-03-09.
//  Copyright © 2018 Jayden Irwin. All rights reserved.
//

import SwiftUI
import GameplayKit

var seed: UInt64 = {
    let savedSeed = UserDefaults.standard.integer(forKey: UserDefaults.Key.seed)
    if savedSeed == 0 {
        let newSeed = UInt64(arc4random())
        UserDefaults.standard.set(Int(newSeed), forKey: UserDefaults.Key.seed)
        return newSeed
    } else {
        return UInt64(savedSeed)
    }
}()
var system = SystemAppearance(seed: seed)

enum SystemColor {
    case primary, secondary, tertiary, danger
}
enum Opacity {
    case min, low, medium, high, max
}
enum PaletteStyle {
    case colorful, monochrome, limited
}
enum BackgroundStyle {
    case color, gradientUp, gradientDown
}
enum ScreenFilter {
    case none, hLines, vLines
}
enum Alignment {
    case none, vertical, horizontal
}
enum LineWidth {
    case thin, medium, thick
}
enum ScreenShapeCase: String, CaseIterable {
    case rectangle, capsule, circle, croppedCircle, verticalHexagon, horizontalHexagon, trapezoid, triangle
}
enum BasicShape {
    case circle, triangle, square, hexagon, trapezoid, diamond
}
enum ShapeDirection {
    case up, down
}
enum CornerStyle {
    case sharp, rounded, circular
}
enum CutoutStyle {
    case angle45, roundedAngle45, roundedRectangle, halfRounded, curved, none
}
enum CutoutEdge {
    case top, bottom
}
enum CutoutPosition {
    case leading, center, trailing
}
enum ArrowStyle {
    case triangle, droplet, pieSlice, map, concaveMap
}
enum ButtonSizingMode {
    case fixed, flexable
}

final class SystemAppearance: ObservableObject {
    
    let random: GKRandomDistribution
    let seed: UInt64
    
    // Subsystems
    let design: DesignPrinciples
    let colors: SystemColors
    
    // General
    var backgroundStyle: BackgroundStyle
    var alignment: Alignment
    var basicShape: BasicShape
    var shapeDirection: ShapeDirection
    var cornerStyle: CornerStyle
    var roundedCornerFraction: CGFloat
    var lineCap: CGLineCap
    var changeSquareButtonToRect: Bool
    var shapeButtonFrameWidth: CGFloat
    var shapeButtonFrameHeight: CGFloat
    var flexButtonFrameHeight: CGFloat = 54.0
    var preferedButtonSizingMode: ButtonSizingMode
    var circularSegmentedViewCurvedOuterEdge: Bool
    var prefersBorders: Bool
    var prefersButtonBorders: Bool
    var prefersDashedLines: Bool
    var prefersRandomLineDashing: Bool
    var basicShapeHStackSpacing: CGFloat
    var borderInsetAmount: CGFloat
    var thinLineWidth: CGFloat {
        mediumLineWidth / 2
    }
    var mediumLineWidth: CGFloat
    var thickLineWidth: CGFloat {
        mediumLineWidth * 2
    }
    
    // Screen
    var screenShapeCase: ScreenShapeCase
    var screenMinBrightness: CGFloat
    var screenFilter: ScreenFilter
    var screenStrokeStyle: StrokeStyle? {
        prefersBorders ? StrokeStyle(lineWidth: thickLineWidth, lineCap: lineCap, dash: lineDash(lineWidth: thickLineWidth)) : nil
    }
    var generalCutoutStyle: CutoutStyle
    private var preferedCutoutEdges: Set<CutoutEdge>
    private var topCutoutPosition: CutoutPosition
    var bottomCutoutPosition: CutoutPosition
    var topMorseCodeSegments: [MorseCodeLine.Segment]?
    var bottomMorseCodeSegments: [MorseCodeLine.Segment]?
    
    // Fonts
    private var defaultFontName: Font.Name
    var fontOverride = false
    var fontName: Font.Name? {
        fontOverride ? nil : defaultFontName
    }
    var defaultFontSize: CGFloat
    
    // Sounds
    var actionSoundResource: AudioController.Resource
    var buttonSoundResource: AudioController.Resource
    var alarmSoundResource: AudioController.Resource
    
    init(seed: UInt64) {
        self.seed = seed
        let source = GKMersenneTwisterRandomSource(seed: seed)
        random = GKRandomDistribution(randomSource: source, lowestValue: 0, highestValue: Int.max)
        srand48(Int(seed)) // Set seed for drand48?
        
        // Subsystems
        design = DesignPrinciples(simplicity: random.nextFraction(), sharpness: random.nextFraction(), order: random.nextFraction(), balance: random.nextFraction(), boldness: random.nextFraction())
        colors = SystemColors(random: random)
        
        // General
        screenMinBrightness = CGFloat(random.nextDouble(in: 0...0.4))
        backgroundStyle = random.nextElement(in: [BackgroundStyle.gradientUp, .gradientDown, .color])!
        screenFilter = random.nextElement(in: [ScreenFilter.hLines, .vLines, .none])!
        
        let allScreenShapeCases: [WeightedDesignElement<ScreenShapeCase>] = [
            .init(baseWeight: 0.1, design: .init(simplicity: 1, sharpness: 0), element: .circle),
            .init(baseWeight: 0.05, design: .init(simplicity: 0.9, sharpness: 1), element: .triangle),
            .init(baseWeight: 1, design: .init(simplicity: 0.9, sharpness: 0.1), element: .capsule),
            .init(baseWeight: 1, design: .init(simplicity: 0.5, sharpness: 0.2), element: .croppedCircle),
            .init(baseWeight: 1, design: .init(simplicity: 0.0, sharpness: 0.7), element: .verticalHexagon),
            .init(baseWeight: 1, design: .init(simplicity: 0.0, sharpness: 0.7), element: .horizontalHexagon),
            .init(baseWeight: 1, design: .init(simplicity: 0.0, sharpness: 0.8), element: .trapezoid),
            .init(baseWeight: 1, design: .init(simplicity: 0.6, sharpness: 0.5), element: .rectangle)
        ]
        screenShapeCase = random.nextWeightedElement(in: allScreenShapeCases, with: design)!
        if let screenShapeOverrideString = UserDefaults.standard.string(forKey: UserDefaults.Key.screenShapeCaseOverride),
            let screenShapeOverride = ScreenShapeCase(rawValue: screenShapeOverrideString) {
            self.screenShapeCase = screenShapeOverride
        }
        
        alignment = random.nextElement(in: [Alignment.vertical, .horizontal, .none])!
        
        let allBasicShapes: [WeightedDesignElement<BasicShape>] = [
            .init(baseWeight: 1, design: .init(simplicity: 1.0, sharpness: 0.0), element: .circle),
            .init(baseWeight: 0.75, design: .init(simplicity: 0.7, sharpness: 1.0), element: .triangle),
            .init(baseWeight: 1, design: .init(simplicity: 0.6, sharpness: 0.5), element: .square),
            .init(baseWeight: 1, design: .init(simplicity: 0.4, sharpness: 0.3), element: .hexagon),
            .init(baseWeight: 0.75, design: .init(simplicity: 0.1, sharpness: 0.7), element: .trapezoid),
            .init(baseWeight: 0.75, design: .init(simplicity: 0.6, sharpness: 0.5), element: .diamond)
        ]
        basicShape = random.nextWeightedElement(in: allBasicShapes, with: design)!
        
        switch basicShape {
        case .hexagon, .triangle, .trapezoid:
            shapeDirection = (random.nextBool(chance: 0.333)) ? .down : .up
        default:
            shapeDirection = .up
        }
        let cornerStyle: CornerStyle
        if basicShape == .circle {
            cornerStyle = .circular
            generalCutoutStyle = random.nextElement(in: [CutoutStyle.roundedRectangle, .halfRounded, .curved])!
        } else {
            switch screenShapeCase {
            case .croppedCircle, .verticalHexagon, .horizontalHexagon, .trapezoid, .rectangle:
                cornerStyle = random.nextBool(chance: 0.25) ? .sharp : .rounded
            case .capsule:
                cornerStyle = .circular
            default:
                cornerStyle = .rounded
            }
            if case .sharp = cornerStyle {
                generalCutoutStyle = .angle45
            } else {
                generalCutoutStyle = random.nextElement(in: [CutoutStyle.roundedRectangle, .halfRounded, .roundedAngle45, .curved])!
            }
        }
        
        func generateMorseCodeSegments() -> [MorseCodeLine.Segment] {
            let useColorShades = Bool.random()
            let shades: [Opacity] = [.low, .medium, .high, .max]
            var nodeLengths: [CGFloat] = [20, 20, 20, 40, 80, 120]
            if cornerStyle != .circular {
                nodeLengths.append(10)
            }
            let spaceLengths: [CGFloat] = [20, 40, 80, 120, 160, 200]
            
            var segs = [MorseCodeLine.Segment]()
            var sum: CGFloat = 0.0
            while sum < 1920.0 {
                let opacity = useColorShades ? shades.randomElement()! : Opacity.max
                let systemColor: SystemColor = {
                    switch Int.random(in: 0..<4) {
                    case 0:
                        return .secondary
                    case 1:
                        return .tertiary
                    default:
                        return .primary
                    }
                }()
                let nl = MorseCodeLine.Segment(length: nodeLengths.randomElement()!, systemColor: systemColor, opacity: opacity)
                let sl = MorseCodeLine.Segment(length: spaceLengths.randomElement()!, systemColor: nil, opacity: .min)
                segs.append(nl)
                segs.append(sl)
                sum += nl.length + sl.length
            }
            return segs
        }
        switch screenShapeCase {
        case .circle, .triangle, .verticalHexagon:
            topMorseCodeSegments = nil
            bottomMorseCodeSegments = nil
        default:
            topMorseCodeSegments = random.nextBool(chance: 0.25) ? generateMorseCodeSegments() : nil
            bottomMorseCodeSegments = random.nextBool(chance: 0.25) ? generateMorseCodeSegments() : nil
        }
        
        roundedCornerFraction = 0.1 + CGFloat(random.nextDouble(in: 0...0.1))
        self.cornerStyle = cornerStyle
        if screenShapeCase == .circle || screenShapeCase == .triangle {
            preferedCutoutEdges = []
        } else {
            let allCutoutEdges: [WeightedElement<Set<CutoutEdge>>] = [
                .init(weight: 0.333, element: []),
                .init(weight: 0.333, element: [.top, .bottom]),
                .init(weight: 1, element: [.top]),
                .init(weight: 1, element: [.bottom])
            ]
            preferedCutoutEdges = random.nextWeightedElement(in: allCutoutEdges)!
        }
        let allCutoutPositions: [WeightedElement<CutoutPosition>] = [
            .init(weight: 1, element: .leading),
            .init(weight: 1, element: .trailing),
            .init(weight: 12, element: .center)
        ]
        topCutoutPosition = random.nextWeightedElement(in: allCutoutPositions)!
        bottomCutoutPosition = random.nextWeightedElement(in: allCutoutPositions)!
        switch cornerStyle {
        case .circular:
            lineCap = .round
        case .rounded:
            lineCap = random.nextBool() ? .round : .butt
        case .sharp:
            lineCap = .butt
        }
        let changeSquareButtonToRect = random.nextBool()
        self.changeSquareButtonToRect = changeSquareButtonToRect
        switch basicShape {
        case .circle:
            shapeButtonFrameWidth = 84
            shapeButtonFrameHeight = 84
        case .square:
            if changeSquareButtonToRect {
                shapeButtonFrameWidth = 90
                shapeButtonFrameHeight = 56
            } else {
                shapeButtonFrameWidth = 80
                shapeButtonFrameHeight = 80
            }
        case .trapezoid:
            shapeButtonFrameWidth = 90
            shapeButtonFrameHeight = 56
        case .triangle:
            shapeButtonFrameWidth = 104
            shapeButtonFrameHeight = 104
        case .diamond:
            shapeButtonFrameWidth = 100
            shapeButtonFrameHeight = 100
        case .hexagon:
            shapeButtonFrameWidth = 94
            shapeButtonFrameHeight = 94
        }
        preferedButtonSizingMode = random.nextBool(chance: 0.1) ? .flexable : .fixed
        switch basicShape {
        case .circle:
            circularSegmentedViewCurvedOuterEdge = true
        case .hexagon:
            circularSegmentedViewCurvedOuterEdge = false
        default:
            circularSegmentedViewCurvedOuterEdge = random.nextBool()
        }
        let prefersBorders = random.nextBool(chance: 0.666)
        self.prefersBorders = prefersBorders
        prefersButtonBorders = random.nextBool(chance: 0.333) ? false : prefersBorders
        let prefersDashedLines = random.nextBool(chance: 0.333)
        self.prefersDashedLines = prefersDashedLines
        if preferedButtonSizingMode == .fixed {
            switch basicShape {
            case .triangle:
                basicShapeHStackSpacing = -12
            case .trapezoid:
                basicShapeHStackSpacing = 0
            case .hexagon:
                basicShapeHStackSpacing = 12
            default:
                basicShapeHStackSpacing = 16
            }
        } else {
            basicShapeHStackSpacing = 16
        }
        borderInsetAmount = random.nextBool(chance: 0.1) ? CGFloat(random.nextInt(upperBound: 7))*2.0 : 0.0
        prefersRandomLineDashing = random.nextBool(chance: 0.2) ? prefersDashedLines : false
        mediumLineWidth = 2.0 + CGFloat(design.boldness * 4.0)
        
        let allFonts: [WeightedDesignElement<Font.Name>] = [
            .init(baseWeight: 1, design: .init(sharpness: 0.5, boldness: 1.0), element: .abEquinox),
            .init(baseWeight: 1, design: .init(sharpness: 0.4, boldness: 0.7), element: .auraboo),
            .init(baseWeight: 2, design: .init(sharpness: 0.0, boldness: 0.8), element: .aurebeshBloops),
            .init(baseWeight: 2, design: .init(sharpness: 0.1, boldness: 0.6), element: .aurebeshDroid),
            .init(baseWeight: 1, design: .init(sharpness: 0.6, boldness: 0.8), element: .aurebeshRacerFast),
            .init(baseWeight: 4, design: .init(sharpness: 0.9, boldness: 0.5), element: .aurekBesh),
            .init(baseWeight: 1, design: .init(sharpness: 0.1, boldness: 0.4), element: .baybayin),
            .init(baseWeight: 1, design: .init(sharpness: 0.9, boldness: 0.1), element: .clyneseBend),
            .init(baseWeight: 1, design: .init(sharpness: 0.6, boldness: 0.8), element: .fresian),
            .init(baseWeight: 2, design: .init(sharpness: 0.9, boldness: 0.6), element: .galactico),
            .init(baseWeight: 1, design: .init(sharpness: 0.9, boldness: 0.1), element: .geonosian),
            .init(baseWeight: 1, design: .init(sharpness: 0.6, boldness: 0.4), element: .kyberCrystal),
            .init(baseWeight: 1, design: .init(sharpness: 1.0, boldness: 0.2), element: .mando),
            .init(baseWeight: 1, design: .init(sharpness: 0.8, boldness: 0.4), element: .outerRim),
            .init(baseWeight: 1, design: .init(sharpness: 0.7, boldness: 0.7), element: .sga2),
            .init(baseWeight: 1, design: .init(sharpness: 0.4, boldness: 0.0), element: .theCalling),
            .init(baseWeight: 1, design: .init(sharpness: 0.3, boldness: 0.6), element: .tradeFederation),
            .init(baseWeight: 1, design: .init(simplicity: 1.0, sharpness: 0.0, boldness: 0.6), element: .umbaran)
        ]
        defaultFontName = random.nextWeightedElement(in: allFonts, with: design)!
        defaultFontSize = defaultFontName.defaultFontSize
        
        actionSoundResource = random.nextBool() ? .action : .action2
        buttonSoundResource = random.nextElement(in: [AudioController.Resource.button, .button2, .button3])!
        alarmSoundResource = random.nextBool() ? .alarmLoop : .alarmHighLoop
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (_) in
            AudioController.shared.makeSoundsForSystem()
        }
    }
    
    func cornerRadius(forLength length: CGFloat, cornerStyle: CornerStyle = system.cornerStyle) -> CGFloat {
        switch cornerStyle {
        case .sharp:
            return 0.0
        case .circular:
            return length / 2.0
        case .rounded:
            return length * roundedCornerFraction
        }
    }
    
    func strokeStyle(_ lineWidth: LineWidth, lineJoin: CGLineCap = system.lineCap, dashed: Bool = false) -> StrokeStyle {
        let lineWidthValue = {
            switch lineWidth {
            case .thin:
                return self.mediumLineWidth / 2
            case .medium:
                return self.mediumLineWidth
            case .thick:
                return self.mediumLineWidth * 2
            }
        }()
        return StrokeStyle(lineWidth: lineWidthValue, lineCap: lineCap, dash: dashed ? lineDash(lineWidth: lineWidthValue) : [])
    }
    
    func lineDash(lineWidth: CGFloat) -> [CGFloat] {
        var dash = [CGFloat]()
        if system.prefersDashedLines {
            let roundLineCapCompensation = system.lineCap == .round ? lineWidth : 0
            dash = Array.init(repeating: roundLineCapCompensation + CGFloat.random(in: 2...6), count: 25)
            if system.prefersRandomLineDashing {
                for index in 0..<dash.count {
                    dash[index] = roundLineCapCompensation + CGFloat.random(in: 8...256)
                }
            }
        }
        return dash
    }
    
    func edgesIgnoringSafeAreaForScreenShape(screenSize: CGSize, traitCollection: UITraitCollection) -> Edge.Set {
        #if targetEnvironment(macCatalyst)
        return .all
        #else
        if traitCollection.verticalSizeClass == .compact {
            // Horizontal iPhone; Ignore vertical, and keep horizontal safe area for simplicity
            return .vertical
        } else {
            switch screenShapeCase {
            case .verticalHexagon, .horizontalHexagon, .croppedCircle, .capsule:
                if traitCollection.horizontalSizeClass == .compact {
                    return .bottom
                }
            case .rectangle:
                if case .sharp = system.cornerStyle {
                    return []
                }
            case .trapezoid:
                let screenTrapezoidHexagonCornerOffset = max(44, screenSize.width/8)
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
            return (system.topMorseCodeSegments == nil) ? .all : [.leading, .trailing, .bottom]
        }
        #endif
    }
    
    private func cameraNotchObscuresScreenShape(screenSize: CGSize) -> Bool {
        edgesIgnoringSafeAreaForScreenShape(screenSize: screenSize, traitCollection: UIScreen.main.traitCollection).contains(.top) && screenSize.width < 500 && topMorseCodeSegments == nil
    }
    
    /// Insets so that content is not obscured by the screen shape and cutouts
    func mainContentInsets(screenSize: CGSize) -> EdgeInsets {
        let screenShapeCase = actualScreenShapeCase(screenSize: screenSize)
        
        let topOnly = {
            let cutoutOffset = topCutoutStyle(screenSize: screenSize, availableWidth: screenSize.width, insetAmount: 0) == .none ? 0.0 : ScreenShape.cutoutHeight
            let triangleOffset = {
                guard screenShapeCase == .triangle else { return 0.0 }
                if shapeDirection == .up {
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
                guard screenShapeCase == .triangle else { return 0.0 }
                if shapeDirection == .up {
                    return 0.0
                } else {
                    return min(screenSize.width, screenSize.height)*0.2
                }
            }()
            return cutoutOffset + triangleOffset
        }()
        
        let borderInset = system.prefersBorders ? (system.thickLineWidth + system.borderInsetAmount) : 0
        
        #if targetEnvironment(macCatalyst)
        let normalShape = (screenShapeCase != .circle && screenShapeCase != .triangle)
        let platformVertical = normalShape ? 50 : 0.0
        let platformHorizontal = normalShape ? 100 : 0.0
        #else
        let platformVertical: CGFloat = 0.0
        let platformHorizontal: CGFloat = 0.0
        #endif
        
        let vertical: CGFloat = (500 < screenSize.height ? 16 : 8) + borderInset + platformVertical + {
            switch screenShapeCase {
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
        let horizontal: CGFloat = 8 + borderInset + platformHorizontal + {
            switch screenShapeCase {
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
        
        let top = topOnly + vertical
        let bottom = bottomOnly + vertical
        return EdgeInsets(top: top, leading: horizontal, bottom: bottom, trailing: horizontal)
    }
    
    func actualScreenShapeCase(screenSize: CGSize) -> ScreenShapeCase {
        switch system.screenShapeCase {
        case .verticalHexagon, .horizontalHexagon:
            switch (500 < screenSize.height, 500 < screenSize.width) {
            case (true, false):
                return .verticalHexagon
            case (false, true):
                return .horizontalHexagon
            default:
                return system.screenShapeCase
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
            return system.screenShapeCase
        }
    }
    
    /// Offsets for views in screen corners, to help them fit a bit better
    func safeCornerOffsets(screenSize: CGSize) -> SafeCornerOffsets {
        let cornerRadiusAvoidance: CGFloat = {
            switch actualScreenShapeCase(screenSize: screenSize) {
            case .triangle, .capsule:
                return 0.0
            case .circle:
                return min(screenSize.width, screenSize.height) / 24
            default:
                return min(cornerRadius(forLength: 600)/8, (screenSize.width + screenSize.height) / 24)
            }
        }()
        var topLeading = CGSize(width: cornerRadiusAvoidance, height: cornerRadiusAvoidance)
        var topTrailing = CGSize(width: -cornerRadiusAvoidance, height: cornerRadiusAvoidance)
        var bottomLeading = CGSize(width: cornerRadiusAvoidance, height: -cornerRadiusAvoidance)
        var bottomTrailing = CGSize(width: -cornerRadiusAvoidance, height: -cornerRadiusAvoidance)
        
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
        switch actualScreenShapeCase(screenSize: screenSize) {
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
            let offset = ScreenShape.screenTrapezoidOrHexagonCornerOffset(screenSize: screenSize) * 0.7
            if system.shapeDirection == .up {
                bottomLeading.width -= offset
                bottomTrailing.width += offset
            } else {
                topLeading.width -= offset
                topTrailing.width += offset
            }
        default:
            break
        }
        
        return SafeCornerOffsets(topLeading: topLeading, topTrailing: topTrailing, bottomLeading: bottomLeading, bottomTrailing: bottomTrailing)
    }
    
    func topCutoutStyle(screenSize: CGSize, availableWidth: CGFloat, insetAmount: CGFloat) -> CutoutStyle {
        if availableWidth + insetAmount*2 < 210 || screenShapeCase == .verticalHexagon {
            return .none
        } else if (screenShapeCase == .capsule || screenShapeCase == .croppedCircle || screenShapeCase == .horizontalHexagon) && screenSize.width < screenSize.height {
            return .none
        } else if preferedCutoutEdges.contains(.top) || cameraNotchObscuresScreenShape(screenSize: screenSize) {
            return generalCutoutStyle
        } else {
            return .none
        }
    }
    
    func bottomCutoutStyle(screenSize: CGSize, availableWidth: CGFloat, insetAmount: CGFloat) -> CutoutStyle {
        if availableWidth + insetAmount*2 < 210 || screenShapeCase == .verticalHexagon {
            return .none
        } else if (screenShapeCase == .capsule || screenShapeCase == .croppedCircle || screenShapeCase == .horizontalHexagon) && screenSize.width < screenSize.height {
            return .none
        } else if preferedCutoutEdges.contains(.bottom) {
            return generalCutoutStyle
        } else {
            return .none
        }
    }
    
    func cutoutFrame(screenSize: CGSize, forTop: Bool) -> CGRect? {
        if forTop {
            guard system.topCutoutStyle(screenSize: screenSize, availableWidth: 999, insetAmount: 0) != .none else { return nil }
        } else {
            guard system.bottomCutoutStyle(screenSize: screenSize, availableWidth: 999, insetAmount: 0) != .none else { return nil }
        }
        
        let rect = CGRect(origin: .zero, size: screenSize)
        let insetRect = rect
        let insetAmount: CGFloat = 0.0
        
        let cornerRadius: CGFloat = {
            if cornerStyle == .sharp {
                return 0.0
            } else if screenShapeCase == .capsule {
                return system.cornerRadius(forLength: min(insetRect.width, insetRect.height))
            } else if cornerStyle == .circular {
                return system.cornerRadius(forLength: min(rect.width, rect.height), cornerStyle: .rounded)
            } else {
                let regularRadius = system.cornerRadius(forLength: min(rect.width, rect.height))
                return max(40.0, (regularRadius - insetAmount) / 2.0)
            }
        }()
        let screenTrapezoidHexagonCornerOffset = max(44, rect.width/8)
        let replacableWidth: CGFloat = {
            switch system.screenShapeCase {
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
            switch system.generalCutoutStyle {
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
            if system.getTopCutoutPosition(screenSize: UIScreen.main.bounds.size) == .leading {
                topLeadingLengthBeforeCutout = totalLengthAroundCutout * 0.333333
            } else if system.getTopCutoutPosition(screenSize: UIScreen.main.bounds.size) == .trailing {
                topLeadingLengthBeforeCutout = totalLengthAroundCutout * 0.666666
            }
            if system.bottomCutoutPosition == .leading {
                bottomLeadingLengthBeforeCutout = totalLengthAroundCutout * 0.333333
            } else if system.bottomCutoutPosition == .trailing {
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
        cameraNotchObscuresScreenShape(screenSize: screenSize) ? .center : topCutoutPosition
    }
    
    func reloadRootView() {
        objectWillChange.send()
    }
}
