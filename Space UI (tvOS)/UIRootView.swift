import SwiftUI

enum Page: String {
    // The tvOS variant only renders the external pages. `settings`, `coms`, and `ticTacToe`
    // aren't navigated to here, but shared code compiled into this target still names them
    // (ScreenView's shader guard, NavigationButton's preview), so they must exist.
    case settings, coms, ticTacToe

    // External — the only pages the `UIRootView` switch actually renders.
    case extOrbits, extCircularProgressLeft, extCircularProgressRight

    static var defaultPage: Page { .extOrbits }
}

extension EnvironmentValues {

    @Entry var page: Page = .defaultPage

}

struct UIRootView: View {
    
    private enum DisplayOrientation: String {
        case `default`, left, right
        
        var angle: Angle {
            switch self {
            case .left:
                return .degrees(90)
            case .right:
                return .degrees(-90)
            default:
                return .zero
            }
        }
    }
    
    @AppStorage(UserDefaults.Key.displayOrientation) private var displayOrientationRawValue = "default"
    private var displayOrientation: DisplayOrientation {
        DisplayOrientation(rawValue: displayOrientationRawValue) ?? .default
    }
    
    @SceneStorage(SceneStorageKey.stackBottomPage) private var stackBottomPage: Page = .defaultPage
    
    private var visiblePage: Page {
        stackBottomPage
    }
    
    private var elementSize: ElementSize {
        switch screen.screenShapeType {
        case .circle, .triangle:
            return .regular
        default:
            return .large
        }
    }
    
    @State var showSettingsView = false
    
    // As on the shared root: this is the one view that reads the globals, because it is what injects them into
    // the environment. Note the stored copy this replaced captured `system` once at init and so never saw a
    // regenerated theme.
    private var appController: AppController = .shared

    /// The theme as everything below it should see it — the generated theme, with the emergency palette resolved
    /// in while the alarm is strobing. Same bridge as the shared root; see `UIRootView.injectedSystem`.
    private var injectedSystem: SystemStyles {
        ShipState.shared.useEmergencyColors ? system.resolvingEmergencyColors() : system
    }

    var body: some View {
        ScreenView {
            switch visiblePage {
            case .extCircularProgressLeft:
                CircularProgressExtPageLeft()
            case .extCircularProgressRight:
                CircularProgressExtPageLeft()
                    .scaleEffect(x: -1, y: 1)
            default:
                OrbitsExtPage()
            }
        }
        .sheet(isPresented: self.$showSettingsView) {
            AppSettingsPage()
        }
        .ignoresSafeArea()
        .frame(width: displayOrientation == .default ? 1920 : 1080, height: displayOrientation == .default ? 1080 : 1920)
        .rotationEffect(displayOrientation.angle)
        .font(Font.spaceFont(size: system.defaultFontSize))
        .foregroundColor(system.colors.color(.secondary, opacity: .max))
        .environment(\.system, injectedSystem)
        .environment(appController)
        .environment(ShipState.shared)
        .environment(\.screen, screen)
        .environment(\.elementSize, elementSize)
        .focusable()
        .onExitCommand {
            showSettingsView = true
        }
    }
}

#Preview {
    UIRootView()
}
