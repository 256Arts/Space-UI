import SwiftUI

extension EnvironmentValues {

    /// Plainly optional rather than an implicitly-unwrapped `ScreenStyles!`. The IUO read as though the value
    /// were always there, but the default really is `nil` for anything rendered outside the root's subtree — a
    /// `#Preview`, or a view hosted directly — so every read was a latent trap. Consumers resolve it against
    /// the `screen` global instead; see `ScreenView`.
    @Entry var screen: ScreenStyles?

}

enum ScreenShapeType: String, Identifiable, CaseIterable {
    case rectangle, capsule, circle, croppedCircle, croppedSquircle, verticalHexagon, horizontalHexagon, trapezoid, triangle
    
    var id: Self { self }
    var name: LocalizedStringResource {
        switch self {
        case .rectangle:
            return "Rectangle"
        case .capsule:
            return "Capsule"
        case .circle:
            return "Circle"
        case .croppedCircle:
            return "Cropped Circle"
        case .croppedSquircle:
            return "Cropped Squircle"
        case .verticalHexagon:
            return "Hexagon (V)"
        case .horizontalHexagon:
            return "Hexagon (H)"
        case .trapezoid:
            return "Trapezoid"
        case .triangle:
            return "Triangle"
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

enum RectEdge: CaseIterable {
    case top, bottom, left, right
}

enum RectCorner: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
}

struct ScreenStyles: Sendable, Equatable {

    /// Where corner insets are relative to cutouts
    enum CornerPositionToCutout {
        case beside, aboveBelow
    }

    /// Identifies the generated theme this treatment was built alongside — the `SystemStyles.generationID` of
    /// that theme. The screen is pure seed-derived data like the rest of the theme, so this is all it takes to
    /// tell two of them apart; `==` below compares it instead of walking every field on each environment write.
    let themeGenerationID: UInt64
    let screenShapeType: ScreenShapeType
    let filter: ScreenFilter
    let distortion: ScreenDistortion
    let backgroundStyle: ScreenBackgroundStyle

    // Screen FX (seed-driven shader parameters). Which one is used depends on `distortion`/`filter`.
    let waveSpeed: Double
    let waveLength: Double
    /// Horizontal displacement of the `wave` distortion, in points
    let waveAmplitude: Double
    /// Whole number: `occasionalWave` compares `floor(cycle) == cycleCount`, so a fraction would never match
    let waveCycleCount: Double
    let chromaticAberrationStrength: Double
    let vignetteStrength: Double
    let signalNoiseIntensity: Double
    let ledGrilleCellSize: Double
    let generalCutoutStyle: CutoutStyle
    private let seedCutoutEdges: Set<CutoutEdge>
    private var preferredCutoutEdges: Set<CutoutEdge> {
        screenShapeType.supportsCutouts ? seedCutoutEdges : []
    }
    private let topCutoutPosition: CutoutPosition
    let bottomCutoutPosition: CutoutPosition
    
    private let seedTopMorseCodeSegments: [MorseCodeLine.Segment]?
    var topMorseCodeSegments: [MorseCodeLine.Segment]? {
        screenShapeType.supportsMorseCodeEdges ? seedTopMorseCodeSegments : nil
    }
    private let seedBottomMorseCodeSegments: [MorseCodeLine.Segment]?
    var bottomMorseCodeSegments: [MorseCodeLine.Segment]? {
        screenShapeType.supportsMorseCodeEdges ? seedBottomMorseCodeSegments : nil
    }
    
    /// Default connected edges for window when window (scene) doesn't have a preference
    var defaultConnectedEdges: [RectEdge] {
        guard screenShapeType.canConnectToAdjacent else { return [] }
        
        var edges: [RectEdge] = []
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
    
    static func == (lhs: ScreenStyles, rhs: ScreenStyles) -> Bool {
        lhs.themeGenerationID == rhs.themeGenerationID
    }

    func connectedCorners(for edges: [RectEdge]) -> [RectCorner] {
        var corners: [RectCorner] = []
        if edges.contains(.top) || edges.contains(.left) {
            corners.append(.topLeft)
        }
        if edges.contains(.top) || edges.contains(.right) {
            corners.append(.topRight)
        }
        if edges.contains(.bottom) || edges.contains(.left) {
            corners.append(.bottomLeft)
        }
        if edges.contains(.bottom) || edges.contains(.right) {
            corners.append(.bottomRight)
        }
        return corners
    }
    
    func circularCorners(connectedCorners: [RectCorner]) -> [RectCorner] {
        switch screenShapeType {
        case .circle:
            RectCorner.allCases
        case .capsule:
            RectCorner.allCases.filter { !connectedCorners.contains($0) }
        default:
            []
        }
    }
    
    func externalDisplayPage(connectedEdges: [RectEdge]) -> Page {
        guard screenShapeType.canConnectToAdjacent else { return .extOrbits }
        
        if connectedEdges.contains(.right), !connectedEdges.contains(.left) {
            return .extCircularProgressLeft
        } else if connectedEdges.contains(.left), !connectedEdges.contains(.right) {
            return .extCircularProgressRight
        } else {
            return .extOrbits
        }
    }
    
    /// Takes the three generated properties it reads rather than the whole `SystemStyles`, because
    /// `SystemStyles.init` builds its screen before `self` is fully initialized.
    init(themeGenerationID: UInt64, design: DesignPrinciples, basicShape: BasicShape, cornerStyle: CornerStyle, random: SeededRandom, screenShapeType: ScreenShapeType? = nil) {
        self.themeGenerationID = themeGenerationID

        backgroundStyle = random.nextElement(in: [ScreenBackgroundStyle.gradientUp, .gradientDown, .color])!

        let allFilters: [WeightedDesignElement<ScreenFilter>] = [
            .init(baseWeight: 2, design: .init(sharpness: 0.6), element: .vLines),
            .init(baseWeight: 2, design: .init(sharpness: 0.6), element: .hLines),
            .init(baseWeight: 1, design: .init(sharpness: 0, order: 0), element: .signalNoise),
            .init(baseWeight: 1, design: .init(sharpness: 0.6), element: .ledGrille),
            .init(baseWeight: 1.5, design: .init(), element: .none)
        ]
        filter = random.nextWeightedElement(in: allFilters, with: design)!

        var allScreenShapeCases: [WeightedDesignElement<ScreenShapeType>] = [
            .init(baseWeight: 1 * (cornerStyle == .circular ? 20 : 1), design: .init(simplicity: 0.9, sharpness: 0.1), element: .capsule),
            .init(baseWeight: 0.5, design: .init(simplicity: 0.5, sharpness: 0.2), element: .croppedCircle),
            .init(baseWeight: 0.5, design: .init(simplicity: 0.5, sharpness: 0.2), element: .croppedSquircle),
            .init(baseWeight: 1, design: .init(simplicity: 0.0, sharpness: 0.7), element: .verticalHexagon),
            .init(baseWeight: 1, design: .init(simplicity: 0.0, sharpness: 0.7), element: .horizontalHexagon),
            .init(baseWeight: 1, design: .init(simplicity: 0.0, sharpness: 0.8), element: .trapezoid),
            .init(baseWeight: 1, design: .init(simplicity: 0.6, sharpness: 0.5), element: .rectangle)
        ]
        if UserDefaults.standard.integer(forKey: UserDefaults.Key.appLaunchCount) > 2 {
            // Circle & triangle are not a good 1st impression for new users
            allScreenShapeCases += [
                .init(baseWeight: 0.1 * (cornerStyle == .circular ? 20 : 1), design: .init(simplicity: 1, sharpness: 0), element: .circle),
                .init(baseWeight: 0.05, design: .init(simplicity: 0.9, sharpness: 1), element: .triangle)
            ]
        }
        let randomScreenShapeType = random.nextWeightedElement(in: allScreenShapeCases, with: design)!
        self.screenShapeType = screenShapeType ?? randomScreenShapeType

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

        // Screen FX. Drawn after every pre-existing draw on the shared stream, so adding
        // these didn't shift how older seeds render. Append any future draws below.
        // One mutually-exclusive ambient effect per theme. `wave` dominates; bold themes lean
        // toward the glow of bloom (mirroring prefersThickEmergencyBorder's boldness bias).
        let allDistortions: [WeightedDesignElement<ScreenDistortion>] = [
            .init(baseWeight: 6, design: .init(), element: .wave),
            .init(baseWeight: 1, design: .init(sharpness: 0.4, order: 0.2), element: .interference),
            .init(baseWeight: 2, design: .init(sharpness: 0), element: .chromaticAberration),
            .init(baseWeight: 1.5, design: .init(), element: .vignette),
            .init(baseWeight: 1, design: .init(boldness: 0.9), element: .bloom)
        ]
        distortion = random.nextWeightedElement(in: allDistortions, with: design)!
        waveSpeed = random.nextDouble(in: 12...26)
        waveLength = random.nextDouble(in: 10...22)
        waveAmplitude = random.nextDouble(in: 2...3) + design.boldness * 2.0
        waveCycleCount = Double(random.nextInt(in: 8...16)) + (design.order * 8.0).rounded()
        chromaticAberrationStrength = random.nextDouble(in: 4...8)
        vignetteStrength = random.nextDouble(in: 0.25...0.45)
        signalNoiseIntensity = random.nextDouble(in: 0.06...0.14)
        ledGrilleCellSize = Double(random.nextInt(in: 3...6))
    }
    
    func resolvedScreenShapeType(screenSize: CGSize) -> ScreenShapeType {
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
    
    func circularEdges(screenSize: CGSize, circularCorners: [RectCorner]) -> [RectEdge] {
        switch screenShapeType {
        case .circle:
            return RectEdge.allCases
        case .capsule:
            var edges: [RectEdge] = []
            if screenSize.height <= screenSize.width {
                if circularCorners.contains(.topLeft), circularCorners.contains(.bottomLeft) {
                    edges.append(.left)
                }
                if circularCorners.contains(.topRight), circularCorners.contains(.bottomRight) {
                    edges.append(.right)
                }
            } else {
                if circularCorners.contains(.topLeft), circularCorners.contains(.topRight) {
                    edges.append(.top)
                }
                if circularCorners.contains(.bottomLeft), circularCorners.contains(.bottomRight) {
                    edges.append(.bottom)
                }
            }
            return edges
        default:
            return []
        }
    }
    
    func edgesIgnoringSafeAreaForScreenShape(screenSize: CGSize, traitCollection: UITraitCollection, safeAreaInsets: UIEdgeInsets, system: SystemStyles) -> Edge.Set {
        #if targetEnvironment(macCatalyst)
        return .all
        #else
        if traitCollection.verticalSizeClass == .compact {
            // Horizontal iPhone; Ignore vertical, and keep horizontal safe area for simplicity
            return .vertical
        } else {
            if hasSharpCornersOnUnevenDisplay(screenSize: screenSize, traitCollection: traitCollection, safeAreaInsets: safeAreaInsets, system: system) {
                // Not the top: that would read as the shape running under a Face ID cutout, which the Duo doesn't have.
                return [.leading, .trailing, .bottom]
            }
            switch resolvedScreenShapeType(screenSize: screenSize) {
            case .rectangle:
                if case .sharp = system.cornerStyle {
                    return []
                }
            case .trapezoid:
                let screenTrapezoidHexagonCornerOffset = max(ScreenShape.hardwareCornerRadius, screenSize.width/8)
                let cornerRadius = system.cornerRadius(forLength: min(screenSize.width, screenSize.height))
                
                if case .sharp = system.cornerStyle {
                    return system.shapeDirection == .up ? .top : .bottom
                } else if (screenSize.width - (screenTrapezoidHexagonCornerOffset + cornerRadius)*2) < 200 {
                    // Sides only where they're uneven (the Duo), where keeping them would push the shape off center.
                    return safeAreaInsets.left != safeAreaInsets.right ? [.leading, .trailing, .bottom] : .bottom
                }
            default:
                break
            }
            return (topMorseCodeSegments == nil && traitCollection.horizontalSizeClass == .regular) ? .all : [.leading, .trailing, .bottom]
        }
        #endif
    }
    
    /// A sharp-cornered shape on a display inset on one side only — the iPhone Duo's outer screen, flat at the hinge
    /// and rounded (with the camera) on the other. Keeping that inset would push the shape off center, so it ignores
    /// the safe area and takes ``hardwareCornerPadding`` instead.
    private func hasSharpCornersOnUnevenDisplay(screenSize: CGSize, traitCollection: UITraitCollection, safeAreaInsets: UIEdgeInsets, system: SystemStyles) -> Bool {
        guard traitCollection.verticalSizeClass != .compact, safeAreaInsets.left != safeAreaInsets.right, case .sharp = system.cornerStyle else { return false }
        switch resolvedScreenShapeType(screenSize: screenSize) {
        case .rectangle, .trapezoid:
            return true
        default:
            return false
        }
    }
    
    /// Pulls a sharp-cornered shape in from the rounded hardware corners of an uneven display (see
    /// ``hasSharpCornersOnUnevenDisplay``) just far enough that their clipping isn't noticeable — less on an edge
    /// whose border would otherwise run over the camera.
    func hardwareCornerPadding(screenSize: CGSize, traitCollection: UITraitCollection, safeAreaInsets: UIEdgeInsets, occludedRegions: [CGRect], system: SystemStyles) -> EdgeInsets {
        #if targetEnvironment(macCatalyst)
        return EdgeInsets()
        #else
        guard hasSharpCornersOnUnevenDisplay(screenSize: screenSize, traitCollection: traitCollection, safeAreaInsets: safeAreaInsets, system: system) else { return EdgeInsets() }
        let inset: CGFloat = 16
        var padding = EdgeInsets(top: inset, leading: safeAreaInsets.left > safeAreaInsets.right ? inset : 0, bottom: inset, trailing: safeAreaInsets.right > safeAreaInsets.left ? inset : 0)
        
        // How far in from the padding the border's inner edge sits, plus a little air before the camera.
        let borderDepth = system.screenBorderInsetAmount + (system.screenBorderWidth ?? 0) + 4
        func clearance(_ distanceFromEdge: CGFloat) -> CGFloat { max(0, distanceFromEdge - borderDepth) }
        // The camera comes with a larger keep-out box around it; only the camera itself is drawn over.
        let innermost = occludedRegions.filter { region in !occludedRegions.contains { $0 != region && region.contains($0) } }
        for region in innermost {
            if region.midY < screenSize.height / 2 {
                padding.top = min(padding.top, clearance(region.minY))
            } else {
                padding.bottom = min(padding.bottom, clearance(screenSize.height - region.maxY))
            }
            if region.midX < screenSize.width / 2 {
                padding.leading = min(padding.leading, clearance(region.minX))
            } else {
                padding.trailing = min(padding.trailing, clearance(screenSize.width - region.maxX))
            }
        }
        return padding
        #endif
    }
    
    private func mainContentPadding(screenSize: CGSize) -> CGFloat {
        min(screenSize.width, screenSize.height) / 40
    }
    
    /// Insets so that content is not obscured by the screen shape and cutouts
    func mainContentInsets(screenSize: CGSize, connectedEdges: [RectEdge], system: SystemStyles) -> EdgeInsets {
        let screenShapeType = resolvedScreenShapeType(screenSize: screenSize)
        
        let topOnly = {
            let cutoutOffset = topCutoutStyle(screenSize: screenSize, availableWidth: screenSize.width, insetAmount: 0) == .none ? 0.0 : ScreenShape.cutoutHeight
            let triangleOffset = {
                if system.shapeDirection == .up {
                    switch screenShapeType {
                    case .triangle:
                        return min(screenSize.width, screenSize.height) * 0.2
                    case .trapezoid:
                        return cutoutOffset.isZero ? 16 : 0
                    default:
                        break
                    }
                }
                return 0.0
            }()
            return cutoutOffset + triangleOffset
        }()
        let bottomOnly = {
            let cutoutOffset = bottomCutoutStyle(screenSize: screenSize, availableWidth: screenSize.width, insetAmount: 0) == .none ? 0.0 : ScreenShape.cutoutHeight
            let triangleOffset = {
                if system.shapeDirection == .down {
                    switch screenShapeType {
                    case .triangle:
                        return min(screenSize.width, screenSize.height) * 0.2
                    case .trapezoid:
                        return cutoutOffset.isZero ? 16 : 0
                    default:
                        break
                    }
                }
                return 0.0
            }()
            return cutoutOffset + triangleOffset
        }()
        
        let borderInset = system.prefersBorders ? (system.thickLineWidth + system.screenBorderInsetAmount) : 0
        
        let screenShapeVertical: CGFloat = {
            switch screenShapeType {
            case .capsule:
                return screenSize.height <= screenSize.width ? 0.0 : screenSize.width/4
            case .verticalHexagon:
                return ScreenShape.screenTrapezoidOrHexagonCornerOffset(screenSize: screenSize)
            case .croppedCircle, .croppedSquircle:
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
                return ScreenShape.screenTrapezoidOrHexagonCornerOffset(screenSize: screenSize)
            case .croppedCircle, .croppedSquircle:
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
        
        let seemlessConnectionOffset = UserDefaults.standard.bool(forKey: UserDefaults.Key.externalDisplaySeemlessMode) ? (system.screenBorderWidth ?? 0) + system.screenBorderInsetAmount : 0
        
        let padding: CGFloat = mainContentPadding(screenSize: screenSize)
        let vertical: CGFloat = padding + borderInset + screenShapeVertical
        let horizontal: CGFloat = padding + borderInset
        
        let top = topOnly + vertical
        let leading =  connectedEdges.contains(.left) ? horizontal - seemlessConnectionOffset : horizontal + screenShapeHorizontal
        let bottom = bottomOnly + vertical
        let trailing = connectedEdges.contains(.right) ? horizontal - seemlessConnectionOffset : horizontal + screenShapeHorizontal
        return EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
    }
    
    /// Offsets for views in screen corners, to help them fit a bit better
    func safeCornerOffsets(screenSize: CGSize, connectedCorners: [RectCorner], system: SystemStyles) -> SafeCornerOffsets {
        let resolvedScreenShapeType = resolvedScreenShapeType(screenSize: screenSize)
        let topCutoutStyle = topCutoutStyle(screenSize: screenSize, availableWidth: screenSize.width, insetAmount: 0)
        let bottomCutoutStyle = bottomCutoutStyle(screenSize: screenSize, availableWidth: screenSize.width, insetAmount: 0)
        let topCutoutRelation: CornerPositionToCutout? = topCutoutStyle == .none ? nil : (500 < screenSize.width ? .beside : .aboveBelow)
        let bottomCutoutRelation: CornerPositionToCutout? = bottomCutoutStyle == .none ? nil : (500 < screenSize.width ? .beside : .aboveBelow)
        let screenCornerRadius = ScreenShape.cornerRadius(rect: CGRect(origin: .zero, size: screenSize), insetAmount: 0, screenShapeType: resolvedScreenShapeType, system: system)
        
        let topCornerRadiusAvoidance: CGFloat = {
            switch resolvedScreenShapeType {
            case .triangle, .capsule, .croppedCircle, .croppedSquircle:
                return 0.0
            case .circle:
                return min(screenSize.width, screenSize.height) / 24
            default:
                let cutoutAdjustment: CGFloat = topCutoutRelation == .aboveBelow ? ScreenShape.cutoutHeight : 0
                let distanceAdjustment = cutoutAdjustment + mainContentPadding(screenSize: screenSize)
                return max(0, (screenCornerRadius - distanceAdjustment) / 4)
            }
        }()
        let bottomCornerRadiusAvoidance: CGFloat = {
            switch resolvedScreenShapeType {
            case .triangle, .capsule, .croppedCircle, .croppedSquircle:
                return 0.0
            case .circle:
                return min(screenSize.width, screenSize.height) / 24
            default:
                let cutoutAdjustment: CGFloat = bottomCutoutRelation == .aboveBelow ? ScreenShape.cutoutHeight : 0
                let distanceAdjustment = cutoutAdjustment + mainContentPadding(screenSize: screenSize)
                return max(0, (screenCornerRadius - distanceAdjustment) / 4)
            }
        }()
        
        var topLeading: CGSize
        var topTrailing: CGSize
        var bottomLeading: CGSize
        var bottomTrailing: CGSize
        
        if resolvedScreenShapeType == .trapezoid, system.shapeDirection == .up {
            // Push views up
            topLeading = connectedCorners.contains(.topLeft) ? .zero : CGSize(width: topCornerRadiusAvoidance, height: -topCornerRadiusAvoidance)
            topTrailing = connectedCorners.contains(.topRight) ? .zero : CGSize(width: -topCornerRadiusAvoidance, height: -topCornerRadiusAvoidance)
        } else {
            topLeading = connectedCorners.contains(.topLeft) ? .zero : CGSize(width: topCornerRadiusAvoidance, height: topCornerRadiusAvoidance)
            topTrailing = connectedCorners.contains(.topRight) ? .zero : CGSize(width: -topCornerRadiusAvoidance, height: topCornerRadiusAvoidance)
        }
        if resolvedScreenShapeType == .trapezoid, system.shapeDirection == .down {
            // Push views down
            bottomLeading = connectedCorners.contains(.bottomLeft) ? .zero : CGSize(width: bottomCornerRadiusAvoidance, height: bottomCornerRadiusAvoidance)
            bottomTrailing = connectedCorners.contains(.bottomRight) ? .zero : CGSize(width: -bottomCornerRadiusAvoidance, height: bottomCornerRadiusAvoidance)
        } else {
            bottomLeading = connectedCorners.contains(.bottomLeft) ? .zero : CGSize(width: bottomCornerRadiusAvoidance, height: -bottomCornerRadiusAvoidance)
            bottomTrailing = connectedCorners.contains(.bottomRight) ? .zero : CGSize(width: -bottomCornerRadiusAvoidance, height: -bottomCornerRadiusAvoidance)
        }
        
        // Push views vertically to the edges of the screen to fill areas beside cutouts
        if topCutoutRelation == .beside {
            topLeading.height -= ScreenShape.cutoutHeight
            topTrailing.height -= ScreenShape.cutoutHeight
        }
        if bottomCutoutRelation == .beside {
            bottomLeading.height += ScreenShape.cutoutHeight
            bottomTrailing.height += ScreenShape.cutoutHeight
        }
        
        // Screen shape compensation
        switch resolvedScreenShapeType {
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
        } else if (screenShapeType == .capsule || screenShapeType == .croppedCircle || screenShapeType == .croppedSquircle || screenShapeType == .horizontalHexagon) && screenSize.width < screenSize.height {
            return .none
        } else if preferredCutoutEdges.contains(.top) {
            return generalCutoutStyle
        } else {
            return .none
        }
    }
    
    func bottomCutoutStyle(screenSize: CGSize, availableWidth: CGFloat, insetAmount: CGFloat) -> CutoutStyle {
        if availableWidth + insetAmount*2 < 210 || screenShapeType == .verticalHexagon {
            return .none
        } else if (screenShapeType == .capsule || screenShapeType == .croppedCircle || screenShapeType == .croppedSquircle || screenShapeType == .horizontalHexagon) && screenSize.width < screenSize.height {
            return .none
        } else if preferredCutoutEdges.contains(.bottom) {
            return generalCutoutStyle
        } else {
            return .none
        }
    }
    
    /// Cutout metrics shared by the drawn screen path (`ScreenShape.path`) and the reported cutout frame
    /// (`cutoutFrame`). Extracting this one value type is what keeps the drawn cutout and the frame we place
    /// content into from disagreeing — previously each re-derived these numbers with slightly different caps.
    struct CutoutLayout {
        let cutoutHeight: CGFloat
        let totalTransitionWidth: CGFloat
        /// Straight edge length that a cutout is allowed to replace.
        let replaceableWidth: CGFloat
        let cutoutContentWidth: CGFloat
        let totalLengthAroundCutout: CGFloat
        let topLeadingLengthBeforeCutout: CGFloat
        let topTrailingLengthAfterCutout: CGFloat
        let bottomLeadingLengthBeforeCutout: CGFloat
        let bottomTrailingLengthAfterCutout: CGFloat
    }

    /// Computes the cutout metrics for a given screen rect. Uses `ScreenShape`'s corner/offset helpers so the
    /// numbers exactly match what `ScreenShape.path` draws. `screenShapeType` is the *resolved* type being drawn
    /// (a hexagon flips with the aspect ratio, a circle becomes a capsule), not the seed's raw `screenShapeType`.
    func cutoutLayout(rect: CGRect, insetAmount: CGFloat, screenShapeType: ScreenShapeType, system: SystemStyles) -> CutoutLayout {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let cornerRadius = ScreenShape.cornerRadius(rect: rect, insetAmount: insetAmount, screenShapeType: screenShapeType, system: system)
        let cornerOffset = ScreenShape.screenTrapezoidOrHexagonCornerOffset(screenSize: rect.size, insetAmount: insetAmount)

        let replaceableWidth: CGFloat = {
            switch screenShapeType {
            case .croppedCircle, .croppedSquircle:
                return insetRect.width - cornerOffset*2.0
            case .horizontalHexagon:
                let riseOverRun = (insetRect.height/2) / cornerOffset
                let angle = atan(riseOverRun)
                let offset = cornerRadius * abs(tan(angle / 2.0))
                return insetRect.width - (cornerOffset + offset)*2.0
            case .trapezoid:
                let topSideLength = insetRect.width - cornerOffset*2
                let topLeadingSpace = (insetRect.width - topSideLength)/2
                let riseOverRun = insetRect.height / topLeadingSpace
                let angle = atan(riseOverRun)
                let topOffset = cornerRadius * abs(tan(angle / 2.0))
                return insetRect.width - (cornerOffset + topOffset)*2.0
            default:
                return insetRect.width - cornerRadius*2.0
            }
        }()

        let cutoutHeight = ScreenShape.cutoutHeight
        let totalTransitionWidth = generalCutoutStyle.totalTransitionWidth(cutoutHeight: cutoutHeight)

        let maxCutoutContentWidth = replaceableWidth - totalTransitionWidth
        let absoluteMaxCutoutContentWidth = 600.0 + insetAmount
        let preferredCutoutContentWidth = self.preferredCutoutContentWidth(screenSize: rect.size) + insetAmount
        let cutoutContentWidth = min(preferredCutoutContentWidth, maxCutoutContentWidth, absoluteMaxCutoutContentWidth)
        let totalLengthAroundCutout = replaceableWidth - cutoutContentWidth - totalTransitionWidth

        let topLeading: CGFloat, topTrailing: CGFloat, bottomLeading: CGFloat, bottomTrailing: CGFloat
        if 200 < totalLengthAroundCutout {
            switch topCutoutPosition {
            case .leading:
                topLeading = totalLengthAroundCutout * 0.333333
                topTrailing = totalLengthAroundCutout * 0.666666
            case .trailing:
                topLeading = totalLengthAroundCutout * 0.666666
                topTrailing = totalLengthAroundCutout * 0.333333
            default:
                topLeading = totalLengthAroundCutout/2
                topTrailing = totalLengthAroundCutout/2
            }
            switch bottomCutoutPosition {
            case .leading:
                bottomLeading = totalLengthAroundCutout * 0.333333
                bottomTrailing = totalLengthAroundCutout * 0.666666
            case .trailing:
                bottomLeading = totalLengthAroundCutout * 0.666666
                bottomTrailing = totalLengthAroundCutout * 0.333333
            default:
                bottomLeading = totalLengthAroundCutout/2
                bottomTrailing = totalLengthAroundCutout/2
            }
        } else {
            topLeading = totalLengthAroundCutout/2
            topTrailing = totalLengthAroundCutout/2
            bottomLeading = totalLengthAroundCutout/2
            bottomTrailing = totalLengthAroundCutout/2
        }

        return CutoutLayout(
            cutoutHeight: cutoutHeight,
            totalTransitionWidth: totalTransitionWidth,
            replaceableWidth: replaceableWidth,
            cutoutContentWidth: cutoutContentWidth,
            totalLengthAroundCutout: totalLengthAroundCutout,
            topLeadingLengthBeforeCutout: topLeading,
            topTrailingLengthAfterCutout: topTrailing,
            bottomLeadingLengthBeforeCutout: bottomLeading,
            bottomTrailingLengthAfterCutout: bottomTrailing
        )
    }

    func cutoutFrame(screenSize: CGSize, forTop: Bool, system: SystemStyles) -> CGRect? {
        if forTop {
            guard topCutoutStyle(screenSize: screenSize, availableWidth: 999, insetAmount: 0) != .none else { return nil }
        } else {
            guard bottomCutoutStyle(screenSize: screenSize, availableWidth: 999, insetAmount: 0) != .none else { return nil }
        }

        let rect = CGRect(origin: .zero, size: screenSize)
        let layout = cutoutLayout(rect: rect, insetAmount: 0, screenShapeType: resolvedScreenShapeType(screenSize: screenSize), system: system)
        let leading = forTop ? layout.topLeadingLengthBeforeCutout : layout.bottomLeadingLengthBeforeCutout

        // x value is an offset from the center, not an actual origin.x
        let x = leading - layout.totalLengthAroundCutout/2
        let y = forTop ? rect.minY : rect.maxY - layout.cutoutHeight
        return CGRect(x: x, y: y, width: layout.cutoutContentWidth, height: layout.cutoutHeight)
    }
    
    func preferredCutoutContentWidth(screenSize: CGSize) -> CGFloat {
        screenSize.width * 0.386
    }
    
}
