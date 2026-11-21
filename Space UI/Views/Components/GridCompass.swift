import SwiftUI

struct GridCompass: View {
    
    @Environment(\.system) private var system
    
    @State private var anglePublisher = DoubleGenerator(range: -20...20)
    
    var body: some View {
        ZStack {
            GridShape(rows: 4, columns: 4, hasOutsideBorders: false)
                .stroke(system.colors.color(.primary, opacity: .max), style: system.strokeStyle(.thin))
                .rotationEffect(.degrees(anglePublisher.value))
                .animation(.easeInOut(duration: 1), value: anglePublisher.value)
            
            // Crosshairs
            Rectangle()
                .foregroundColor(system.colors.color(.primary, opacity: .max))
                .frame(width: 3)
            Rectangle()
                .foregroundColor(system.colors.color(.primary, opacity: .max))
                .frame(height: 3)
            
            // Angle Marks
            Path { path in
                path.move(to: CGPoint(x: 75, y: 15))
                path.addRelativeArc(center: CGPoint(x: 75, y: 75), radius: 60, startAngle: Angle(degrees: -90), delta: Angle(degrees: 90))
                path.move(to: CGPoint(x: 75, y: 135))
                path.addRelativeArc(center: CGPoint(x: 75, y: 75), radius: 60, startAngle: Angle(degrees: 90), delta: Angle(degrees: 90))
            }
            .stroke(system.colors.color(.primary, opacity: .max), style: StrokeStyle(lineWidth: 10, dash: [3, 15], dashPhase: 10))
            
            Triangle(roundedCornerFraction: system.roundedCornerFraction)
                .environment(\.shapeDirection, .up)
                .foregroundColor(system.colors.color(.primary, opacity: .max))
                .frame(width: 30, height: 30)
            Triangle(roundedCornerFraction: system.roundedCornerFraction)
                .stroke(system.colors.color(.primary, opacity: .min), style: system.strokeStyle(.thin))
                .environment(\.shapeDirection, .up)
                .frame(width: 30, height: 30)
            
            Circle()
                .strokeBorder(system.colors.color(.primary, opacity: .max), style: system.strokeStyle(.thin))
        }
        .clipShape(Circle())
    }
}

#Preview {
    GridCompass()
}
