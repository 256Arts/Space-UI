//
//  OrbitsView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-03-18.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI
import GameplayKit

struct OrbitsView: View {
    
    struct Orbit: Identifiable {
        let id: Int
        let size: CGSize
        let currentAngle: CGFloat
    }
    
    let orbits: [Orbit]
    
    @State var phase: CGFloat = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .stroke(Color(color: .secondary, opacity: .high), lineWidth: 1)
                    .frame(width: geometry.size.width * 2.5, height: 1)
                Rectangle()
                    .stroke(Color(color: .secondary, opacity: .high), lineWidth: 1)
                    .frame(width: 1, height: geometry.size.height)
                ForEach(self.orbits) { orbit in
                    HStack(spacing: -1) {
                        Rectangle()
                            .stroke(Color(color: .secondary, opacity: .high), style: StrokeStyle(lineWidth: 1, lineCap: system.lineCap, dash: system.lineDash(lineWidth: 1)))
                            .frame(width: 1, height: geometry.size.height)
                        Ellipse()
                            .stroke(Color(color: .primary, opacity: .medium), lineWidth: 4)
                            .frame(width: orbit.size.width * geometry.size.width, height: orbit.size.height * geometry.size.height)
                            .zIndex(1)
                            .overlay {
                                Ellipse()
                                    .stroke(Color(color: .primary, opacity: .max), style: StrokeStyle(lineWidth: 5, dash: [700, 500], dashPhase: self.phase))
                            }
                            .overlay {
                                OrbitPlanetView(vid: Int(system.seed) + orbit.id)
                                    .offset(x: orbit.size.width/2 * geometry.size.width * cos(orbit.currentAngle), y: orbit.size.height/2 * geometry.size.height * sin(orbit.currentAngle))
                            }
                        Rectangle()
                            .stroke(Color(color: .secondary, opacity: .high), style: StrokeStyle(lineWidth: 1, lineCap: system.lineCap, dash: system.lineDash(lineWidth: 1)))
                            .frame(width: 1, height: geometry.size.height)
                    }
                }
            }
            .offset(x: -0.35 * geometry.size.width, y: 0)
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 30).repeatForever(autoreverses: false)) {
                self.phase = 1200
            }
        }
    }
    
    init() {
        let random: GKRandom = {
            let source = GKMersenneTwisterRandomSource(seed: system.seed)
            return GKRandomDistribution(randomSource: source, lowestValue: 0, highestValue: Int.max)
        }()
        orbits = [
            Orbit(id: 0, size: CGSize(width: 0.08, height: 0.10), currentAngle: CGFloat(random.nextDouble(in: -.pi ... .pi))/3),
            Orbit(id: 1, size: CGSize(width: 0.22, height: 0.22), currentAngle: CGFloat(random.nextDouble(in: -.pi ... .pi))/3),
            Orbit(id: 2, size: CGSize(width: 0.44, height: 0.31), currentAngle: CGFloat(random.nextDouble(in: -.pi ... .pi))/3),
            Orbit(id: 3, size: CGSize(width: 0.90, height: 0.48), currentAngle: CGFloat(random.nextDouble(in: -.pi ... .pi))/3),
            Orbit(id: 4, size: CGSize(width: 1.70, height: 0.85), currentAngle: CGFloat(random.nextDouble(in: -.pi ... .pi))/3)
        ]
    }
    
}

struct OrbitPlanetView: View {
    
    let vid: Int
    
    var body: some View {
        AutoShape(direction: .up)
            .frame(width: 30, height: 30)
            .foregroundColor(Color(color: .secondary, opacity: .max))
            .shadow(radius: 4)
            .overlay(alignment: .bottomLeading) {
                Text(Lorem.word(vid: vid).prefix(7))
                    .lineLimit(1)
                    .fixedSize()
                    .shadow(color: Color.screenBackground, radius: 8, x: 0, y: 0)
                    .rotationEffect(Angle(degrees: 90), anchor: .bottomLeading)
                    .offset(x: 6, y: 10)
            }
            .overlay(alignment: .topLeading) {
                Text(Lorem.word(vid: vid + 7).prefix(7))
                    .lineLimit(1)
                    .foregroundColor(Color(color: .tertiary, opacity: .max))
                    .fixedSize()
                    .shadow(color: Color.screenBackground, radius: 8, x: 0, y: 0)
                    .offset(x: 35, y: 0)
            }
    }
}

#Preview {
    OrbitsView()
}
