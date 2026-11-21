import Testing
import SwiftUI
@testable import Space_UI

/// A stable fingerprint of a drawn `Path`. Every element is recorded in draw order with its points rounded to
/// three decimals (and -0 folded into 0), then folded into one FNV-1a hash — short enough to paste into a golden table, precise enough
/// that a single misplaced corner changes it. Rounding absorbs the last-bit float noise an arc's flattening can
/// produce across compilers; anything a person could see moves well past 0.001pt.
enum ScreenPathDigest {

    static func current(_ path: Path) -> String {
        var description = ""
        var elementCount = 0
        path.forEach { element in
            elementCount += 1
            switch element {
            case .move(let to):
                description += "M\(string(to))"
            case .line(let to):
                description += "L\(string(to))"
            case .quadCurve(let to, let control):
                description += "Q\(string(to))\(string(control))"
            case .curve(let to, let control1, let control2):
                description += "C\(string(to))\(string(control1))\(string(control2))"
            case .closeSubpath:
                description += "Z"
            }
        }
        return "\(elementCount)/\(hash(of: description))"
    }

    /// Folds many per-path digests into one, so a golden table stays a line per shape instead of a page per shape.
    static func combined(_ digests: [String]) -> String {
        "\(digests.count)/\(hash(of: digests.joined(separator: "|")))"
    }

    private static func string(_ point: CGPoint) -> String {
        String(format: "(%.3f,%.3f)", normalized(point.x), normalized(point.y))
    }

    /// Rounds to the digest's precision and folds -0 into 0. An arc written as starting at -2π rather than 0 lands
    /// on the same point but reports a negative zero — a formatting difference, not a geometric one.
    private static func normalized(_ value: CGFloat) -> Double {
        (Double(value) * 1_000).rounded() / 1_000 + 0.0
    }

    private static func hash(of string: String) -> String {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100_0000_01b3
        }
        return String(format: "%016llx", hash)
    }
}

/// Golden snapshots of what `ScreenShape` actually draws. `CutoutGeometryTests` pins the cutout *metrics*; these
/// pin the path itself, which is the only thing that catches a geometry fold placing a corner subtly wrong — the
/// shape is procedural, so there is no screenshot anyone eyeballs and no seed a person would notice regressing.
///
/// One digest per `ScreenShapeType`, covering every seed × size × connected-edge × inset combination below, so a
/// failure names the shape branch that moved. If a change here is deliberate, re-capture with
/// `printCurrentDigests` and paste the new values in.
///
/// Serialized for the same reason as `GoldenSeedTests`: `SystemStyles.init` writes the global `screen`.
@MainActor
@Suite(.serialized)
struct ScreenPathGoldenTests {

    static let sizes: [CGSize] = [
        CGSize(width: 800, height: 1_200),
        CGSize(width: 1_200, height: 1_600),
        CGSize(width: 1_600, height: 900),
        CGSize(width: 2_400, height: 1_080)
    ]
    static let connectedEdgeCases: [[RectEdge]] = [[], [.right], [.left, .right]]
    static let insetAmounts: [CGFloat] = [0, 6]

    /// Re-captured on an iOS 27 simulator run 2026-10-27, after `cutoutLayout` started measuring the shape type being
    /// drawn instead of the seed's raw one. The shapes with a straight cutout edge moved (`rectangle` too, because this
    /// matrix draws each type under seeds whose own type differs); `circle`, `triangle` and `verticalHexagon` didn't.
    // Cropped shapes re-captured 2026-10-31 after fixing edge coverage and adding croppedSquircle.
    // All re-captured 2026-11-11: the alien-script font's draw shifted every seed's screen styles, not the geometry.
    nonisolated static let expected: [String: String] = [
        "rectangle": "288/9b7435303c3341ea",
        "capsule": "288/b3225629024380e9",
        "circle": "288/9265650951ce20db",
        "croppedCircle": "288/30d30af7836ecdf1",
        "croppedSquircle": "288/50f27a21015d58f7",
        "verticalHexagon": "288/b472dc3599f96d4e",
        "horizontalHexagon": "288/696e3b1bb18a1575",
        "trapezoid": "288/a6ec1d7122c58d17",
        "triangle": "288/294c6f75e2a11442"
    ]

    /// `ScreenStyles` withholds the circle and triangle screen shapes until the third launch, and the test host is
    /// a real app launch that bumps that counter. Pin it past the threshold so a digest fingerprints the seed
    /// alone — same reason as `GoldenSeedTests`.
    init() {
        UserDefaults.standard.set(3, forKey: UserDefaults.Key.appLaunchCount)
    }

    /// Digest of every path drawn for one screen shape, across the whole seed/size/edge/inset matrix. The shape
    /// type is passed explicitly rather than taken from the seed's own `screenShapeType`, so a dozen seeds cover
    /// all shape branches instead of only the ones they happen to generate.
    static func digest(for screenShapeType: ScreenShapeType) -> String {
        var digests = [String]()
        for seed in TestSeeds.representative {
            let system = SystemStyles(config: .seedOnly(seed))
            for size in sizes {
                for connectedEdges in connectedEdgeCases {
                    for insetAmount in insetAmounts {
                        let shape = ScreenShape(
                            system: system,
                            screenStyles: system.screen,
                            screenShapeType: screenShapeType,
                            connectedEdges: connectedEdges,
                            insetAmount: insetAmount
                        )
                        let path = shape.path(in: CGRect(origin: .zero, size: size))
                        digests.append(ScreenPathDigest.current(path))
                    }
                }
            }
        }
        return ScreenPathDigest.combined(digests)
    }

    @Test(arguments: ScreenShapeType.allCases)
    func drawnPathMatchesGolden(screenShapeType: ScreenShapeType) throws {
        let golden = try #require(Self.expected[screenShapeType.rawValue], "No golden recorded for \(screenShapeType.rawValue)")
        #expect(Self.digest(for: screenShapeType) == golden, "Screen path drift for \(screenShapeType.rawValue)")
    }

    /// Recapture helper: enable, run in Xcode, and copy the printed lines into `expected` above when a geometry
    /// change is intentional. Disabled by default so it doesn't fail the suite (it deliberately records issues).
    @Test(.disabled("Enable only to re-capture golden path digests after an intentional geometry change"))
    func printCurrentDigests() {
        for screenShapeType in ScreenShapeType.allCases {
            Issue.record("\"\(screenShapeType.rawValue)\": \"\(Self.digest(for: screenShapeType))\",")
        }
    }
}
