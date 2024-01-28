//
//  DecorativeStatusView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-30.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI
import GameplayKit

struct DecorativeStatusView: View {
    
    let binaryBase: Int
    
    @ObservedObject var data: ShipData.StatusState
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 10) {
                switch geometry.size.width {
                case ..<88:
                    EmptyView()
                case ..<100:
                    BinaryView(value: self.data.binary1/4, maxValue: 7)
                case ..<200:
                    BinaryView(value: self.data.binary1/2, maxValue: 15)
                default:
                    BinaryView(value: self.data.binary1, maxValue: 31)
                }
                if 250 < geometry.size.width {
                    Image(self.data.circleIconName1)
                        .resizable()
                        .foregroundColor(Color(color: .primary, opacity: .high))
                        .frame(width: 26, height: 26, alignment: .center)
                }
                if 275 < geometry.size.width {
                    Image(self.data.circleIconName2)
                        .resizable()
                        .foregroundColor(Color(color: .primary, opacity: .high))
                        .frame(width: 26, height: 26, alignment: .center)
                }
                if 300 < geometry.size.width {
                    Image(self.data.circleIconName3)
                        .resizable()
                        .foregroundColor(Color(color: .primary, opacity: .high))
                        .frame(width: 26, height: 26, alignment: .center)
                }
                if 460 < geometry.size.width {
                    BinaryView(value: self.data.binary2, maxValue: 31)
                }
            }
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
    }
    
    init(data: ShipData.StatusState) {
        let random: GKRandom = {
            let source = GKMersenneTwisterRandomSource(seed: system.seed)
            return GKRandomDistribution(randomSource: source, lowestValue: 0, highestValue: Int.max)
        }()
        self.binaryBase = random.nextBool(chance: 0.22) ? 3 : 2
        self.data = data
    }
    
}

#Preview {
    DecorativeStatusView(data: .init(binary1: 5, circleIconName1: "a", circleIconName2: "b", circleIconName3: "c", binary2: 5))
}
