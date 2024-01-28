//
//  AsteriskShape.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-22.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct AsteriskShape: Shape {
    
    let ticks: Int
    let innerRadiusFraction: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let pi2 = CGFloat.pi * 2.0
        let radius = min(rect.width, rect.height)/2
        
        return Path { path in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            for tickNumber in 0..<ticks {
                let angle = (pi2 * (CGFloat(ticks) / 2 + CGFloat(tickNumber)) / CGFloat(ticks)) - .pi/2
                let xOffset = radius * cos(angle)
                let yOffset = radius * sin(angle)
                path.move(to: CGPoint(x: rect.midX + xOffset * innerRadiusFraction, y: rect.midY + yOffset * innerRadiusFraction))
                path.addLine(to: CGPoint(x: rect.midX + xOffset, y: rect.midY + yOffset))
            }
        }
    }
    
    init(ticks: Int, innerRadiusFraction: CGFloat = 0.0) {
        self.ticks = ticks
        self.innerRadiusFraction = innerRadiusFraction
    }
}

#Preview {
    AsteriskShape(ticks: 30, innerRadiusFraction: 0)
}
