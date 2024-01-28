//
//  Spirograph.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-21.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct Spirograph: Shape {
    
    @State var innerRadius: CGFloat
    @State var outerRadius: CGFloat
    
    var distance: CGFloat
    var animatableData: CGFloat {
        get { distance }
        set { distance = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let divisor = gcd(innerRadius, outerRadius)
        let difference = innerRadius - outerRadius
        let endPoint = ceil(2 * CGFloat.pi * outerRadius / divisor)
        let offsetX = rect.width/2
        let offsetY = rect.height/2
        let diffOverOuterRadius = difference / outerRadius

        return Path { path in
            for theta in stride(from: 0, through: endPoint, by: 0.2) {
                let x = difference * cos(theta) + distance * cos(diffOverOuterRadius * theta)
                let y = difference * sin(theta) - distance * sin(diffOverOuterRadius * theta)
                let point = CGPoint(x: x + offsetX, y: y + offsetY)

                if theta.isZero {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
        }
    }
    
    func gcd(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
        var a = a
        var b = b
        while !b.isZero {
            let temp = b
            b = a.truncatingRemainder(dividingBy: b)
            a = temp
        }
        return a
    }
}

#Preview {
    Spirograph(innerRadius: 56, outerRadius: 101, distance: 25)
        .stroke()
}
