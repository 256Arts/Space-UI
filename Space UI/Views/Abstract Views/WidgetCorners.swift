//
//  WidgetCorners.swift
//  Space UI
//
//  Created by Jayden Irwin on 2022-10-07.
//  Copyright © 2022 Jayden Irwin. All rights reserved.
//

import SwiftUI

struct WidgetCorners: ViewModifier {

    let did: Int
    let topLeading: Bool
    let topTrailing: Bool
    let bottomLeading: Bool
    let bottomTrailing: Bool
    
    @Environment(\.safeCornerOffsets) private var safeCornerOffsets
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topLeading) {
                if topLeading && ((Int(system.seed) + did) % 4 != 0) {
                    RandomCircularWidget(did: did + 1, vid: did + 7)
                        .offset(safeCornerOffsets.topLeading)
                }
            }
            .overlay(alignment: .topTrailing) {
                if topTrailing && ((Int(system.seed) + did) % 4 != 1) {
                    RandomWidget(did: did + 2, vid: did + 8)
                        .offset(safeCornerOffsets.topTrailing)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if bottomLeading && ((Int(system.seed) + did) % 4 != 2) {
                    RandomCircularWidget(did: did + 3, vid: did + 9)
                        .offset(safeCornerOffsets.bottomLeading)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if bottomTrailing && ((Int(system.seed) + did) % 4 != 3) {
                    RandomWidget(did: did + 4, vid: did + 10)
                        .offset(safeCornerOffsets.bottomTrailing)
                }
            }
    }
}

extension View {
    
    func widgetCorners(did: Int, topLeading: Bool, topTrailing: Bool, bottomLeading: Bool, bottomTrailing: Bool) -> some View {
        modifier(WidgetCorners(did: did, topLeading: topLeading, topTrailing: topTrailing, bottomLeading: bottomLeading, bottomTrailing: bottomTrailing))
    }
    
}
