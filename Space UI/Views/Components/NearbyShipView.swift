import SwiftUI

struct NearbyShipView: View {
    
    static let blurRadius: CGFloat = 6.0
    static let stretch: CGFloat = 2.0
    static let offsetY: CGFloat = 30.0
    
    @Environment(\.system) private var system

    let ship: NearbyShip
    let showShipRotation: Bool
    
    @State var blurRadius = NearbyShipView.blurRadius
    @State var stretch = NearbyShipView.stretch
    @State var offsetY = NearbyShipView.offsetY
    @State var pulseScale: CGFloat = 0.8
    @State var pulseOpacity: Double = 1.0

    var body: some View {
        Image(ship.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(system.colors.color(ship.isHostile ? .danger : .secondary, opacity: .max))
            .background {
                if ship.isHostile {
                    Circle()
                        .fill(system.colors.color(.danger, opacity: .medium))
                        .scaleEffect(pulseScale)
                        .opacity(pulseOpacity)
                        .onAppear {
                            withAnimation(Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                                pulseScale = 2.0
                                pulseOpacity = 0.0
                            }
                        }
                }
            }
            .blur(radius: self.blurRadius)
            .scaleEffect(x: 1, y: self.stretch, anchor: .top)
            .offset(y: self.offsetY)
            .rotationEffect(self.showShipRotation ? ship.rotation : Angle.zero)
            .onAppear {
                withAnimation(Animation.easeOut(duration: 0.2)) {
                    self.blurRadius = 0.0
                    self.stretch = 1.0
                    self.offsetY = 0.0
                }
            }
            .onDisappear {
                withAnimation(Animation.easeOut(duration: 0.2)) {
                    self.blurRadius = NearbyShipView.blurRadius
                    self.stretch = NearbyShipView.stretch
                    self.offsetY = NearbyShipView.offsetY
                }
            }
    }
}

#Preview {
    NearbyShipView(
        ship: NearbyShip(
            coord: .zero,
            rotation: .zero,
            isApproachingViaHyperspace: false,
            isHostile: false,
            isLarge: false,
            imageName: "Cargo Ship Up"
        ),
        showShipRotation: true
    )
}
