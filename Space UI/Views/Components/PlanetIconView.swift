import SwiftUI

struct PlanetIconView: View {
    
    enum SelectionStyle {
        case color, shapeBorder, flash
    }
    
    @Environment(\.system) private var system
    @Environment(\.shapeDirection) var shapeDirection: ShapeDirection
    
    let planet: GalaxyView.Planet
    let selectionStyle: SelectionStyle
    
    @Binding var selectedID: Int
    @Binding var sphereAnimationProgress: CGFloat
    
    @State private var opacity = 1.0
    
    var body: some View {
        Group {
            #if os(visionOS)
            Sphere3DView(vertical: 4, horizontal: 3, color: system.colors.color(planetColor(), opacity: .max), tilt: planet.axisTilt)
            #else
            TimelineView(.animation(minimumInterval: 1.0/30.0)) { context in
                Sphere(vertical: 4, horizontal: 3, rotation: Sphere.spinAngle(at: context.date) + planet.spinPhase, tilt: planet.axisTilt)
                    .trim(from: 0.0, to: sphereAnimationProgress)
                    .stroke(system.colors.color(planetColor(), opacity: .max), style: system.strokeStyle(.thin))
            }
            #endif
        }
            .frame(width: planet.diameter, height: planet.diameter)
            .contentShape(Circle())
            .overlay {
                if planet.hasRing {
                    Ellipse()
                        .stroke(system.colors.color(planetColor(), opacity: .max), style: system.strokeStyle(.thin))
                        .frame(width: planet.diameter * 1.6, height: planet.diameter * 0.5)
                }
            }
            // Roll the globe (and its ring) in-plane so its spin axis points in the planet's own screen direction.
            .rotationEffect(planet.axisRoll)
            .opacity(planet.id == selectedID ? opacity : 1.0)
            .overlay {
                if planet.id == selectedID && selectionStyle == .shapeBorder {
                    AutoShape(system: system, direction: shapeDirection)
                        .stroke(system.colors.color(.secondary, opacity: .max), style: system.strokeStyle(.thin))
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
    
    func planetColor() -> ColorRole {
        if planet.id != selectedID || selectionStyle == .shapeBorder {
            planet.isOrigin ? .secondary : .primary
        } else {
            .tertiary
        }
    }
}

#Preview {
    PlanetIconView(planet: GalaxyView.Planet(id: 10, coord: .zero, diameter: 20, isBlackHole: false, nebulaShapeNumber: nil, hasRing: true), selectionStyle: .color, selectedID: .constant(5), sphereAnimationProgress: .constant(1.0))
}
