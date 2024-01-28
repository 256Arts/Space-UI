//
//  Color.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-15.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

extension Color {
    
    static var screenBackground: Color {
        Color(color: .primary, brightnessMultiplier: 0.0)
    }
    
    /// Avoid using this
    init(color: SystemColor, brightnessMultiplier: CGFloat = 1.0, opacity: CGFloat = 1.0) {
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
        self = Self.make(displayP3Hue: hue, saturation: saturation, brightnessMultiplier: brightnessMultiplier, opacity: opacity)
    }
    
    init(color: SystemColor, brightness: Brightness = .max, opacity: Opacity = .max) {
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
        self = Self.make(displayP3Hue: hue, saturation: saturation, brightnessMultiplier: brightnessMultiplier, opacity: opacityValue)
    }
    
    private static func make(displayP3Hue hue: CGFloat, saturation: CGFloat, brightnessMultiplier: CGFloat, opacity: CGFloat) -> Color {
        Color(uiColor: UIColor { traits in
            let brightness: CGFloat = {
                if traits.userInterfaceStyle == .light {
                    return system.colors.backgroundBrightness - (brightnessMultiplier * system.colors.backgroundBrightness)
                } else {
                    return system.colors.backgroundBrightness + (brightnessMultiplier * (1.0 - system.colors.backgroundBrightness))
                }
            }()
            return UIColor(displayP3Hue: hue, saturation: saturation, brightness: brightness, opacity: opacity)
        })
    }
}

extension UIColor {
    convenience init(displayP3Hue hue: CGFloat, saturation: CGFloat, brightness: CGFloat, opacity: CGFloat) {
        let standardRGB = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: opacity)
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        standardRGB.getRed(&red, green: &green, blue: &blue, alpha: nil)
        self.init(displayP3Red: Double(red), green: Double(green), blue: Double(blue), alpha: Double(opacity))
    }
}
