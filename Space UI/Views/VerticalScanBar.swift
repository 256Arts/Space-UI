//
//  VerticalScanBar.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-03-23.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

// Example of what this looks like:
// >------<

struct VerticalScanBar: View {
    
    @State var scanBarOffset = CGFloat.random(in: -0.5...0.5)
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: -4) {
                Triangle()
                    .environment(\.shapeDirection, .down)
                    .foregroundColor(Color(color: .primary, opacity: .max))
                    .frame(width: 30, height: 30)
                Rectangle()
                    .foregroundColor(Color(color: .primary, opacity: .max))
                    .frame(width: 5)
                Triangle()
                    .environment(\.shapeDirection, .up)
                    .foregroundColor(Color(color: .primary, opacity: .max))
                    .frame(width: 30, height: 30)
            }
            .offset(x: self.scanBarOffset * geometry.size.width, y: 0)
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
        .task {
            Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { (_) in
                withAnimation(Animation.easeInOut(duration: 3)) {
                    self.scanBarOffset = CGFloat.random(in: -0.5...0.5)
                }
            }
        }
    }
}

#Preview {
    VerticalScanBar()
}
