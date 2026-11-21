import Foundation
import CoreGraphics
@testable import Space_UI

/// Seeds used to exercise theme generation across variety. `representative` is a small hand-picked set (including
/// edge values); `sweep` is a denser contiguous range for property tests. Widen `sweep` toward thousands of seeds
/// once the suite is confirmed fast on device — kept moderate here so a first run stays quick.
enum TestSeeds {
    static let representative: [UInt64] = [
        0, 1, 2, 3, 7, 42, 100, 1_000, 65_535, 4_294_967_296, 12_345_678_901_234, UInt64.max
    ]
    static let sweep: [UInt64] = Array(1...120)
}

extension Config {
    /// A plain seed-only config (no design-principle / hue overrides), matching a fresh install with nothing pinned.
    static func seedOnly(_ seed: UInt64) -> Config {
        Config(seed: seed, designPrinciples: nil, primaryHue: nil, primarySaturation: nil)
    }
}

/// A stable, human-readable fingerprint of a generated theme. Used by the golden-seed tests to catch unintended
/// generation drift (e.g. an accidental change in a "seed v2" refactor). Order and formatting are part of the
/// contract — appending new fields is fine, reordering/reformatting invalidates recorded goldens.
///
/// Every size recorded here is the one *before* `platformSizeMultiplier`, so a digest fingerprints the seed
/// alone and a golden holds on whichever destination the suite runs on. `SystemStyles` already exposes the line
/// width that way (`mediumLineWidthBase`); the font size only exists scaled, so it is divided back out below.
enum ThemeDigest {
    @MainActor
    static func current(_ system: SystemStyles, _ screen: ScreenStyles) -> String {
        [
            "shape=\(system.basicShape)",
            "dir=\(system.shapeDirection)",
            "corner=\(system.cornerStyle)",
            "roundFrac=\(rounded(system.roundedCornerFraction))",
            "lineCap=\(system.lineCap.rawValue)",
            "medLine=\(rounded(system.mediumLineWidthBase))",
            "btnMode=\(system.preferredButtonSizingMode)",
            "btnW=\(rounded(system.shapeButtonFrameWidth))",
            "btnH=\(rounded(system.shapeButtonFrameHeight))",
            "font=\(system.font?.name ?? "nil")",
            "fontSize=\(rounded(system.defaultFontSize / platformSizeMultiplier))",
            "borders=\(system.prefersBorders)",
            "btnBorders=\(system.prefersButtonBorders)",
            "dashed=\(system.prefersDashedLines)",
            "action=\(system.actionSoundResource.rawValue)",
            "button=\(system.buttonSoundResource.rawValue)",
            "alarm=\(system.alarmSoundResource.rawValue)",
            "palette=\(system.colors.paletteStyle)",
            "light=\(system.colors.useLightAppearance)",
            "screenShape=\(screen.screenShapeType.rawValue)",
            "cutout=\(screen.generalCutoutStyle)",
            "filter=\(screen.filter)",
            "bg=\(screen.backgroundStyle)"
        ].joined(separator: ";")
    }

    private static func rounded(_ value: CGFloat) -> String {
        String(format: "%.4f", Double(value))
    }
}
