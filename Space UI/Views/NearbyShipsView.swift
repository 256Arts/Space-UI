//
//  NearbyShipsView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-22.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI
import GameplayKit

struct NearbyShipsView: View {
    
    struct RingConfiguration: Identifiable {
        let index: Int
        var id: Int { index }
        let isAnimated: Bool
    }
    
    let did: Int
    let hasRays: Bool
    let textRingPreferedRadius: CGFloat?
    let rotateTextRing: Bool
    let textRingPadding: CGFloat = 8.0
    let hasAsterisk: Bool
    let ringConfigs: [RingConfiguration]
    let hasAxisLines: Bool
    let axisLineEndCount: Int
    let hasTrianglePointers: Bool
    let trianglePointerCount: Int
    let trianglePointerLength: CGFloat
    let fillTrianglePointers: Bool
    let hasRadarScan: Bool
    let showShipRotation: Bool
    
    @ObservedObject var nearbyShipsState = ShipData.shared.nearbyShipsState
    @State var textRingAngle = Angle.zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if self.hasRays {
                    DecorativeRaysView()
                }
                if let textRingPreferedRadius = self.textRingPreferedRadius {
                    CircularText(string: "Nearby ships detected. It is possible there are more ships that are cloaked.", radius: min(geometry.size.width/2, geometry.size.height/2, textRingPreferedRadius), onTopEdge: true)
                        .foregroundColor(Color(color: .primary, opacity: .medium))
                        .rotationEffect(self.textRingAngle)
                }
                if self.hasAsterisk {
                    AsteriskShape(ticks: 30)
                        .stroke(Color(color: .primary, opacity: .medium), style: system.strokeStyle(.thick))
                        .frame(width: 0.25 * min(geometry.size.width, geometry.size.height), height: 0.25 * min(geometry.size.width, geometry.size.height), alignment: .center)
                }
                ForEach(ringConfigs) { config in
                    DecorativeRingView(animateSize: config.isAnimated, minimumWidthFraction: decorativeRingMinimumWidthFraction(parentSize: geometry.size, ringIndex: config.index))
                        .frame(width: decorativeRingFrameLengths(parentSize: geometry.size, ringIndex: config.index))
                }
                if self.hasAxisLines {
                    AsteriskShape(ticks: self.axisLineEndCount)
                        .stroke(Color(color: .primary, opacity: .high), style: system.strokeStyle(.thin))
                }
                if self.hasTrianglePointers {
                    CircularStack {
                        ForEach(0..<trianglePointerCount) { index in
                            if self.fillTrianglePointers {
                                Triangle(overrideDirection: .down)
                                    .foregroundColor(Color(color: .primary, opacity: .max))
                                    .frame(width: self.trianglePointerLength, height: self.trianglePointerLength, alignment: .center)
                                    .rotationEffect(CircularStack.subviewRotationAngles(stepCount: trianglePointerCount)[index])
                            } else {
                                Triangle(overrideDirection: .down)
                                    .stroke(Color(color: .primary, opacity: .max), style: system.strokeStyle(.thin))
                                    .frame(width: self.trianglePointerLength, height: self.trianglePointerLength, alignment: .center)
                                    .rotationEffect(CircularStack.subviewRotationAngles(stepCount: trianglePointerCount)[index])
                            }
                        }
                    }
                    .frame(width: 200 + trianglePointerLength)
                }
                if self.hasRadarScan {
                    RadarScanView(did: did)
                        .blendMode(.lighten)
                }
                ShipData.shared.icon
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color(color: .secondary, opacity: .max))
                    .frame(width: 0.12 * min(geometry.size.width, geometry.size.height), height: 0.12 * min(geometry.size.width, geometry.size.height), alignment: .center)
                ForEach(self.nearbyShipsState.nearbyShips) { ship in
                    NearbyShipView(ship: ship, showShipRotation: self.showShipRotation)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: (ship.isLarge ? 0.2 : 0.1) * min(geometry.size.width, geometry.size.height), height: (ship.isLarge ? 0.2 : 0.1) * min(geometry.size.width, geometry.size.height), alignment: .center)
                        .offset(x: ship.coord.x * min(geometry.size.width, geometry.size.height), y: ship.coord.y * min(geometry.size.width, geometry.size.height))
                }
            }
            .drawingGroup()
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
        .onAppear() {
            AudioController.shared.play(.sonarLoop)
            if self.rotateTextRing {
                withAnimation(Animation.linear(duration: 30.0).repeatForever(autoreverses: false)) {
                    self.textRingAngle = Angle.degrees(360)
                }
            }
        }
        .onDisappear() {
            AudioController.shared.stopLoopingSound(.sonarLoop)
        }
    }
    
    init(did: Int) {
        self.did = did
        let random: GKRandom = {
            let source = GKMersenneTwisterRandomSource(seed: UInt64(did))
            return GKRandomDistribution(randomSource: source, lowestValue: 0, highestValue: Int.max)
        }()
        
        hasRays = random.nextBool(chance: 0.125)
        textRingPreferedRadius = random.nextBool(chance: 0.25) ? CGFloat(Int.random(in: 2...5)) * 50.0 : nil
        rotateTextRing = (textRingPreferedRadius != nil) && random.nextBool()
        hasAsterisk = random.nextBool(chance: 0.166)
        
        let ringCount = random.nextInt(in: 3...5)
        var rings = [RingConfiguration]()
        for index in 0..<ringCount {
            rings.append(.init(index: index, isAnimated: random.nextBool()))
        }
        ringConfigs = rings
        
        hasAxisLines = random.nextBool(chance: 0.166)
        axisLineEndCount = random.nextInt(in: 1...3)
        hasTrianglePointers = random.nextBool(chance: 0.25)
        trianglePointerCount = random.nextInt(in: 1...6)
        trianglePointerLength = CGFloat(random.nextInt(in: 15...30))
        fillTrianglePointers = random.nextBool()
        hasRadarScan = random.nextBool()
        showShipRotation = random.nextBool()
    }
    
    // The following 2 functions stop decorative rings from covering up the text ring.
    func decorativeRingMinimumWidthFraction(parentSize: CGSize, ringIndex: Int) -> CGFloat {
        if let textRingPreferedRadius = self.textRingPreferedRadius {
            let decorativeRingInsideTextRing = ringIndex < self.ringConfigs.count/2
            if !decorativeRingInsideTextRing { // Stops outer rings from getting too small
                let ringMaxRadius = min(parentSize.width, parentSize.height)/2
                let textRingRadius = min(textRingPreferedRadius, ringMaxRadius)
                return (textRingRadius + textRingPadding) / ringMaxRadius
            }
        }
        return 0.1
    }
    func decorativeRingFrameLengths(parentSize: CGSize, ringIndex: Int) -> CGFloat? {
        if let textRingPreferedRadius = self.textRingPreferedRadius {
            let decorativeRingInsideTextRing = ringIndex < self.ringConfigs.count/2
            if decorativeRingInsideTextRing { // Stops inner rings from getting too big
                let ringMaxRadius = min(parentSize.width, parentSize.height)/2
                let textRingRadius = min(textRingPreferedRadius, ringMaxRadius)
                return (textRingRadius - system.defaultFontSize - textRingPadding) * 2
            }
        }
        return nil
    }
    
}

#Preview {
    NearbyShipsView(did: 0)
}
