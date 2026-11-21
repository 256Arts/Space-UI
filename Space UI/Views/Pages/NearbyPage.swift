import SwiftUI

struct NearbyPage: View {
    
    @IDGen private var idGen
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    var body: some View {
        if vSizeClass == .regular && hSizeClass == .regular {
            NearbyShipsView(did: idGen(0), vid: idGen(1))
                .overlay(alignment: .bottom) {
                    HStack(spacing: 16) {
                        NavigationButton(to: .powerManagement)
                        NavigationButton(to: .coms)
                        NavigationButton(to: .targeting)
                        NavigationButton(to: .planet)
                    }
                }
                .widgetCorners(did: idGen(63), topLeading: true, topTrailing: true, bottomLeading: false, bottomTrailing: false)
                .containerValue(\.isRoundElement, true)
        } else {
            AutoStack(spacing: -20) {
                NearbyShipsView(did: idGen(0), vid: idGen(1))
                AutoStack(spacing: 16) {
                    NavigationButton(to: .powerManagement)
                    NavigationButton(to: .coms)
                    NavigationButton(to: .targeting)
                    NavigationButton(to: .planet)
                }
            }
            .widgetCorners(did: idGen(63), topLeading: true, topTrailing: vSizeClass == .regular, bottomLeading: hSizeClass == .regular, bottomTrailing: false)
        }
    }
}

#Preview {
    NearbyPage()
}
