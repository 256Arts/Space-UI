// Created by 256 Arts Developer on 2026-08-23.

/// The app's deterministic generator: SplitMix64 expands the seed into xoshiro256\*\* state, and every draw after
/// that is pure integer math. Two devices given the same `Config` therefore generate byte-identical themes no
/// matter which OS or framework version they are running — the property the whole room's coherence rests on.
///
/// A reference type on purpose. One generation pass threads a single stream through several initializers
/// (``SystemColors``, ``ScreenStyles``, ``TargetState``), each consuming draws in turn; a value type would hand
/// each of them a copy of the stream and they would all generate from the same numbers.
final class SeededRandom: RandomNumberGenerator {

    private var state: (UInt64, UInt64, UInt64, UInt64)

    init(seed: UInt64) {
        // SplitMix64: a seed of 0 (or of any two nearby values) would leave xoshiro's state degenerate and its
        // first draws correlated, so spread the one seed word across all four state words first.
        var z = seed
        func nextStateWord() -> UInt64 {
            z &+= 0x9E37_79B9_7F4A_7C15
            var word = z
            word = (word ^ (word >> 30)) &* 0xBF58_476D_1CE4_E5B9
            word = (word ^ (word >> 27)) &* 0x94D0_49BB_1331_11EB
            return word ^ (word >> 31)
        }
        state = (nextStateWord(), nextStateWord(), nextStateWord(), nextStateWord())
    }

    /// xoshiro256\*\*.
    func next() -> UInt64 {
        let result = rotatedLeft(state.1 &* 5, by: 7) &* 9
        let shifted = state.1 << 17
        state.2 ^= state.0
        state.3 ^= state.1
        state.1 ^= state.2
        state.0 ^= state.3
        state.2 ^= shifted
        state.3 = rotatedLeft(state.3, by: 45)
        return result
    }

    private func rotatedLeft(_ value: UInt64, by amount: UInt64) -> UInt64 {
        (value << amount) | (value >> (64 - amount))
    }

    /// The standard library's `random(in:using:)` family wants an `inout` generator. `self` is a class, so the
    /// local it mutates is this same stream — which is what lets the unbiased stdlib draws be used directly.
    private func draw<T>(_ body: (inout SeededRandom) -> T) -> T {
        var generator = self
        return body(&generator)
    }

}

struct WeightedElement<E> {
    let weight: Double
    let element: E
}

struct WeightedDesignElement<E> {
    let baseWeight: Double
    let design: DesignTraits
    let element: E
}

extension SeededRandom {

    func nextInt(in range: Range<Int>) -> Int {
        draw { .random(in: range, using: &$0) }
    }
    func nextInt(in range: ClosedRange<Int>) -> Int {
        draw { .random(in: range, using: &$0) }
    }

    func nextDouble(in range: Range<Double>) -> Double {
        draw { .random(in: range, using: &$0) }
    }
    func nextDouble(in range: ClosedRange<Double>) -> Double {
        draw { .random(in: range, using: &$0) }
    }

    func nextFraction() -> Double {
        nextDouble(in: 0..<1)
    }

    func nextBool() -> Bool {
        draw { .random(using: &$0) }
    }

    func nextBool(chance: Double) -> Bool {
        nextFraction() < chance
    }

    func nextElement<E>(in array: [E]) -> E? {
        draw { array.randomElement(using: &$0) }
    }

    func nextWeightedElement<E>(in array: [WeightedElement<E>]) -> E? {
        guard !array.isEmpty else { return nil }

        let total = array.reduce(0, { $0 + $1.weight })
        // Nothing scored: pick uniformly rather than trapping in nextDouble(in: 0..<0).
        guard total > 0 else { return nextElement(in: array)?.element }
        let randomValue = nextDouble(in: 0..<total)

        var currentValue = 0.0
        for weightedElement in array {
            currentValue += weightedElement.weight
            if randomValue <= currentValue {
                return weightedElement.element
            }
        }
        return array[0].element
    }

    /// Picks an element weighted by both its base weight and how closely its declared traits match the theme, so a
    /// theme's most characteristic elements dominate and its least characteristic ones stay rare.
    func nextWeightedElement<E>(in array: [WeightedDesignElement<E>], with design: DesignPrinciples) -> E? {
        nextWeightedElement(in: array.map {
            WeightedElement(weight: $0.baseWeight * $0.design.weightScale(for: design), element: $0.element)
        })
    }

}
