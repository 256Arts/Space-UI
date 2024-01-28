//
//  PlanetDetailsView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-03-16.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct PlanetDetailsView: View {
    
    @IDGen private var idGen
    @EnvironmentObject private var system: SystemStyles
    
    @Binding var planet: GalaxyPage.Planet
    
    let showPlanetImage: Bool
    
    var body: some View {
        Section {
            VStack(alignment: .leading) {
                TextPair(did: 0, label: "Name", value: planet.detailTexts[0])
                TextPair(did: 0, label: "Races", value: planet.detailTexts[1])
                TextPair(did: 0, label: "Leadership", value: planet.detailTexts[2])
                TextPair(did: 0, label: "Population", value: planet.detailTexts[3])
                TextPair(did: 0, label: "Currency", value: planet.detailTexts[4])
                
                HStack(alignment: .top) {
                    DecorativeBoxesView(vid: idGen(1))
                    CircularProgressView(did: idGen(1), value: .constant(planet.progress1), lineWidth: nil)
                        .frame(width: 56, height: 56)
                    DecorativeBoxesView(vid: idGen(2))
                    CircularProgressView(did: idGen(1), value: .constant(planet.progress2), lineWidth: nil)
                        .frame(width: 56, height: 56)
                }
            }
            .multilineTextAlignment(.leading)
            .frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .frame(maxWidth: 320)
        .background(alignment: .bottomTrailing) {
            if self.showPlanetImage {
                Image(["Mercury", "Planet3", "Venus"].randomElement()!)
                    .colorMultiply(Color(color: .primary, opacity: .max))
                    .rotationEffect(Angle(degrees: Double.random(in: 0..<360)))
                    .offset(x: 100, y: 100)
                    .opacity(0.5)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: system.cornerStyle == .sharp ? 0 : 24))
    }
    
}

#Preview {
    PlanetDetailsView(
        planet: .constant(.init(id: 1, coord: .zero, diameter: 10, isBlackHole: false, nebulaShapeNumber: nil, hasRing: false)),
        showPlanetImage: true)
}
