import Testing
@testable import Space_UI

/// Guards the properties `AudioVisualizer` relies on now that it bakes its waveform from `TilingValueNoise`
/// instead of GameplayKit's `GKNoiseMap`: the loop must close seamlessly at the end of a period, samples must
/// stay in range, and the field must be reproducible from its seed alone.
struct TilingValueNoiseTests {

    private static let noise = TilingValueNoise(seed: 0xC0FF_EE12_3456_789A, columns: 4, rows: 12)

    /// `AudioVisualizer` bakes `y` from 0 up to (not including) 1 across its 150 frames, then wraps back to
    /// frame 0. If the field didn't close, every loop would jump.
    @Test
    func oneYPeriodClosesSeamlessly() {
        for step in 0...10 {
            let x = Double(step) / 10
            #expect(Self.noise.value(x: x, y: 0) == Self.noise.value(x: x, y: 1))
            // Approaching the seam from below must also converge on the seam's value.
            #expect(abs(Self.noise.value(x: x, y: 0.999) - Self.noise.value(x: x, y: 0)) < 0.01)
        }
    }

    /// The visualizer maps samples straight onto bar heights, so an out-of-range sample would overshoot the
    /// frame the bars are drawn in.
    @Test
    func samplesStayWithinTheUnitRange() {
        for xStep in 0..<40 {
            for yStep in 0..<150 {
                let value = Self.noise.value(x: Double(xStep) / 40, y: Double(yStep) / 150)
                #expect(-1 <= value && value <= 1)
            }
        }
    }

    /// Same seed, same field — the whole reason the visualizer's waveform survives a relaunch.
    @Test
    func theFieldIsDeterministicInItsSeed() {
        let a = TilingValueNoise(seed: 99, columns: 4, rows: 12)
        let b = TilingValueNoise(seed: 99, columns: 4, rows: 12)
        let c = TilingValueNoise(seed: 100, columns: 4, rows: 12)
        var differs = false
        for step in 0..<50 {
            let x = Double(step) / 50
            let y = Double(step) / 50
            #expect(a.value(x: x, y: y) == b.value(x: x, y: y))
            differs = differs || a.value(x: x, y: y) != c.value(x: x, y: y)
        }
        // The two layers' fields are seeded apart precisely so they move independently.
        #expect(differs)
    }

    /// The waveform would read as noise-free flat bars if the field barely moved across the loop.
    @Test
    func theFieldVariesAcrossBothAxes() {
        let acrossX = (0..<40).map { Self.noise.value(x: Double($0) / 40, y: 0.25) }
        let acrossY = (0..<150).map { Self.noise.value(x: 0.25, y: Double($0) / 150) }
        #expect(0.3 < (acrossX.max()! - acrossX.min()!))
        #expect(0.3 < (acrossY.max()! - acrossY.min()!))
    }

}
