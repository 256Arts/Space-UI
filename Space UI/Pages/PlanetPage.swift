//
//  PlanetPage.swift
//  Space UI
//
//  Created by Jayden Irwin on 2019-12-15.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import SwiftUI

struct PlanetPage: View {
    
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
                            RandomCircularWidget(did: 1, vid: 2)
                                .offset(safeCornerOffsets.topLeading)
                            Spacer()
                            Text("\(Lorem.word(vid: 3))\n\(Lorem.word(vid: 4))\n\(Lorem.word(vid: 5))\n\(Lorem.word(vid: 6))")
                                .multilineTextAlignment(.leading)
                            RandomWidget(did: 7, vid: 8)
                            Spacer()
                            AutoStack {
                                RandomCircularWidget(did: 7, vid: 10)
                                RandomCircularWidget(did: 7, vid: 11)
                            }
                        }
                        Spacer()
                            .frame(minWidth: 300)
                        VStack(alignment: .trailing, spacing: 16) {
                            AutoStack {
                                RandomCircularWidget(did: 15, vid: 16)
                                RandomCircularWidget(did: 15, vid: 18)
                            }
                            .offset(safeCornerOffsets.topTrailing)
                            Spacer()
                            RandomWidget(did: 15, vid: 19)
                            Spacer()
                            Text("\(Lorem.word(vid: 11))\n\(Lorem.word(vid: 12))\n\(Lorem.word(vid: 13))\n\(Lorem.word(vid: 14))")
                                .multilineTextAlignment(.trailing)
                            RandomCircularWidget(did: 19, vid: 20)
                        }
                        Spacer()
                    }
                }
                VStack {
                    ShipOnPlanetView()
                    HStack(spacing: system.basicShapeHStackSpacing) {
                        NavigationButton(to: .nearby) {
                            Text("Nearby")
                        }
                        NavigationButton(to: .targeting) {
                            Text("Targeting")
                        }
                        .environment(\.shapeDirection, .down)
                        NavigationButton(to: .galaxy) {
                            Text("Galaxy")
                        }
                    }
                }
            }
            if vSizeClass == .regular {
                HStack(spacing: 16) {
                    ForEach(0..<4) { index in
                        RandomCircularWidget(did: 21, vid: 22 + index)
                    }
                }
            }
        }
    }
}

struct PlanetPage_Previews: PreviewProvider {
    static var previews: some View {
        PlanetPage()
    }
}
