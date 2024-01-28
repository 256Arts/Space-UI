//
//  PlanetIconView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-08-13.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct PlanetIconView: View {
    
    enum SelectionStyle {
        case color, shapeBorder, flash
    }
    
    @EnvironmentObject private var system: SystemStyles
    @Environment(\.shapeDirection) var shapeDirection: ShapeDirection
    
    let planet: GalaxyPage.Planet
    let selectionStyle: SelectionStyle
    
    @Binding var selectedID: Int
    @Binding var sphereAnimationProgress: CGFloat
    
    @State private var opacity = 1.0
    
    var body: some View {
        Sphere(vertical: 4, horizontal: 3)
            .trim(from: 0.0, to: sphereAnimationProgress)
            .stroke(Color(color: planetColor(), opacity: .max), style: system.strokeStyle(.thin))
            .frame(width: planet.diameter)
            .contentShape(Circle())
            .overlay {
                if planet.hasRing {
                    Ellipse()
                        .stroke(Color(color: planetColor(), opacity: .max), style: system.strokeStyle(.thin))
                        .frame(width: planet.diameter * 1.6, height: planet.diameter * 0.5)
                }
            }
            .opacity(planet.id == selectedID ? opacity : 1.0)
            .overlay {
                if planet.id == selectedID && selectionStyle == .shapeBorder {
                    AutoShape(direction: shapeDirection)
                        .stroke(Color(color: .secondary, opacity: .max), style: system.strokeStyle(.thin))
                        .frame(width: planet.diameter * 2, height: planet.diameter * 2)
                        .offset(y: system.basicShape == .triangle || system.basicShape == .trapezoid ? (shapeDirection == .up ? -5 : 5) : 0)
                }
            }
            .offset(x: planet.coord.x, y: planet.coord.y)
            .onAppear {
                if selectionStyle == .flash {
                    withAnimation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                        opacity = 0.0
                    }
                }
            }
    }
    
    func planetColor() -> SystemColor {
        if planet.id != selectedID || selectionStyle == .shapeBorder {
            return planet.isOrigin ? .secondary : .primary
        } else {
            return .tertiary
        }
    }
}

#Preview {
    PlanetIconView(planet: GalaxyPage.Planet(id: 10, coord: .zero, diameter: 20, isBlackHole: false, nebulaShapeNumber: nil, hasRing: true), selectionStyle: .color, selectedID: .constant(5), sphereAnimationProgress: .constant(1.0))
}
