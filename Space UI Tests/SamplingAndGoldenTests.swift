import Testing
import Foundation
import CoreGraphics
@testable import Space_UI

/// Poisson-disk sampling backs several decorative layouts. The one hard requirement is that it always terminates
/// (an unbounded retry loop would freeze the main thread once the disk saturates) and stays deterministic per seed.
struct PoissonDiskSamplingTests {

    @Test
    func terminatesWhenDiskSaturates() {
        // minRadius 40 in a 100×100 rect saturates almost immediately; the point is it returns rather than hanging.
        let samples = PoissonDiskSampling.takeSamples(
            in: CGRect(x: 0, y: 0, width: 100, height: 100),
            inCircle: false,
            existingPoints: [],
            tryCount: 5_000,
            minRadius: 40,
            random: SeededRandom(seed: 42)
        )
        #expect(samples.count <= 5_000)
    }

    @Test(arguments: [1, 7, 42, 100] as [UInt64])
    func isDeterministicPerSeed(seed: UInt64) {
        func run() -> [CGPoint] {
            PoissonDiskSampling.takeSamples(
                in: CGRect(x: 0, y: 0, width: 400, height: 400),
                inCircle: true,
                existingPoints: [],
                tryCount: 30,
                minRadius: 20,
                random: SeededRandom(seed: seed)
            )
        }
        let a = run()
        let b = run()
        #expect(a.count == b.count)
        #expect(zip(a, b).allSatisfy { $0 == $1 })
    }
}

/// Golden values for a handful of pinned seeds catch *unintended* generation drift — e.g. a "seed v2" refactor that
/// was only meant to change the RNG accidentally shifting an unrelated shape choice. If a change here is deliberate,
/// re-capture with `printCurrentDigests` and paste the new values in. Captured on a simulator run 2026-11-11, after
/// the alien-script font joined the font pick — a deliberate stream shift, so every field after it moved.
///
/// Serialized: `SystemStyles.init` assigns the global `screen` as a side effect, and the digest reads that
/// global back. Run in parallel, one case's construction overwrote `screen` between another case constructing
/// its own and reading it, so a couple of seeds reported someone else's screen shape and failed.
@MainActor
@Suite(.serialized)
struct GoldenSeedTests {

    nonisolated static let expected: [UInt64: String] = [
        1: "shape=circle;dir=up;corner=circular;roundFrac=0.1669;lineCap=1;medLine=5.2856;btnMode=fixed;btnW=84.0000;btnH=84.0000;font=Galactico;fontSize=20.0000;borders=true;btnBorders=true;dashed=false;action=action2;button=button2;alarm=alarmLoop;palette=limited;light=false;screenShape=capsule;cutout=curved;filter=signalNoise;bg=color",
        42: "shape=square;dir=up;corner=rounded;roundFrac=0.1878;lineCap=1;medLine=2.8577;btnMode=flexible;btnW=90.0000;btnH=56.0000;font=SpaceUIAlien11714729386585084922;fontSize=20.0000;borders=true;btnBorders=false;dashed=false;action=action;button=button2;alarm=alarmLoop;palette=colorful;light=false;screenShape=rectangle;cutout=curved;filter=hLines;bg=color",
        1_000: "shape=hexagon;dir=up;corner=rounded;roundFrac=0.1746;lineCap=1;medLine=5.3301;btnMode=fixed;btnW=94.0000;btnH=94.0000;font=Galactico;fontSize=20.0000;borders=true;btnBorders=false;dashed=true;action=action;button=button;alarm=alarmLoop;palette=monochrome;light=false;screenShape=capsule;cutout=roundedRectangle;filter=signalNoise;bg=gradientDown",
        65_535: "shape=hexagon;dir=up;corner=rounded;roundFrac=0.1379;lineCap=0;medLine=5.3650;btnMode=fixed;btnW=94.0000;btnH=94.0000;font=ClyneseBend;fontSize=22.0000;borders=false;btnBorders=false;dashed=false;action=action2;button=button;alarm=alarmLoop;palette=limited;light=false;screenShape=trapezoid;cutout=roundedAngle45;filter=signalNoise;bg=gradientUp"
    ]

    /// `ScreenStyles` withholds the circle and triangle screen shapes until the third launch, and the test host is
    /// a real app launch that bumps that counter — so a digest captured on a fresh simulator silently disagreed
    /// with one captured after a few runs. Pin the counter past the threshold: a golden must fingerprint the seed
    /// alone, which is the contract `ThemeDigest` already claims. Runs before each case (a fresh suite instance).
    init() {
        UserDefaults.standard.set(3, forKey: UserDefaults.Key.appLaunchCount)
    }

    @Test(arguments: GoldenSeedTests.expected.sorted { $0.key < $1.key }.map { ($0.key, $0.value) })
    func pinnedSeedMatchesGolden(seed: UInt64, golden: String) {
        let system = SystemStyles(config: .seedOnly(seed))
        #expect(ThemeDigest.current(system, system.screen) == golden, "Theme drift for seed \(seed)")
    }

    /// Recapture helper: enable, run in Xcode, and copy the printed lines into `expected` above when a theme change
    /// is intentional. Disabled by default so it doesn't fail the suite (it deliberately records issues).
    @Test(.disabled("Enable only to re-capture golden digests after an intentional theme change"))
    func printCurrentDigests() {
        for seed in Self.expected.keys.sorted() {
            let system = SystemStyles(config: .seedOnly(seed))
            Issue.record("\(seed): \"\(ThemeDigest.current(system, system.screen))\",")
        }
    }
}
