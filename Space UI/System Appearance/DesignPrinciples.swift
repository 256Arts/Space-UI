import Foundation

struct DesignPrinciples: Codable, RawRepresentable {
    typealias RawValue = String
    
    var simplicity: Double
    var sharpness: Double
    var order: Double
    var balance: Double
    var boldness: Double
    
    init(simplicity: Double = 0.5, sharpness: Double = 0.5, order: Double = 0.5, balance: Double = 0.5, boldness: Double = 0.5) {
        self.simplicity = simplicity
        self.sharpness = sharpness
        self.order = order
        self.balance = balance
        self.boldness = boldness
    }
    
    init?(rawValue: String) {
        let numbers = rawValue.split(separator: ",").compactMap(Double.init)
        guard numbers.count == 5 else { return nil }
        simplicity = numbers[0]
        sharpness = numbers[1]
        order = numbers[2]
        balance = numbers[3]
        boldness = numbers[4]
    }
    
    var rawValue: String {
        "\(simplicity),\(sharpness),\(order),\(balance),\(boldness)"
    }
    

    /// The five editable axes, each paired with accessors into a `DesignPrinciples` value — lets the settings UI
    /// render one slider row per axis instead of five hand-written copies. Order matches the on-screen ordering.
    /// (Accessor closures rather than a `WritableKeyPath` because writable key paths aren't `Sendable`.)
    struct Axis: Identifiable, Sendable {
        /// Stable, non-localized identity — `title` is a `LocalizedStringResource`, which isn't `Hashable`
        /// in a way `Identifiable` can synthesize against.
        let id: String
        let title: LocalizedStringResource
        let get: @Sendable (DesignPrinciples) -> Double
        let set: @Sendable (inout DesignPrinciples, Double) -> Void
    }
    static let axes: [Axis] = [
        Axis(id: "simplicity", title: "Simplicity", get: { $0.simplicity }, set: { $0.simplicity = $1 }),
        Axis(id: "sharpness", title: "Sharpness", get: { $0.sharpness }, set: { $0.sharpness = $1 }),
        Axis(id: "order", title: "Order", get: { $0.order }, set: { $0.order = $1 }),
        Axis(id: "balance", title: "Balance", get: { $0.balance }, set: { $0.balance = $1 }),
        Axis(id: "boldness", title: "Boldness", get: { $0.boldness }, set: { $0.boldness = $1 })
    ]

}

/// The design qualities a single generated element claims, as the *element* side of the weighted picks in
/// `nextWeightedElement(in:with:)`. Each axis is optional: `nil` means the element takes no position on it, so
/// that axis sits out the match and the element competes only on the qualities it actually expresses.
///
/// `DesignPrinciples` can't stand in here — its axes are all concrete, so an axis an element never mentioned
/// would read as a mid-scale 0.5 opinion and score against every theme that isn't middling on it.
struct DesignTraits {

    var simplicity: Double?
    var sharpness: Double?
    var order: Double?
    var balance: Double?
    var boldness: Double?

    /// How well a theme matches these traits: 1 when the theme sits exactly on every declared axis, 0 when it sits
    /// at the far end of all of them. An element declaring nothing scores 1.
    func similarity(to principles: DesignPrinciples) -> Double {
        meanDistance(to: principles).map { 1 - $0 } ?? 1
    }

    /// What `similarity` multiplies into an element's base weight: 1× at a typical match, so traits scale a weight
    /// up for a characteristic theme and down for an unlikely one, and a trait-less element keeps its base weight
    /// as written. A raw `similarity` would rank trait-less elements above every matched one (they score a perfect
    /// 1 where a typical match is ~0.64), so their base weights read about 1.5× larger than they were drawn.
    func weightScale(for principles: DesignPrinciples) -> Double {
        meanDistance(to: principles).map { (1 - $0) / Self.typicalSimilarity } ?? 1
    }

    /// The mean `similarity` across every traited element evaluated while generating 2,000 seeded themes.
    static let typicalSimilarity = 0.64

    /// The average gap between each declared trait and the theme, or nil when the element declares none.
    private func meanDistance(to principles: DesignPrinciples) -> Double? {
        let distances = [
            (simplicity, principles.simplicity),
            (sharpness, principles.sharpness),
            (order, principles.order),
            (balance, principles.balance),
            (boldness, principles.boldness)
        ].compactMap { trait, principle in trait.map { abs($0 - principle) } }
        return distances.isEmpty ? nil : distances.reduce(0, +) / Double(distances.count)
    }

}
