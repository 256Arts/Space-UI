//
//  RadarScanView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-27.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI
import GameplayKit

struct RadarScanView: View {
    
    enum Style {
        case single, double, flatColor
    }
    
    let scanStartAngleDegrees = Double.random(in: 0.0...360.0)
    let style: Style
    let halftoneFilter: Bool
    var gradient: Gradient {
        switch style {
        case .single:
            return Gradient(stops: [
                .init(color: Color.clear, location: 0.75),
                .init(color: Color(color: .primary, opacity: .high), location: 1)
            ])
        case .double:
            return Gradient(stops: [
                .init(color: Color.clear, location: 0.3),
                .init(color: Color(color: .primary, opacity: .high), location: 0.5),
                .init(color: Color.clear, location: 0.5001),
                .init(color: Color.clear, location: 0.8),
                .init(color: Color(color: .primary, opacity: .high), location: 1)
            ])
        default:
            return Gradient(stops: [
                .init(color: Color.clear, location: 0.7999),
                .init(color: Color(color: .primary, opacity: .high), location: 0.8),
                .init(color: Color(color: .primary, opacity: .high), location: 1)
            ])
        }
    }
    
    @State var rotateScan = false
    
    var body: some View {
        Circle()
            .fill(AngularGradient(gradient: gradient, center: UnitPoint.center, angle: Angle(degrees: self.rotateScan ? scanStartAngleDegrees : scanStartAngleDegrees - 360)))
            .layerEffect(
                Shader(function: ShaderLibrary[dynamicMember: "halftone"], arguments: [ .float(10) ]),
                maxSampleOffset: CGSize(width: 5, height: 5),
                isEnabled: halftoneFilter)
            .task {
                withAnimation(Animation.linear(duration: TimeInterval.random(in: 6...10)).repeatForever(autoreverses: false), {
                    self.rotateScan = true
                })
            }
    }
    
    init(did: Int) {
        style = {
            switch did % 10 {
            case 0:
                return .double
            case 1, 2:
                return .flatColor
            default:
                return .single
            }
        }()
        halftoneFilter = (did % 2 == 0)
    }
    
}

#Preview {
    RadarScanView(did: 0)
}
