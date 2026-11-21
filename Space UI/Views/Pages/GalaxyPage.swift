import SwiftUI

struct GalaxyPage: View {
    
    @Environment(\.safeCornerOffsets) private var safeCornerOffsets
    
    var body: some View {
        GalaxyView()
        .overlay(alignment: .topLeading) {
            NavigationButton(to: .planet)
                .offset(safeCornerOffsets.topLeading)
        }
    }
    
}

#Preview {
    GalaxyPage()
}
