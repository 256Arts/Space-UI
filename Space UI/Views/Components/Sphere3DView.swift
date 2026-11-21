#if os(visionOS)
import SwiftUI
import RealityKit

/// A true-3D wireframe sphere — rings of thin torus meshes — spinning slowly about its polar (vertical) axis,
/// tilted slightly toward the viewer so the top pole is visible. Optional `surfacePoints` place marker dots on
/// the surface that ride along as the globe spins. The RealityKit counterpart of the projected 2D `Sphere`.
///
/// visionOS only: windowed RealityView is viewed with the user's own eyes there (custom cameras have no effect),
/// so the globe is sized to the view via GeometryReader3D and head tracking provides the 3D. On other platforms
/// a windowed RealityView renders an opaque box and hits RealityKit-internal Metal issues, so those use the
/// projected `Sphere` with spin instead (see `ShipOnPlanetView`).
struct Sphere3DView: View {

    let vertical: Int
    let horizontal: Int
    let color: Color
    /// Unit-length directions (in the sphere's own space) at which to place point-of-interest marker dots.
    var surfacePoints: [SIMD3<Float>] = []
    var pointColor: Color = .white
    /// How far the polar axis is tipped toward the viewer.
    var tilt: Angle = .degrees(23)
    /// When true, a horizontal drag grabs and spins the globe about its polar axis on top of the ambient spin.
    var isInteractive: Bool = false

    /// Committed touch-spin offset (persists between drags); applied to the `planetSpin` node.
    @State private var spinPhase: Angle = .zero
    /// Live spin from the in-progress drag; folded into `spinPhase` on release.
    @State private var dragSpin: Angle = .zero

    var body: some View {
        GeometryReader3D { geometry in
            let realityView = RealityView { content in
                let bounds = content.convert(geometry.frame(in: .local), from: .local, to: content)
                let radius = Float(min(bounds.extents.x, bounds.extents.y)) / 2
                guard 0 < radius else { return }
                let root = makeRoot(radius: radius)
                root.position = bounds.center
                content.add(root)
            } update: { content in
                recolor(content)
                if isInteractive, let spin = content.entities.first(where: { $0.name == "planetTilt" })?.children.first(where: { $0.name == "planetSpin" }) {
                    spin.orientation = simd_quatf(angle: Float((spinPhase + dragSpin).radians), axis: [0, 1, 0])
                }
            }

            if isInteractive {
                realityView.gesture(spinGesture(diameter: geometry.size.width))
            } else {
                realityView
            }
        }
    }

    /// Grabs the globe and spins it about its polar axis with a horizontal drag, committing the swept angle into
    /// `spinPhase` on release so the ambient auto-spin resumes seamlessly from there.
    private func spinGesture(diameter: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragSpin = Sphere.dragRotation(translationWidth: value.translation.width, diameter: diameter)
            }
            .onEnded { value in
                spinPhase = spinPhase + Sphere.dragRotation(translationWidth: value.translation.width, diameter: diameter)
                dragSpin = .zero
            }
    }

    /// Builds the tilt → spin → sphere hierarchy: a `planetTilt` root holds the `planetSpin` node (the touch-spin
    /// offset) holding the ambient-spinning `planetSphere` (rings + marker children). Separating the touch offset
    /// from the ambient spin lets them compose without either disturbing the other.
    private func makeRoot(radius: Float) -> Entity {
        let root = Entity()
        root.name = "planetTilt"
        root.orientation = simd_quatf(angle: Float(tilt.radians), axis: [1, 0, 0])

        let spin = Entity()
        spin.name = "planetSpin"

        let sphere = Self.makeWireframeSphere(radius: radius, vertical: vertical, horizontal: horizontal, color: UIColor(color))
        sphere.name = "planetSphere"

        let markerRadius = max(0.001, radius * 0.06)
        let markerMaterial = UnlitMaterial(color: UIColor(pointColor))
        for direction in surfacePoints {
            let marker = ModelEntity(mesh: .generateSphere(radius: markerRadius), materials: [markerMaterial])
            marker.name = "poi"
            marker.position = direction * radius
            sphere.addChild(marker)
        }
        spin.addChild(sphere)
        root.addChild(spin)

        // Slow spin about the polar (vertical) axis: one revolution per minute, matching `Sphere.spinAngle(at:)`.
        let spinAction = SpinAction(revolutions: 1, localAxis: [0, 1, 0])
        if let animation = try? AnimationResource.makeActionAnimation(for: spinAction, duration: 60, bindTarget: .transform).repeat() {
            sphere.playAnimation(animation)
        }
        return root
    }

    /// Recolors rings and markers when the theme/selection color changes without the view being rebuilt.
    private func recolor(_ content: some RealityViewContentProtocol) {
        guard let sphere = content.entities.first(where: { $0.name == "planetTilt" })?.children.first(where: { $0.name == "planetSpin" })?.children.first(where: { $0.name == "planetSphere" }) else { return }
        let ringMaterial = UnlitMaterial(color: UIColor(color))
        let markerMaterial = UnlitMaterial(color: UIColor(pointColor))
        for case let child as ModelEntity in sphere.children {
            child.model?.materials = [child.name == "poi" ? markerMaterial : ringMaterial]
        }
    }

    private static func makeWireframeSphere(radius: Float, vertical: Int, horizontal: Int, color: UIColor) -> Entity {
        let material = UnlitMaterial(color: color)
        let pipeRadius = max(0.0004, radius * 0.025)
        let sphere = Entity()

        if 1 < horizontal {
            for step in 1...horizontal {
                let y = 1.0 - 2.0 * Float(step) / Float(horizontal+1)
                let ring = ModelEntity(mesh: .generateTorus(ringRadius: radius * sqrt(1.0 - y*y), pipeRadius: pipeRadius), materials: [material])
                ring.name = "ring"
                ring.position.y = y * radius
                sphere.addChild(ring)
            }
        }

        if 1 < vertical {
            // Each full great circle through the poles covers 2 of the 2D shape's meridians.
            let ringCount = max(1, vertical/2)
            for step in 0..<ringCount {
                let longitude = Float(step) * .pi / Float(ringCount)
                let ring = ModelEntity(mesh: .generateTorus(ringRadius: radius, pipeRadius: pipeRadius), materials: [material])
                ring.name = "ring"
                ring.orientation = simd_quatf(angle: longitude, axis: [0, 1, 0]) * simd_quatf(angle: .pi/2, axis: [1, 0, 0])
                sphere.addChild(ring)
            }
        }
        return sphere
    }
}

extension MeshResource {

    /// A torus lying in the xz-plane, centered at the origin, circling the y-axis.
    static func generateTorus(ringRadius: Float, pipeRadius: Float, ringSegments: Int = 48, pipeSegments: Int = 8) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []

        for ring in 0...ringSegments {
            let theta = Float(ring) / Float(ringSegments) * 2 * .pi
            let ringDirection = SIMD3<Float>(cos(theta), 0, sin(theta))
            for pipe in 0...pipeSegments {
                let phi = Float(pipe) / Float(pipeSegments) * 2 * .pi
                let normal = ringDirection * cos(phi) + SIMD3<Float>(0, 1, 0) * sin(phi)
                positions.append(ringDirection * ringRadius + normal * pipeRadius)
                normals.append(normal)
            }
        }
        for ring in 0..<ringSegments {
            for pipe in 0..<pipeSegments {
                let a = UInt32(ring * (pipeSegments+1) + pipe)
                let b = a + UInt32(pipeSegments + 1)
                indices += [a, b, a+1, a+1, b, b+1]
            }
        }

        var descriptor = MeshDescriptor(name: "torus")
        descriptor.positions = MeshBuffer(positions)
        descriptor.normals = MeshBuffer(normals)
        descriptor.primitives = .triangles(indices)
        return try! .generate(from: [descriptor])
    }
}

#Preview {
    Sphere3DView(vertical: 7, horizontal: 7, color: .white)
}
#endif
