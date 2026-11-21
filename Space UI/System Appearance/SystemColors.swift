import SwiftUI

enum ColorRole {
    case primary, secondary, tertiary, danger
}
enum Brightness {
    case min, low, medium, high, max
}
enum Opacity {
    case min, low, medium, high, max
}
enum PaletteStyle {
    case colorful, monochrome, limited
}

struct SystemColors: Sendable {

    /// Whether the primary role resolves to the danger colour. Not generated: the root sets it for the length of
    /// an emergency (see `resolvingEmergencyColors()`), so an emergency is an explicit input to the palette
    /// rather than a hidden read of live ship state from inside `color(_:)`.
    private(set) var usesEmergencyPrimary = false

    let paletteStyle: PaletteStyle
    let useLightAppearance: Bool

    let backgroundBrightness: CGFloat
    let dangerHue: CGFloat = 0.0
    let dangerSaturation: CGFloat = 1.0
    let primaryHue: CGFloat
    let primarySaturation: CGFloat
    let secondaryHue: CGFloat
    let secondarySaturation: CGFloat
    let tertiaryHue: CGFloat
    let tertiarySaturation: CGFloat

    init(random: SeededRandom, primaryHue overridePrimaryHue: CGFloat? = nil, primarySaturation overridePrimarySaturation: CGFloat? = nil) {
        let allAppearances: [WeightedElement<Bool>] = [
            .init(weight: 0.01, element: true),
            .init(weight: 0.99, element: false)
        ]
        let useLightAppearance = random.nextWeightedElement(in: allAppearances)!

        let allPaletteStyles: [WeightedElement<PaletteStyle>] = [
            .init(weight: 1 + (useLightAppearance ? 10 : 0), element: .monochrome),
            .init(weight: 1, element: .colorful),
            .init(weight: 4, element: .limited)
        ]
        let paletteStyle = random.nextWeightedElement(in: allPaletteStyles)!

        #if DEBUG
        // For screenshots
        backgroundBrightness = CGFloat(random.nextDouble(in: useLightAppearance ? 0.7...1.0 : 0.2...0.3))
        #else
        backgroundBrightness = CGFloat(random.nextDouble(in: useLightAppearance ? 0.7...1.0 : 0...0.3))
        #endif

        let randomPrimaryHue = CGFloat(random.nextFraction())
        let randomPrimarySaturation: CGFloat

        var secondaryHue: CGFloat = 0.0
        var secondarySaturation: CGFloat = 0.0
        let tertiaryHue: CGFloat
        var tertiarySaturation: CGFloat = 1.0

        if paletteStyle == .monochrome {
            let allPrimarySats: [WeightedElement<CGFloat>] = [
                .init(weight: 1, element: CGFloat(random.nextFraction())),
                .init(weight: useLightAppearance ? 5 : 0, element: 0)
            ]
            randomPrimarySaturation = random.nextWeightedElement(in: allPrimarySats)!

            secondaryHue = randomPrimaryHue
            secondarySaturation = randomPrimarySaturation
            tertiaryHue = randomPrimaryHue
            tertiarySaturation = randomPrimarySaturation
        } else {
            let allPrimarySats: [WeightedElement<CGFloat>] = [
                .init(weight: 1, element: 1),
                .init(weight: 0.1, element: CGFloat(random.nextFraction()))
            ]
            randomPrimarySaturation = random.nextWeightedElement(in: allPrimarySats)!

            if random.nextBool(chance: 0.2) {
                let secondaryHueOffset = 0.08 + CGFloat(random.nextDouble(in: 0...0.3))
                secondaryHue = randomPrimaryHue + secondaryHueOffset
                if 1 < secondaryHue {
                    secondaryHue -= 1
                }
                secondarySaturation = 0.5
            } // else white
            if paletteStyle == .limited {
                tertiaryHue = secondaryHue
                tertiarySaturation = secondarySaturation
            } else {
                let tertiaryHueOffset = 0.08 + CGFloat(random.nextDouble(in: 0...0.3))
                var hue = randomPrimaryHue + tertiaryHueOffset
                if 1 < hue {
                    hue -= 1
                }
                tertiaryHue = hue
            }
        }

        self.secondaryHue = secondaryHue
        self.secondarySaturation = secondarySaturation
        self.tertiaryHue = tertiaryHue
        self.tertiarySaturation = tertiarySaturation

        // Override these after generation to advance the random number generator as normal
        if let overridePrimaryHue, let overridePrimarySaturation {
            self.primaryHue = overridePrimaryHue
            self.primarySaturation = overridePrimarySaturation
            self.useLightAppearance = false
            self.paletteStyle = .colorful
        } else {
            self.useLightAppearance = useLightAppearance
            self.paletteStyle = paletteStyle
            self.primaryHue = randomPrimaryHue
            self.primarySaturation = randomPrimarySaturation
        }
    }

}

extension SystemColors {

    /// The palette an emergency is drawn in: every `.primary` read resolves to the danger colour, so the whole
    /// UI (including the screen background) turns red while the alarm strobes. Resolved once by the root and
    /// injected, which is what keeps this type pure seed-derived data.
    func resolvingEmergencyColors() -> SystemColors {
        var copy = self
        copy.usesEmergencyPrimary = true
        return copy
    }

    var screenBackground: Color {
        #if os(visionOS)
        color(.primary, opacity: 0.2)
        #else
        color(.primary, brightnessMultiplier: 0.0)
        #endif
    }

    func color(_ role: ColorRole, brightness: Brightness = .max, opacity: Opacity = .max) -> Color {
        let brightnessMultiplier: CGFloat = {
            switch brightness {
            case .min: return 0.2
            case .low: return 0.4
            case .medium: return 0.6
            case .high: return 0.8
            case .max: return 1.0
            }
        }()
        let opacityValue: CGFloat = {
            switch opacity {
            case .min: return 0.2
            case .low: return 0.4
            case .medium: return 0.6
            case .high: return 0.8
            case .max: return 1.0
            }
        }()
        return color(role, brightnessMultiplier: brightnessMultiplier, opacity: opacityValue)
    }

    func color(_ role: ColorRole, brightnessMultiplier: CGFloat = 1.0, opacity: CGFloat = 1.0) -> Color {
        let (hue, saturation) = hueAndSaturation(for: role)
        return makeColor(displayP3Hue: hue, saturation: saturation, brightnessMultiplier: brightnessMultiplier, opacity: opacity)
    }

    private func hueAndSaturation(for role: ColorRole) -> (hue: CGFloat, saturation: CGFloat) {
        switch role {
        case .primary:
            if usesEmergencyPrimary {
                return (dangerHue, dangerSaturation)
            }
            return (primaryHue, primarySaturation)
        case .secondary:
            return (secondaryHue, secondarySaturation)
        case .tertiary:
            return (tertiaryHue, tertiarySaturation)
        case .danger:
            return (dangerHue, dangerSaturation)
        }
    }

    private func makeColor(displayP3Hue hue: CGFloat, saturation: CGFloat, brightnessMultiplier: CGFloat, opacity: CGFloat) -> Color {
        // Resolve against the theme's own appearance, never the device's. A theme fully specifies its
        // look via useLightAppearance/backgroundBrightness, so a color must render identically regardless
        // of the system light/dark setting or the SwiftUI environment it happens to be drawn in. Keying
        // this off traits.userInterfaceStyle instead made colors go black wherever a dark theme was drawn
        // outside a forced .colorScheme (e.g. the screen border, flanking morse-code lines) in light mode.
        let brightness = useLightAppearance
            ? backgroundBrightness - (brightnessMultiplier * backgroundBrightness)
            : backgroundBrightness + (brightnessMultiplier * (1.0 - backgroundBrightness))
        #if canImport(UIKit)
        return Color(uiColor: UIColor(displayP3Hue: hue, saturation: saturation, brightness: brightness, opacity: opacity))
        #else
        return Color(NSColor(displayP3Hue: hue, saturation: saturation, brightness: brightness, opacity: opacity))
        #endif
    }
}
