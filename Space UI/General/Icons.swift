//
//  Icons.swift
//  Space UI
//
//  Created by Jayden Irwin on 2019-12-19.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import SwiftUI
import GameplayKit

enum CircleIcon: String, CaseIterable {
    case circle3Circles, circle6Circles, circleCapsule, circleHexagonSplit, circleHexagon, circleRingSplit, circleRing, circleSplit3, circleSplit4, circleSquare, circleTriangle
    
    static func image(vid: Int) -> Image {
        let actualIndex = Int(system.seed) + vid
        let name = Self.allCases[actualIndex % Self.allCases.count]
        return Image(decorative: name.rawValue)
    }
}

enum GeneralIcon: String, CaseIterable {
    case asterisk, hexagon, hexagonFill, hexagonSplit, line, plus, squareSplit, triangle
    
    static func image(vid: Int) -> Image {
        let actualIndex = Int(system.seed) + vid
        let name = Self.allCases[actualIndex % Self.allCases.count]
        return Image(decorative: name.rawValue)
    }
}

enum LargeIcon: String, CaseIterable {
    case art, geometric, kagawaFlag, naganoFlag, hexagons3, triforce
    
    static func image(vid: Int) -> Image {
        let actualIndex = Int(system.seed) + vid
        let name = Self.allCases[actualIndex % Self.allCases.count]
        return Image(decorative: name.rawValue)
    }
}
