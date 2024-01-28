//
//  Color.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2018-03-09.
//  Copyright © 2018 256 Arts Developer. All rights reserved.
//

import SwiftUI
import GameplayKit

var system = SystemStyles(seed: seed) {
    didSet {
        AppController.shared.reloadRootView()
        ScreenShape.pathCache.removeAll()
    }
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
enum BasicShape {
    case circle, triangle, square, hexagon, trapezoid, diamond
}
enum ShapeDirection {
    case up, down
}
enum CornerStyle {
    case sharp, rounded
    /// Creates capsule shapes
    case circular
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

final class SystemStyles: ObservableObject {
    
    let random: GKRandomDistribution
    let seed: UInt64
    
    // Subsystems
    let design: DesignPrinciples
    let colors: SystemColors
    let screen: ScreenStyles
    
    // General
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
    var prefersProminentButtons: Bool
    var prefersButtonBorders: Bool
    var prefersDashedLines: Bool
    var prefersRandomLineDashing: Bool
    var basicShapeHStackSpacing: CGFloat
    var screenBorderInsetAmount: CGFloat
    var mediumLineWidthBase: CGFloat
    var thinLineWidth: CGFloat {
        mediumLineWidth / 2
    }
    var mediumLineWidth: CGFloat {
        #if os(tvOS)
        round(mediumLineWidthBase * 1.5)
        #elseif targetEnvironment(macCatalyst)
        round(mediumLineWidthBase * 1.2)
        #else
        round(mediumLineWidthBase)
        #endif
    }
    var thickLineWidth: CGFloat {
        mediumLineWidth * 2
    }
    var screenBorderWidth: CGFloat? {
        guard prefersBorders, (!colors.useLightAppearance || !screenBorderInsetAmount.isZero) else { return nil }
        
        return thickLineWidth
    }
    
    // Colors
    var buttonTextColor: Color {
        if prefersProminentButtons {
            return Color.screenBackground
        } else {
            return Color(color: .secondary, opacity: .max)
        }
    }
    var binaryNumberColors: [FillAndBorder] {
        switch colors.paletteStyle {
        case .colorful:
            return [
                FillAndBorder(fill: Color(color: .primary, opacity: .max)),
                FillAndBorder(fill: Color(color: .secondary, opacity: .max)),
                FillAndBorder(fill: Color(color: .tertiary, opacity: .max))
            ]
        case .limited:
            return [
                (prefersBorders ? FillAndBorder(fill: .clear, border: Color(color: .primary, opacity: .max)) : FillAndBorder(fill: Color(color: .primary, opacity: .min))),
                FillAndBorder(fill: Color(color: .primary, opacity: .max)),
                FillAndBorder(fill: Color(color: .secondary, opacity: .max))
            ]
        case .monochrome:
            return [
                FillAndBorder(fill: .clear, border: Color(color: .primary, opacity: .max)),
                FillAndBorder(fill: Color(color: .primary, opacity: .max)),
                FillAndBorder(fill: Color(color: .primary, opacity: .medium))
            ]
        }
    }
    
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
        let allBasicShapes: [WeightedDesignElement<BasicShape>] = [
            .init(baseWeight: 1, design: .init(simplicity: 1.0, sharpness: 0.0), element: .circle),
            .init(baseWeight: 0.75, design: .init(simplicity: 0.7, sharpness: 1.0), element: .triangle),
            .init(baseWeight: 1, design: .init(simplicity: 0.6, sharpness: 0.5), element: .square),
            .init(baseWeight: 1, design: .init(simplicity: 0.4, sharpness: 0.3), element: .hexagon),
            .init(baseWeight: 0.75, design: .init(simplicity: 0.1, sharpness: 0.7), element: .trapezoid),
            .init(baseWeight: 0.75, design: .init(simplicity: 0.6, sharpness: 0.5), element: .diamond)
        ]
        basicShape = random.nextWeightedElement(in: allBasicShapes, with: design)!
        
        let cornerStyle: CornerStyle
        if basicShape == .circle {
            cornerStyle = .circular
        } else {
            let allCornerStyles: [WeightedDesignElement<CornerStyle>] = [
                .init(baseWeight: 3, design: .init(simplicity: 0.5, sharpness: 0.5), element: .rounded),
                .init(baseWeight: 1, design: .init(simplicity: 0.8, sharpness: 1.0), element: .sharp),
                .init(baseWeight: 1, design: .init(simplicity: 1.0, sharpness: 0.0), element: .circular)
            ]
            cornerStyle = random.nextWeightedElement(in: allCornerStyles, with: design)!
        }
        
        // Subsystems
        screen = ScreenStyles(random: random, design: design, basicShape: basicShape, cornerStyle: cornerStyle)
        
        // General
        alignment = random.nextElement(in: [Alignment.vertical, .horizontal, .none])!
        
        switch basicShape {
        case .hexagon, .triangle, .trapezoid:
            shapeDirection = (random.nextBool(chance: 0.333)) ? .down : .up
        default:
            shapeDirection = .up
        }
        
        roundedCornerFraction = 0.1 + CGFloat(random.nextDouble(in: 0...0.1))
        self.cornerStyle = cornerStyle
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
        prefersProminentButtons = random.nextBool(chance: 0.25)
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
        let screenBorderInsetAmount = random.nextBool(chance: 0.1) ? CGFloat(random.nextInt(upperBound: 7))*2.0 : 0.0
        self.screenBorderInsetAmount = prefersBorders ? screenBorderInsetAmount : 0
        prefersRandomLineDashing = random.nextBool(chance: 0.2) ? prefersDashedLines : false
        mediumLineWidthBase = 2.0 + CGFloat(design.boldness * 4.0)
        
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
        if prefersDashedLines {
            let roundLineCapCompensation = lineCap == .round ? lineWidth : 0
            dash = Array.init(repeating: roundLineCapCompensation + CGFloat.random(in: 2...6), count: 25)
            if prefersRandomLineDashing {
                for index in 0..<dash.count {
                    dash[index] = roundLineCapCompensation + CGFloat.random(in: 8...256)
                }
            }
        }
        return dash
    }
    
    func buttonBackgroundColor(isDisabled: Bool, isSelected: Bool) -> Color {
        if prefersProminentButtons {
            if isDisabled {
                return .clear
            } else {
                return isSelected ? Color(color: .tertiary, brightness: .max) : Color(color: .primary, brightness: .max)
            }
        } else {
            if isDisabled {
                return .clear
            } else {
                return isSelected ? Color(color: .tertiary, brightness: .medium) : Color(color: .primary, brightness: .low)
            }
        }
    }
}
