import Testing
@testable import Space_UI

/// The weighted pick that biases every generated theme toward its own character. This was inverted for a long
/// time — the metric returned a *distance* and was multiplied in as if it were a similarity, so the element that
/// matched a theme exactly scored zero and the least characteristic elements dominated. The goldens only catch
/// that something moved; these assert which way it points, so the sign can't flip back unnoticed.
struct DesignWeightingTests {

    private static let simple = DesignPrinciples(simplicity: 1, sharpness: 0, order: 0, balance: 0, boldness: 0)

    @Test
    func exactMatchScoresOne() {
        let traits = DesignTraits(simplicity: 1, sharpness: 0, boldness: 0)
        #expect(traits.similarity(to: Self.simple) == 1)
    }

    @Test
    func oppositeScoresZero() {
        let traits = DesignTraits(simplicity: 0, sharpness: 1, boldness: 1)
        #expect(traits.similarity(to: Self.simple) == 0)
    }

    /// An element that declares nothing is neutral, not middling: it keeps its full base weight against every
    /// theme rather than being scored on axes it never claimed.
    @Test
    func undeclaredAxesSitOut() {
        #expect(DesignTraits().similarity(to: Self.simple) == 1)
        #expect(DesignTraits(simplicity: 1).similarity(to: Self.simple) == 1)
        #expect(DesignTraits().similarity(to: DesignPrinciples()) == 1)
    }

    /// Traits scale a weight both ways around a neutral 1×, so a trait-less element's base weight means what it says
    /// beside traited ones. Scaling by raw similarity left it at a perfect 1 against a ~0.64 typical match.
    @Test
    func weightScaleIsNeutralWithoutTraits() {
        #expect(DesignTraits().weightScale(for: Self.simple) == 1)
        #expect(DesignTraits(simplicity: 1, sharpness: 0).weightScale(for: Self.simple) > 1)
        #expect(DesignTraits(simplicity: 0, sharpness: 1).weightScale(for: Self.simple) < 1)
    }

    @Test
    func partialMatchesRankBetweenTheExtremes() {
        let near = DesignTraits(simplicity: 0.9, sharpness: 0.1).similarity(to: Self.simple)
        let far = DesignTraits(simplicity: 0.2, sharpness: 0.8).similarity(to: Self.simple)
        #expect(near > far)
        #expect(0 < far && near < 1)
    }

    /// The behaviour that actually matters: over many draws, the element matching the theme is picked far more
    /// often than the one opposing it. Inverting the metric flips this, so it fails loudly.
    @Test
    func matchingElementWinsOverManyDraws() {
        let elements: [WeightedDesignElement<String>] = [
            .init(baseWeight: 1, design: .init(simplicity: 1, sharpness: 0), element: "match"),
            .init(baseWeight: 1, design: .init(simplicity: 0, sharpness: 1), element: "mismatch")
        ]
        let random = SeededRandom(seed: 7)
        var matches = 0
        for _ in 0..<500 where random.nextWeightedElement(in: elements, with: Self.simple) == "match" {
            matches += 1
        }
        #expect(matches > 450, "The theme's own character should dominate, got \(matches)/500")
    }

    /// Every element scoring zero used to trap in `nextDouble(in: 0..<0)`. A theme sitting exactly opposite a
    /// whole element list is rare but reachable, and it must degrade to a uniform pick, not a crash.
    @Test
    func allZeroWeightsFallBackToAUniformPick() {
        let opposed: [WeightedDesignElement<String>] = [
            .init(baseWeight: 1, design: .init(simplicity: 0, sharpness: 1, order: 1, balance: 1, boldness: 1), element: "a"),
            .init(baseWeight: 1, design: .init(simplicity: 0, sharpness: 1, order: 1, balance: 1, boldness: 1), element: "b")
        ]
        let picked = SeededRandom(seed: 3).nextWeightedElement(in: opposed, with: Self.simple)
        #expect(picked == "a" || picked == "b")
        #expect(SeededRandom(seed: 3).nextWeightedElement(in: [] as [WeightedElement<String>]) == nil)
    }
}
