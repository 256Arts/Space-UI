import SwiftUI

// Example of what this looks like:
// >------<

struct VerticalScanBar: View {
    
    @Environment(\.system) private var system
    
    @State var scanBarOffset = CGFloat.random(in: -0.5...0.5)
    @State var changeTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: -4) {
                Triangle(roundedCornerFraction: system.roundedCornerFraction)
                    .environment(\.shapeDirection, .down)
                    .foregroundColor(system.colors.color(.primary, opacity: .max))
                    .frame(width: 30, height: 30)
                Rectangle()
                    .foregroundColor(system.colors.color(.primary, opacity: .max))
                    .frame(width: 5)
                Triangle(roundedCornerFraction: system.roundedCornerFraction)
                    .environment(\.shapeDirection, .up)
                    .foregroundColor(system.colors.color(.primary, opacity: .max))
                    .frame(width: 30, height: 30)
            }
            .offset(x: scanBarOffset * geometry.size.width, y: 0)
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
        .onAppear {
            changeTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { (_) in
                Task { @MainActor in
                    withAnimation(Animation.easeInOut(duration: 3)) {
                        scanBarOffset = CGFloat.random(in: -0.5...0.5)
                    }
                }
            }
        }
        .onDisappear {
            changeTimer?.invalidate()
        }
    }
}

#Preview {
    VerticalScanBar()
}
