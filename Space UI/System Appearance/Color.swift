//
//  Color.swift
//  Space UI
//
//  Created by Jayden Irwin on 2019-12-15.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import SwiftUI

extension Color {
    
    /// Avoid using this
    init(color: SystemColor, brightness: CGFloat = 1.0, opacity: CGFloat = 1.0) {
        let hue: CGFloat
        let saturation: CGFloat
        switch color {
        case .primary:
            hue = system.colors.primaryHue
            saturation = system.colors.primarySaturation
        case .secondary:
            hue = system.colors.secondaryHue
            saturation = system.colors.secondarySaturation
        case .tertiary:
            hue = system.colors.tertiaryHue
            saturation = system.colors.tertiarySaturation
        case .danger:
            hue = system.colors.dangerHue
            saturation = system.colors.dangerSaturation
        }
        self.init(displayP3Hue: hue, saturation: saturation, brightness: brightness, opacity: opacity)
    }
    
    init(color: SystemColor, brightness: Opacity = .max, opacity: Opacity = .max) {
        let hue: CGFloat
        let saturation: CGFloat
        switch color {
        case .primary:
            hue = system.colors.primaryHue
            saturation = system.colors.primarySaturation
        case .secondary:
            hue = system.colors.secondaryHue
            saturation = system.colors.secondarySaturation
        case .tertiary:
            hue = system.colors.tertiaryHue
            saturation = system.colors.tertiarySaturation
        case .danger:
            hue = system.colors.dangerHue
            saturation = system.colors.dangerSaturation
        }
        let brightnessMultiplier: CGFloat = {
            switch brightness {
            case .min:
                return 0.0
            case .low:
                return 0.25
            case .medium:
                return 0.5
            case .high:
                return 0.75
            case .max:
                return 1.0
            }
        }()
        let opacityValue: CGFloat = {
            switch opacity {
            case .min:
                return 0.2
            case .low:
                return 0.4
            case .medium:
                return 0.6
            case .high:
                return 0.8
            case .max:
                return 1.0
            }
        }()
        let actualBrightness = system.screen.minBrightness + (brightnessMultiplier * (1.0 - system.screen.minBrightness))
        self.init(displayP3Hue: hue, saturation: saturation, brightness: actualBrightness, opacity: opacityValue)
    }
    
    init(displayP3Hue hue: CGFloat, saturation: CGFloat, brightness: CGFloat, opacity: CGFloat) {
        let standardRGB = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: opacity)
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        standardRGB.getRed(&red, green: &green, blue: &blue, alpha: nil)
        self.init(.displayP3, red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(opacity))
    }
    
}
