#if DEBUG
import SwiftUI

struct DebugControls: View {
    
    @Environment(\.system) private var system
    @Environment(PageNavigator.self) private var pageNavigator

    @SceneStorage(SceneStorageKey.debugShowingExternalDisplay) private var debugShowingExternalDisplay = false
    
    var body: some View {
        VStack {
            Button("Font", systemImage: "textformat") {
                DebugSettings.fontOverride.toggle()
            }
            
            Button("Emergency", systemImage: "exclamationmark.triangle") {
                // Both halves open and close the puzzle on every screen in the room, not just this one, so the
                // debug button exercises what a real emergency does.
                if ShipState.shared.isInEmergency {
                    ShipState.shared.endEmergency()
                } else {
                    ShipState.shared.beginEmergency(reason: .internalIssue, puzzle: EmergencyPuzzle.allCases.randomElement()!)
                }
            }
            
            #if STORY
            if ShipState.shared.isRunningStory {
                switch pageNavigator.stackBottomPage {
                case .story:
                    Button("Lock", systemImage: "lock") {
                        pageNavigator.setPage(.lockScreen)
                    }
                default:
                    Button("Story", systemImage: "book") {
                        pageNavigator.setPage(.story)
                    }
                }
            }

            // Flip between story and ambient mode, so the Show build can check the public build's path
            // without switching targets. The App Store build is only ever ambient: nothing to flip.
            Button("Ambient Scene", systemImage: !ShipState.shared.isRunningStory ? "book" : "sparkles") {
                let enteringAmbient = ShipState.shared.isRunningStory
                if enteringAmbient, pageNavigator.stackBottomPage == .story {
                    pageNavigator.setPage(.lockScreen) // StoryPage force-unwraps the story state; never leave it showing in ambient mode
                }
                ShipState.shared = ShipState(seed: seed, inStoryMode: !enteringAmbient)
                AppController.shared.reloadRootView()
                // Respawn the scene as an ambient system when entering (no-ops when returning to story mode).
                ShipState.shared.ambientHyperspaceJump()
            }
            #endif
            
            Button("External Display", systemImage: {
                #if targetEnvironment(macCatalyst)
                debugShowingExternalDisplay ? "tv" : "desktopcomputer"
                #else
                debugShowingExternalDisplay ? "tv" : "iphone"
                #endif
            }()) {
                // Preview-only reseed: swaps the theme to visualise a second display without touching
                // ShipState, the persisted seed, or peers. Not a "regenerate seed" path.
                Space_UI.system = SystemStyles(config: randomConfig)
                DispatchQueue.main.async {
                    if debugShowingExternalDisplay {
                        AppController.shared.closeModalPage()
                    } else {
                        AppController.shared.openPageModally(screen.externalDisplayPage(connectedEdges: screen.defaultConnectedEdges))
                    }
                    debugShowingExternalDisplay.toggle()
                }
            }
            
            Button("Regenerate Seed", systemImage: "slider.horizontal.2.arrow.trianglehead.counterclockwise") {
                AppController.shared.applyConfig(randomConfig, broadcast: true, persist: false)
            }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(FlexButtonStyle())
        .font(Font.system(size: 18, weight: .semibold, design: .rounded))
    }
}

#Preview {
    DebugControls()
}
#endif
