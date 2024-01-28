//
//  Compass.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-03-19.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct Compass: View {
    
    @EnvironmentObject private var system: SystemStyles
    
    @StateObject private var anglePublisher = DoubleGenerator(range: -20...20)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Outer Circles
                Circle()
                    .stroke(Color(color: .primary, opacity: .high), style: system.strokeStyle(.thin))
                Circle()
                    .stroke(Color(color: .primary, opacity: .max), style: StrokeStyle(lineWidth: 20, dash: [2, 9], dashPhase: 1))
                Circle()
                    .stroke(Color(color: .primary, opacity: .max), style: StrokeStyle(lineWidth: 10, dash: [1, 10], dashPhase: 6))
                
                // Crosshairs
                Rectangle()
                    .foregroundColor(Color(color: .primary, opacity: .max))
                    .frame(width: system.thinLineWidth)
                Rectangle()
                    .foregroundColor(Color(color: .primary, opacity: .max))
                    .frame(height: system.thinLineWidth)
                
                // Horizontal Tick Lines
                HStack(spacing: 20) {
                    Rectangle()
                        .foregroundColor(Color(color: .primary, opacity: .max))
                        .frame(width: 1, height: 12)
                    Rectangle()
                        .foregroundColor(Color(color: .primary, opacity: .max))
                        .frame(width: 1, height: 20)
                    Rectangle()
                        .foregroundColor(Color(color: .primary, opacity: .max))
                        .frame(width: 1, height: 12)
                    Rectangle()
                        .foregroundColor(Color(color: .primary, opacity: .max))
                        .frame(width: 1, height: 12)
                    Rectangle()
                        .foregroundColor(Color(color: .primary, opacity: .max))
                        .frame(width: 1, height: 20)
                    Rectangle()
                        .foregroundColor(Color(color: .primary, opacity: .max))
                        .frame(width: 1, height: 12)
                }
                
                // Inner Circles
                ZStack {
                    PieSlice(deltaAngle: .pi, hasRadialLines: false)
                        .foregroundColor(Color(color: .primary, opacity: .max))
                        .frame(width: geometry.size.width * 0.5, height: geometry.size.height * 0.5)
                        .rotationEffect(Angle(radians: .pi))
                        .offset(x: 0, y: geometry.size.height * 0.25)
                    Circle()
                        .stroke(Color(color: .primary, opacity: .max), lineWidth: 1)
                        .frame(width: geometry.size.width * 0.25, height: geometry.size.height * 0.25)
                    Circle()
                        .stroke(Color(color: .secondary, opacity: .max), lineWidth: system.thinLineWidth)
                        .frame(width: geometry.size.width * 0.4, height: geometry.size.height * 0.4)
                    Circle()
                        .stroke(Color(color: .primary, opacity: .max), lineWidth: 1)
                        .frame(width: geometry.size.width * 0.5, height: geometry.size.height * 0.5)
                    Triangle()
                        .environment(\.shapeDirection, .up)
                        .foregroundColor(Color(color: .primary, opacity: .max))
                        .frame(width: 20, height: 20)
                        .offset(x: 0, y: -geometry.size.height * 0.65)
                }
            }
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
        .rotationEffect(.degrees(anglePublisher.value))
        .animation(.spring(response: 1, dampingFraction: 0.5, blendDuration: 0), value: anglePublisher.value)
    }
}

#Preview {
    Compass()
}
