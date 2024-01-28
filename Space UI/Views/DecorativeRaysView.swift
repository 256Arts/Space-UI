//
//  DecorativeRaysView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-01-01.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

// Example of what this looks like:
// *

struct DecorativeRaysView: View {
    
    let cycleCount: Int
    let linePortion = 1.0 / CGFloat(Int.random(in: 2...4))
    
    var dash: [CGFloat] {
        let cycleLength = (.pi*2) / CGFloat(cycleCount)
        let lineLength = cycleLength * linePortion
        let noLineLength = cycleLength - lineLength
        return [lineLength, noLineLength]
    }
    var dashPhase: CGFloat {
        let cycleLength = (.pi*2) / CGFloat(cycleCount)
        let lineDeltaAngle = linePortion * cycleLength
        return (.pi + lineDeltaAngle) / 2
    }
    
    var body: some View {
        GeometryReader { geometry in
            Circle()
                .stroke(Color(color: .primary, opacity: .low), style: StrokeStyle(lineWidth: min(geometry.size.width, geometry.size.height)/2, dash: self.dash.map({ $0 * min(geometry.size.width, geometry.size.height)/4 }), dashPhase: min(geometry.size.width, geometry.size.height)/4 * self.dashPhase))
                .frame(width: min(geometry.size.width, geometry.size.height)/2, height: min(geometry.size.width, geometry.size.height)/2)
                .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
    }
    
    init(cycleCount: Int? = nil) {
        self.cycleCount = cycleCount ?? Int.random(in: 1...4)
    }
    
}

#Preview {
    DecorativeRaysView()
}
