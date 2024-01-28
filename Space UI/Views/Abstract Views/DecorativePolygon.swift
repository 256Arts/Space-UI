//
//  PolygonVisualizationView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-18.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct DecorativePolygon: Shape {
    
    var sides: CGFloat
    var animatableData: CGFloat {
        get { sides }
        set { sides = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        // hypotenuse
        let h = CGFloat(min(rect.size.width, rect.size.height)) / 2.0
        // center
        let c = CGPoint(x: rect.size.width / 2.0, y: rect.size.height / 2.0)
        var path = Path()
        let extra: Int = sides != floor(sides) ? 1 : 0
        var vertexes = [CGPoint]()
        for i in 0..<Int(sides) + extra {
            let angle = (CGFloat(i) * (2.0 * .pi / sides))
            // Calculate vertex
            let pt = CGPoint(x: c.x + (sin(angle) * h), y: c.y + (cos(angle) * h))
            vertexes.append(pt)
            if i == 0 {
                path.move(to: pt) // move to first vertex
            } else {
                path.addLine(to: pt) // draw line to next vertex
            }
        }
        path.closeSubpath()
        // Draw vertex-to-vertex lines
        drawVertexLines(path: &path, vertexes: vertexes, n: 0)
        return path
    }
    
    func drawVertexLines(path: inout Path, vertexes: [CGPoint], n: Int) {
        guard 2 < (vertexes.count - n) else { return }
        for i in (n+2)..<min(n + (vertexes.count-1), vertexes.count) {
            path.move(to: vertexes[n])
            path.addLine(to: vertexes[i])
        }
        drawVertexLines(path: &path, vertexes: vertexes, n: n+1)
    }
    
}

#Preview {
    DecorativePolygon(sides: 5)
}
