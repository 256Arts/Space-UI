//
//  NearbyShipView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-03-24.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct NearbyShipView: View {
    
    static let blurRadius: CGFloat = 6.0
    static let stretch: CGFloat = 2.0
    static let offsetY: CGFloat = 30.0
    
    let ship: NearbyShip
    let showShipRotation: Bool
    
    @State var blurRadius = NearbyShipView.blurRadius
    @State var stretch = NearbyShipView.stretch
    @State var offsetY = NearbyShipView.offsetY
    
    var body: some View {
        Image((ship.isLarge ? ShipData.shared.enemyCommandShipIconNames : ShipData.shared.enemyStarshipIconNames).randomElement()!)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(Color(color: .secondary, opacity: .max))
            .blur(radius: self.blurRadius)
            .scaleEffect(x: 1, y: self.stretch, anchor: .top)
            .offset(y: self.offsetY)
            .rotationEffect(self.showShipRotation ? ship.rotation : Angle.zero)
            .onAppear() {
                withAnimation(Animation.easeOut(duration: 0.2)) {
                    self.blurRadius = 0.0
                    self.stretch = 1.0
                    self.offsetY = 0.0
                }
            }
            .onDisappear() {
                withAnimation(Animation.easeOut(duration: 0.2)) {
                    self.blurRadius = NearbyShipView.blurRadius
                    self.stretch = NearbyShipView.stretch
                    self.offsetY = NearbyShipView.offsetY
                }
            }
    }
}

#Preview {
    NearbyShipView(ship: NearbyShip(coord: .zero, rotation: .zero, isLarge: false), showShipRotation: true)
}
