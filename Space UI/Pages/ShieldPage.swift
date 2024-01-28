//
//  ShieldPage.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-15.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI
import GameplayKit

struct ShieldPage: View {
    
    let word1 = Lorem.word(vid: 1)
    let word2 = Lorem.word(vid: 2)
    let word3 = Lorem.word(vid: 3)
    let word4 = Lorem.word(vid: 4)
    let word5 = Lorem.word(vid: 5)
    
    @IDGen private var idGen
    @Environment(\.safeCornerOffsets) private var safeCornerOffsets
    
    @ObservedObject var shipData = ShipData.shared
    @State var atomAngle = 0.0
    @State var atomDistance: CGFloat = 30
    
    var body: some View {
        AutoStack {
            ZStack {
                Circle()
                    .strokeBorder(LinearGradient(gradient: Gradient(colors: [Color(color: .tertiary, opacity: .max), Color(color: .primary, opacity: .min)]), startPoint: .top, endPoint: .bottom), style: system.strokeStyle(.thick))
                    .rotationEffect(Angle(degrees: self.shipData.shieldAngle))
                ShipData.shared.icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color(color: .secondary, opacity: .max))
                    .scaleEffect(0.75)
            }
            .overlay(alignment: .top) {
                NavigationButton(to: .powerManagement)
            }
            .overlay(alignment: .topLeading) {
                RandomCircularWidget(did: idGen(1), vid: idGen(1))
                    .frame(width: 100, height: 100, alignment: .topLeading)
                    .offset(safeCornerOffsets.topLeading)
            }
            .overlay(alignment: .topTrailing) {
                Spirograph(innerRadius: 42, outerRadius: 22, distance: self.atomDistance)
                    .stroke(Color(color: .primary, opacity: .max), style: system.strokeStyle(.thin))
                    .frame(width: 150, height: 150, alignment: .topTrailing)
                    .rotationEffect(Angle(degrees: self.atomAngle))
                    .overlay(Text(word2).fixedSize())
                    .offset(safeCornerOffsets.topTrailing)
            }
            .overlay(alignment: .bottom) {
                HStack {
                    Button {
                        AudioController.shared.play(.action)
                        withAnimation {
                            self.shipData.shieldAngle -= 20.0
                        }
                    } label: {
                        Image(systemName: "arrowtriangle.left.fill")
                    }
                    .buttonStyle(GroupedButtonStyle(segmentPosition: .leading))
                    
                    Button {
                        AudioController.shared.play(.action)
                        withAnimation {
                            self.shipData.shieldAngle += 20.0
                        }
                    } label: {
                        Image(systemName: "arrowtriangle.right.fill")
                    }
                    .buttonStyle(GroupedButtonStyle(segmentPosition: .trailing))
                }
            }
            VStack {
                Text(word3)
                Text(word4)
                Text(word5)
            }
            .frame(width: 350)
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 20.0).repeatForever(autoreverses: false)) {
                self.atomAngle = 360.0
            }
            withAnimation(Animation.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                self.atomDistance = 40
            }
        }
    }
}

#Preview {
    ShieldPage()
}
