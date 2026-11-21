import Testing
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
@testable import Space_UI

/// Invariants that must hold for *every* seed, not just the one you happen to be looking at. This is the safety net
/// that makes theme-generation-changing refactors (the "seed v2" work) safe to land: if a change makes some seed
/// produce a degenerate theme, one of these fails instead of it surfacing on a wall-mounted screen mid-show.
@MainActor
struct ThemePropertyTests {

    private static let lengths: [CGFloat] = [1, 10, 50, 200, 800, 2_000]
    private static let probeSizes: [CGSize] = [
        CGSize(width: 390, height: 844),   // phone portrait
        CGSize(width: 1_024, height: 768), // tablet landscape
        CGSize(width: 1_600, height: 1_200)
    ]

    @Test(arguments: TestSeeds.sweep)
    func cornerRadiiAreNonNegative(seed: UInt64) {
        let system = SystemStyles(config: .seedOnly(seed))
        for length in Self.lengths {
            #expect(system.cornerRadius(forLength: length) >= 0)
            for style in [CornerStyle.sharp, .rounded, .circular] {
                #expect(system.cornerRadius(forLength: length, cornerStyle: style) >= 0)
            }
        }
    }

    @Test(arguments: TestSeeds.sweep)
    func lineWidthsArePositive(seed: UInt64) {
        let system = SystemStyles(config: .seedOnly(seed))
        #expect(system.thinLineWidth > 0)
        #expect(system.mediumLineWidth > 0)
        #expect(system.thickLineWidth > 0)
        #expect(system.thinLineWidth <= system.mediumLineWidth)
        #expect(system.mediumLineWidth <= system.thickLineWidth)
    }

    @Test(arguments: TestSeeds.sweep)
    func chosenFontResolves(seed: UInt64) throws {
        let system = SystemStyles(config: .seedOnly(seed))
        // With the debug font override off (the default), a theme always resolves a concrete font: a bundled face
        // that is registered, or an alien script that generates.
        let font = try #require(system.font)
        #if canImport(UIKit)
        #expect(font.uiFont(size: system.defaultFontSize) != nil, "No font for \(font.name)")
        #endif
    }

    /// With Extra Fonts off — the shipping default — no seed may land on a Star Wars face.
    @Test(arguments: TestSeeds.sweep)
    func defaultThemesAvoidExtraFonts(seed: UInt64) throws {
        try #require(!Font.Name.extraFontsEnabled, "Extra Fonts must be off in the test host for this to mean anything")
        let system = SystemStyles(config: .seedOnly(seed))
        if case .bundled(let name) = try #require(system.font) {
            #expect(!name.isExtra)
        }
    }

    @Test(arguments: TestSeeds.sweep)
    func screenPathIsDrawableAndBounded(seed: UInt64) {
        let system = SystemStyles(config: .seedOnly(seed))
        let styles = system.screen
        for size in Self.probeSizes {
            let shape = ScreenShape(system: system, screenStyles: styles, screenShapeType: styles.screenShapeType, connectedEdges: [])
            let path = shape.path(in: CGRect(origin: .zero, size: size))
            #expect(!path.isEmpty)
            let bounds = path.boundingRect
            #expect(bounds.width.isFinite && bounds.height.isFinite)
            #expect(!bounds.width.isNaN && !bounds.height.isNaN)
        }
    }
}
