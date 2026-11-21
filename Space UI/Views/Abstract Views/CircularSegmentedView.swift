import SwiftUI

// Looks like a pie graph.

struct AngularSegment: InsettableShape {

    let angle: Angle
    let topIsCurved: Bool
    let cornerRadius: CGFloat
    /// Perpendicular inset of each straight edge toward the slice's bisector. Half the visual gap between adjacent slices.
    let edgeInset: CGFloat

    var insetAmount: CGFloat = 0.0

    func path(in rect: CGRect) -> Path {
        // The slice is drawn pointing up, with its arc concentric with the rect's center,
        // so a full ring of rotated slices forms a perfect circle.
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height)/2 - insetAmount
        let halfAngle = angle.radians/2.0
        let edgeInset = edgeInset + insetAmount
        guard 0 < halfAngle, halfAngle < .pi/2, edgeInset < radius else { return Path() }

        // Where the 2 inset straight edges intersect, on the bisector.
        let apex = CGPoint(x: center.x, y: center.y - edgeInset / sin(halfAngle))
        // Where the straight edges meet the circle of `radius` around `center`.
        let edgeLength = sqrt(radius*radius - edgeInset*edgeInset) - edgeInset / tan(halfAngle)
        guard 0 < edgeLength else { return Path() }
        let leftPoint = CGPoint(x: apex.x - edgeLength * sin(halfAngle), y: apex.y - edgeLength * cos(halfAngle))
        let rightPoint = CGPoint(x: apex.x + edgeLength * sin(halfAngle), y: apex.y - edgeLength * cos(halfAngle))
        let leftPointAngle = Angle(radians: atan2(leftPoint.y - center.y, leftPoint.x - center.x))
        let rightPointAngle = Angle(radians: atan2(rightPoint.y - center.y, rightPoint.x - center.x))

        return Path { path in
            path.move(to: CGPoint(x: (apex.x + leftPoint.x)/2, y: (apex.y + leftPoint.y)/2))
            if cornerRadius.isZero {
                path.addLine(to: apex)
                path.addLine(to: rightPoint)
                if topIsCurved {
                    path.addRelativeArc(center: center, radius: radius, startAngle: rightPointAngle, delta: leftPointAngle - rightPointAngle)
                } else {
                    path.addLine(to: leftPoint)
                }
            } else {
                path.addArc(tangent1End: apex, tangent2End: rightPoint, radius: cornerRadius)
                if topIsCurved {
                    path.addLine(to: rightPoint)
                    path.addRelativeArc(center: center, radius: radius, startAngle: rightPointAngle, delta: leftPointAngle - rightPointAngle)
                } else {
                    path.addArc(tangent1End: rightPoint, tangent2End: leftPoint, radius: cornerRadius)
                    path.addArc(tangent1End: leftPoint, tangent2End: apex, radius: cornerRadius)
                }
            }
            path.closeSubpath()
        }
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var arc = self
        arc.insetAmount += amount
        return arc
    }
}

struct CircularSegmentedView: View {

    struct SegmentModel: Identifiable {
        let id: Int
        var state: Bool = .random()
        /// Takes the theme rather than reaching for the `system` global: a `SegmentModel` is a plain value, so it
        /// has no environment of its own — the view that renders it does.
        @MainActor
        func fillAndBorder(_ system: SystemStyles) -> FillAndBorder {
            state ? FillAndBorder(fill: .clear, border: system.colors.color(.primary, opacity: .max)) : FillAndBorder(fill: system.colors.color(.primary, opacity: .max))
        }
    }

    let spacing: CGFloat = 8.0
    let curvedOuterEdge: Bool

    @Environment(\.system) private var system

    @State var values: [SegmentModel]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(values) { value in
                    let fillAndBorder = value.fillAndBorder(system)
                    segment(cornerRadius: segmentCornerRadius(size: geometry.size))
                        .foregroundColor(fillAndBorder.fill)
                        .overlay {
                            if let border = fillAndBorder.border {
                                segment(cornerRadius: segmentCornerRadius(size: geometry.size))
                                    .strokeBorder(border, style: system.strokeStyle(.thin))
                            }
                        }
                        .rotationEffect(CircularStack.subviewRotationAngles(stepCount: values.count)[value.id])
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    init() {
        self.curvedOuterEdge = Space_UI.system.circularSegmentedViewCurvedOuterEdge
        self._values = State(initialValue: [SegmentModel(id: 0), SegmentModel(id: 1), SegmentModel(id: 2), SegmentModel(id: 3), SegmentModel(id: 4), SegmentModel(id: 5)])
    }

    func segment(cornerRadius: CGFloat) -> AngularSegment {
        AngularSegment(angle: .degrees(360 / Double(values.count)), topIsCurved: curvedOuterEdge, cornerRadius: cornerRadius, edgeInset: spacing / 2)
    }
    func segmentCornerRadius(size: CGSize) -> CGFloat {
        let diameter = min(size.width, size.height)
        return (system.cornerStyle == .sharp) ? 0.0 : system.cornerRadius(forLength: diameter/4.0, cornerStyle: .rounded)
    }

}

#Preview {
    CircularSegmentedView()
}
