//
//  CircularStack.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2022-07-28.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct CircularStack: Layout {
    
    private static func angleStep(startAngle: Angle, endAngle: Angle, stepCount: Int) -> Angle {
        var denominator = Double(stepCount)
        let diffFrom2PI = abs(abs((endAngle - startAngle).radians) - .pi*2)
        if 0.01 < diffFrom2PI {
            denominator -= 1.0
        }
        return Angle(radians: (1.0 / denominator) * (endAngle - startAngle).radians)
    }
    
    /// Other views can use this func to rotate the subviews inside a `CircularStack`
    static func subviewRotationAngles(startAngle: Angle = .degrees(0), endAngle: Angle = .degrees(360), stepCount: Int) -> [Angle] {
        let angleStep = Self.angleStep(startAngle: startAngle, endAngle: endAngle, stepCount: stepCount)
        var rotationAngles: [Angle] = []
        for index in 0..<stepCount {
            let offsetAngle = startAngle + (angleStep * Double(index))
            rotationAngles.append(offsetAngle)
        }
        return rotationAngles
    }
    
    var startAngle: Angle = .degrees(0)
    var endAngle: Angle = .degrees(360)
    
    /// Returns a size that the layout container needs to arrange its subviews.
    ///
    /// This implementation uses whatever space the container view proposes.
    /// If the container asks for this layout's ideal size, it offers the
    /// the `unspecified` proposal, which contains `nil` in each dimension.
    /// To convert that to a concrete size, this method uses the proposal's
    /// `replacingUnspecifiedDimensions(_:)` method.
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        // Take whatever space is offered.
        let nonInfiniteProposal = proposal.replacingUnspecifiedDimensions(by: CGSize(width: 300, height: 300))
        let diameter = min(nonInfiniteProposal.width, nonInfiniteProposal.height)
        return CGSize(width: diameter, height: diameter)
    }

    /// Places the stack's subviews
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let nonInfiniteSubviewSizes: [CGSize] = subviews.compactMap {
            let size = $0.sizeThatFits(.infinity)
            if size.width == .infinity || size.height == .infinity {
                return nil
            } else {
                return size
            }
        }
        let avgSubviewSize: CGFloat = {
            if nonInfiniteSubviewSizes.isEmpty {
                let maxSubviewSize = min(bounds.size.width, bounds.size.height) / 2
                return maxSubviewSize
            } else {
                return nonInfiniteSubviewSizes.reduce(0, { $0 + ($1.width + $1.height) / 2 }) / CGFloat(nonInfiniteSubviewSizes.count)
            }
        }()
        
        // Place the views within the bounds.
        let radius = (min(bounds.size.width, bounds.size.height) - avgSubviewSize) / 2.0

        // The angle between views depends on the number of views.
        let angleStep = Self.angleStep(startAngle: startAngle, endAngle: endAngle, stepCount: subviews.count)

        // Read the ranks from each view, and find the appropriate offset.
        // This only has an effect for the specific case of three views with
        // nonuniform rank values. Otherwise, the offset is zero, and it has
        // no effect on the placement.
        var angle = startAngle

        for subview in subviews {
            // Find a vector with an appropriate size and rotation.
            var point = CGPoint(x: 0, y: -radius)
                .applying(CGAffineTransform(rotationAngle: angle.radians))

            // Shift the vector to the middle of the region.
            point.x += bounds.midX
            point.y += bounds.midY

            // Place the subview.
            subview.place(at: point, anchor: .center, proposal: ProposedViewSize(width: avgSubviewSize, height: avgSubviewSize))
            
            angle += angleStep
        }
    }
    
}

#Preview {
    CircularStack {
        Text("1")
        Text("2")
        Text("3")
        Text("4")
        Text("5")
    }
}
