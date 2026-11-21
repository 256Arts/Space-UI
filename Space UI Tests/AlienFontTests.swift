// Created by 256 Arts Developer on 2026-11-11.

import AlienFontKit
import CoreText
import Testing
@testable import Space_UI

@MainActor
struct AlienFontTests {

    /// "Sometimes": the generated script turns up in the sweep, but the bundled faces still carry most themes.
    @Test func someThemesUseAnAlienScript() {
        let alienCount = TestSeeds.sweep.count { seed in
            if case .alien = SystemStyles(config: .seedOnly(seed)).font { true } else { false }
        }
        #expect(alienCount > 0)
        #expect(alienCount < TestSeeds.sweep.count / 2)
    }

    /// The dials follow the theme: these pins are where the design principles say they should be.
    @Test func optionsFollowDesignPrinciples() {
        let plain = AlienFont(seed: 7, design: DesignPrinciples(simplicity: 1, sharpness: 1, order: 1, balance: 1, boldness: 0))
        #expect(plain.options.sharpness == 1)
        #expect(plain.options.contrast == 0)
        #expect(plain.options.dots == 0)
        #expect(plain.options.symmetry == 1)
        #expect(plain.options.openings == 0)
        #expect(plain.weight == 400)

        let busy = AlienFont(seed: 7, design: DesignPrinciples(simplicity: 0, sharpness: 0, order: 0, balance: 0, boldness: 1))
        #expect(busy.options.contrast == maximumContrast)
        #expect(busy.options.symmetry == 0)
        #expect(busy.weight == 800)
        #expect(Family.weightRange.contains(busy.weight))
    }

    /// Every device in the room rebuilds the same script from the same seed.
    @Test func sameSeedSameFont() throws {
        let design = DesignPrinciples()
        #expect(AlienFont(seed: 99, design: design) == AlienFont(seed: 99, design: design))
        let font = try #require(AlienFont(seed: 99, design: design).ctFont(size: 20))
        #expect(CTFontGetSize(font) == 20)
        #expect(CTFontGetGlyphCount(font) > 26)
    }

}
