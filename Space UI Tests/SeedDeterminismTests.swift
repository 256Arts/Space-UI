import Testing
import CoreGraphics
@testable import Space_UI

/// The core cross-device invariant: the same seed must generate the same theme. Two rooms of screens sharing a
/// seed rely on this, and a regression is invisible until show night.
@MainActor
struct SeedDeterminismTests {

    @Test(arguments: TestSeeds.representative)
    func themeIsDeterministic(seed: UInt64) {
        let config = Config.seedOnly(seed)

        let a = SystemStyles(config: config)
        let b = SystemStyles(config: config)

        // Digest folds every field that matters; comparing it gives one clear failure with the differing seed.
        #expect(ThemeDigest.current(a, a.screen) == ThemeDigest.current(b, b.screen))
    }

    @Test(arguments: TestSeeds.representative)
    func colorPaletteIsDeterministic(seed: UInt64) {
        let config = Config.seedOnly(seed)

        let a = SystemStyles(config: config)
        let b = SystemStyles(config: config)

        #expect(a.colors.paletteStyle == b.colors.paletteStyle)
        #expect(a.colors.useLightAppearance == b.colors.useLightAppearance)
        // Compare the seed-derived hue/saturation directly rather than resolved SwiftUI `Color`s (whose equality
        // is unreliable), since these are the stable inputs the whole palette is built from.
        #expect(a.colors.primaryHue == b.colors.primaryHue)
        #expect(a.colors.primarySaturation == b.colors.primarySaturation)
    }
}
