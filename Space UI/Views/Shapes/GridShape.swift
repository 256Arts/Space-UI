//
//  GridShape.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-01-14.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct GridShape: Shape {
    
    var rows: Int
    var columns: Int
    var hasInsideBorders = true
    var hasOutsideBorders = true
    var hasVertexDetails = false
    var outsideCornerRadius: CGFloat = 0.0
    
    func path(in rect: CGRect) -> Path {
        let cellSize = CGSize(width: rect.width/CGFloat(rows), height: rect.height/CGFloat(columns))
        
        return Path { path in
            if hasInsideBorders {
                for row in 1..<rows {
                    let y = rect.minY + (CGFloat(row) * cellSize.height)
                    path.move(to: CGPoint(x: rect.minX, y: y))
                    path.addLine(to: CGPoint(x: rect.maxX, y: y))
                }
                for column in 1..<columns {
                    let x = rect.minX + (CGFloat(column) * cellSize.width)
                    path.move(to: CGPoint(x: x , y: rect.minY))
                    path.addLine(to: CGPoint(x: x, y: rect.maxY))
                }
            }
            if hasOutsideBorders {
                path.addRoundedRect(in: rect, cornerSize: CGSize(width: outsideCornerRadius, height: outsideCornerRadius))
            }
        }
//        if hasVertexDetails {
//            var point = CGPoint(x: startX, y: -(CGFloat(columns) * cellSize.height)/2)
//            for _ in 0...columns {
//                for _ in 0...rows {
//                    let node = SKShapeNode(SystemStyles.shared.shape, height: 4)
//                    node.position = point
//                    addChild(node)
//                    point.x += cellSize.width
//                }
//                point.x = startX
//                point.y += cellSize.height
//            }
//        }
    }
}

#Preview {
    GridShape(rows: 3, columns: 3)
}
