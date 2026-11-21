import SwiftUI

struct QuickStartView: View {
    
    init(currentWindowID: WindowID) {
        self.currentWindowID = currentWindowID
    }
    
    @Environment(AppController.self) private var appController
    @Environment(\.supportsMultipleWindows) private var supportsMultipleWindows
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    
    let currentWindowID: WindowID
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Start")
                .font(.title2)
            
            if currentWindowID == .spaceWindow {
                // The tap gesture's discoverable label; QuickStart only shows in ambient (non-story) mode.
                Button("Hyperspace Jump", systemImage: "sparkles") {
                    ShipState.shared.ambientHyperspaceJump()
                }
            }

            if supportsMultipleWindows {
                if currentWindowID == .spaceWindow {
                    Button("Open UI Window", systemImage: "rectangle.badge.plus") {
                        dismissWindow(id: WindowID.ui.rawValue)
                        openWindow(id: WindowID.ui.rawValue)
                    }
                } else {
                    Button("Open Space Window", systemImage: "rectangle.badge.plus") {
                        dismissWindow(id: WindowID.spaceWindow.rawValue)
                        openWindow(id: WindowID.spaceWindow.rawValue)
                    }
                }
            }
            
            Button("Settings", systemImage: "gearshape") {
                appController.openPageModally(.settings)
            }

            // The right-edge swipe's discoverable label, in the same spirit as Hyperspace Jump above — and the
            // way in on Mac and Vision Pro, which have no screen edge to swipe from.
            Button("Swipe the right edge for settings", systemImage: "sidebar.right") {
                appController.showingSettingsInspector = true
            }
        }
        .padding()
        .frame(maxWidth: 500, alignment: .leading)
        #if os(visionOS)
        .background(Material.regular, in: RoundedRectangle(cornerRadius: 40))
        #else
        .glassEffect(in: RoundedRectangle(cornerRadius: 40))
        #endif
        .scenePadding()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    QuickStartView(currentWindowID: .ui)
}
