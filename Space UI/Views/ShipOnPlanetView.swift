//
//  ShipOnPlanetView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2022-10-04.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

import SwiftUI
import GameplayKit

struct ShipOnPlanetView: View {
    
    let pointIconsAreCircles: Bool
    let pointsHaveLabels: Bool
    let points: [CGPoint]
    let planetAngle: Double
    
    @State var sphereAnimationProgress: CGFloat = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    Ellipse()
                        .stroke(Color(color: .primary, opacity: .max), style: system.strokeStyle(.medium))
                        .frame(width: geometry.size.height/4, height: geometry.size.height/2, alignment: .center)
                    Ellipse()
                        .stroke(Color(color: .primary, opacity: .max), style: system.strokeStyle(.medium))
                        .frame(width: geometry.size.height/8, height: geometry.size.height/4, alignment: .center)
                    ShipData.shared.icon
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color(color: .secondary, opacity: .max))
                        .frame(height: geometry.size.height/8, alignment: .center)
                }
                ZStack(alignment: .leading) {
                    RadialGradient(gradient: Gradient(colors: [.clear, Color(color: .primary, opacity: .low)]), center: .center, startRadius: 0, endRadius: geometry.size.height/4)
                        .clipShape(Circle())
                    Sphere(vertical: self.planetLines(size: geometry.size), horizontal: self.planetLines(size: geometry.size))
                        .trim(from: 0.0, to: self.sphereAnimationProgress)
                        .stroke(Color(color: .primary, opacity: .high), style: system.strokeStyle(.medium))
                        .rotationEffect(Angle(degrees: self.planetAngle))
                    ForEach(self.points) { point in
                        HStack {
                            if self.pointIconsAreCircles {
                                CircleIcon.image(vid: 8)
                                    .foregroundColor(Color(color: .tertiary, opacity: .max))
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: system.cornerRadius(forLength: 24))
                                        .fill(Color(color: .tertiary, opacity: .max))
                                        .frame(width: 24, height: 24)
                                    GeneralIcon.image(vid: 9)
                                        .foregroundColor(Color(color: .tertiary, opacity: .min))
                                }
                            }
                            if self.pointsHaveLabels {
                                Text(Lorem.word(vid: 8))
                                    .frame(minWidth: 0, idealWidth: nil, maxWidth: 100)
                                    .fixedSize()
                                    .lineLimit(nil)
                                    .font(Font.spaceFont(size: 18))
                                    .foregroundColor(Color(color: .tertiary, opacity: .max))
                            }
                        }
                        .shadow(color: Color.screenBackground, radius: 8, x: 0, y: 0)
                        .offset(x: CGFloat(point.x * min(geometry.size.width, geometry.size.height/2)), y: CGFloat(point.y * min(geometry.size.width, geometry.size.height/2)))
                    }
                }
                .frame(width: min(geometry.size.width, geometry.size.height/2), height: min(geometry.size.width, geometry.size.height/2), alignment: .center)
            }
            .frame(minHeight: geometry.size.height/2)
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
        .onAppear() {
            withAnimation(.linear(duration: 1.0)) {
                self.sphereAnimationProgress = 1.0
            }
        }
    }
    
    init() {
        let random: GKRandom = {
            let source = GKMersenneTwisterRandomSource(seed: system.seed)
            return GKRandomDistribution(randomSource: source, lowestValue: 0, highestValue: Int.max)
        }()
        pointIconsAreCircles = random.nextBool()
        pointsHaveLabels = random.nextBool()
        points = PoissonDiskSampling.samples(in: CGRect(x: 0, y: -0.5, width: 1, height: 1), inCircle: true, staticPoint: nil, candidatePointCount: 4, rejectRadius: 0.2, random: random)
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

extension CGPoint: Identifiable {
    public var id: String { "\(x)-\(y)" }
}
