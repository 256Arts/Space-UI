// Created by 256 Arts Developer on 2026-11-11.

import AlienFontKit
import CoreText
import SwiftUI
import Synchronization

/// The face a theme draws its labels in: one of the bundled fonts, or a script AlienFontKit invents for the seed.
enum ThemeFont: Sendable {
    case bundled(Font.Name)
    case alien(AlienFont)

    var defaultFontSize: CGFloat {
        switch self {
        case .bundled(let name): name.defaultFontSize
        case .alien: AlienFont.baseSize * platformSizeMultiplier
        }
    }

    /// For logs and theme fingerprints.
    var name: String {
        switch self {
        case .bundled(let name): name.rawValue
        case .alien(let font): font.options.name
        }
    }

    func font(size: CGFloat) -> Font {
        switch self {
        case .bundled(let name):
            Font.custom(name.rawValue, fixedSize: size).weight(name.weight)
        case .alien(let font):
            font.ctFont(size: size).map(Font.init) ?? .system(size: size, weight: .bold)
        }
    }

    #if canImport(UIKit)
    /// The same face for UIKit text measurement, or `nil` if it can't be made.
    func uiFont(size: CGFloat) -> UIFont? {
        switch self {
        case .bundled(let name): UIFont(name: name.rawValue, size: size)
        case .alien(let font): font.ctFont(size: size).map { $0 as UIFont }
        }
    }
    #endif
}

/// A generated alien-script family, its every dial taken from the theme's design principles so the script feels
/// like it belongs to the rest of the interface: sharp themes get mitred strokes, balanced ones symmetric glyphs,
/// simple ones monoline strokes or dot grids, bold ones a heavier weight.
///
/// Only the options live on the theme. The font itself is generated on first use and cached (`ctFont(size:)`), so
/// building a `SystemStyles` stays cheap and side-effect free. It is never registered with the font manager either:
/// the face is drawn straight from its descriptor, so nothing outlives the theme in a process-wide font list.
struct AlienFont: Sendable, Hashable {

    static let baseSize: CGFloat = 20

    let options: FamilyOptions
    /// On the `wght` axis.
    let weight: Double

    /// Every dial is drawn from its own stream on `seed`, so the main theme stream spends one draw on this whatever
    /// the theme ends up picking.
    init(seed: UInt64, design: DesignPrinciples) {
        let random = SeededRandom(seed: seed)
        let generator = random.nextWeightedElement(in: [
            .init(baseWeight: 2, design: .init(simplicity: 0.3, order: 0.4), element: Generator.strokes),
            .init(baseWeight: 1, design: .init(simplicity: 0.9, order: 1.0), element: .dotGrid),
            .init(baseWeight: 0.5, design: .init(sharpness: 0.0, balance: 1.0), element: .rings)
        ], with: design)!
        let dotBase = random.nextWeightedElement(in: [
            .init(baseWeight: 1, design: .init(simplicity: 1.0, order: 0.8), element: DotBase.two),
            .init(baseWeight: 1, design: .init(simplicity: 0.2, order: 0.5), element: .three)
        ], with: design)!
        let dotJoin = random.nextWeightedElement(in: [
            .init(baseWeight: 1, design: .init(simplicity: 0.3, boldness: 0.2), element: DotJoin.separate),
            .init(baseWeight: 1, design: .init(order: 0.9, balance: 0.3), element: .horizontal),
            .init(baseWeight: 1, design: .init(order: 0.9, balance: 0.7), element: .vertical),
            .init(baseWeight: 1, design: .init(simplicity: 0.9, boldness: 0.9), element: .all)
        ], with: design)!
        let dotRounding = random.nextWeightedElement(in: [
            .init(baseWeight: 2, design: .init(order: 0.7), element: DotRounding.eachDot),
            .init(baseWeight: 1, design: .init(simplicity: 1.0, balance: 0.9), element: .wholeCell),
            .init(baseWeight: 1, design: .init(simplicity: 0.2, balance: 0.9), element: .command)
        ], with: design)!
        let digitLayout = random.nextWeightedElement(in: [
            .init(baseWeight: 1, design: .init(order: 1.0, balance: 0.5), element: DigitLayout.die),
            .init(baseWeight: 1, design: .init(simplicity: 0.7, balance: 1.0), element: .ring),
            .init(baseWeight: 1, design: .init(simplicity: 0.3, order: 0.7), element: .clock)
        ], with: design)!

        options = FamilyOptions(
            // Unique per seed: CoreText can keep serving glyphs from an earlier font that had the same name.
            name: "SpaceUIAlien\(seed)",
            seed: seed,
            generator: generator,
            dotBase: dotBase,
            sharpness: design.sharpness,
            // Simple themes draw monoline; busier ones modulate their strokes like a pen.
            contrast: (1 - design.simplicity) * maximumContrast,
            symmetry: design.balance,
            // Stray dots in place of strokes read as ornament, which simple themes don't have.
            dots: (1 - design.simplicity) * 0.4,
            dotJoin: dotJoin,
            dotRounding: dotRounding,
            // A broken ring is a loose end; ordered themes close theirs.
            openings: 1 - design.order,
            digitLayout: digitLayout,
            // Matches the bundled faces, most of which draw "…" as nothing: truncated labels just stop.
            blankEllipsis: true
        )
        // Regular to ExtraBold: the thinnest masters vanish at label sizes.
        weight = 400 + design.boldness * 400
    }

    func ctFont(size: CGFloat) -> CTFont? {
        descriptor().map { CTFontCreateWithFontDescriptor($0, size, nil) }
    }

    // MARK: - Generation

    private struct Descriptor: @unchecked Sendable {
        // CTFontDescriptor is immutable and safe to share across threads.
        let value: CTFontDescriptor?
    }

    /// Generated faces by their options, so a peer re-sending the same seed doesn't generate it again. Cleared
    /// when it fills, so regenerating the seed all evening doesn't keep every font ever drawn.
    private static let cache = Mutex<[AlienFont: Descriptor]>([:])

    /// The Regular face at `weight`, generated the first time any theme asks for it. `nil` only if no seed near
    /// this one gives a family, in which case the labels fall back to the system font.
    private func descriptor() -> CTFontDescriptor? {
        Self.cache.withLock { cache in
            if let cached = cache[self] { return cached.value }
            if cache.count >= 8 { cache.removeAll() }
            let made = Descriptor(value: makeDescriptor())
            cache[self] = made
            return made.value
        }
    }

    private func makeDescriptor() -> CTFontDescriptor? {
        // A rare seed can't invent enough distinct glyphs; its neighbours almost always can, and every device
        // walks the same neighbours, so the room still agrees.
        for offset in UInt64(0)..<4 {
            var options = options
            options.seed = options.seed &+ offset
            guard let family = try? Family(options),
                  let faces = CTFontManagerCreateFontDescriptorsFromData(family.fontData as CFData) as? [CTFontDescriptor],
                  let regular = faces.first else { continue }
            let wght = 0x7767_6874 // 'wght'
            return CTFontDescriptorCreateCopyWithAttributes(regular, [kCTFontVariationAttribute: [wght: weight]] as CFDictionary)
        }
        return nil
    }

}
