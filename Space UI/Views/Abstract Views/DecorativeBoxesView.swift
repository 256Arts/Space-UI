//
//  DecorativeBoxesView.swift
//  Space UI
//
//  Created by Jayden Irwin on 2020-01-01.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import SwiftUI
import GameplayKit

// Example of what this looks like:
// [][][]
// []  []
// []

struct DecorativeBoxesView: View {
    
    let values: [Int]
    
    @Environment(\.elementSize) private var elementSize
    var columns: Int {
        switch elementSize {
        case .mini, .small:
            return Int.random(in: 1...2)
        case .regular:
            return Int.random(in: 3...4)
        case .large:
            return Int.random(in: 5...6)
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 3) {
            ForEach(0..<columns, id: \.self) { x in
                VStack(spacing: 3) {
                    ForEach(0..<self.values[x], id: \.self) { _ in
                        RoundedRectangle(cornerRadius: system.cornerRadius(forLength: 8))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
    }
    
    init() {
        values = (0..<6).map { _ in
            Int.random(in: 1...3)
        }
    }
    
}

struct DecorativeBoxesView_Previews: PreviewProvider {
    static var previews: some View {
        DecorativeBoxesView()
    }
}
