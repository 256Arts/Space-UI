//
//  TargetingPage.swift
//  Space UI
//
//  Created by Jayden Irwin on 2019-12-15.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import SwiftUI

struct TargetingPage: View {
    
    @Environment(\.safeCornerOffsets) private var safeCornerOffsets
    @Environment(\.shapeDirection) private var shapeDirection: ShapeDirection
    
    @ObservedObject var shipData = ShipData.shared
    @ObservedObject var targetState = ShipData.shared.targetState
    
    var body: some View {
        VStack {
            HStack {
                NavigationButton(to: .nearby) {
                    Text("Nearby")
                }
                NavigationButton(to: .planet) {
                    Text("Planet")
                }
            }
            GeometryReader { geometry in
                ZStack {
                    ZStack {
                        ZStack {
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .fill(Color(color: .primary, opacity: self.targetState.targetingSegment1 ? .medium : .low))
                                .onTapGesture {
                                    self.targetState.targetingSegment1.toggle()
                            }
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .stroke(Color(color: .primary, opacity: .max), style: StrokeStyle(lineWidth: system.mediumLineWidth, lineJoin: .round))
                        }
                        .rotationEffect(Angle(degrees: -27), anchor: .bottom)
                        ZStack {
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .fill(Color(color: .primary, opacity: self.targetState.targetingSegment2 ? .medium : .low))
                                .onTapGesture {
                                    self.targetState.targetingSegment2.toggle()
                            }
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .stroke(Color(color: .primary, opacity: .max), style: StrokeStyle(lineWidth: system.mediumLineWidth, lineJoin: .round))
                        }
                        .rotationEffect(Angle(degrees: -9), anchor: .bottom)
                        ZStack {
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .fill(Color(color: .primary, opacity: self.targetState.targetingSegment3 ? .medium : .low))
                                .onTapGesture {
                                    self.targetState.targetingSegment3.toggle()
                            }
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .stroke(Color(color: .primary, opacity: .max), style: StrokeStyle(lineWidth: system.mediumLineWidth, lineJoin: .round))
                        }
                        .rotationEffect(Angle(degrees: 9), anchor: .bottom)
                        ZStack {
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .fill(Color(color: .primary, opacity: self.targetState.targetingSegment4 ? .medium : .low))
                                .onTapGesture {
                                    self.targetState.targetingSegment4.toggle()
                            }
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .stroke(Color(color: .primary, opacity: .max), style: StrokeStyle(lineWidth: system.mediumLineWidth, lineJoin: .round))
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
        .overlay(alignment: .bottomLeading) {
            CircularProgressView(did: 1, value: shipData.powerState.weaponsHavePower ? .constant(1) : .constant(0), lineWidth: nil)
                .frame(width: 100, height: 100)
                .offset(safeCornerOffsets.bottomLeading)
        }
        .overlay(alignment: .bottomTrailing) {
            HStack {
                Button(action: {
                    AudioController.shared.play(.action)
                    shipData.weaponsInLaserMode = true
                }, label: {
                    Text("Lasers")
                }).buttonStyle(GroupedButtonStyle(segmentPosition: .leading, isSelected: shipData.weaponsInLaserMode))
                Button(action: {
                    AudioController.shared.play(.action)
                    shipData.weaponsInLaserMode = false
                }, label: {
                    Text("Missiles")
                }).buttonStyle(GroupedButtonStyle(segmentPosition: .trailing, isSelected: !shipData.weaponsInLaserMode))
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

struct TargetingView_Previews: PreviewProvider {
    static var previews: some View {
        TargetingPage()
    }
}
