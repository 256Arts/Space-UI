import SwiftUI

struct Compass: View {
    
    @Environment(\.system) private var system
    
    @State private var anglePublisher = DoubleGenerator(range: -20...20)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Outer Circles
                Circle()
                    .stroke(system.colors.color(.primary, opacity: .high), style: system.strokeStyle(.thin))
                Circle()
                    .stroke(system.colors.color(.primary, opacity: .max), style: StrokeStyle(lineWidth: 20, dash: [2, 9], dashPhase: 1))
                Circle()
                    .stroke(system.colors.color(.primary, opacity: .max), style: StrokeStyle(lineWidth: 10, dash: [1, 10], dashPhase: 6))
                
                // Crosshairs
                Rectangle()
                    .foregroundColor(system.colors.color(.primary, opacity: .max))
                    .frame(width: system.thinLineWidth)
                Rectangle()
                    .foregroundColor(system.colors.color(.primary, opacity: .max))
                    .frame(height: system.thinLineWidth)
                
                // Horizontal Tick Lines
                HStack(spacing: 20) {
                    Rectangle()
                        .foregroundColor(system.colors.color(.primary, opacity: .max))
                        .frame(width: 1, height: 12)
                    Rectangle()
                        .foregroundColor(system.colors.color(.primary, opacity: .max))
                        .frame(width: 1, height: 20)
                    Rectangle()
                        .foregroundColor(system.colors.color(.primary, opacity: .max))
                        .frame(width: 1, height: 12)
                    Rectangle()
                        .foregroundColor(system.colors.color(.primary, opacity: .max))
                        .frame(width: 1, height: 12)
                    Rectangle()
                        .foregroundColor(system.colors.color(.primary, opacity: .max))
                        .frame(width: 1, height: 20)
                    Rectangle()
                        .foregroundColor(system.colors.color(.primary, opacity: .max))
                        .frame(width: 1, height: 12)
                }
                
                // Inner Circles
                ZStack {
                    PieSlice(deltaAngle: .pi, hasRadialLines: false)
                        .foregroundColor(system.colors.color(.primary, opacity: .max))
                        .frame(width: geometry.size.width * 0.5, height: geometry.size.height * 0.5)
                        .rotationEffect(Angle(radians: .pi))
                    Circle()
                        .stroke(system.colors.color(.primary, opacity: .max), lineWidth: 1)
                        .frame(width: geometry.size.width * 0.25, height: geometry.size.height * 0.25)
                    Circle()
                        .stroke(system.colors.color(.secondary, opacity: .max), lineWidth: system.thinLineWidth)
                        .frame(width: geometry.size.width * 0.4, height: geometry.size.height * 0.4)
                    Circle()
                        .stroke(system.colors.color(.primary, opacity: .max), lineWidth: 1)
                        .frame(width: geometry.size.width * 0.5, height: geometry.size.height * 0.5)
                    Triangle(roundedCornerFraction: system.roundedCornerFraction)
                        .environment(\.shapeDirection, .up)
                        .foregroundColor(system.colors.color(.primary, opacity: .max))
                        .frame(width: 20, height: 20)
                        .offset(x: 0, y: -geometry.size.height * 0.65)
                }
            }
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
        .rotationEffect(.degrees(anglePublisher.value))
        .animation(.spring(response: 1, dampingFraction: 0.5, blendDuration: 0), value: anglePublisher.value)
    }
}

#Preview {
    Compass()
}
