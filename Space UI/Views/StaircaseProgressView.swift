//
//  StaircaseProgressView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-19.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct StaircaseProgressView: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.addLine(to: CGPoint(x: geometry.size.width, y: 0.0))
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.95, y: geometry.size.height))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.95, y: geometry.size.height * 0.95))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.9, y: geometry.size.height * 0.95))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.9, y: geometry.size.height * 0.9))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.85, y: geometry.size.height * 0.9))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.85, y: geometry.size.height * 0.85))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.8, y: geometry.size.height * 0.85))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.8, y: geometry.size.height * 0.8))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.75, y: geometry.size.height * 0.8))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.75, y: geometry.size.height * 0.85))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.7, y: geometry.size.height * 0.85))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.7, y: geometry.size.height * 0.8))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.65, y: geometry.size.height * 0.8))
                path.addLine(to: CGPoint(x: geometry.size.width * 0.65, y: geometry.size.height * 0.75))
                path.addLine(to: CGPoint(x: 0.0, y: geometry.size.height * 0.75))
                path.addLine(to: .zero)
                path.closeSubpath()
            }
            .foregroundColor(Color(color: .primary, opacity: .max))
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
    }
}

#Preview {
    StaircaseProgressView()
}
