// Created by 256 Arts Developer on 2026-09-03.

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// The App Store screenshot run, switched on by the `-screenshotMode` launch argument the UI test passes.
///
/// There is no stored content to seed here — every pixel is generated from one `UInt64` seed — so the run's
/// "demo data" is that seed plus the settings that would otherwise make two runs differ: the first-run
/// tutorial alert over the lock screen, a random emergency recolouring a page red mid-walk, and the peer
/// session finding a real device on the same network and adopting *its* theme.
///
/// Those all arrive as launch arguments, which land in `UserDefaults`' argument domain: read like any other
/// default, ahead of everything else, and never written to disk. That matters more here than it looks — the
/// Mac build shares its container with the copy of the app the developer actually uses, so a run that *set*
/// these would quietly overwrite their saved seed and settings. See `ScreenshotTests.launchArguments`.
enum ScreenshotMode {

    static let launchArgument = "-screenshotMode"

    static let pageArgument = "-screenshotPage"

    /// Whether this launch is a screenshot run.
    static let isActive = ProcessInfo.processInfo.arguments.contains(launchArgument)

    /// The page this launch is meant to photograph, as a `Page` raw value.
    ///
    /// The walk is one launch per page rather than a tour through the app's own navigation, because the
    /// buttons that would carry it are generated: their shape, size, and position all come from the seed,
    /// and several themes draw them where a synthesized click does not reach them. Naming the page outright
    /// photographs the same screens whatever the seed decides they should look like.
    static var page: String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: pageArgument), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }

    // MARK: - Saying what happened

    /// What this launch is showing, in one line, for the walk and for the shared runner.
    ///
    /// A failed walk otherwise reports only "seeded content never appeared", which is equally true of a
    /// run that never resolved a page, a screen that never opened, and an identifier renamed last week.
    /// The walk reads this out of the accessibility tree before its first wait and prints it on any miss.
    ///
    /// Derived from the launch arguments alone — there is no store to seed, every pixel comes from `-seed`
    /// — so it is already true on the first frame. It also catches the one quiet failure this mode has: a
    /// page name that does not resolve, which would otherwise fall back to `.defaultPage` and leave the
    /// walk waiting on a screen nobody asked to photograph.
    static var status: String {
        guard let rawValue = page else {
            return "REFUSED — -screenshotMode was passed without -screenshotPage, so there is no page to show"
        }
        guard let resolved = Page(rawValue: rawValue) else {
            return "REFUSED — -screenshotPage \(rawValue) is not a known Page case"
        }
        return "ready — pinned defaults, page \(resolved.rawValue), seed \(seed)"
    }

    #if targetEnvironment(macCatalyst)

    /// Leaves the Mac showing exactly one window, in full screen.
    ///
    /// macOS restores the window layout of the last session, so a run that follows one where the app was left
    /// with the paired left/right windows open finds two — merged into a tab group, with the second one's
    /// controls in the accessibility tree but its content behind the tab bar. The walk then taps a button in a
    /// window the camera is not pointed at.
    @MainActor
    static func prepareMacWindows() {
        guard isActive else { return }

        let application = UIApplication.shared
        let scenes = application.connectedScenes.compactMap { $0 as? UIWindowScene }
        let kept = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        for scene in scenes where scene !== kept {
            application.requestSceneSessionDestruction(scene.session, options: nil)
        }

        // After the tab group has come apart: a window still merged into one would take the tabs with it.
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            enterFullScreen()
        }
    }

    /// Puts the app's window in full screen, the way the app is meant to be seen: no title bar, no rounded
    /// corners, the console filling the display.
    ///
    /// UIKit has no call for it, so this reaches the `NSWindow` underneath through AppKit's own selectors.
    /// The window is also made non-restorable, so a run leaves no full-screen state behind for the copy of
    /// the app the developer actually uses, which shares this container.
    @MainActor
    private static func enterFullScreen() {
        guard let appKit = NSClassFromString("NSApplication") as? NSObject.Type,
              let app = appKit.value(forKey: "sharedApplication") as? NSObject,
              let windows = app.value(forKey: "windows") as? [NSObject] else { return }
        let fullScreenMask: UInt = 1 << 14   // NSWindowStyleMaskFullScreen
        for window in windows where (window.value(forKey: "isVisible") as? Bool) == true {
            window.setValue(false, forKey: "restorable")
            let styleMask = window.value(forKey: "styleMask") as? UInt ?? 0
            if styleMask & fullScreenMask == 0 {
                window.perform(NSSelectorFromString("toggleFullScreen:"), with: nil)
            }
        }
    }

    #endif

}

extension View {

    /// Carries `ScreenshotMode.status` into the accessibility tree, where the walk reads it.
    ///
    /// Nothing on a normal launch; on a screenshot run, a one-point transparent label — present to
    /// XCUITest, invisible in the shot. It is how the walk can tell a run that never resolved its page
    /// from a screen that never opened, neither of which the app can report any other way: a simulator
    /// app's `print` does not reach the build log, and there is no file path both the app and the runner
    /// can write.
    @MainActor
    @ViewBuilder
    func screenshotModeStatus() -> some View {
        if ScreenshotMode.isActive {
            overlay(alignment: .topLeading) {
                Text(ScreenshotMode.status)
                    .font(.system(size: 1))
                    .opacity(0.001)
                    .accessibilityIdentifier("ScreenshotMode.Status")
                    .allowsHitTesting(false)
            }
        } else {
            self
        }
    }
}
