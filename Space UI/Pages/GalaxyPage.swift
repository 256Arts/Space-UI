//
//  GalaxyPage.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-15.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
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
    let selectionStyle: PlanetIconView.SelectionStyle
    
    @Environment(\.safeCornerOffsets) private var safeCornerOffsets
    
    @State var sphereAnimationProgress: CGFloat = 0.0
    @State var selectedPlanet: Planet
    @State var blackHoleAngle = Angle.zero
    
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
        .overlay(alignment: .topLeading) {
            NavigationButton(to: .planet)
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
        selectionStyle = {
            switch random.nextInt(in: (system.colors.paletteStyle == .colorful ? 0 : 1)..<3) {
            case 0:
                return .color
            case 1:
                return .shapeBorder
            default:
                return .flash
            }
        }()
        var id = 0
        planets = coords.map({
            let diameter = CGFloat(random.nextDouble(in: 20...40))
            let randomNumber = random.nextInt(in: 0...18)
            let nebulaShapeNumber = $0 != .zero && randomNumber == 1 ? random.nextInt(in: 1...3) : nil
            let p = Planet(id: id, coord: $0, diameter: diameter, isBlackHole: $0 != .zero && randomNumber == 0, nebulaShapeNumber: nebulaShapeNumber, hasRing: randomNumber == 2)
            id += 1
            return p
        })
        selectedPlanet = planets[0]
    }
    
}

#Preview {
    GalaxyPage()
}
