//
//  PlanetDetailsView.swift
//  Space UI
//
//  Created by Jayden Irwin on 2020-03-16.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import SwiftUI

struct PlanetDetailsView: View {
    
    let showPlanetImage: Bool
    
    @Binding var details: [String]
    @Binding var progress1: Double
    @Binding var progress2: Double
    
    var body: some View {
        Section {
            VStack(alignment: .leading) {
                TextPair(did: 0, label: "Name", value: self.details[0])
                TextPair(did: 0, label: "Races", value: self.details[1])
                TextPair(did: 0, label: "Leadership", value: self.details[2])
                TextPair(did: 0, label: "Population", value: self.details[3])
                TextPair(did: 0, label: "Currency", value: self.details[4])
                HStack(alignment: .top) {
                    DecorativeBoxesView()
                    CircularProgressView(did: 1, value: self.$progress1, lineWidth: nil)
                        .frame(width: 56, height: 56)
                    DecorativeBoxesView()
                    CircularProgressView(did: 1, value: self.$progress2, lineWidth: nil)
                        .frame(width: 56, height: 56)
                }
            }
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
        .onAppear() {
            self.progress1 = Double.random(in: 0.1...1)
            self.progress2 = Double.random(in: 0.1...1)
        }
    }
    
}

struct PlanetDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        PlanetDetailsView(showPlanetImage: true, details: .constant(["a", "b", "c", "d", "e"]), progress1: .constant(0.5), progress2: .constant(0.5))
    }
}
