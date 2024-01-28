//
//  CircularProgressView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-01-01.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI
import GameplayKit

struct CircularProgressView<Inner: View>: View {
    
    enum Design {
        case continuous, dashed, asteresk
    }
    
    let design: Design
    let inner: Inner
    
    @Environment(\.elementSize) private var elementSize
    
    @Binding var value: Double
    @State var lineWidth: CGFloat?
    
    var tickCount: Int {
        switch elementSize {
        case .large:
            return 96
        case .regular:
            return 64
        case .small:
            return 48
        case .mini:
            return 32
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if design == .asteresk {
                    AsteriskShape(ticks: tickCount, innerRadiusFraction: 0.75)
                        .stroke(Color(color: .primary, brightness: .min), style: strokeStyle(size: geometry.size))
                    AsteriskShape(ticks: tickCount, innerRadiusFraction: 0.75)
                        .trim(from: 0, to: self.value)
                        .stroke(Color(color: .primary, brightness: .max), style: strokeStyle(size: geometry.size))
                        .rotationEffect(Angle(degrees: -90))
                } else {
                    Circle()
                        .stroke(Color(color: .primary, brightness: .min), style: strokeStyle(size: geometry.size))
                        .rotationEffect(Angle(degrees: -90)) // Needed to match the dashes
                    Circle()
                        .trim(from: 0, to: self.value)
                        .stroke(Color(color: .primary, brightness: .max), style: strokeStyle(size: geometry.size))
                        .rotationEffect(Angle(degrees: -90))
                }
                self.inner
                    .multilineTextAlignment(.center)
                    .padding(actualLineWidth(size: geometry.size) / 2)
            }
            .padding(actualLineWidth(size: geometry.size) / 2)
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
        .animation(Animation.easeOut(duration: 0.5), value: value)
        .aspectRatio(1, contentMode: .fit)
    }
    
    init(did: Int, value: Binding<Double>, lineWidth: CGFloat? = nil, @ViewBuilder content: () -> Inner = { EmptyView() }) {
        let random: GKRandom = {
            let source = GKMersenneTwisterRandomSource(seed: UInt64(did))
            return GKRandomDistribution(randomSource: source, lowestValue: 0, highestValue: Int.max)
        }()
        let designValues: [WeightedDesignElement<Design>] = [
            .init(baseWeight: 1, design: .init(simplicity: 1), element: .continuous),
            .init(baseWeight: 1, design: .init(simplicity: 0.3), element: .dashed),
            .init(baseWeight: 2, design: .init(simplicity: 0.3), element: .asteresk)
        ]
        
        self.design = random.nextWeightedElement(in: designValues, with: system.design)!
        self.inner = content()
        self._value = value
        self._lineWidth = State<CGFloat?>(initialValue: lineWidth)
    }
    
    func strokeStyle(size: CGSize) -> StrokeStyle {
        let lineWidth = actualLineWidth(size: size)
        switch design {
        case .dashed:
            return StrokeStyle(lineWidth: lineWidth, dash: [lineWidth/3, lineWidth/3])
        case .continuous:
            return StrokeStyle(lineWidth: lineWidth, lineCap: system.lineCap)
        case .asteresk:
            return system.strokeStyle(.thin)
        }
    }
    
    func actualLineWidth(size: CGSize) -> CGFloat {
        lineWidth ?? size.width/8
    }
}

struct CircularProgressView_Previews: PreviewProvider {
    
    @State static var value: Double = 0.0
    
    static var previews: some View {
        CircularProgressView(did: 0, value: $value)
            .onAppear(perform: {
                self.value = 0.66
            })
    }
}
