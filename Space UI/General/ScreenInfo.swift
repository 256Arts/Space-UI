// Created by 256 Arts Developer on 2026-08-23.

import SwiftUI

// tvOS asks none of these questions — it has one fixed, full-bleed screen, so nothing there consults a screen
// snapshot or overrides brightness. Compiled out rather than carried as a target membership exception.
#if !os(tvOS)

#if !os(visionOS)
extension UIScreen {
    @MainActor
    static var current: UIScreen? {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.screen }
            .first
    }

    /// The user's brightness captured the first time story mode forced the screen to full, so it can be
    /// restored when they leave the app. `nil` while we aren't overriding.
    @MainActor
    private static var brightnessBeforeStoryOverride: CGFloat?

    /// Forces the screen to full brightness for the live story show, remembering the user's original
    /// brightness the first time so ``restoreUserBrightness()`` can put it back on exit.
    @MainActor
    static func forceFullBrightnessForStory() {
        guard let screen = current else { return }
        if brightnessBeforeStoryOverride == nil {
            brightnessBeforeStoryOverride = screen.brightness
        }
        screen.brightness = 1
    }

    /// Restores the brightness captured before story mode overrode it. No-op if we never overrode.
    @MainActor
    static func restoreUserBrightness() {
        guard let saved = brightnessBeforeStoryOverride else { return }
        current?.brightness = saved
        brightnessBeforeStoryOverride = nil
    }
}
#endif

/// Sendable snapshot of `UIScreen.current` properties, safe to read from any actor.
/// Refreshed from the main actor (see `UIRootView`) whenever screen state may have changed.
struct ScreenInfo: Sendable {
    let bounds: CGRect
    let traitCollection: UITraitCollection
    /// The key window's, so the screen shape can tell a display that is inset on one side only (the iPhone Duo's
    /// outer screen, flat on its hinge edge) from the usual symmetric ones.
    let safeAreaInsets: UIEdgeInsets

    private static let lock = NSLock()
    nonisolated(unsafe) private static var _current = ScreenInfo(bounds: .zero, traitCollection: UITraitCollection(), safeAreaInsets: .zero)

    static var current: ScreenInfo {
        lock.lock(); defer { lock.unlock() }
        return _current
    }

    @MainActor
    static func refresh() {
        #if os(visionOS)
        // No UIScreen on visionOS: snapshot the key window instead.
        let window = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
        let snapshot = ScreenInfo(
            bounds: window?.bounds ?? .zero,
            traitCollection: window?.traitCollection ?? UITraitCollection(),
            safeAreaInsets: window?.safeAreaInsets ?? .zero
        )
        #else
        let screen = UIScreen.current
        let window = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
        let snapshot = ScreenInfo(
            bounds: screen?.bounds ?? .zero,
            traitCollection: screen?.traitCollection ?? UITraitCollection(),
            safeAreaInsets: window?.safeAreaInsets ?? .zero
        )
        #endif
        lock.lock()
        _current = snapshot
        lock.unlock()
    }
}

#endif
