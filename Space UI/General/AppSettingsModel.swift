import SwiftUI

/// The outbound links both settings surfaces list, so the two can't drift apart.
enum SettingsLink: String, CaseIterable, Identifiable {

    case developerWebsite, community, gitHub
    /// Cross-promotes Alien Font, which builds its scripts with the same AlienFontKit the themes draw in. Shown
    /// beside the font settings rather than with the other links, so it reads as the next step, not an ad.
    case alienFont

    /// The links listed in each surface's links section.
    static let general: [SettingsLink] = [.developerWebsite, .community, .gitHub]

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .developerWebsite: "Developer Website"
        case .community: "Join Community"
        case .gitHub: "Contribute on GitHub"
        case .alienFont: "Design Your Own Alien Font"
        }
    }

    var systemImage: String {
        switch self {
        case .developerWebsite: "safari"
        case .community: "bubble.left.and.bubble.right"
        case .gitHub: "chevron.left.forwardslash.chevron.right"
        case .alienFont: "character.book.closed"
        }
    }

    /// Set for our own apps, whose page `SettingsLinkView` opens in the App Store sheet instead of leaving the app.
    var appStoreID: Int? {
        switch self {
        case .alienFont: 6833600760
        default: nil
        }
    }

    var url: URL {
        switch self {
        case .developerWebsite: URL(string: "https://www.jaydenirwin.com/")!
        case .community: URL(string: "https://www.256arts.com/joincommunity/")!
        case .gitHub: URL(string: "https://github.com/256Arts/Space-UI")!
        case .alienFont: URL(string: "https://apps.apple.com/app/alien-font/id\(appStoreID!)")!
        }
    }

}

/// The app's settings state, shared by the two surfaces that edit it: the in-universe `AppSettingsPage` and the
/// native `SettingsInspector`. A singleton rather than per-view state so the two agree whenever both are on
/// screen, which they are any time the inspector is opened over the settings page itself.
///
/// Each stored property is the in-memory half of a `UserDefaults` key — read once at init, written back in
/// `didSet` — the same shape as `PeerSessionController`. That stands in for the `@AppStorage` properties the
/// page used to declare (a plain, non-`View` type can't have them), and it lets each setting's side effects
/// live next to the setting rather than as an `.onChange` both surfaces would have to remember to repeat.
@MainActor
@Observable
final class AppSettingsModel {

    static let shared = AppSettingsModel()

    /// `@AppStorage` persisted this as its comma-joined raw string, so it reads back through `init(rawValue:)`
    /// — `object(forKey:) as? DesignPrinciples` always returns nil. Same round-trip as `savedDesignPrinciples`.
    private static var storedDesignPrinciples: DesignPrinciples {
        UserDefaults.standard.string(forKey: UserDefaults.Key.designPrinciples)
            .flatMap(DesignPrinciples.init(rawValue:)) ?? DesignPrinciples()
    }

    // MARK: - Design

    var applyDesignPrinciples = UserDefaults.standard.bool(forKey: UserDefaults.Key.applyDesignPrinciples) {
        didSet {
            UserDefaults.standard.set(applyDesignPrinciples, forKey: UserDefaults.Key.applyDesignPrinciples)
            // Toggling is what commits the sliders' working copy, so flipping the switch is the whole gesture
            // on both surfaces — the page's single apply button and the inspector's plain `Toggle`.
            commitDesignPrinciples()
        }
    }
    // Read straight from the key rather than through `savedDesignPrinciples`, which returns nil while
    // `applyDesignPrinciples` is off — the sliders still have to show the saved values when they're inactive.
    var designPrinciples = AppSettingsModel.storedDesignPrinciples {
        didSet { UserDefaults.standard.set(designPrinciples.rawValue, forKey: UserDefaults.Key.designPrinciples) }
    }
    var primaryHue = UserDefaults.standard.object(forKey: UserDefaults.Key.primaryHue) as? Double ?? 0 {
        didSet { UserDefaults.standard.set(primaryHue, forKey: UserDefaults.Key.primaryHue) }
    }
    var primarySaturation = UserDefaults.standard.object(forKey: UserDefaults.Key.primarySaturation) as? Double ?? 1 {
        didSet { UserDefaults.standard.set(primarySaturation, forKey: UserDefaults.Key.primarySaturation) }
    }

    // MARK: - Per-device appearance

    var screenShapeOverrideValue = UserDefaults.standard.string(forKey: UserDefaults.Key.screenShapeOverride) ?? "" {
        didSet {
            UserDefaults.standard.set(screenShapeOverrideValue, forKey: UserDefaults.Key.screenShapeOverride)
            AppController.shared.applyLocalAppearance()
        }
    }
    var extraFonts = UserDefaults.standard.bool(forKey: UserDefaults.Key.extraFonts) {
        didSet {
            UserDefaults.standard.set(extraFonts, forKey: UserDefaults.Key.extraFonts)
            AppController.shared.applyLocalAppearance()
        }
    }

    #if !os(visionOS)
    var externalDisplayOnTop = UserDefaults.standard.bool(forKey: UserDefaults.Key.externalDisplayOnTop) {
        didSet { didSetExternalDisplay(externalDisplayOnTop, forKey: UserDefaults.Key.externalDisplayOnTop) }
    }
    var externalDisplayOnBottom = UserDefaults.standard.bool(forKey: UserDefaults.Key.externalDisplayOnBottom) {
        didSet { didSetExternalDisplay(externalDisplayOnBottom, forKey: UserDefaults.Key.externalDisplayOnBottom) }
    }
    var externalDisplayOnLeft = UserDefaults.standard.bool(forKey: UserDefaults.Key.externalDisplayOnLeft) {
        didSet { didSetExternalDisplay(externalDisplayOnLeft, forKey: UserDefaults.Key.externalDisplayOnLeft) }
    }
    var externalDisplayOnRight = UserDefaults.standard.bool(forKey: UserDefaults.Key.externalDisplayOnRight) {
        didSet { didSetExternalDisplay(externalDisplayOnRight, forKey: UserDefaults.Key.externalDisplayOnRight) }
    }
    var externalDisplaySeemlessMode = UserDefaults.standard.bool(forKey: UserDefaults.Key.externalDisplaySeemlessMode) {
        didSet { UserDefaults.standard.set(externalDisplaySeemlessMode, forKey: UserDefaults.Key.externalDisplaySeemlessMode) }
    }
    #endif

    var nearbyInteractionRoleValue = UserDefaults.standard.string(forKey: UserDefaults.Key.nearbyInteractionRole) ?? "" {
        didSet { UserDefaults.standard.set(nearbyInteractionRoleValue, forKey: UserDefaults.Key.nearbyInteractionRole) }
    }

    // MARK: - Working copies

    /// The seed the text field is editing. Only reaches the room once ``saveSeed()`` parses it, so a half-typed
    /// number never restyles anything.
    var seedCopy = String(Space_UI.system.seed)
    /// Working copy of the design principles the sliders edit, committed by ``commitDesignPrinciples()``.
    /// Kept apart from `designPrinciples` so a drag doesn't rebuild the theme on every intermediate value.
    var editingPrinciples = AppSettingsModel.storedDesignPrinciples
    var primaryColor = Space_UI.system.colors.color(.primary, opacity: .max)

    // MARK: - Peer session status

    private var peerSessionController: PeerSessionController { .shared }

    /// Whether this device is a joiner, and so must take the host's seed rather than choose its own.
    var isLocked: Bool {
        !peerSessionController.connectedPeerIDs.isEmpty && !peerSessionController.isHost
    }

    /// Whether `syncOverNetworkBody` would read "Disabled" — kept separate so callers don't have to compare
    /// against the (potentially localized) display text.
    var isSyncDisabled: Bool {
        peerSessionController.connectedPeerIDs.isEmpty && !peerSessionController.canHost && !peerSessionController.canJoin
    }

    var syncOverNetworkBody: LocalizedStringResource {
        if peerSessionController.connectedPeerIDs.isEmpty {
            switch (peerSessionController.canHost, peerSessionController.canJoin) {
            case (true, true):
                return "Looking to host/join..."
            case (true, false):
                return "Looking to host..."
            case (false, true):
                return "Looking to join..."
            case (false, false):
                return "Disabled"
            }
        } else if peerSessionController.isHost {
            return "Hosting \(peerSessionController.connectedPeerIDs.count) Peers"
        } else {
            return "Connected To Peers"
        }
    }

    // MARK: - Editing

    func principleBinding(_ axis: DesignPrinciples.Axis) -> Binding<Double> {
        Binding(
            get: { [self] in axis.get(editingPrinciples) },
            set: { [self] in axis.set(&editingPrinciples, $0) }
        )
    }

    /// Promotes the sliders' and colour picker's working copies to the saved settings.
    func commitDesignPrinciples() {
        designPrinciples = editingPrinciples
        let hsb = primaryColor.getHSB()
        primaryHue = hsb.hue
        primarySaturation = hsb.saturation
    }

    func randomizeSeed() {
        seedCopy = String(arc4random())
        saveSeed()
    }

    func saveSeed() {
        guard let newSeed = UInt64(seedCopy), newSeed != Space_UI.system.seed else { return }

        let newConfig = Config(
            seed: newSeed,
            designPrinciples: savedDesignPrinciples,
            primaryHue: savedPrimaryHue,
            primarySaturation: savedPrimarySaturation
        )
        AppController.shared.applyConfig(newConfig, broadcast: true)
    }

    /// Re-reads the theme-derived working copies after the theme is rebuilt — a new seed typed here, a config
    /// received from the host, or a regenerate. Called from the `system` global's `didSet`, which is the one
    /// choke point every theme change passes through; the views can't do it themselves now that this state
    /// outlives the subtree the root rebuilds on `AppController.configID`.
    func refreshFromTheme() {
        seedCopy = String(Space_UI.system.seed)
        primaryColor = Space_UI.system.colors.color(.primary, opacity: .max)
    }

    #if !os(visionOS)
    /// The shared tail of every external-display toggle: which edges are "connected" changes the screen shape
    /// itself, so the cached paths and the whole root have to go.
    private func didSetExternalDisplay(_ isOn: Bool, forKey key: String) {
        UserDefaults.standard.set(isOn, forKey: key)
        ScreenShape.pathCache.removeAll()
        AppController.shared.reloadRootView()
    }
    #endif

}
