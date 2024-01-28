//
//  DoorView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-19.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct DoorView: View {
    
    @Binding var openFraction: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ZStack {
                    // Top left
                    Path { path in
                        path.move(to: CGPoint(x: 0.0, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: geometry.size.width/2 + geometry.size.height/2, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: geometry.size.width/2 - geometry.size.height/2, y: 0.0))
                    }
                    .stroke(lineWidth: 5)
                    .offset(x: -self.openFraction * geometry.size.width/2, y: 0.0)

                    // Bottom right
                    Path { path in
                        path.move(to: CGPoint(x: geometry.size.width, y: 0.0))
                        path.addLine(to: CGPoint(x: geometry.size.width/2 - geometry.size.height/2, y: 0.0))
                        path.addLine(to: CGPoint(x: geometry.size.width/2 + geometry.size.height/2, y: geometry.size.height))
                    }
                    .stroke(lineWidth: 5)
                    .offset(x: self.openFraction * geometry.size.width/2, y: 0.0)

                    // Bottom left
                    Path { path in
                        path.move(to: CGPoint(x: 0.0, y: 0.0))
                        path.addLine(to: CGPoint(x: geometry.size.width/2 + geometry.size.height/2, y: 0.0))
                        path.addLine(to: CGPoint(x: geometry.size.width/2 - geometry.size.height/2, y: geometry.size.height))
                    }
                    .foregroundColor(Color(color: .primary, opacity: .min))
                    .overlay(Path { path in
                        path.move(to: CGPoint(x: 0.0, y: 0.0))
                        path.addLine(to: CGPoint(x: geometry.size.width/2 + geometry.size.height/2, y: 0.0))
                        path.addLine(to: CGPoint(x: geometry.size.width/2 - geometry.size.height/2, y: geometry.size.height))
                    }.stroke(lineWidth: 5))
                    .offset(x: -self.openFraction * geometry.size.width/2, y: 0.0)

                    // Top right
                    Path { path in
                        path.move(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: geometry.size.width/2 - geometry.size.height/2, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: geometry.size.width/2 + geometry.size.height/2, y: 0.0))
                    }
                    .foregroundColor(Color(color: .primary, opacity: .min))
                    .overlay(Path { path in
                        path.move(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: geometry.size.width/2 - geometry.size.height/2, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: geometry.size.width/2 + geometry.size.height/2, y: 0.0))
                    }.stroke(lineWidth: 5))
                    .offset(x: self.openFraction * geometry.size.width/2, y: 0.0)
                }.mask(Path { path in
                    path.move(to: CGPoint(x: geometry.size.height/2, y: 0.0))
                    path.addLine(to: CGPoint(x: geometry.size.width - geometry.size.height/2, y: 0.0))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height/2))
                    path.addLine(to: CGPoint(x: geometry.size.width - geometry.size.height/2, y: geometry.size.height))
                    path.addLine(to: CGPoint(x: geometry.size.height/2, y: geometry.size.height))
                    path.addLine(to: CGPoint(x: 0.0, y: geometry.size.height/2))
                    path.addLine(to: CGPoint(x: geometry.size.height/2, y: 0.0))
                    path.closeSubpath()
                })
                
                Path { path in
                    path.move(to: CGPoint(x: geometry.size.height/2, y: 0.0))
                    path.addLine(to: CGPoint(x: geometry.size.width - geometry.size.height/2, y: 0.0))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height/2))
                    path.addLine(to: CGPoint(x: geometry.size.width - geometry.size.height/2, y: geometry.size.height))
                    path.addLine(to: CGPoint(x: geometry.size.height/2, y: geometry.size.height))
                    path.addLine(to: CGPoint(x: 0.0, y: geometry.size.height/2))
                    path.addLine(to: CGPoint(x: geometry.size.height/2, y: 0.0))
                    path.closeSubpath()
                }
                .stroke(lineWidth: 5)
            }
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
    }
}

#Preview {
    DoorView(openFraction: .constant(0.0))
}
