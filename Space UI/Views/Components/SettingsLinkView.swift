// Created by 256 Arts Developer on 2026-11-13.

import StoreKit
import SwiftUI

/// One `SettingsLink`, as both settings surfaces draw it. A link to one of our apps opens its product page in the
/// App Store's own sheet over Space UI, so following it doesn't drop the person out of the app; anything else, and
/// visionOS (which has no in-app product sheet), opens the URL.
struct SettingsLinkView: View {

    let link: SettingsLink

    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            #if os(visionOS)
            openURL(link.url)
            #else
            if let appStoreID = link.appStoreID {
                AppStoreProductSheet.present(appStoreID: appStoreID) { openURL(link.url) }
            } else {
                openURL(link.url)
            }
            #endif
        } label: {
            Label {
                Text(link.title)
            } icon: {
                Image(systemName: link.systemImage)
            }
        }
    }

}

#if !os(visionOS)
/// `SKStoreProductViewController`, which SwiftUI has no modifier for (`appStoreOverlay` is the banner, not the page).
@MainActor
private enum AppStoreProductSheet {

    /// The controller dismisses only when its delegate tells it to.
    private final class Delegate: NSObject, SKStoreProductViewControllerDelegate {
        func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
            viewController.presentingViewController?.dismiss(animated: true)
        }
    }

    private static let delegate = Delegate()

    /// Presents over whatever is frontmost in the active window — the inspector is itself presented — and calls
    /// `fallback` if there's nothing to present from or the page fails to load.
    static func present(appStoreID: Int, fallback: @escaping () -> Void) {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .keyWindow
        guard var presenter = window?.rootViewController else {
            fallback()
            return
        }
        while let presented = presenter.presentedViewController {
            presenter = presented
        }

        let controller = SKStoreProductViewController()
        controller.delegate = delegate
        // Shown at once, loading, rather than after the load, so the tap answers immediately.
        presenter.present(controller, animated: true)
        controller.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: appStoreID]) { loaded, _ in
            guard !loaded else { return }
            Task { @MainActor in
                controller.presentingViewController?.dismiss(animated: true)
                fallback()
            }
        }
    }

}
#endif
