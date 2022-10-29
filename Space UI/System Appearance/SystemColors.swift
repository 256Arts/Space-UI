//
//  SystemColors.swift
//  Space UI
//
//  Created by Jayden Irwin on 2022-09-09.
//  Copyright © 2022 Jayden Irwin. All rights reserved.
//

import GameplayKit

enum SystemColor {
    case primary, secondary, tertiary, danger
}
enum Opacity {
    case min, low, medium, high, max
}
enum PaletteStyle {
    case colorful, monochrome, limited
}

final class SystemColors {
    
    let paletteStyle: PaletteStyle
    
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
        let allPaletteStyles: [WeightedElement<PaletteStyle>] = [
            .init(weight: 1, element: .monochrome),
            .init(weight: 1, element: .colorful),
            .init(weight: 4, element: .limited)
        ]
        paletteStyle = random.nextWeightedElement(in: allPaletteStyles)!
        primaryHueNormal = CGFloat(random.nextFraction())
        if paletteStyle == .monochrome {
            primarySaturationNormal = CGFloat(random.nextFraction())
            secondaryHue = primaryHueNormal
            secondarySaturation = primarySaturationNormal
            tertiaryHue = primaryHueNormal
            tertiarySaturation = primarySaturation
        } else {
            primarySaturationNormal = 1
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
