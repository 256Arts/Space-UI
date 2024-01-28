//
//  AutoGrid.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-12-06.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

// Input: 4 children -> Output layouts: 1x4, 2x2, 4x1
// Input: 5 children -> Output layouts: 1x5, 5x1
// Also allows triangles to layout in alternating direction: 🔺🔻🔺🔻 // TODO: .environment(\.shapeDirection, col % 2 == 0 ? .up : .down)

struct AutoGrid: Layout {
    
    struct GridCoordinate {
        let row: Int
        let column: Int
    }
    
    var spacing: CGFloat = 20
    
    /// Allows the grid to layout in a size larger than the proposal
    var ignoreMaxSize: Bool = true
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let avgSubviewSize = avgSubviewSize(subviews)
        let idealSize = proposedGridAndSize(proposal: proposal, subviews: subviews, avgSubviewSize: avgSubviewSize).size
        return ignoreMaxSize ? idealSize : minSize(idealSize, proposal: proposal)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let avgSubviewSize = avgSubviewSize(subviews)
        let proposedGridAndSize = proposedGridAndSize(proposal: proposal, subviews: subviews, avgSubviewSize: avgSubviewSize)
        
        let firstSubviewPoint = CGPoint(
            x: bounds.midX - proposedGridAndSize.size.width/2 + avgSubviewSize.width/2,
            y: bounds.midY - proposedGridAndSize.size.height/2 + avgSubviewSize.height/2)
        
        for (index, subview) in subviews.enumerated() {
            let gridIndex = gridIndex(subviewIndex: index, totalColumns: proposedGridAndSize.coord.column)
            
            let point = CGPoint(
                x: firstSubviewPoint.x + (avgSubviewSize.width + spacing) * CGFloat(gridIndex.column),
                y: firstSubviewPoint.y + (avgSubviewSize.height + spacing) * CGFloat(gridIndex.row))
            
            subview.place(at: point, anchor: .center, proposal: .unspecified)
        }
    }
    
    private func avgSubviewSize(_ subviews: Subviews) -> CGSize {
        let finiteSubviewSizes: [CGSize] = subviews.compactMap {
            let maxSize = $0.sizeThatFits(.infinity)
            if maxSize.width == .infinity || maxSize.height == .infinity {
                return nil
            } else {
                return maxSize
            }
        }
        if finiteSubviewSizes.isEmpty {
            // Default subview is square
            return CGSize(width: 96, height: 96)
        } else {
            let totalSize = finiteSubviewSizes.reduce(.zero, { CGSize(width: $0.width + $1.width, height: $0.width + $1.width) })
            return CGSize(width: totalSize.width / CGFloat(finiteSubviewSizes.count), height: totalSize.height / CGFloat(finiteSubviewSizes.count))
        }
    }
    
    private func proposedGridAndSize(proposal: ProposedViewSize, subviews: Subviews, avgSubviewSize: CGSize) -> (coord: GridCoordinate, size: CGSize) {
        var bestGrid = GridCoordinate(row: 1, column: subviews.count)
        var bestGridScore: CGFloat = .infinity
        
        for grid in gridDimensions(of: subviews.count) {
            let thisSize = CGSize(width: avgSubviewSize.width * CGFloat(grid.row), height: avgSubviewSize.height * CGFloat(grid.column))
            let thisScore = aspectRatioDifference(thisSize, proposal.aspectRatio)
            if thisScore < bestGridScore {
                bestGrid = grid
                bestGridScore = thisScore
            }
        }
        
        let width = CGFloat(bestGrid.column) * avgSubviewSize.width + CGFloat(bestGrid.column - 1) * spacing
        let height = CGFloat(bestGrid.row) * avgSubviewSize.height + CGFloat(bestGrid.row - 1) * spacing
        return (bestGrid, CGSize(width: width, height: height))
    }
    
    private func minSize(_ size: CGSize, proposal: ProposedViewSize) -> CGSize {
        let width: CGFloat = {
            if let propWidth = proposal.width {
                return min(size.width, propWidth)
            }
            return size.width
        }()
        let height: CGFloat = {
            if let propHeight = proposal.height {
                return min(size.height, propHeight)
            }
            return size.height
        }()
        return CGSize(width: width, height: height)
    }
    
    private func gridIndex(subviewIndex: Int, totalColumns: Int) -> GridCoordinate {
        GridCoordinate(row: subviewIndex / totalColumns, column: subviewIndex % totalColumns)
    }
    
    private func gridDimensions(of n: Int) -> [GridCoordinate] {
        precondition(n > 0, "n must be positive")
        let sqrtn = Int(Double(n).squareRoot())
        var factors: [GridCoordinate] = []
        for i in 1...sqrtn {
            if n % i == 0 {
                factors.append(GridCoordinate(row: i, column: n/i))
                if i != n/i {
                    factors.append(GridCoordinate(row: n/i, column: i))
                }
            }
        }
        return factors
    }
    
}

#Preview {
    AutoGrid(spacing: 8) {
        Text("Hello")
        Text("World")
    }
}
