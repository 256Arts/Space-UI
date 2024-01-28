//
//  DecorativeRingView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-27.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct DecorativeRingView: View {
    
    static func generateWidthMultiplier(minimumWidthFraction: CGFloat) -> CGFloat {
        let widthSteps: CGFloat = 20
        let minimumStep = Int(ceil(min(1, minimumWidthFraction) * widthSteps))
        return CGFloat(Int.random(in: minimumStep...Int(widthSteps))) / widthSteps
    }
    
    let lineWidth: CGFloat
    let opacity: Opacity
    let dash: [CGFloat]
    let animateSize: Bool
    let minimumWidthFraction: CGFloat
    
    @State var angle: Double = 0.0
    @State var widthMultiplier: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            Circle()
                .stroke(Color(color: .primary, opacity: self.opacity), style: StrokeStyle(lineWidth: self.lineWidth, lineCap: system.lineCap, dash: self.dash))
                .frame(width: self.widthMultiplier * min(geometry.size.width, geometry.size.height))
                .rotationEffect(Angle(degrees: self.angle))
                .task {
                    if !self.dash.isEmpty {
                        withAnimation(Animation.linear(duration: 9999).repeatForever(autoreverses: false)) {
                            self.angle += 49999 * Double.random(in: -1...1)
                        }
                    }
                    
                    if self.animateSize {
                        let animationDuration = TimeInterval.random(in: 2.5...5.0)
                        Timer.scheduledTimer(withTimeInterval: TimeInterval.random(in: animationDuration...animationDuration*2), repeats: true, block: { _ in
                            withAnimation(Animation.easeOut(duration: animationDuration), {
                                self.widthMultiplier = DecorativeRingView.generateWidthMultiplier(minimumWidthFraction: minimumWidthFraction)
                            })
                        })
                    }
                }
                .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
    }
    
    init(animateSize: Bool, opacity: Opacity? = nil, minimumWidthFraction: CGFloat = 0.1) {
        let lineWidthMultiplier = Int.random(in: 1...3)
        let lineWidth = CGFloat(lineWidthMultiplier)*2.0
        self.lineWidth = lineWidth
        if let b = opacity {
            self.opacity = b
        } else {
            switch lineWidthMultiplier {
            case 1:
                self.opacity = .max
            case 2:
                self.opacity = .high
            default:
                self.opacity = .medium
            }
        }
        self.dash = system.lineDash(lineWidth: lineWidth)
        self.animateSize = animateSize
        self.minimumWidthFraction = minimumWidthFraction
        self._widthMultiplier = State(initialValue: Self.generateWidthMultiplier(minimumWidthFraction: minimumWidthFraction))
    }
    
}

#Preview {
    DecorativeRingView(animateSize: true)
}
