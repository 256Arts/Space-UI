//
//  LockScreenPage.swift
//  Space UI
//
//  Created by Jayden Irwin on 2019-10-04.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import SwiftUI
import GameplayKit

struct LockScreenPage: View {
    
    enum BrandNamePosition {
        case topCorner, centerRing
    }
    
    let random: GKRandom = {
        let source = GKMersenneTwisterRandomSource(seed: system.seed)
        return GKRandomDistribution(randomSource: source, lowestValue: 0, highestValue: Int.max)
    }()
    let hasRingViews: Bool
    let hasTopBottomRings: Bool
    let hasCircularSegmentedView: Bool
    let brandNamePosition: BrandNamePosition
    let shipName = "S-Wing"
    let shipManufacturer = "Space Corp."
    
    @Environment(\.safeCornerOffsets) private var safeCornerOffsets
    
    @State var topBottomRingsAngle = Angle.zero
    @State var tutorialIsShown = !UserDefaults.standard.bool(forKey: UserDefaults.Key.tutorialShown)
    
    var body: some View {
        ZStack {
            if hasRingViews {
                DecorativeRingView(animateSize: true, opacity: .low)
                DecorativeRingView(animateSize: true, opacity: .low)
            }
            if hasTopBottomRings {
                GeometryReader { geometry in
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 10.0, lineCap: .round, dash: [0.001, 28.0]))
                        .foregroundColor(Color(color: .primary, opacity: .medium))
                        .frame(height: geometry.size.width)
                        .rotationEffect(topBottomRingsAngle)
                        .position(x: geometry.size.width/2, y: -geometry.size.height * 0.4)
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 10.0, lineCap: .round, dash: [0.001, 28.0]))
                        .foregroundColor(Color(color: .primary, opacity: .medium))
                        .frame(height: geometry.size.width)
                        .rotationEffect(topBottomRingsAngle)
                        .position(x: geometry.size.width/2, y: geometry.size.height * 1.4)
                }
            }
            VStack {
                HStack {
                    if brandNamePosition == .topCorner {
                        TextPair(did: 0, label: shipManufacturer, value: shipName, largerFontSize: 28)
                            .multilineTextAlignment(.leading)
                            .offset(safeCornerOffsets.topLeading)
                    }
                    Spacer()
                }
                Spacer()
                HStack {
                    ForEach(0..<self.random.nextInt(in: 3...5)) { index in
                        CircleIcon.image(vid: index)
                            .foregroundColor(Color(color: .primary, opacity: .high))
                    }
                }
            }
            AutoStack(spacing: 16) {
                NavigationButton(to: .powerManagement) {
                    Text("Ship")
                }
                NavigationButton(to: .ticTacToe) {
                    Text("Computer")
                }
            }
            .background {
                if brandNamePosition != .topCorner {
                    ZStack {
                        CircularText(string: shipName, radius: 150, onTopEdge: true)
                            .foregroundColor(Color(color: .primary, opacity: .max))
                        CircularText(string: shipManufacturer, radius: 150, onTopEdge: false)
                            .foregroundColor(Color(color: .primary, opacity: .medium))
                    }
                }
            }
        }
        .widgetCorners(did: 27, topLeading: false, topTrailing: true, bottomLeading: true, bottomTrailing: true)
        .onAppear {
            withAnimation(Animation.linear(duration: 100.0).repeatForever(autoreverses: false)) {
                self.topBottomRingsAngle = Angle.degrees(360)
            }
        }
        .sheet(isPresented: self.$tutorialIsShown, content: {
            TutorialView()
        })
    }
    
    init() {
        hasRingViews = random.nextBool(chance: 0.666)
        hasTopBottomRings = random.nextBool()
        hasCircularSegmentedView = random.nextBool()
        brandNamePosition = random.nextBool() ? .topCorner : .centerRing
    }
}

struct LockScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LockScreenPage()
    }
}
