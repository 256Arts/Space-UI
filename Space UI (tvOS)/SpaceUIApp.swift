import SwiftUI

enum WindowID: String {
    case ui
}

@main
struct SpaceUIApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            UIRootView()
                .background(Color.black, ignoresSafeAreaEdges: .all)
        }
        .onChange(of: scenePhase) { _, newValue in
            switch newValue {
            case .active:
                PeerSessionController.shared.lookToHost()
                PeerSessionController.shared.lookToJoin()
                AudioController.shared.startAmbience()
                
                if UserDefaults.standard.bool(forKey: UserDefaults.Key.syncHomeLights) {
                    Task {
                        try? await HomeStore.shared.updateLights(sourceFilter: .lightPanel)
                    }
                }
                
                if UserDefaults.standard.bool(forKey: UserDefaults.Key.keepAwake) {
                    UIApplication.shared.isIdleTimerDisabled = true
                }
            case .background:
                PeerSessionController.shared.stopLookingToHost()
                PeerSessionController.shared.stopLookingToJoin()
                AudioController.shared.invalidateAmbientSoundTimers()
            default:
                break
            }
        }
    }
    
    init() {
        let userDefaults = UserDefaults.standard
        userDefaults.register()
        
        userDefaults
            .set(
                userDefaults.integer(forKey: UserDefaults.Key.appLaunchCount) + 1,
                forKey: UserDefaults.Key.appLaunchCount
            )
    }
    
}
