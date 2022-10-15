//
//  GalaxyPage.swift
//  Space UI
//
//  Created by Jayden Irwin on 2019-12-15.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import SwiftUI
import GameplayKit

struct GalaxyPage: View {
    
    struct Planet: Identifiable {
        let id: Int
        let coord: CGPoint
        let diameter: CGFloat
        let isBlackHole: Bool
        let nebulaShapeNumber: Int?
        let hasRing: Bool
        var isOrigin: Bool {
            id == 0
        }
    }
    
    let planets: [Planet]
    let showPlanetImage: Bool
    let shapeOverlayOnSelection: Bool
    
    @Environment(\.safeCornerOffsets) private var safeCornerOffsets
    
    @State var sphereAnimationProgress: CGFloat = 0.0
    @State var selectedID = 0
    @State var blackHoleAngle = Angle.zero
    @State var detailTexts = [
        Lorem.word(vid: 1),
        Lorem.words(vid: 2, count: 3),
        Lorem.word(vid: 3),
        Lorem.word(vid: 4),
        Lorem.word(vid: 5)
    ]
    @State var progress1: Double = 0.0
    @State var progress2: Double = 0.0
    
    var body: some View {
        ZStack {
            ForEach(self.planets) { planet in
                if let nebNumber = planet.nebulaShapeNumber {
                    Image(decorative: "Nebula \(system.basicShape == .square ? "Grid" : "Trigrid") \(nebNumber)")
                        .foregroundColor(Color(color: .primary, opacity: .medium))
                        .offset(x: planet.coord.x, y: planet.coord.y)
                        .zIndex(-1)
                } else if planet.isBlackHole {
                    Image(decorative: "Black Hole")
                        .foregroundColor(Color(color: .primary, opacity: .medium))
                        .rotationEffect(self.blackHoleAngle)
                        .offset(x: planet.coord.x, y: planet.coord.y)
                } else {
                    PlanetIconView(planet: planet, shapeOverlayOnSelection: shapeOverlayOnSelection, selectedID: self.$selectedID, sphereAnimationProgress: self.$sphereAnimationProgress)
                        .onTapGesture {
                            self.selectPlanet(id: planet.id)
                        }
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .overlay {
            AutoStack { // To place overlay on bottom or trailing edge
                Spacer()
                PlanetDetailsView(showPlanetImage: self.showPlanetImage, details: self.$detailTexts, progress1: self.$progress1, progress2: self.$progress2)
            }
            .animation(.none)
        }
        .overlay(alignment: .topLeading) {
            NavigationButton(to: .planet) {
                Text("Planet")
            }
            .offset(safeCornerOffsets.topLeading)
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
        let random: GKRandom = {
            let source = GKMersenneTwisterRandomSource(seed: system.seed)
            return GKRandomDistribution(randomSource: source, lowestValue: 0, highestValue: Int.max)
        }()
        let coords = PoissonDiskSampling.samples(in: CGRect(x: -1250, y: -750, width: 2500, height: 1500), inCircle: false, staticPoint: .zero, candidatePointCount: 100, rejectRadius: 130, random: random)
        showPlanetImage = random.nextBool()
        shapeOverlayOnSelection = system.colors.paletteStyle != .colorful || Bool.random()
        var id = 0
        planets = coords.map({
            let diameter = CGFloat(random.nextDouble(in: 20...40))
            let randomNumber = random.nextInt(in: 0...25)
            let nebulaShapeNumber = randomNumber == 1 ? random.nextInt(in: 1...3) : nil
            let p = Planet(id: id, coord: $0, diameter: diameter, isBlackHole: randomNumber == 0, nebulaShapeNumber: nebulaShapeNumber, hasRing: randomNumber == 2)
            id += 1
            return p
        })
    }
    
    func selectPlanet(id: Int) {
        guard self.selectedID != id else { return }
        AudioController.shared.play(.button)
        self.selectedID = id
        self.detailTexts = [
            Lorem.word(vid: 6),
            Lorem.words(vid: 7, count: 3),
            Lorem.word(vid: 8),
            Lorem.word(vid: 9),
            Lorem.word(vid: 10)
        ]
        self.progress1 = Double.random(in: 0.1...1)
        self.progress2 = Double.random(in: 0.1...1)
    }
    
}

struct GalaxyPage_Previews: PreviewProvider {
    static var previews: some View {
        GalaxyPage()
    }
}
