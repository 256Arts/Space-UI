import SwiftUI

extension Font {
    
    enum Name: String, CaseIterable {
        case abEquinox = "ABEquinoxBasic"
        case almostThere = "AlmostThere-Numeric"
        case aurebeshEnglish = "Aurebesh_english-Regular"
        case baybayin = "Baybayin Rounded Regular"
        case clyneseBend = "ClyneseBend"
        case fresian = "FresianAlphabetAF"
        case galactico = "Galactico"
        case geonosian = "GeonosianPM"
        case kyberCrystal = "KyberCrystalDisplay"
        case mando = "MandoAF-Regular"
        case outerRim = "OuterRimAF-Regular"
        case sFoil = "S-Foil"
        case sga2 = "SGA2"
        case theCalling = "TheCalling"
        case tradeFederation = "Trade Federation"
        
        /// Per-family base point size and weight, tuned so each face renders at a comparable visual size.
        private var metrics: (baseSize: CGFloat, weight: Font.Weight) {
            switch self {
            case .abEquinox: (20, .heavy)
            case .almostThere: (20, .heavy)
            case .aurebeshEnglish: (20, .heavy)
            case .baybayin: (20, .medium)
            case .clyneseBend: (22, .heavy)
            case .fresian: (20, .heavy)
            case .galactico: (20, .heavy)
            case .geonosian: (40, .heavy)
            case .kyberCrystal: (22, .heavy)
            case .mando: (28, .heavy)
            case .outerRim: (30, .heavy)
            case .sFoil: (20, .heavy)
            case .sga2: (25, .bold)
            case .theCalling: (24, .regular)
            case .tradeFederation: (17, .heavy)
            }
        }

        /// Faces named for Star Wars' in-universe scripts and places. They ship in the bundle but are kept out of
        /// theme generation unless the user turns on Extra Fonts, so nothing trademark-adjacent is the default look.
        /// The rest are either real-world scripts (Baybayin), other fiction (SGA2, the Standard Galactic Alphabet),
        /// or generic sci-fi display faces.
        var isExtra: Bool {
            switch self {
            case .aurebeshEnglish, .geonosian, .kyberCrystal, .mando, .outerRim, .sFoil, .tradeFederation:
                true
            case .abEquinox, .almostThere, .baybayin, .clyneseBend, .fresian, .galactico, .sga2, .theCalling:
                false
            }
        }

        /// Whether the user has opted into the Star Wars faces. Deliberately a per-device setting like the screen
        /// shape override — it is not part of the `Config` the room's peers share.
        static var extraFontsEnabled: Bool {
            UserDefaults.standard.bool(forKey: UserDefaults.Key.extraFonts)
        }

        var defaultFontSize: CGFloat {
            metrics.baseSize * platformSizeMultiplier
        }

        var weight: Font.Weight {
            metrics.weight
        }
    }

    @MainActor
    static func spaceFont(size: CGFloat) -> Font {
        guard let font = Space_UI.system.font else {
            return Font.system(size: size, weight: .bold)
        }
        return font.font(size: size)
    }
    
    /// The legible Latin face used for text the user actually has to read. Aurebesh English is one of the extra
    /// faces, so without them this falls back to the system font — same shape as `spaceFont`'s nil path.
    static func english(size: CGFloat = Font.Name.aurebeshEnglish.defaultFontSize) -> Font {
        guard Font.Name.extraFontsEnabled else {
            return Font.system(size: size, weight: .bold)
        }
        return Font.custom(Font.Name.aurebeshEnglish.rawValue, fixedSize: size).weight(.heavy)
    }

    static func english(scale: CGFloat) -> Font {
        english(size: scale * Font.Name.aurebeshEnglish.defaultFontSize)
    }
    
}
