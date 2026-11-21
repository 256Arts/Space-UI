import SwiftUI

struct ShipOnPlanetView: View {
    @Environment(\.system) private var system

    /// The seed picks one of two planet designs, on every platform:
    /// - `true`: a 3D globe spinning only about its polar axis (so the ship stays over the north pole), with the
    ///   points of interest attached to the surface so they rotate with the planet and hide on the far side.
    ///   Rendered with RealityKit on visionOS, and with the projected `Sphere` (spun) elsewhere.
    /// - `false`: the projected 2D wireframe held static at a random angle (no rotation), with the points
    ///   overlaid in 2D.
    let usePlanet3D: Bool
    let pointIconsAreCircles: Bool
    let pointsHaveLabels: Bool
    let points: [CGPoint]
    /// 3D surface directions for the points of interest, derived from `points` (used only in the 3D design).
    let surfacePoints: [SIMD3<Float>]
    let planetAngle: Double

    @State var sphereAnimationProgress: CGFloat = 0.0
    /// Committed touch-spin offset (persists between drags), layered on top of the ambient auto-spin.
    @State private var spinPhase: Angle = .zero
    /// Live horizontal drag translation while the user is spinning the globe; folded into `spinPhase` on release.
    @State private var dragTranslation: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let planetDiameter = min(geometry.size.width, geometry.size.height / 2)
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    Ellipse()
                        .stroke(system.colors.color(.primary, opacity: .max), style: system.strokeStyle(.medium))
                        .frame(width: geometry.size.height/4, height: geometry.size.height/2, alignment: .center)
                    Ellipse()
                        .stroke(system.colors.color(.primary, opacity: .max), style: system.strokeStyle(.medium))
                        .frame(width: geometry.size.height/8, height: geometry.size.height/4, alignment: .center)
                    ShipState.shared.icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(system.colors.color(.secondary, opacity: .max))
                        .frame(height: geometry.size.height/8, alignment: .center)
                }
                let sphereStack = ZStack(alignment: .leading) {
                    RadialGradient(gradient: Gradient(colors: [.clear, system.colors.color(.primary, opacity: .low)]), center: .center, startRadius: 0, endRadius: geometry.size.height/4)
                        .clipShape(Circle())
                    if usePlanet3D {
                        #if os(visionOS)
                        Sphere3DView(
                            vertical: planetLines(size: geometry.size),
                            horizontal: planetLines(size: geometry.size),
                            color: system.colors.color(.primary, opacity: .high),
                            surfacePoints: surfacePoints,
                            pointColor: system.colors.color(.tertiary, opacity: .max),
                            isInteractive: true)
                        #else
                        // The planet spins about its polar axis (pole stays at the top under the ship). Points
                        // of interest are omitted here — a live RealityView isn't viable on this platform (see
                        // Sphere3DView), and projecting 2D markers onto the spinning globe read as unstable.
                        // `spinPhase` + the live drag let the user grab and spin the globe on top of the ambient spin.
                        TimelineView(.animation(minimumInterval: 1.0/30.0)) { context in
                            Sphere(vertical: planetLines(size: geometry.size), horizontal: planetLines(size: geometry.size), rotation: Sphere.spinAngle(at: context.date) + spinPhase + Sphere.dragRotation(translationWidth: dragTranslation, diameter: planetDiameter))
                                .trim(from: 0.0, to: self.sphereAnimationProgress)
                                .stroke(system.colors.color(.primary, opacity: .high), style: system.strokeStyle(.medium))
                        }
                        #endif
                    } else {
                        // Static (rotation disabled) at a random angle. The 2D point markers are positioned in
                        // screen space rather than on the globe, so this variant is intentionally not spinnable.
                        Sphere(vertical: planetLines(size: geometry.size), horizontal: planetLines(size: geometry.size))
                            .trim(from: 0.0, to: self.sphereAnimationProgress)
                            .stroke(system.colors.color(.primary, opacity: .high), style: system.strokeStyle(.medium))
                            .rotationEffect(Angle(degrees: self.planetAngle))
                        pointsOverlay(size: geometry.size)
                    }
                }
                .frame(width: planetDiameter, height: planetDiameter, alignment: .center)

                #if os(visionOS)
                sphereStack // Sphere3DView manages its own spin gesture in 3D.
                #else
                if usePlanet3D {
                    sphereStack
                        .contentShape(Circle())
                        .gesture(spinGesture(diameter: planetDiameter))
                } else {
                    sphereStack
                }
                #endif
            }
            .frame(minHeight: geometry.size.height/2)
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0)) {
                self.sphereAnimationProgress = 1.0
            }
        }
    }

    #if !os(visionOS)
    /// Grabs the projected globe and spins it about its polar axis with a horizontal drag, committing the
    /// swept angle into `spinPhase` on release so the ambient auto-spin resumes seamlessly from there.
    private func spinGesture(diameter: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragTranslation = value.translation.width
            }
            .onEnded { value in
                spinPhase = spinPhase + Sphere.dragRotation(translationWidth: value.translation.width, diameter: diameter)
                dragTranslation = 0
            }
    }
    #endif

    @ViewBuilder
    private func pointsOverlay(size: CGSize) -> some View {
        ForEach(Array(self.points.enumerated()), id: \.offset) { _, point in
            HStack {
                if self.pointIconsAreCircles {
                    CircleIcon.image(vid: 8)
                        .foregroundColor(system.colors.color(.tertiary, opacity: .max))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: system.cornerRadius(forLength: 24))
                            .fill(system.colors.color(.tertiary, opacity: .max))
                            .frame(width: 24, height: 24)
                        GeneralIcon.image(vid: 9)
                            .foregroundColor(system.colors.color(.tertiary, opacity: .min))
                    }
                }
                if self.pointsHaveLabels {
                    Text(Lorem.word(vid: 8))
                        .frame(minWidth: 0, idealWidth: nil, maxWidth: 100)
                        .fixedSize()
                        .lineLimit(nil)
                        .font(Font.spaceFont(size: 18))
                        .foregroundColor(system.colors.color(.tertiary, opacity: .max))
                }
            }
            .shadow(color: system.colors.screenBackground, radius: 8, x: 0, y: 0)
            .offset(x: CGFloat(point.x * min(size.width, size.height/2)), y: CGFloat(point.y * min(size.width, size.height/2)))
        }
    }

    init() {
        let random = SeededRandom(seed: Space_UI.system.seed)
        usePlanet3D = random.nextBool()
        pointIconsAreCircles = random.nextBool()
        pointsHaveLabels = random.nextBool()
        let points = PoissonDiskSampling.takeSamples(in: CGRect(x: 0, y: -0.5, width: 1, height: 1), inCircle: true, existingPoints: [], tryCount: 4, minRadius: 0.2, random: random)
        self.points = points
        // Map each 2D disk sample to a direction on the unit sphere (longitude from x, latitude from y).
        surfacePoints = points.map { point in
            let longitude = Float(point.x) * 2 * .pi
            let latitude = Float(point.y) * .pi
            return SIMD3<Float>(cos(latitude) * sin(longitude), sin(latitude), cos(latitude) * cos(longitude))
        }
        planetAngle = random.nextDouble(in: 0..<360)
    }

    func planetLines(size: CGSize) -> Int {
        let availableLength = min(size.width, size.height)
        return Int(availableLength / 37.0)
    }
}

struct ShipOnPlanetView_Previews: PreviewProvider {
    static var previews: some View {
        ShipOnPlanetView()
    }
}
