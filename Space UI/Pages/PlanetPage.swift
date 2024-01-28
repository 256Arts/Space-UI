//
//  PlanetPage.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-15.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct PlanetPage: View {
    
    @IDGen private var idGen
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.safeCornerOffsets) private var safeCornerOffsets
    
    var body: some View {
        VStack {
            ZStack {
                if hSizeClass == .regular {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 16) {
                            RandomCircularWidget(did: idGen(1), vid: idGen(2))
                                .offset(safeCornerOffsets.topLeading)
                            Spacer()
                            Text("\(Lorem.word(vid: idGen(3)))\n\(Lorem.word(vid: idGen(4)))\n\(Lorem.word(vid: idGen(5)))\n\(Lorem.word(vid: idGen(6)))")
                                .multilineTextAlignment(.leading)
                            RandomWidget(did: idGen(7), vid: idGen(8))
                            Spacer()
                            AutoStack {
                                RandomCircularWidget(did: idGen(9), vid: idGen(10))
                                RandomCircularWidget(did: idGen(10), vid: idGen(11))
                            }
                        }
                        Spacer()
                            .frame(minWidth: 300)
                        VStack(alignment: .trailing, spacing: 16) {
                            AutoStack {
                                RandomCircularWidget(did: idGen(15), vid: idGen(16))
                                RandomCircularWidget(did: idGen(15), vid: idGen(18))
                            }
                            .offset(safeCornerOffsets.topTrailing)
                            Spacer()
                            RandomWidget(did: idGen(15), vid: idGen(19))
                            Spacer()
                            Text("\(Lorem.word(vid: idGen(11)))\n\(Lorem.word(vid: idGen(12)))\n\(Lorem.word(vid: idGen(13)))\n\(Lorem.word(vid: idGen(14)))")
                                .multilineTextAlignment(.trailing)
                            RandomCircularWidget(did: idGen(19), vid: idGen(20))
                        }
                        Spacer()
                    }
                }
                VStack {
                    ShipOnPlanetView()
                    
                    HStack(spacing: system.basicShapeHStackSpacing) {
                        NavigationButton(to: .nearby)
                        NavigationButton(to: .targeting)
                        .environment(\.shapeDirection, .down)
                        NavigationButton(to: .galaxy)
                    }
                }
            }
            if vSizeClass == .regular {
                HStack(spacing: 16) {
                    ForEach(0..<4) { index in
                        RandomCircularWidget(did: idGen(21), vid: idGen(22) + index)
                    }
                }
            }
        }
    }
}

#Preview {
    PlanetPage()
}
