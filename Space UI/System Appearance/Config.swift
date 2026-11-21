import Foundation

struct Config: Codable {
    let seed: UInt64
    let designPrinciples: DesignPrinciples?
    let primaryHue: CGFloat?
    let primarySaturation: CGFloat?
}
