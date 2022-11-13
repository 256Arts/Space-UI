//
//  PlanetIconView.swift
//  Space UI
//
//  Created by Jayden Irwin on 2020-08-13.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import SwiftUI

struct PlanetIconView: View {
    
    @EnvironmentObject private var system: SystemAppearance
    @Environment(\.shapeDirection) var shapeDirection: ShapeDirection
    
    let planet: GalaxyPage.Planet
    let shapeOverlayOnSelection: Bool
    
    @Binding var selectedID: Int
    @Binding var sphereAnimationProgress: CGFloat
    
    var body: some View {
        Sphere(vertical: 4, horizontal: 3)
            .trim(from: 0.0, to: self.sphereAnimationProgress)
            .stroke(Color(color: self.planetColor(), opacity: .max), style: system.strokeStyle(.thin))
            .frame(width: self.planet.diameter)
            .overlay( self.planet.hasRing ?
                Ellipse()
                    .stroke(Color(color: self.planetColor(), opacity: .max), style: system.strokeStyle(.thin))
                    .frame(width: self.planet.diameter * 1.6, height: self.planet.diameter * 0.5)
                : nil
            )
            .overlay( planet.id == selectedID && shapeOverlayOnSelection ?
                AutoShape(direction: shapeDirection)
                    .stroke(Color(color: .secondary, opacity: .max), style: system.strokeStyle(.thin))
                    .frame(width: self.planet.diameter * 2, height: self.planet.diameter * 2)
                : nil
            )
            .offset(x: self.planet.coord.x, y: self.planet.coord.y)
    }
    
    func planetColor() -> SystemColor {
        if planet.id != selectedID || shapeOverlayOnSelection {
            return planet.isOrigin ? .secondary : .primary
        } else {
            return .tertiary
        }
    }
}

struct SinglePlanetView_Previews: PreviewProvider {
    static var previews: some View {
        PlanetIconView(planet: GalaxyPage.Planet(id: 10, coord: .zero, diameter: 20, isBlackHole: false, nebulaShapeNumber: nil, hasRing: true), shapeOverlayOnSelection: true, selectedID: .constant(5), sphereAnimationProgress: .constant(1.0))
    }
}
