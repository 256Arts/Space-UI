//
//  NearbyPage.swift
//  Space UI
//
//  Created by Jayden Irwin on 2019-12-15.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import SwiftUI
import GameplayKit

struct NearbyPage: View {
    
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.safeCornerOffsets) private var safeCornerOffsets
    
    var body: some View {
        if vSizeClass == .regular && hSizeClass == .regular {
            NearbyShipsView(did: 0)
                .overlay(alignment: .bottom) {
                    HStack(spacing: 16) {
                        NavigationButton(to: .powerManagement) {
                            Text("Power")
                        }
                        NavigationButton(to: .coms) {
                            Text("Coms")
                        }
                        NavigationButton(to: .targeting) {
                            Text("Targeting")
                        }
                        NavigationButton(to: .planet) {
                            Text("Planet")
                        }
                    }
                }
                .widgetCorners(did: 63, topLeading: true, topTrailing: true, bottomLeading: false, bottomTrailing: false)
        } else {
            AutoStack(spacing: -20) {
                NearbyShipsView(did: 0)
                AutoStack(spacing: 16) {
                    NavigationButton(to: .powerManagement) {
                        Text("Power")
                    }
                    NavigationButton(to: .coms) {
                        Text("Coms")
                    }
                    NavigationButton(to: .targeting) {
                        Text("Targeting")
                    }
                    NavigationButton(to: .planet) {
                        Text("Planet")
                    }
                }
            }
            .widgetCorners(did: 63, topLeading: true, topTrailing: true, bottomLeading: true, bottomTrailing: true)
        }
    }
}

struct NearbyView_Previews: PreviewProvider {
    static var previews: some View {
        NearbyPage()
    }
}
