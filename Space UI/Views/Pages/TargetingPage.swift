import SwiftUI

struct TargetingPage: View {
    
    @IDGen private var idGen
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.safeCornerOffsets) private var safeCornerOffsets
    @Environment(\.shapeDirection) private var shapeDirection: ShapeDirection
    @Environment(\.system) private var system
    @Environment(ShipState.self) private var shipData
    var targetState = ShipState.shared.targetState
    
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
                                .fill(system.colors.color(.primary, opacity: self.targetState.targetingSegment1 ? .medium : .min))
                                .onTapGesture {
                                    self.targetState.targetingSegment1.toggle()
                            }
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .stroke(system.colors.color(.primary, opacity: .max), style: strokeStyle)
                        }
                        .rotationEffect(Angle(degrees: -27))
                        ZStack {
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .fill(system.colors.color(.primary, opacity: self.targetState.targetingSegment2 ? .medium : .min))
                                .onTapGesture {
                                    self.targetState.targetingSegment2.toggle()
                            }
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .stroke(system.colors.color(.primary, opacity: .max), style: strokeStyle)
                        }
                        .rotationEffect(Angle(degrees: -9))
                        ZStack {
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .fill(system.colors.color(.primary, opacity: self.targetState.targetingSegment3 ? .medium : .min))
                                .onTapGesture {
                                    self.targetState.targetingSegment3.toggle()
                            }
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .stroke(system.colors.color(.primary, opacity: .max), style: strokeStyle)
                        }
                        .rotationEffect(Angle(degrees: 9))
                        ZStack {
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .fill(system.colors.color(.primary, opacity: self.targetState.targetingSegment4 ? .medium : .min))
                                .onTapGesture {
                                    self.targetState.targetingSegment4.toggle()
                            }
                            PieSlice(deltaAngle: .pi/10, hasRadialLines: true)
                                .stroke(system.colors.color(.primary, opacity: .max), style: strokeStyle)
                        }
                        .rotationEffect(Angle(degrees: 27))
                    }
                    .frame(width: min(geometry.size.width, geometry.size.height) * 2, height: min(geometry.size.width, geometry.size.height) * 2, alignment: .center)
                    .offset(x: 0, y: min(geometry.size.width, geometry.size.height) / 2)
                    ForEach(self.targetState.targets) { target in
                        AutoShape(system: system, direction: shapeDirection)
                            .frame(width: 20, height: 20, alignment: .center)
                            .foregroundColor(system.colors.color(target.isHostile ? .danger : .secondary, opacity: .max))
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
                Button("Lasers") {
                    AudioController.shared.play(.action)
                    shipData.weaponsInLaserMode = true
                }
                .buttonStyle(GroupedButtonStyle(segmentPosition: .leading, isSelected: shipData.weaponsInLaserMode))
                Button("Missiles") {
                    AudioController.shared.play(.action)
                    shipData.weaponsInLaserMode = false
                }
                .buttonStyle(GroupedButtonStyle(segmentPosition: .trailing, isSelected: !shipData.weaponsInLaserMode))
            }
            .offset(safeCornerOffsets.bottomTrailing)
        }
        .task {
            // Auto-cancelling loop instead of a `Timer` that would stack a new tick on every page visit.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.8))
                guard !Task.isCancelled else { break }
                self.targetState.simulateTargetMovement()
            }
        }
    }
}

#Preview {
    TargetingPage()
}
