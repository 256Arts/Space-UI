import SwiftUI

extension Color {

    func getHSB() -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        // Convert SwiftUI Color to UIKit's UIColor
        let uiColor = UIColor(self)

        // Extract components using the native getHue method
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        return (h, s, b, a)
    }
}

#if canImport(UIKit)
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
#else
extension NSColor {
    convenience init(displayP3Hue hue: CGFloat, saturation: CGFloat, brightness: CGFloat, opacity: CGFloat) {
        let standardRGB = NSColor(hue: hue, saturation: saturation, brightness: brightness, alpha: opacity)
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        standardRGB.getRed(&red, green: &green, blue: &blue, alpha: nil)
        self.init(displayP3Red: Double(red), green: Double(green), blue: Double(blue), alpha: Double(opacity))
    }
}
#endif
