import SwiftUI

struct GalaxyView: View {
    
    struct Planet: Identifiable {
        let id: Int
        let coord: CGPoint
        let diameter: CGFloat
        let isBlackHole: Bool
        let nebulaShapeNumber: Int?
        let hasRing: Bool
        /// How far the spin axis is tipped toward the viewer. In the "own rotation axis" variant each planet
        /// gets its own value; otherwise every planet shares the default gentle tilt.
        var axisTilt: Angle = .degrees(23)
        /// In-plane rotation of the whole globe, pointing the spin axis in a different screen direction.
        var axisRoll: Angle = .zero
        /// Per-planet offset into the shared spin so differently-axed globes aren't all in phase.
        var spinPhase: Angle = .zero
        var isOrigin: Bool {
            id == 0
        }
        let detailTexts = [
            Lorem.word(vid: 6),
            Lorem.words(vid: 7, count: 3),
            Lorem.word(vid: 8),
            Lorem.word(vid: 9),
            Lorem.word(vid: 10)
        ]
        let progress1 = Double.random(in: 0.1...1)
        let progress2 = Double.random(in: 0.1...1)
    }
    
    let planets: [Planet]
    let showPlanetImage: Bool
    let showNavigationMap: Bool
    let selectionStyle: PlanetIconView.SelectionStyle
    
    @IDGen private var idGen
    @Environment(\.system) private var system
    
    @State var sphereAnimationProgress: CGFloat = 0.0
    @State var selectedPlanet: Planet
    @State var blackHoleAngle = Angle.zero
    
    var body: some View {
        ZStack {
            // Recede the two sector-map layers to different depths so the graph reads with a bit of
            // parallax on visionOS; the planets stay near the front plane (z ≈ 0).
            NavigationMapShape(mapData: .init(vid: idGen(0)))
                .stroke(system.colors.color(.secondary, opacity: .high), style: system.strokeStyle(.medium))
                .depthOffset(-20)
            NavigationMapShape(mapData: .init(vid: idGen(1)))
                .stroke(system.colors.color(.secondary, opacity: .min), style: system.strokeStyle(.thin))
                .scaleEffect(2)
                .depthOffset(-50)
            
            ForEach(self.planets) { planet in
                if let nebNumber = planet.nebulaShapeNumber {
                    Image(decorative: "Nebula \(system.basicShape == .square ? "Grid" : "Trigrid") \(nebNumber)")
                        .foregroundColor(system.colors.color(.primary, opacity: .medium))
                        .offset(x: planet.coord.x, y: planet.coord.y)
                        .zIndex(-1)
                } else if planet.isBlackHole {
                    Image(decorative: "Black Hole")
                        .foregroundColor(system.colors.color(.primary, opacity: .medium))
                        .rotationEffect(self.blackHoleAngle)
                        .offset(x: planet.coord.x, y: planet.coord.y)
                } else {
                    PlanetIconView(planet: planet, selectionStyle: selectionStyle, selectedID: Binding(get: {
                        selectedPlanet.id
                    }, set: { _ in }), sphereAnimationProgress: self.$sphereAnimationProgress)
                        .onTapGesture {
                            AudioController.shared.play(.button)
                            selectedPlanet = planet
                        }
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .overlay {
            AutoStack { // To place overlay on bottom or trailing edge
                Spacer()
                PlanetDetailsView(planet: $selectedPlanet, showPlanetImage: self.showPlanetImage)
            }
            .transaction { transaction in
                transaction.animation = nil
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 0.6)) {
                self.sphereAnimationProgress = 1.0
            }
            withAnimation(Animation.linear(duration: 5.0).repeatForever(autoreverses: false)) {
                self.blackHoleAngle = Angle.degrees(360)
            }
        }
    }
    
    init() {
        let random = SeededRandom(seed: Space_UI.system.seed)
        let coords = PoissonDiskSampling.takeSamples(in: CGRect(x: -1250, y: -750, width: 2500, height: 1500), inCircle: false, existingPoints: [.zero], tryCount: 100, minRadius: 130, random: random)
        showPlanetImage = random.nextBool()
        showNavigationMap = random.nextBool(chance: 0.75)
        selectionStyle = {
            switch random.nextInt(in: (Space_UI.system.colors.paletteStyle == .colorful ? 0 : 1)..<3) {
            case 0:
                return .color
            case 1:
                return .shapeBorder
            default:
                return .flash
            }
        }()
        // Design variant: give every planet its own randomly-oriented spin axis instead of one shared tilt.
        let planetsHaveOwnAxis = random.nextBool()
        var id = 0
        planets = coords.map({
            let diameter = CGFloat(random.nextDouble(in: 20...40))
            let randomNumber = random.nextInt(in: 0...18)
            let nebulaShapeNumber = $0 != .zero && randomNumber == 1 ? random.nextInt(in: 1...3) : nil
            let p: Planet
            if planetsHaveOwnAxis {
                p = Planet(id: id, coord: $0, diameter: diameter, isBlackHole: $0 != .zero && randomNumber == 0, nebulaShapeNumber: nebulaShapeNumber, hasRing: randomNumber == 2, axisTilt: .degrees(random.nextDouble(in: -50...50)), axisRoll: .degrees(random.nextDouble(in: -180...180)), spinPhase: .degrees(random.nextDouble(in: 0...360)))
            } else {
                p = Planet(id: id, coord: $0, diameter: diameter, isBlackHole: $0 != .zero && randomNumber == 0, nebulaShapeNumber: nebulaShapeNumber, hasRing: randomNumber == 2)
            }
            id += 1
            return p
        })
        selectedPlanet = planets[0]
    }
    
}

#Preview {
    GalaxyView()
}
