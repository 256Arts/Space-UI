import SwiftUI

struct Sphere: Shape {

    let vertical: Int
    let horizontal: Int
    var rotation: Angle = .zero
    var tilt: Angle = .degrees(23)

    private static let samplesPerCircle = 48

    /// Slow spin for `rotation`: one revolution per minute.
    static func spinAngle(at date: Date) -> Angle {
        .degrees(date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 60.0) * 6.0)
    }

    /// Maps a horizontal drag translation to a spin angle for touch-spinning the globe: dragging one diameter
    /// across the sphere turns it a half revolution (a trackball-like feel independent of the globe's size).
    /// Shared by the projected 2D `Sphere` and the RealityKit `Sphere3DView` so both spin at the same rate.
    static func dragRotation(translationWidth: CGFloat, diameter: CGFloat) -> Angle {
        guard 0 < diameter else { return .zero }
        return .degrees(Double(translationWidth / diameter) * 180.0)
    }

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height)/2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let tiltSin = sin(tilt.radians)
        let tiltCos = cos(tilt.radians)

        // Orthographic projection of a unit-sphere point (y up, z toward the viewer),
        // tipping the top of the sphere toward the viewer by `tilt`.
        // Points on the back hemisphere are hidden.
        func project(_ x: Double, _ y: Double, _ z: Double) -> (point: CGPoint, isVisible: Bool) {
            (CGPoint(x: center.x + x * radius, y: center.y - (y * tiltCos - z * tiltSin) * radius), 0 <= y * tiltSin + z * tiltCos)
        }

        return Path { path in
            path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius*2, height: radius*2))

            if 1 < horizontal {
                for step in 1...horizontal {
                    let y = 1.0 - 2.0 * Double(step) / Double(horizontal+1)
                    let latitudeRadius = sqrt(1.0 - y*y)
                    addVisiblePolyline(to: &path, parameterRange: 0...(2 * .pi)) { angle in
                        project(latitudeRadius * sin(angle), y, latitudeRadius * cos(angle))
                    }
                }
            }

            if 1 < vertical {
                for step in 0..<vertical {
                    let longitude = rotation.radians + Double(step) * 2 * .pi / Double(vertical)
                    addVisiblePolyline(to: &path, parameterRange: (-.pi/2)...(.pi/2)) { latitude in
                        project(cos(latitude) * sin(longitude), sin(latitude), cos(latitude) * cos(longitude))
                    }
                }
            }
        }
    }

    /// Samples a curve on the sphere, drawing only the runs of points that face the viewer.
    private func addVisiblePolyline(to path: inout Path, parameterRange: ClosedRange<Double>, point: (Double) -> (point: CGPoint, isVisible: Bool)) {
        var isDrawing = false
        for sample in 0...Self.samplesPerCircle {
            let parameter = parameterRange.lowerBound + (parameterRange.upperBound - parameterRange.lowerBound) * Double(sample) / Double(Self.samplesPerCircle)
            let (samplePoint, isVisible) = point(parameter)
            if isVisible {
                isDrawing ? path.addLine(to: samplePoint) : path.move(to: samplePoint)
            }
            isDrawing = isVisible
        }
    }
}

#Preview {
    TimelineView(.animation) { context in
        Sphere(vertical: 7, horizontal: 7, rotation: Sphere.spinAngle(at: context.date)).stroke()
    }
}
