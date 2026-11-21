import SwiftUI

// The bar-height data for the visualizer: two pre-baked noise tables plus the derived visual style.
// Building the tables (bins × frameCount) is expensive, so a model is generated once per
// (seed, width, height, complexity) and reused across re-renders instead of being rebuilt on every
// parent update. Generation is deterministic in all four, which is what makes the cache key sound —
// but the size terms are the view's measured geometry, so this is *not* a shared value across
// devices. See `generate`.
struct AudioVisualizerModel {

    static let frameCount: Int32 = 150
    static let secondaryBarsMaxDifference: CGFloat = 80.0

    let bins: Int32
    let barWidth: CGFloat
    let layers: Int          // 1 = single waveform, 2 = foreground + background layer
    let symmetrical: Bool
    let alignBarsToBottom: Bool
    let primaryBarsMaxHeight: CGFloat
    /// Bar heights, indexed by ``index(x:frame:)``.
    let noiseMap: [CGFloat]
    /// Background-layer offsets on the same indexing; `nil` when there is only one layer.
    let noiseMap2: [CGFloat]?

    /// Row-major over bars: every bar's whole animation loop sits contiguously.
    private static func index(x: Int32, frame: Int32) -> Int {
        Int(x) * Int(frameCount) + Int(frame)
    }

    /// Bar `x` height at a whole `frame` for `layer`, before volume scaling.
    private func rawLevel(x: Int32, frame: Int32, layer: Int) -> CGFloat {
        let index = Self.index(x: x, frame: frame)
        guard noiseMap.indices.contains(index) else { return barWidth }
        let base = noiseMap[index]
        if layer == 1 || layers == 1 {
            return base
        }
        // The background layer is an offset on top of the primary; negatives clamp to 0.
        return max(0, base + (noiseMap2?[index] ?? 0))
    }

    /// Bar `x` noise height interpolated between two frames. Interpolating lets the 30 fps noise
    /// animate smoothly at the display's refresh rate without SwiftUI animation.
    func level(x: Int32, frameA: Int32, frameB: Int32, blend: CGFloat, layer: Int) -> CGFloat {
        let a = rawLevel(x: x, frame: frameA, layer: layer)
        let b = rawLevel(x: x, frame: frameB, layer: layer)
        return a + (b - a) * blend
    }

    /// Fade the outermost bars so the waveform tapers toward both edges.
    private static func edgeTaper(x: Int32, bins: Int32) -> CGFloat {
        switch min(x, bins - 1 - x) {
        case 0:
            0.15
        case 1:
            0.3
        case 2:
            0.55
        case 3:
            0.8
        default:
            1
        }
    }

    /// Bake one layer's noise into a `bins × frameCount` table, normalized so its strongest sample reaches ±1
    /// (the field's own peak varies with the lattice, and a waveform whose tallest bar falls short looks flat).
    /// Mirroring happens here, before any shaping, because the shaping is symmetric in `x` anyway.
    private static func bakedNoise(_ noise: TilingValueNoise, bins: Int32, generatedBins: Int32, symmetrical: Bool) -> [CGFloat] {
        var values = [CGFloat](repeating: 0, count: Int(max(0, bins)) * Int(frameCount))
        var peak: CGFloat = 0
        for x in 0..<generatedBins {
            for t in 0..<frameCount {
                // `y` spans one full period, so frame 150 lands back on frame 0 and the loop is seamless.
                let value = CGFloat(noise.value(x: Double(x) / Double(max(1, bins)), y: Double(t) / Double(frameCount)))
                values[index(x: x, frame: t)] = value
                peak = max(peak, abs(value))
            }
        }
        if 0 < peak, peak != 1 {
            for i in values.indices {
                values[i] /= peak
            }
        }
        if symmetrical {
            for x in generatedBins..<bins {
                for t in 0..<frameCount {
                    values[index(x: x, frame: t)] = values[index(x: bins - 1 - x, frame: t)]
                }
            }
        }
        return values
    }

    // `highComplexitySound` makes the waveforms look more like music than a single voice track.
    static func generate(seed: UInt64, width: CGFloat, height: CGFloat, highComplexitySound: Bool) -> AudioVisualizerModel {
        // Seeded from `system.seed` so a given theme's waveform is stable across launches. It is *not* stable
        // across devices: `bins` is derived from the measured `width`, so a phone and a Mac showing the same
        // theme get different bar counts and different noise. That is fine — the visualizer is decoration, in
        // the same class as the other per-screen flourishes, not shared simulation content like `ShipState`.
        let random = SeededRandom(seed: seed)

        // Randomly pick visual style properties from the seeded RNG.
        let barWidth = CGFloat(random.nextInt(in: 5...8))
        let primaryBarsMaxHeight = height
        // bins = how many bars fit across the available width given barWidth + 2pt gap.
        let bins = max(0, Int32(width / ((barWidth * 2) + 2)))
        let layers = random.nextInt(in: 1...2)
        let symmetrical = random.nextBool()               // mirror left half onto right half
        let alignBarsToBottom = random.nextBool(chance: 0.25) // 25% chance bars grow upward from bottom

        // If symmetrical, only compute the left half; the right half is a mirror copy.
        let generatedBins = symmetrical ? Int32(ceil(Double(bins) / 2.0)) : bins

        // --- Primary noise table (layer 1) ---
        // Every bar gets a pre-baked height for every animation frame. 4 lattice columns across the bars and 12
        // rows across the loop give slow shapes; the octaves on top are what make neighbouring bars differ.
        let primaryNoise = bakedNoise(TilingValueNoise(seed: random.next(), columns: 4, rows: 12), bins: bins, generatedBins: generatedBins, symmetrical: symmetrical)
        var noiseMap = [CGFloat](repeating: 0, count: primaryNoise.count)
        for x in 0..<bins {
            let taper = edgeTaper(x: x, bins: bins)
            for t in 0..<frameCount {
                let i = index(x: x, frame: t)
                // abs() keeps all heights positive; scale to the max bar height.
                var noiseValue = abs(primaryNoise[i])
                if !highComplexitySound {
                    // Voice-track look: ignore low-med noise so quiet bars stay flat,
                    // and remap [0.5, 1.0] back to [0, 1.0] so peaks still reach full height.
                    noiseValue = max(0, (noiseValue - 0.5) * 2)
                }
                // Add barWidth as a minimum height so bars are always at least as tall as they are wide.
                noiseMap[i] = barWidth + noiseValue * (primaryBarsMaxHeight - barWidth) * taper
            }
        }

        // --- Secondary noise table (layer 0, background) ---
        // Only generated when layers == 2. A different (seed-derived) noise seed makes it move independently
        // from the primary layer, giving depth. Half the columns make it vary more slowly across the bars,
        // for a wider, background-feel waveform.
        var noiseMap2: [CGFloat]?
        if 1 < layers {
            let secondaryNoise = bakedNoise(TilingValueNoise(seed: random.next(), columns: 2, rows: 12), bins: bins, generatedBins: generatedBins, symmetrical: symmetrical)
            var values = [CGFloat](repeating: 0, count: secondaryNoise.count)
            for x in 0..<bins {
                let taper = edgeTaper(x: x, bins: bins)
                for t in 0..<frameCount {
                    let i = index(x: x, frame: t)
                    // No abs() here — values can be negative, which is clamped to 0 in level().
                    // This layer is an offset added on top of the primary, not a standalone height.
                    var noiseValue = secondaryNoise[i]
                    if !highComplexitySound {
                        // Match the primary layer's thresholding so quiet sections stay flat.
                        // Signed range here is [-1, 1], so threshold at ±0.5 and remap outward.
                        if noiseValue > 0.5 {
                            noiseValue = (noiseValue - 0.5) * 2
                        } else if noiseValue < -0.5 {
                            noiseValue = (noiseValue + 0.5) * 2
                        } else {
                            noiseValue = 0
                        }
                    }
                    values[i] = noiseValue * secondaryBarsMaxDifference * taper
                }
            }
            noiseMap2 = values
        }

        return AudioVisualizerModel(bins: bins, barWidth: barWidth, layers: layers, symmetrical: symmetrical, alignBarsToBottom: alignBarsToBottom, primaryBarsMaxHeight: primaryBarsMaxHeight, noiseMap: noiseMap, noiseMap2: noiseMap2)
    }
}

// Reuses generated models across re-renders. Keyed on everything generation depends on;
// old seeds are never revisited, so the cache is dropped wholesale once it grows large
// (e.g. after repeated Regenerate Seed) rather than tracking eviction per entry.
@MainActor
private enum AudioVisualizerModelCache {

    private struct Key: Hashable {
        let seed: UInt64
        let width: Int
        let height: Int
        let highComplexitySound: Bool
    }

    private static var models: [Key: AudioVisualizerModel] = [:]

    // Loose safety cap, independent of PathCache's — only a handful of keys are ever live (a couple
    // of widths/heights per theme), so this only bites after many Regenerate Seed cycles.
    private static let maxEntries = 16

    static func model(seed: UInt64, width: CGFloat, height: CGFloat, highComplexitySound: Bool) -> AudioVisualizerModel {
        let key = Key(seed: seed, width: Int(width.rounded()), height: Int(height.rounded()), highComplexitySound: highComplexitySound)
        if let cached = models[key] {
            return cached
        }
        if models.count >= maxEntries {
            models.removeAll(keepingCapacity: true)
        }
        let model = AudioVisualizerModel.generate(seed: seed, width: width, height: height, highComplexitySound: highComplexitySound)
        models[key] = model
        return model
    }
}

struct AudioVisualizer: View {

    private static let fadeInDuration: TimeInterval = 0.6       // bars rising when playback (re)starts
    private static let collapseDuration: TimeInterval = 0.5     // bars settling to the baseline when paused

    @Environment(\.system) private var system

    let width: CGFloat
    let height: CGFloat
    let highComplexitySound: Bool

    /// Whole noise loops per second. A single voice track reads calmer at a lower rate; the busier
    /// music look can move faster without looking spasmodic.
    private var frameRate: Double { highComplexitySound ? 30.0 : 12.0 }

    var music = MusicController.shared

    @Binding var isPlaying: Bool

    // Accumulated noise frames banked from completed play segments. While playing, live time
    // is added on top; while paused this stays fixed, so the noise pattern freezes in place.
    @State private var bankedFrames: Double = 0
    // Start of the current play/pause segment — anchors both the noise phase and the envelope ramp.
    @State private var segmentStart = Date.now
    // Height envelope (0...1) at `segmentStart`; the envelope ramps from here toward its target.
    @State private var envelopeAnchor: CGFloat = 0
    // Set once the post-pause collapse finishes, which pauses the timeline so idle bars cost nothing.
    @State private var isIdle = false
    @State private var collapseTask: Task<Void, Never>?

    init(width: CGFloat, height: CGFloat = 200, highComplexitySound: Bool, isPlaying: Binding<Bool>) {
        self.width = width
        self.height = height
        self.highComplexitySound = highComplexitySound
        self._isPlaying = isPlaying
    }

    /// Envelope value `date` seconds into the current segment, easing from the anchor toward the
    /// segment's target (1 while playing, 0 once paused). `playing` is passed explicitly so the
    /// onChange handler can evaluate the *ending* segment before `isPlaying` flips to the new value.
    private func envelope(at date: Date, playing: Bool) -> CGFloat {
        let duration = playing ? Self.fadeInDuration : Self.collapseDuration
        let target: CGFloat = playing ? 1 : 0
        let progress = CGFloat(min(1, max(0, date.timeIntervalSince(segmentStart) / duration)))
        return envelopeAnchor + (target - envelopeAnchor) * progress
    }

    var body: some View {
        // Resolve the cached model and theme values on the main actor, outside the render closure.
        let model = AudioVisualizerModelCache.model(seed: system.seed, width: width, height: height, highComplexitySound: highComplexitySound)
        let foregroundColor = system.colors.color(.primary, opacity: .max)
        let backgroundColor = system.colors.color(.primary, opacity: model.layers == 2 ? .medium : .max)
        let cornerRadius: CGFloat = system.cornerStyle == .sharp ? 0 : model.barWidth / 2
        // Per-bar advance = bar + gap; matches the bins calc (width / (barWidth*2 + 2)).
        let advance = model.barWidth * 2 + 2
        let totalWidth = CGFloat(max(0, model.bins - 1)) * advance + model.barWidth

        // Keep animating while playing and through the post-pause collapse; pause once fully idle.
        TimelineView(.animation(paused: isIdle)) { context in
            // Advance the noise phase only while playing, so pausing freezes the pattern.
            // truncatingRemainder before the Int32 cast — this view runs 24/7, so an unwrapped
            // frame count would eventually overflow.
            let frames = isPlaying ? bankedFrames + context.date.timeIntervalSince(segmentStart) * frameRate : bankedFrames
            let framePos = frames.truncatingRemainder(dividingBy: Double(AudioVisualizerModel.frameCount))
            let frameA = Int32(framePos)
            let frameB = (frameA + 1) % AudioVisualizerModel.frameCount
            let blend = CGFloat(framePos - Double(frameA))
            let envelope = self.envelope(at: context.date, playing: isPlaying)

            Canvas { canvas, size in
                let startX = (size.width - totalWidth) / 2
                for layer in 0..<model.layers {
                    let color = (model.layers == 2 && layer == 0) ? backgroundColor : foregroundColor
                    for x in 0..<model.bins {
                        // Envelope blends between the flat resting height (barWidth) and the full
                        // noise height, so pausing settles every bar down to the baseline bar.
                        let noiseHeight = model.level(x: x, frameA: frameA, frameB: frameB, blend: blend, layer: layer)
                        let barHeight = model.barWidth + (noiseHeight - model.barWidth) * envelope
                        guard barHeight > 0 else { continue }
                        let barX = startX + CGFloat(x) * advance
                        let barY = model.alignBarsToBottom ? (size.height - barHeight) : (size.height - barHeight) / 2
                        let rect = CGRect(x: barX, y: barY, width: model.barWidth, height: barHeight)
                        canvas.fill(Path(roundedRect: rect, cornerRadius: cornerRadius), with: .color(color))
                    }
                }
            }
        }
        .frame(height: model.primaryBarsMaxHeight + AudioVisualizerModel.secondaryBarsMaxDifference)
        .onAppear {
            segmentStart = .now
            envelopeAnchor = 0
            isIdle = !isPlaying
        }
        .onChange(of: isPlaying) { wasPlaying, nowPlaying in
            let now = Date.now
            // Bank the frames played this segment so the frozen pattern resumes seamlessly.
            if wasPlaying {
                bankedFrames += now.timeIntervalSince(segmentStart) * frameRate
            }
            // Carry the ending segment's current envelope value into the new segment so it ramps
            // from where it is. Evaluate against the old segmentStart before resetting it below.
            envelopeAnchor = envelope(at: now, playing: wasPlaying)
            segmentStart = now
            collapseTask?.cancel()
            if nowPlaying {
                isIdle = false
                collapseTask = nil
            } else {
                // Let the collapse animate, then pause the timeline.
                collapseTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(Self.collapseDuration))
                    isIdle = true
                }
            }
        }
        .onChange(of: music.artwork) { _, _ in
            // Restart the waveform and fade-in for the new track.
            bankedFrames = 0
            envelopeAnchor = 0
            segmentStart = .now
            if isPlaying {
                collapseTask?.cancel()
                collapseTask = nil
                isIdle = false
            }
        }
        .onDisappear {
            collapseTask?.cancel()
        }
    }
}

#Preview {
    AudioVisualizer(width: 400, highComplexitySound: true, isPlaying: .constant(true))
}
