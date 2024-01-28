//
//  SystemColors.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2022-09-09.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

import GameplayKit

enum SystemColor {
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

final class SystemColors {
    
    let paletteStyle: PaletteStyle
    let useLightAppearance: Bool
    
    let backgroundBrightness: CGFloat
    let dangerHue: CGFloat = 0.0
    let dangerSaturation: CGFloat = 1.0
    let primaryHueNormal: CGFloat
    let primarySaturationNormal: CGFloat
    var primaryHue: CGFloat {
        ShipData.shared.isInEmergency ? dangerHue : primaryHueNormal
    }
    var primarySaturation: CGFloat {
        ShipData.shared.isInEmergency ? dangerSaturation : primarySaturationNormal
    }
    var secondaryHue: CGFloat = 0.0
    var secondarySaturation: CGFloat = 0.0
    var tertiaryHue: CGFloat
    var tertiarySaturation: CGFloat = 1.0
    
    init(random: GKRandom) {
        let allAppearances: [WeightedElement<Bool>] = [
            .init(weight: 0.01, element: true),
            .init(weight: 0.99, element: false)
        ]
        useLightAppearance = random.nextWeightedElement(in: allAppearances)!
        
        let allPaletteStyles: [WeightedElement<PaletteStyle>] = [
            .init(weight: 1 + (useLightAppearance ? 10 : 0), element: .monochrome),
            .init(weight: 1, element: .colorful),
            .init(weight: 4, element: .limited)
        ]
        paletteStyle = random.nextWeightedElement(in: allPaletteStyles)!
        
        #if DEBUG
        // For screenshots
        backgroundBrightness = CGFloat(random.nextDouble(in: useLightAppearance ? 0.7...1.0 : 0.2...0.3))
        #else
        backgroundBrightness = CGFloat(random.nextDouble(in: useLightAppearance ? 0.7...1.0 : 0...0.3))
        #endif
        primaryHueNormal = CGFloat(random.nextFraction())
        if paletteStyle == .monochrome {
            let allPrimarySats: [WeightedElement<CGFloat>] = [
                .init(weight: 1, element: CGFloat(random.nextFraction())),
                .init(weight: useLightAppearance ? 5 : 0, element: 0)
            ]
            primarySaturationNormal = random.nextWeightedElement(in: allPrimarySats)!
            
            secondaryHue = primaryHueNormal
            secondarySaturation = primarySaturationNormal
            tertiaryHue = primaryHueNormal
            tertiarySaturation = primarySaturation
        } else {
            let allPrimarySats: [WeightedElement<CGFloat>] = [
                .init(weight: 1, element: 1),
                .init(weight: 0.1, element: CGFloat(random.nextFraction()))
            ]
            primarySaturationNormal = random.nextWeightedElement(in: allPrimarySats)!
            
            if random.nextBool(chance: 0.2) {
                let secondaryHueOffset = 0.08 + CGFloat(random.nextDouble(in: 0...0.3))
                secondaryHue = primaryHueNormal + secondaryHueOffset
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
                tertiaryHue = primaryHueNormal + tertiaryHueOffset
                if 1 < tertiaryHue {
                    tertiaryHue -= 1
                }
            }
        }
    }
    
}
