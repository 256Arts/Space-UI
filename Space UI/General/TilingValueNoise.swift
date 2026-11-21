// Created by 256 Arts Developer on 2026-08-23.

import Foundation

/// Fractal value noise on an integer lattice that wraps in `y`: sampling `y` across `0..<1` covers exactly one
/// period, so a table baked over that range loops seamlessly back to its first row. Octaves of
/// smoothstep-interpolated lattice values read as organic without the cost — or the framework — of gradient noise.
///
/// Deterministic in `seed` alone, and pure integer math like ``SeededRandom``, so the same seed gives the same
/// field on every OS version.
struct TilingValueNoise {

    /// Lattice cells across the sampled `x` range, in the first octave. Fewer cells = broader, slower shapes.
    let columns: Int
    /// Lattice cells in one `y` period, in the first octave.
    let rows: Int
    let octaves: Int
    let seed: UInt64

    init(seed: UInt64, columns: Int, rows: Int, octaves: Int = 3) {
        self.seed = seed
        self.columns = max(1, columns)
        self.rows = max(1, rows)
        self.octaves = max(1, octaves)
    }

    /// Noise in `-1...1` at the given fractions of the field. `x` is open-ended; `y` wraps at 1.
    func value(x: Double, y: Double) -> Double {
        var total = 0.0
        var amplitude = 1.0
        var amplitudeSum = 0.0
        for octave in 0..<octaves {
            let detail = 1 << octave
            total += amplitude * octaveValue(x: x, y: y, columns: columns * detail, rows: rows * detail, octave: octave)
            amplitudeSum += amplitude
            amplitude /= 2
        }
        return total / amplitudeSum
    }

    /// Bilinear blend of the four lattice values around the sample, eased on both axes so cell edges don't show.
    private func octaveValue(x: Double, y: Double, columns: Int, rows: Int, octave: Int) -> Double {
        let xPosition = x * Double(columns)
        let yPosition = y * Double(rows)
        let column = Int(xPosition.rounded(.down))
        let row = Int(yPosition.rounded(.down))
        let xBlend = Self.eased(xPosition - Double(column))
        let yBlend = Self.eased(yPosition - Double(row))

        let top = Self.blend(latticeValue(column, row, rows: rows, octave: octave), latticeValue(column + 1, row, rows: rows, octave: octave), xBlend)
        let bottom = Self.blend(latticeValue(column, row + 1, rows: rows, octave: octave), latticeValue(column + 1, row + 1, rows: rows, octave: octave), xBlend)
        return Self.blend(top, bottom, yBlend)
    }

    /// The lattice point's own value in `-1..<1`. `row` wraps into one period, which is what makes `y` seamless.
    private func latticeValue(_ column: Int, _ row: Int, rows: Int, octave: Int) -> Double {
        let wrappedRow = ((row % rows) + rows) % rows
        // SplitMix64's finalizer, the same avalanche ``SeededRandom`` spreads its seed with, used here as a hash
        // of (seed, column, row, octave) so neighbouring lattice points are uncorrelated.
        var word = seed
        word &+= UInt64(bitPattern: Int64(column)) &* 0x9E37_79B9_7F4A_7C15
        word &+= UInt64(wrappedRow) &* 0xBF58_476D_1CE4_E5B9
        word &+= UInt64(octave) &* 0x94D0_49BB_1331_11EB
        word = (word ^ (word >> 30)) &* 0xBF58_476D_1CE4_E5B9
        word = (word ^ (word >> 27)) &* 0x94D0_49BB_1331_11EB
        word ^= word >> 31
        // Top 53 bits give an exactly representable fraction in 0..<1; remap to -1..<1.
        return Double(word >> 11) * (1.0 / 9_007_199_254_740_992.0) * 2 - 1
    }

    /// Smoothstep: zero slope at both ends, so the blend between cells has no visible crease.
    private static func eased(_ fraction: Double) -> Double {
        fraction * fraction * (3 - 2 * fraction)
    }

    private static func blend(_ a: Double, _ b: Double, _ fraction: Double) -> Double {
        a + (b - a) * fraction
    }

}
