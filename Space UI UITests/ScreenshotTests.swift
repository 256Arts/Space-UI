// Created by 256 Arts Developer on 2026-09-03.

import XCTest
#if canImport(UIKit)
import UIKit
#endif

/// Photographs the pages that become App Store screenshots and hands each one to the shared `screenshots`
/// runner.
///
/// A launch per page rather than one walk through the app's own navigation. Two reasons, and the second is
/// the important one:
///
/// The buttons that would carry a walk are generated from the seed — shape, size, and position all change
/// with it — and several themes draw them where a synthesized click does not land. Naming the page in the
/// launch arguments photographs the same screens whatever the seed decides they should look like.
///
/// And a launch per page means a *seed* per page. The product page is then four different generated
/// interfaces rather than four views of one, which is the thing being sold: there is no fixed look, and a
/// shopper scrolling the shots should see that before reading a word of the description.
@MainActor
final class ScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    /// Whether the walk turned the device on its side, which the capture has to undo.
    ///
    /// Tracked here rather than read back from `XCUIDevice.shared.orientation`, which a simulator
    /// answers as portrait however the UI is laid out.
    private var isLandscape = false

    /// The pages that become the product page, in the order they appear on it, each with the seed its theme
    /// is generated from.
    ///
    /// The seeds are picked for how the shot reads, not for anything the numbers mean — swap one and re-run
    /// to try another look for that page. None may generate a hexagon or triangle screen shape — they crop the
    /// page too hard for a first look — and `-appLaunchCount` below keeps the shape a property of the seed alone.
    /// `SCREENSHOT_SEEDS=<comma-separated>` overrides the whole column for a run, so a set can be shopped
    /// without an edit here:
    ///
    ///     TEST_RUNNER_SCREENSHOT_SEEDS=1,2,3,4 Scripts/screenshots.sh mac
    private static let pages: [(page: String, name: String, seed: String)] = zip(
        [
            ("galaxy", "01-galaxy"),
            ("lockScreen", "02-lock-screen"),
            ("planet", "03-planet"),
            ("nearby", "04-nearby"),
        ],
        seeds
    ).map { ($0.0, $0.1, $1) }

    private static var seeds: [String] {
        let chosen = ["31", "21", "38", "1"]   // screens: lime cropped circle, amber capsule, violet trapezoid, pink capsule
        guard let overridden = ProcessInfo.processInfo.environment["SCREENSHOT_SEEDS"] else { return chosen }
        return overridden.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    func testCaptureAppStoreScreenshots() throws {
        continueAfterFailure = false

        for (page, name, seed) in Self.pages {
            app = XCUIApplication()
            app.launchArguments = Self.launchArguments + [ScreenshotMode.pageArgument, page, "-seed", seed]
            app.launch()
            #if os(iOS)
            turnToRequestedOrientation()
            #endif
            app.activate()   // the Mac shot is of the frontmost window, so make sure this is it
            checkSeedIsThrowaway()

            // Every one of these pages draws at least one navigation button, so the first to exist is proof
            // the theme has been generated and the page drawn — the capture cannot beat it onto the screen.
            let drawn = app.buttons.element(boundBy: 0)
            waitFor(drawn, "\(page)'s first button", shot: name, timeout: 60)
            #if targetEnvironment(macCatalyst)
            settle(seconds: 4)   // the Mac window also animates into full screen; see ScreenshotMode.prepareMacWindows
            #else
            settle()
            #endif
            capture(name)

            app.terminate()
        }
    }

    /// Mirrors `ScreenshotMode` in the app, which the test target cannot import.
    private enum ScreenshotMode {
        static let launchArgument = "-screenshotMode"
        static let pageArgument = "-screenshotPage"
    }

    // MARK: - The seed

    /// What the app said it prepared, read out of the accessibility tree.
    ///
    /// The app hangs `ScreenshotMode.status` on its root view (`.screenshotModeStatus()`). A walk that
    /// cannot find it is running against a build that has not adopted that modifier, which is worth
    /// saying plainly rather than reporting as an empty seed.
    private var seedStatus: String {
        let label = app.descendants(matching: .any)["ScreenshotMode.Status"]
        guard label.waitForExistence(timeout: 30) else {
            return "no ScreenshotMode.Status element — add .screenshotModeStatus() to the app's root view"
        }
        // A SwiftUI `Text` reaches XCUITest as the element's *value* on macOS and as its *label* on iOS,
        // so take whichever is filled in rather than betting on one.
        if let value = label.value as? String, !value.isEmpty { return value }
        return label.label
    }

    /// Stops the walk when the app did not report itself ready.
    ///
    /// `ScreenshotMode.status` refuses — and says why — when `-screenshotPage` is missing or names
    /// no known `Page`. The walk that followed would then wait on the wrong screen and fail on a missing
    /// button, which says nothing about why. Read the reason instead, before the first wait.
    private func checkSeedIsThrowaway() {
        let status = seedStatus
        print("SCREENSHOT MODE: \(status)")
        guard status.hasPrefix("ready") else {
            attach(XCTAttachment(string: app.debugDescription), named: "element-tree")
            return XCTFail("the app did not report itself ready — \(status)")
        }
    }

    private static var platform: String {
        #if targetEnvironment(macCatalyst)
        "Mac Catalyst"
        #elseif os(visionOS)
        "visionOS"
        #else
        UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS" : "iOS"
        #endif
    }

    /// Which simulator this was, for a failure read days after the run's own log is gone.
    private static var device: String {
        ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "this machine"
    }

    // MARK: - The run's settings

    /// What the app is launched with.
    ///
    /// Everything after `-screenshotMode` is a `UserDefaults` key: launch arguments land in the argument
    /// domain, which is read ahead of the app's own defaults and never written to disk. The run therefore
    /// leaves no trace, which matters because the Mac build shares its container with the copy of the app
    /// the developer actually uses — writing these would overwrite their saved seed and settings.
    private static var launchArguments: [String] {
        [
            ScreenshotMode.launchArgument,

            // `-seed` is appended per page; see `pages`.

            // Let the seed alone decide the look, rather than whatever this machine was last set to.
            "-applyDesignPrinciples", "NO",
            "-extraFonts", "NO",
            "-screenShapeOverride", "",
            // `ScreenStyles` adds the circle and triangle screen shapes from the third launch on, so without
            // this a seed's shape would depend on how often that device has run the app. Shoot what a new
            // user sees.
            "-appLaunchCount", "1",

            "-tutorialShown", "YES",          // an alert over the lock screen otherwise — the first shot
            "-randomEmergencies", "NO",       // recolours a page red and opens a puzzle over the walk
            // A real device on the same network would connect and push its own theme mid-walk, and asking
            // for local network access puts a system alert in the shot.
            "-canHostSession", "NO",
            "-canJoinSession", "NO",
            // A capture run is unattended, and often several simulators at once.
            "-playAmbience", "NO",
            "-playEnvironmental", "NO",
            "-playSounds", "NO",
        ]
    }

    // MARK: - Driving

    /// Waits for `element`, failing with the platform, the device, what was expected, and what the app
    /// reported it prepared — so a miss during `shot` says why, not just that something never appeared.
    private func waitFor(_ element: XCUIElement, _ description: String, shot: String, timeout: TimeInterval = 30) {
        guard element.waitForExistence(timeout: timeout) else {
            attach(XCTAttachment(string: app.debugDescription), named: "element-tree")
            return XCTFail("""
                \(shot): never found \(description) in \(Int(timeout))s on \(Self.platform), \(Self.device).
                The app reported: \(seedStatus)
                """)
        }
    }

    #if os(iOS)
    /// Turns the device the way the runner asked (`IPAD_ORIENTATION`, landscape by default on iPad).
    ///
    /// After `launch()`, not before: a rotation set before the app is up is silently dropped, and
    /// the set comes back portrait. The runner checks every shot's shape, so that fails the run.
    private func turnToRequestedOrientation() {
        guard ProcessInfo.processInfo.environment["SCREENSHOT_ORIENTATION"] == "landscape" else { return }
        XCUIDevice.shared.orientation = .landscapeLeft
        isLandscape = true
        settle()
    }
    #endif

    /// The pages animate in — rings spin up, the radar sweeps, the galaxy drifts — and none of it has an
    /// element to wait on, so the shots pause instead.
    private func settle(seconds: TimeInterval = 2) {
        Thread.sleep(forTimeInterval: seconds)
    }

    // MARK: - Capturing

    /// Where the Mac and visionOS shots are asked for. The runner watches this directory; see
    /// `requestExternalCapture(named:)`.
    private static let handshakeDirectory = URL(fileURLWithPath: "/tmp/app-store-screenshots")

    /// Whether this platform's shot is taken from outside the app.
    ///
    /// iPhone and iPad are photographed from inside, because the simulator's screen already *is* the store's
    /// canvas at the exact pixel size it wants. The other two are not: a Mac window has to be captured with
    /// its shadow and rounded corners, and visionOS has no screen for `XCUIScreen.main` to return.
    private var capturesExternally: Bool {
        #if targetEnvironment(macCatalyst) || os(visionOS)
        true
        #else
        false
        #endif
    }

    private func capture(_ name: String) {
        // Every capture below photographs the whole screen, or the frontmost window — never this
        // app in particular. So an app that has lost the foreground yields another app's UI, filed
        // under this app's name, at the right size, with nothing to notice. The shared runner holds
        // a machine-wide lock so that cannot happen; this is the check that it held.
        XCTAssertEqual(app.state, .runningForeground,
                       "\(name): the app under test was not frontmost — another app has this device")
        if capturesExternally, requestExternalCapture(named: name) { return }
        attach(upright(XCUIScreen.main.screenshot()), named: name)
    }

    /// The screenshot, turned the way the device is being held.
    ///
    /// `XCUIScreen.main.screenshot()` photographs the *physical* screen: a rotated device comes back
    /// as a portrait buffer carrying its quarter turn as metadata, which `XCTAttachment(screenshot:)`
    /// writes out content-on-its-side. Redrawing bakes the metadata into the pixels — `UIImage.size`
    /// is already the turned size and `draw(at:)` honours the orientation, so no manual rotation.
    private func upright(_ screenshot: XCUIScreenshot) -> XCTAttachment {
        #if os(iOS)
        guard isLandscape else { return XCTAttachment(screenshot: screenshot) }
        let image = screenshot.image
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale   // keep the pixel count the store checks against
        format.opaque = true
        return XCTAttachment(image: UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(at: .zero)
        })
        #else
        XCTAttachment(screenshot: screenshot)
        #endif
    }

    private func attach(_ attachment: XCTAttachment, named name: String) {
        attachment.name = name
        attachment.lifetime = .keepAlways   // attachments on a passing test are discarded otherwise
        add(attachment)
    }

    /// Asks the shell running the tests to photograph the app, and waits for it.
    ///
    /// The good Mac capture is `screencapture -l`, which reads the window's own buffer: correctly masked to
    /// the rounded corners, with real alpha and the system's own shadow. (`XCUIElement.screenshot()` crops
    /// the *screen* to the window's frame, so it loses the shadow — drawn outside that frame — and leaves
    /// desktop inside the corners.) But `screencapture` needs Screen Recording, which the test runner has no
    /// grant for and the terminal running the script does. So the test drives the UI and the script takes
    /// the picture. visionOS goes the same way for a different reason: `simctl io screenshot` returns the
    /// whole simulated view at the store's size, where the app's own window comes back at the window's size.
    ///
    /// They meet in a plain directory under /tmp, which works only because the runner is deliberately
    /// unsandboxed ("Space UI UITests/UITests.entitlements"): a sandboxed runner cannot write /tmp, and its
    /// own container is unreadable to the script, so the two would have nowhere to meet.
    ///
    /// - Returns: whether the shot was taken. A simulator that cannot reach the host's /tmp reports `false`
    ///   so the caller falls back to an attachment, rather than failing a run over the wrong-sized shot.
    private func requestExternalCapture(named name: String) -> Bool {
        let files = FileManager.default
        let handshake = Self.handshakeDirectory
        guard files.fileExists(atPath: handshake.path) else {
            #if targetEnvironment(macCatalyst)
            XCTFail("\(handshake.path) does not exist — is Scripts/screenshots.sh running?")
            #endif
            return false
        }

        let done = handshake.appendingPathComponent("done-\(name)")
        try? files.removeItem(at: done)

        let request = handshake.appendingPathComponent("request-\(name)")
        guard files.createFile(atPath: request.path, contents: nil) else {
            #if targetEnvironment(macCatalyst)
            XCTFail("could not write a capture request to \(request.path)")
            #endif
            return false
        }

        let deadline = Date().addingTimeInterval(30)
        while Date() < deadline {
            if files.fileExists(atPath: done.path) { return true }
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTFail("timed out waiting for the script to capture \(name) — is the runner watching \(handshake.path)?")
        return false
    }

}
