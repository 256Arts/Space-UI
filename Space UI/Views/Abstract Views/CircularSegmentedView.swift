//
//  CircularSegmentedView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-01-01.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

// Looks like a pie graph.

struct AngularSegment: InsettableShape {
    
    let angle: Angle
    let topIsCurved: Bool
    let cornerRadius: CGFloat
    
    var insetAmount: CGFloat = 0.0 // NOT implemented yet
    
    func path(in rect: CGRect) -> Path {
        // Offset from which to start rounding corners
        let offset = cornerRadius * CGFloat(abs(tan(angle.radians)))
        let radius = min(insetRect(rect).width, insetRect(rect).height)
        
        // Bottom point(s)
        let circleCenter = CGPoint(x: insetRect(rect).midX, y: insetRect(rect).maxY)
        let circleCenterRoundedCornerLeftPoint: CGPoint = {
            guard !cornerRadius.isZero else { return .zero }
            let roundedX = circleCenter.x - offset * CGFloat(sin(angle.radians/2.0))
            let roundedY = circleCenter.y - offset * CGFloat(cos(angle.radians/2.0))
            return CGPoint(x: roundedX, y: roundedY)
        }()
        let circleCenterRoundedCornerRightPoint: CGPoint = {
            guard !cornerRadius.isZero else { return .zero }
            let roundedX = circleCenter.x + offset * CGFloat(sin(angle.radians/2.0))
            let roundedY = circleCenter.y - offset * CGFloat(cos(angle.radians/2.0))
            return CGPoint(x: roundedX, y: roundedY)
        }()
        
        let startAngle = .pi*3/2 - angle.radians/2.0
        let hypotX = radius * CGFloat(sin(angle.radians/2.0))
        let hypotY = radius * CGFloat(cos(angle.radians/2.0))
        
        // Left point(s)
        let leftPoint = CGPoint(x: circleCenter.x - hypotX, y: circleCenter.y - hypotY)
        let leftRoundedCornerLowerPoint: CGPoint = {
            guard !cornerRadius.isZero else { return .zero }
            let roundedX = leftPoint.x + offset * CGFloat(sin(angle.radians/2.0))
            let roundedY = leftPoint.y + offset * CGFloat(cos(angle.radians/2.0))
            return CGPoint(x: roundedX, y: roundedY)
        }()
        let leftRoundedCornerRightPoint: CGPoint = {
            guard !cornerRadius.isZero else { return .zero }
            let roundedX = leftPoint.x + offset
            return CGPoint(x: roundedX, y: leftPoint.y)
        }()
        
        // Right point(s)
        let rightPoint = CGPoint(x: circleCenter.x + hypotX, y: circleCenter.y - hypotY)
        let rightRoundedCornerLowerPoint: CGPoint = {
            guard !cornerRadius.isZero else { return .zero }
            let roundedX = rightPoint.x - offset * CGFloat(sin(angle.radians/2.0))
            let roundedY = rightPoint.y + offset * CGFloat(cos(angle.radians/2.0))
            return CGPoint(x: roundedX, y: roundedY)
        }()
        let rightRoundedCornerLeftPoint: CGPoint = {
            guard !cornerRadius.isZero else { return .zero }
            let roundedX = rightPoint.x - offset
            return CGPoint(x: roundedX, y: rightPoint.y)
        }()
        
        return Path { path in
            if cornerRadius.isZero {
                path.move(to: circleCenter)
            } else {
                path.move(to: circleCenterRoundedCornerLeftPoint)
            }
            if cornerRadius.isZero || topIsCurved {
                path.addLine(to: leftPoint)
            } else {
                path.addLine(to: leftRoundedCornerLowerPoint)
                path.addArc(tangent1End: leftPoint, tangent2End: leftRoundedCornerRightPoint, radius: cornerRadius)
            }
            if topIsCurved {
                path.addRelativeArc(center: circleCenter, radius: radius, startAngle: Angle(radians: startAngle), delta: angle)
            } else if cornerRadius.isZero {
                path.addLine(to: rightPoint)
            } else {
                path.addLine(to: rightRoundedCornerLeftPoint)
            }
            if cornerRadius.isZero {
                path.addLine(to: circleCenter)
            } else {
                if !topIsCurved {
                    path.addArc(tangent1End: rightPoint, tangent2End: rightRoundedCornerLowerPoint, radius: cornerRadius)
                }
                path.addLine(to: circleCenterRoundedCornerRightPoint)
                path.addArc(tangent1End: circleCenter, tangent2End: circleCenterRoundedCornerLeftPoint, radius: cornerRadius)
            }
            path.closeSubpath()
        }
    }
    
    func inset(by amount: CGFloat) -> some InsettableShape {
        var arc = self
        arc.insetAmount += amount
        return arc
    }
    func insetRect(_ rect: CGRect) -> CGRect {
        rect.insetBy(dx: insetAmount, dy: insetAmount)
    }
}

struct CircularSegmentedView: View {
    
    struct SegmentModel: Identifiable {
        let id: Int
        var state: Bool = .random()
        var fillAndBorder: FillAndBorder {
            state ? FillAndBorder(fill: .clear, border: Color(color: .primary, opacity: .max)) : FillAndBorder(fill: Color(color: .primary, opacity: .max))
        }
    }
    
    let spacing: CGFloat = 12.0
    let curvedOuterEdge: Bool
    
    @EnvironmentObject private var systemStyles: SystemStyles
    
    @State var values: [SegmentModel]
    
    var body: some View {
        GeometryReader { geometry in
            CircularStack {
                ForEach(values) { value in
                    AngularSegment(angle: segmentAngle(size: geometry.size), topIsCurved: curvedOuterEdge, cornerRadius: segmentCornerRadius(size: geometry.size))
                        .foregroundColor(value.fillAndBorder.fill)
                        .overlay {
                            if value.fillAndBorder.border != nil {
                                AngularSegment(angle: segmentAngle(size: geometry.size), topIsCurved: curvedOuterEdge, cornerRadius: segmentCornerRadius(size: geometry.size))
                                    .strokeBorder(value.fillAndBorder.border!, style: systemStyles.strokeStyle(.thin))
                            }
                        }
                        .offset(x: 0.0, y: -spacing / 2.0)
                        .rotationEffect(CircularStack.subviewRotationAngles(stepCount: values.count)[value.id])
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(spacing / 2)
    }
    
    init() {
        self.curvedOuterEdge = system.circularSegmentedViewCurvedOuterEdge
        self._values = State(initialValue: [SegmentModel(id: 0), SegmentModel(id: 1), SegmentModel(id: 2), SegmentModel(id: 3), SegmentModel(id: 4), SegmentModel(id: 5)])
    }
    
    func segmentAngle(size: CGSize) -> Angle {
        let radius = min(size.width, size.height) / 2
        let spacingAngle = atan(spacing / radius)
        return Angle(degrees: (360 / Double(values.count)) - spacingAngle * .pi)
    }
    func segmentCornerRadius(size: CGSize) -> CGFloat {
        let diameter = min(size.width, size.height)
        return (systemStyles.cornerStyle == .sharp) ? 0.0 : systemStyles.cornerRadius(forLength: diameter/4.0, cornerStyle: .rounded)
    }
    
}

#Preview {
    CircularSegmentedView()
}
