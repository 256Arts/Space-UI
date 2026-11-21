import SwiftUI

// Draws a conduit between two points with SF Symbol markers flowing along it in the
// start→end direction. The path is a cubic Bézier whose control points are offset along
// one axis from each endpoint, so the curve always leaves the start and arrives at the end
// travelling along that axis, easing across in the middle. Its styling is a per-instance
// design variant generated locally from the `did` (Design ID), matching how other views
// derive their look (see CircularProgressView): the lead axis, the marker symbol, whether
// the markers travel, and whether a colour pulse sweeps along them. A colour pulse is never
// applied to a conduit the user is actively dragging (`isPreview`). The marker's rounded vs
// square treatment follows the theme's `cornerStyle`.
// Only the endpoints matter; the curve's shape depends solely on their relative position.
struct FlowingArrowsView: View {
    @Environment(\.system) private var system

    /// Repeated marker along the conduit, pointing in the direction of flow.
    enum ChevronStyle {
        case chevron, triangle
    }

    let start: CGPoint
    let end: CGPoint
    let colorRole: ColorRole
    /// A dimmer, thinner treatment used while the conduit is only a drag preview.
    let isPreview: Bool

    // Design variant, generated once from the Design ID.
    private let chevronStyle: ChevronStyle
    private let prefersDominantAxis: Bool
    private let animatesFlow: Bool
    private let animatesCharge: Bool

    /// Spacing between markers along the curve, in points.
    private let chevronSpacing: CGFloat = 18
    /// Number of samples used to build the arc-length lookup table.
    private let sampleCount = 24
    /// Revolutions per second of the marker flow and the charge pulse, respectively.
    private let flowSpeed = 0.15
    private let chargeSpeed = 0.4

    @Environment(\.accessibilityReduceMotion) private var reducedMotion

    init(did: Int, start: CGPoint, end: CGPoint, colorRole: ColorRole = .primary, isPreview: Bool = false) {
        self.start = start
        self.end = end
        self.colorRole = colorRole
        self.isPreview = isPreview

        let random = SeededRandom(seed: UInt64(did))
        let markerChoices: [WeightedDesignElement<ChevronStyle>] = [
            .init(baseWeight: 1, design: .init(sharpness: 0.2), element: .chevron),
            .init(baseWeight: 1, design: .init(sharpness: 0.9, boldness: 0.7), element: .triangle)
        ]
        // Reads the `system` global rather than the environment because an `init` runs before the view has one.
        // Safe: the root rebuilds this subtree on a theme change (`AppController.configID`), re-running the init.
        self.chevronStyle = random.nextWeightedElement(in: markerChoices, with: Space_UI.system.design)!
        self.prefersDominantAxis = random.nextBool()
        self.animatesFlow = random.nextBool(chance: 0.75)
        self.animatesCharge = random.nextBool(chance: 0.6)
    }

    private var span: CGFloat {
        hypot(end.x - start.x, end.y - start.y)
    }

    /// The SF Symbol name. Direction-fixed (`.right`, no RTL flip) since we rotate it to the
    /// flow tangent ourselves. The triangle picks a square vs rounded glyph per corner style.
    private var symbolName: String {
        let sharp = system.cornerStyle == .sharp
        switch chevronStyle {
        case .chevron:
            return "chevron.right"
        case .triangle:
            return sharp ? "play.fill" : "arrowtriangle.right.fill"
        }
    }

    var body: some View {
        // Resolve theme values and geometry on the main actor, outside the Canvas render closure.
        let baseColor = system.colors.color(colorRole, opacity: isPreview ? .low : .medium)
        let chargeColor = system.colors.color(colorRole, opacity: .max)

        let verticalLead = prefersDominantAxis && abs(end.y - start.y) > abs(end.x - start.x)
        let (control1, control2) = controlPoints(vertical: verticalLead)
        // Distribute markers by true arc length so their density is independent of how much
        // the curve bows — uniform-t bunches them on the more curved conduits.
        let table = arcLengthTable(control1: control1, control2: control2)
        let length = table.last ?? span
        let count = max(5, Int(length / chevronSpacing))

        // Flow (markers travelling) and charge (colour pulse) are independent variants, both
        // suppressed by Reduce Motion. A colour pulse is additionally never applied to a
        // conduit the user is actively dragging.
        let animateFlow = animatesFlow && !reducedMotion
        let animateCharge = animatesCharge && !reducedMotion && !isPreview

        return TimelineView(.animation(paused: !(animateFlow || animateCharge))) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let phase = animateFlow ? (now * flowSpeed).truncatingRemainder(dividingBy: 1) : 0
            let chargePhase = animateCharge ? now * chargeSpeed : 0
            Canvas { context, _ in
                guard let baseSymbol = context.resolveSymbol(id: 0),
                      let chargeSymbol = context.resolveSymbol(id: 1) else { return }
                for index in 0..<count {
                    // Even position along the conduit's length, then mapped to the Bézier parameter.
                    let fraction = (phase + Double(index) / Double(count)).truncatingRemainder(dividingBy: 1)
                    let t = parameter(forArcFraction: CGFloat(fraction), table: table)
                    let point = pointOnCurve(t: t, control1: control1, control2: control2)
                    let angle = tangentAngle(t: t, control1: control1, control2: control2)
                    // Fade markers in and out near the endpoints so they emerge from the
                    // source and dissolve into the target rather than popping.
                    let edgeFade = min(1, min(fraction, 1 - fraction) * 6)
                    // Charge highlight: a travelling pulse when animating, a solid tint on a
                    // static powered conduit, and absent on a drag preview.
                    let chargeLevel: Double
                    if isPreview {
                        chargeLevel = 0
                    } else if animateCharge {
                        // Sharpened sine, so a tight bright band travels along the conduit.
                        chargeLevel = pow(0.5 + 0.5 * sin((fraction * 1.5 - chargePhase) * 2 * .pi), 3)
                    } else {
                        chargeLevel = 1
                    }

                    var layer = context
                    layer.translateBy(x: point.x, y: point.y)
                    layer.rotate(by: Angle(radians: Double(angle)))
                    layer.opacity = edgeFade
                    layer.draw(baseSymbol, at: .zero, anchor: .center)
                    let chargeOpacity = edgeFade * chargeLevel
                    if chargeOpacity > 0.01 {
                        layer.opacity = chargeOpacity
                        layer.draw(chargeSymbol, at: .zero, anchor: .center)
                    }
                }
            } symbols: {
                markerSymbol(color: baseColor).tag(0)
                markerSymbol(color: chargeColor).tag(1)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Marker

    private func markerSymbol(color: Color) -> some View {
        Image(systemName: symbolName)
            .font(.system(size: isPreview ? 11 : 14, weight: .semibold, design: system.cornerStyle == .sharp ? .default : .rounded))
            .foregroundStyle(color)
    }

    // MARK: - Curve

    /// Control points offset from each endpoint along the lead axis. The reach is at least a
    /// fraction of the span, so there is always a visible lead even for stacked endpoints.
    private func controlPoints(vertical: Bool) -> (CGPoint, CGPoint) {
        if vertical {
            let direction: CGFloat = end.y >= start.y ? 1 : -1
            let lead = max(abs(end.y - start.y) * 0.5, span * 0.28)
            return (CGPoint(x: start.x, y: start.y + direction * lead),
                    CGPoint(x: end.x, y: end.y - direction * lead))
        } else {
            let direction: CGFloat = end.x >= start.x ? 1 : -1
            let lead = max(abs(end.x - start.x) * 0.5, span * 0.28)
            return (CGPoint(x: start.x + direction * lead, y: start.y),
                    CGPoint(x: end.x - direction * lead, y: end.y))
        }
    }

    private func pointOnCurve(t: CGFloat, control1: CGPoint, control2: CGPoint) -> CGPoint {
        let mt = 1 - t
        let x = mt * mt * mt * start.x + 3 * mt * mt * t * control1.x + 3 * mt * t * t * control2.x + t * t * t * end.x
        let y = mt * mt * mt * start.y + 3 * mt * mt * t * control1.y + 3 * mt * t * t * control2.y + t * t * t * end.y
        return CGPoint(x: x, y: y)
    }

    private func tangentAngle(t: CGFloat, control1: CGPoint, control2: CGPoint) -> CGFloat {
        let mt = 1 - t
        let dx = 3 * mt * mt * (control1.x - start.x) + 6 * mt * t * (control2.x - control1.x) + 3 * t * t * (end.x - control2.x)
        let dy = 3 * mt * mt * (control1.y - start.y) + 6 * mt * t * (control2.y - control1.y) + 3 * t * t * (end.y - control2.y)
        return atan2(dy, dx)
    }

    // MARK: - Arc length

    /// Cumulative arc length at each of `sampleCount` evenly spaced parameter steps (plus a
    /// leading zero), used to convert a length fraction into a Bézier parameter.
    private func arcLengthTable(control1: CGPoint, control2: CGPoint) -> [CGFloat] {
        var table: [CGFloat] = [0]
        table.reserveCapacity(sampleCount + 1)
        var previous = start
        var total: CGFloat = 0
        for step in 1...sampleCount {
            let point = pointOnCurve(t: CGFloat(step) / CGFloat(sampleCount), control1: control1, control2: control2)
            total += hypot(point.x - previous.x, point.y - previous.y)
            table.append(total)
            previous = point
        }
        return table
    }

    private func parameter(forArcFraction fraction: CGFloat, table: [CGFloat]) -> CGFloat {
        let total = table.last ?? 0
        guard total > 0 else { return fraction }
        let target = fraction * total
        let segments = table.count - 1
        var index = 0
        while index < segments - 1 && table[index + 1] < target {
            index += 1
        }
        let segmentStart = table[index]
        let segmentEnd = table[index + 1]
        let withinSegment = segmentEnd > segmentStart ? (target - segmentStart) / (segmentEnd - segmentStart) : 0
        return (CGFloat(index) + withinSegment) / CGFloat(segments)
    }
}
