import SwiftUI
import Synchronization

var savedDesignPrinciples: DesignPrinciples? {
    guard UserDefaults.standard.bool(forKey: UserDefaults.Key.applyDesignPrinciples) else { return nil }

    // `@AppStorage` persists `DesignPrinciples` as its comma-joined raw string, so it must be read back through
    // `init(rawValue:)` — `object(forKey:) as? DesignPrinciples` always returned nil, so the sliders never applied.
    return UserDefaults.standard.string(forKey: UserDefaults.Key.designPrinciples).flatMap(DesignPrinciples.init(rawValue:))
}

var savedPrimaryHue: CGFloat? {
    guard UserDefaults.standard.bool(forKey: UserDefaults.Key.applyDesignPrinciples) else { return nil }
    
    // `@AppStorage` stores this as a `Double`; cast through `Double` rather than the unreliable `as? CGFloat`.
    return (UserDefaults.standard.object(forKey: UserDefaults.Key.primaryHue) as? Double).map { CGFloat($0) }
}

var savedPrimarySaturation: CGFloat? {
    guard UserDefaults.standard.bool(forKey: UserDefaults.Key.applyDesignPrinciples) else { return nil }
    
    return (UserDefaults.standard.object(forKey: UserDefaults.Key.primarySaturation) as? Double).map { CGFloat($0) }
}

var savedConfig: Config {
    Config(
        seed: seed,
        designPrinciples: savedDesignPrinciples,
        primaryHue: savedPrimaryHue,
        primarySaturation: savedPrimarySaturation
    )
}

/// A fresh, randomly-seeded config carrying the user's saved design overrides. Used by every
/// "regenerate the theme" affordance so they all pick a new seed the same way.
var randomConfig: Config {
    Config(
        seed: UInt64(arc4random()),
        designPrinciples: savedDesignPrinciples,
        primaryHue: savedPrimaryHue,
        primarySaturation: savedPrimarySaturation
    )
}

/// The screen treatment generated alongside the current theme. A window's own treatment reaches views through
/// the `\.screen` environment; this is the fallback for anything drawn outside the root's subtree.
@MainActor
var screen: ScreenStyles {
    system.screen
}

@MainActor
var system = SystemStyles(config: savedConfig) {
    didSet {
        AppController.shared.reloadRootView()
        ScreenShape.pathCache.removeAll()
        // The theme picks the UI sounds, so a new theme needs new players. Deliberately here rather than in
        // `SystemStyles.init`, which is a pure generator that tests and the environment's default value also
        // run — neither should be touching the app's audio.
        AudioController.shared.makeSoundsForSystem()
        // The settings surfaces outlive the subtree the reload rebuilds, so their theme-derived fields (the
        // seed field, the colour well) have to be told rather than re-defaulted.
        AppSettingsModel.shared.refreshFromTheme()
    }
}

extension EnvironmentValues {

    /// The generated theme, as the root injected it. Views read this rather than the `system` global (see
    /// `AGENTS.md`), so a view always draws with the theme its own window was handed — including the emergency
    /// palette, which the root resolves in for the length of an alarm.
    var system: SystemStyles {
        get { self[SystemStylesKey.self] }
        set { self[SystemStylesKey.self] = newValue }
    }

}

private struct SystemStylesKey: EnvironmentKey {

    /// A real generated theme rather than a placeholder, because a view drawn outside the root's subtree — a
    /// `#Preview`, a directly-hosted view — needs every field to be something. `static let`, so it is generated
    /// once and every fallback read returns the same value; a computed default (what `@Entry` writes) would
    /// re-generate a theme on every read and invalidate its readers on every unrelated environment write.
    static let defaultValue = SystemStyles(config: Config(seed: 0, designPrinciples: nil, primaryHue: nil, primarySaturation: nil))

}

enum ScreenBackgroundStyle {
    case color, gradientUp, gradientDown
}
enum ScreenFilter {
    case none, hLines, vLines, signalNoise, ledGrille
}
/// The seed's ambient screen effect. Mutually exclusive — one per theme, never stacked.
/// `wave` is a geometry `distortionEffect`; the rest are cheaper colour/layer effects.
enum ScreenDistortion {
    case wave, interference, chromaticAberration, vignette, bloom
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
    case fixed, flexible
}

struct SystemStyles: Sendable, Equatable {

    // Monotonic id uniquely identifying this generated theme instance (and the ScreenStyles
    // built alongside it). Lets caches like ScreenShape.pathCache key on the theme directly
    // instead of relying on being cleared whenever the theme changes.
    private static let generationCounter = Atomic<UInt64>(0)
    let generationID: UInt64

    /// Two themes are the same theme when they come from the same generation. Everything below is derived from
    /// that one draw, so `==` compares the id rather than ~40 fields on every environment write — plus the
    /// emergency palette swap, which is the one thing the root changes about a theme after generating it.
    static func == (lhs: SystemStyles, rhs: SystemStyles) -> Bool {
        lhs.generationID == rhs.generationID && lhs.colors.usesEmergencyPrimary == rhs.colors.usesEmergencyPrimary
    }

    let seed: UInt64

    // Subsystems
    let design: DesignPrinciples
    private(set) var colors: SystemColors
    /// The screen treatment drawn from the same seeded stream, immediately after this theme's own draws.
    let screen: ScreenStyles

    // General
    let basicShape: BasicShape
    let shapeDirection: ShapeDirection
    let cornerStyle: CornerStyle
    let roundedCornerFraction: CGFloat
    let lineCap: CGLineCap
    let changeSquareButtonToRect: Bool
    let shapeButtonFrameWidth: CGFloat
    let shapeButtonFrameHeight: CGFloat
    let flexButtonFrameHeight: CGFloat = 54.0
    let preferredButtonSizingMode: ButtonSizingMode
    let circularSegmentedViewCurvedOuterEdge: Bool
    let prefersBorders: Bool
    let prefersProminentButtons: Bool
    let prefersButtonBorders: Bool
    let prefersDashedLines: Bool
    let prefersRandomLineDashing: Bool
    let prefersThickEmergencyBorder: Bool
    let basicShapeHStackSpacing: CGFloat
    let screenBorderInsetAmount: CGFloat
    let mediumLineWidthBase: CGFloat
    var thinLineWidth: CGFloat {
        mediumLineWidth / 2
    }
    var mediumLineWidth: CGFloat {
        round(mediumLineWidthBase * platformSizeMultiplier)
    }
    var thickLineWidth: CGFloat {
        mediumLineWidth * 2
    }
    var screenBorderWidth: CGFloat? {
        guard prefersBorders, (!colors.useLightAppearance || !screenBorderInsetAmount.isZero) else { return nil }
        
        return thickLineWidth
    }
    
    // Colors
    var binaryNumberColors: [FillAndBorder] {
        switch colors.paletteStyle {
        case .colorful:
            return [
                FillAndBorder(fill: colors.color(.primary, opacity: .max)),
                FillAndBorder(fill: colors.color(.secondary, opacity: .max)),
                FillAndBorder(fill: colors.color(.tertiary, opacity: .max))
            ]
        case .limited:
            return [
                (prefersBorders ? FillAndBorder(fill: .clear, border: colors.color(.primary, opacity: .max)) : FillAndBorder(fill: colors.color(.primary, opacity: .min))),
                FillAndBorder(fill: colors.color(.primary, opacity: .max)),
                FillAndBorder(fill: colors.color(.secondary, opacity: .max))
            ]
        case .monochrome:
            return [
                FillAndBorder(fill: .clear, border: colors.color(.primary, opacity: .max)),
                FillAndBorder(fill: colors.color(.primary, opacity: .max)),
                FillAndBorder(fill: colors.color(.primary, opacity: .medium))
            ]
        }
    }
    func buttonTextColor(isDisabled: Bool) -> Color {
        if prefersProminentButtons {
            isDisabled ? colors.color(.primary, opacity: .min) : colors.screenBackground
        } else {
            colors.color(.secondary, opacity: .max)
        }
    }
    
    // Fonts
    private let defaultFont: ThemeFont
    /// `nil` draws the system font instead.
    var font: ThemeFont? {
        #if DEBUG
        DebugSettings.fontOverride ? nil : defaultFont
        #else
        defaultFont
        #endif
    }
    let defaultFontSize: CGFloat
    
    // Sounds
    let actionSoundResource: AudioController.Resource
    let buttonSoundResource: AudioController.Resource
    let alarmSoundResource: AudioController.Resource
    
    init(config: Config) {
        self.generationID = SystemStyles.generationCounter.add(1, ordering: .relaxed).newValue
        self.seed = config.seed
        let random = SeededRandom(seed: seed)

        // Generate design regardless of override, to advance the random number generator
        let genDesign = DesignPrinciples(
            simplicity: random.nextFraction(),
            sharpness: random.nextFraction(),
            order: random.nextFraction(),
            balance: random.nextFraction(),
            boldness: random.nextFraction()
        )
        let design = config.designPrinciples ?? genDesign
        self.design = design

        let allBasicShapes: [WeightedDesignElement<BasicShape>] = [
            .init(baseWeight: 1, design: .init(simplicity: 1.0, sharpness: 0.0), element: .circle),
            .init(baseWeight: 0.75, design: .init(simplicity: 0.7, sharpness: 1.0), element: .triangle),
            .init(baseWeight: 1, design: .init(simplicity: 0.6, sharpness: 0.5), element: .square),
            .init(baseWeight: 1, design: .init(simplicity: 0.4, sharpness: 0.3), element: .hexagon),
            .init(baseWeight: 0.75, design: .init(simplicity: 0.1, sharpness: 0.7), element: .trapezoid),
            .init(baseWeight: 0.75, design: .init(simplicity: 0.6, sharpness: 0.5), element: .diamond)
        ]
        let basicShape = random.nextWeightedElement(in: allBasicShapes, with: design)!
        self.basicShape = basicShape

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
        self.cornerStyle = cornerStyle

        // Subsystems
        self.colors = SystemColors(
            random: random,
            primaryHue: config.primaryHue,
            primarySaturation: config.primarySaturation
        )

        // General
        switch basicShape {
        case .hexagon, .triangle, .trapezoid:
            shapeDirection = (random.nextBool(chance: 0.333)) ? .down : .up
        default:
            shapeDirection = .up
        }

        roundedCornerFraction = 0.1 + CGFloat(random.nextDouble(in: 0...0.1))
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
        let preferredButtonSizingMode: ButtonSizingMode = random.nextBool(chance: 0.1) ? .flexible : .fixed
        self.preferredButtonSizingMode = preferredButtonSizingMode
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
        if preferredButtonSizingMode == .fixed {
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
        let screenBorderInsetAmount = random.nextBool(chance: 0.1) ? CGFloat(random.nextInt(in: 0..<7))*2.0 : 0.0
        self.screenBorderInsetAmount = prefersBorders ? screenBorderInsetAmount : 0
        prefersRandomLineDashing = random.nextBool(chance: 0.2) ? prefersDashedLines : false
        // Bolder themes are more likely to dramatize emergencies with a thicker screen border
        prefersThickEmergencyBorder = prefersBorders && random.nextBool(chance: design.boldness)
        mediumLineWidthBase = 2.0 + CGFloat(design.boldness * 4.0)

        let bundledFonts: [WeightedDesignElement<Font.Name>] = [
            .init(baseWeight: 1, design: .init(sharpness: 0.5, boldness: 1.0), element: .abEquinox),
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
            .init(baseWeight: 1, design: .init(sharpness: 0.3, boldness: 0.6), element: .tradeFederation)
        ]
        // Drawn whether or not the alien script wins, so the rest of the stream doesn't depend on the pick. The
        // script matches every theme by construction (its dials come from `design`), so it declares no traits and
        // competes on base weight alone. Matching the non-extra faces' combined weight puts it on about half of themes,
        // fewer with the extra fonts on.
        let alienFont = AlienFont(seed: random.next(), design: design)
        let allFonts = bundledFonts.map { WeightedDesignElement(baseWeight: $0.baseWeight, design: $0.design, element: ThemeFont.bundled($0.element)) }
            + [WeightedDesignElement(baseWeight: 8, design: DesignTraits(), element: ThemeFont.alien(alienFont))]
        // One weighted draw whatever survives the filter, so opting in or out of the extra fonts changes which
        // face this seed gets and nothing else downstream in the stream (sounds, screen).
        let candidateFonts = Font.Name.extraFontsEnabled ? allFonts : allFonts.filter {
            if case .bundled(let name) = $0.element { !name.isExtra } else { true }
        }
        let defaultFont = random.nextWeightedElement(in: candidateFonts, with: design)!
        self.defaultFont = defaultFont
        defaultFontSize = defaultFont.defaultFontSize

        actionSoundResource = random.nextBool() ? .action : .action2
        buttonSoundResource = random.nextElement(in: [AudioController.Resource.button, .button2, .button3])!
        alarmSoundResource = random.nextBool() ? .alarmLoop : .alarmHighLoop

        let screenShapeOverride = ScreenShapeType(rawValue: UserDefaults.standard.string(forKey: UserDefaults.Key.screenShapeOverride) ?? "")
        screen = ScreenStyles(
            themeGenerationID: generationID,
            design: design,
            basicShape: basicShape,
            cornerStyle: cornerStyle,
            random: random,
            screenShapeType: screenShapeOverride
        )
    }

    /// The palette an emergency is drawn in. The root resolves this once and injects it, so `.primary` reads red
    /// everywhere for the length of the alarm without any colour lookup consulting live ship state.
    func resolvingEmergencyColors() -> SystemStyles {
        var copy = self
        copy.colors = colors.resolvingEmergencyColors()
        return copy
    }
    
    func cornerRadius(forLength length: CGFloat) -> CGFloat {
        switch cornerStyle {
        case .sharp:
            return 0.0
        case .circular:
            return length / 2.0
        case .rounded:
            return length * roundedCornerFraction
        }
    }
    
    func cornerRadius(forLength length: CGFloat, cornerStyle: CornerStyle) -> CGFloat {
        switch cornerStyle {
        case .sharp:
            return 0.0
        case .circular:
            return length / 2.0
        case .rounded:
            return length * roundedCornerFraction
        }
    }
    
    func strokeStyle(_ lineWidth: LineWidth, lineJoin: CGLineCap? = nil, dashed: Bool = false) -> StrokeStyle {
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
            // Seed from the theme so the dash pattern is deterministic across synced
            // devices and stable across redraws (rather than reshuffling each frame).
            let random = SeededRandom(seed: seed)
            let roundLineCapCompensation = lineCap == .round ? lineWidth : 0
            dash = Array.init(repeating: roundLineCapCompensation + CGFloat(random.nextDouble(in: 2...6)), count: 25)
            if prefersRandomLineDashing {
                for index in 0..<dash.count {
                    dash[index] = roundLineCapCompensation + CGFloat(random.nextDouble(in: 8...256))
                }
            }
        }
        return dash
    }
    
    func buttonBackgroundColor(isDisabled: Bool, isSelected: Bool) -> Color {
        if prefersProminentButtons {
            if isDisabled {
                colors.color(.primary, brightness: .min)
            } else {
                isSelected ? colors.color(.tertiary, brightness: .max) : colors.color(.primary, brightness: .max)
            }
        } else {
            if isDisabled {
                .clear
            } else {
                isSelected ? colors.color(.tertiary, brightness: .medium) : colors.color(.primary, brightness: .low)
            }
        }
    }
}
