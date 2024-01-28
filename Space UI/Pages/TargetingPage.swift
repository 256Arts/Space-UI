//
//  TargetingPage.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-15.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct TargetingPage: View {
    
    @IDGen private var idGen
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.safeCornerOffsets) private var safeCornerOffsets
    @Environment(\.shapeDirection) private var shapeDirection: ShapeDirection
    
    @ObservedObject var shipData = ShipData.shared
    @ObservedObject var targetState = ShipData.shared.targetState
    
    var strokeStyle: StrokeStyle {
        system.strokeStyle(.medium)
    }
    
    var body: some View {
        VStack {
            HStack {
                NavigationButton(to: .nearby)
                NavigationButton(to: .planet)
            }
            GeometryReader { geometry in
                ZStack {
                    ZStack {
                        ZStack {
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .fill(Color(color: .primary, opacity: self.targetState.targetingSegment1 ? .medium : .min))
                                .onTapGesture {
                                    self.targetState.targetingSegment1.toggle()
                            }
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .stroke(Color(color: .primary, opacity: .max), style: strokeStyle)
                        }
                        .rotationEffect(Angle(degrees: -27), anchor: .bottom)
                        ZStack {
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .fill(Color(color: .primary, opacity: self.targetState.targetingSegment2 ? .medium : .min))
                                .onTapGesture {
                                    self.targetState.targetingSegment2.toggle()
                            }
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .stroke(Color(color: .primary, opacity: .max), style: strokeStyle)
                        }
                        .rotationEffect(Angle(degrees: -9), anchor: .bottom)
                        ZStack {
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .fill(Color(color: .primary, opacity: self.targetState.targetingSegment3 ? .medium : .min))
                                .onTapGesture {
                                    self.targetState.targetingSegment3.toggle()
                            }
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .stroke(Color(color: .primary, opacity: .max), style: strokeStyle)
                        }
                        .rotationEffect(Angle(degrees: 9), anchor: .bottom)
                        ZStack {
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .fill(Color(color: .primary, opacity: self.targetState.targetingSegment4 ? .medium : .min))
                                .onTapGesture {
                                    self.targetState.targetingSegment4.toggle()
                            }
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .stroke(Color(color: .primary, opacity: .max), style: strokeStyle)
                        }
                        .rotationEffect(Angle(degrees: 27), anchor: .bottom)
                    }
                    .frame(width: min(geometry.size.width, geometry.size.height) * 2, height: min(geometry.size.width, geometry.size.height) * 2, alignment: .center)
                    .offset(x: 0, y: -min(geometry.size.width, geometry.size.height) / 2)
                    ForEach(self.targetState.targets) { target in
                        AutoShape(direction: shapeDirection)
                            .frame(width: 20, height: 20, alignment: .center)
                            .foregroundColor(Color(color: target.isHostile ? .danger : .secondary, opacity: .max))
                            .offset(x: target.coord.x * min(geometry.size.width, geometry.size.height), y: target.coord.y * min(geometry.size.width, geometry.size.height) * 0.6) // Stretch points over pie slice area
                    }
                }
                .position(x: geometry.size.width/2, y: geometry.size.height/2)
            }
        }
        .widgetCorners(did: idGen(1), topLeading: hSizeClass == .regular, topTrailing: hSizeClass == .regular, bottomLeading: false, bottomTrailing: false)
        .overlay(alignment: .bottomLeading) {
            CircularProgressView(did: idGen(2), value: shipData.powerState.weaponsHavePower ? .constant(1) : .constant(0), lineWidth: nil)
                .frame(width: 100, height: 100)
                .offset(safeCornerOffsets.bottomLeading)
        }
        .overlay(alignment: .bottomTrailing) {
            HStack {
                Button {
                    AudioController.shared.play(.action)
                    shipData.weaponsInLaserMode = true
                } label: {
                    Text("Lasers")
                }
                .buttonStyle(GroupedButtonStyle(segmentPosition: .leading, isSelected: shipData.weaponsInLaserMode))
                Button {
                    AudioController.shared.play(.action)
                    shipData.weaponsInLaserMode = false
                } label: {
                    Text("Missiles")
                }
                .buttonStyle(GroupedButtonStyle(segmentPosition: .trailing, isSelected: !shipData.weaponsInLaserMode))
            }
            .offset(safeCornerOffsets.bottomTrailing)
        }
        .onAppear() {
            Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
                self.targetState.simulateTargetMovement()
            }
        }
    }
}

#Preview {
    TargetingPage()
}
