import Foundation

/// Generate random ints and allow SwiftUI to observe them
@MainActor @Observable
final class IntGenerator {

    let range: ClosedRange<Int>
    let averageFrequency: TimeInterval

    var value: Int

    /// Held so a generator that is built and immediately discarded — `@State` re-runs its default on every
    /// view init — takes its loop with it instead of ticking forever on nothing.
    private var task: Task<Void, Never>?

    init(range: ClosedRange<Int>, delay: TimeInterval = 1, averageFrequency: TimeInterval = 1, initialValue: Int = 0) {
        self.range = range
        self.averageFrequency = averageFrequency
        self.value = initialValue

        // `self` is resolved after each sleep, never held across one, so a discarded generator can deinit.
        task = Task { [weak self] in
            var nextDelay = delay
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(nextDelay))
                guard let self else { return }
                self.value = Int.random(in: self.range)
                nextDelay = self.averageFrequency * Double.random(in: 0.75...1.25)
            }
        }
    }

    isolated deinit {
        task?.cancel()
    }
}

/// Generate random doubles and allow SwiftUI to observe them
@MainActor @Observable
final class DoubleGenerator {

    let range: ClosedRange<Double>
    let averageFrequency: TimeInterval

    var value: Double

    /// Held so a generator that is built and immediately discarded — `@State` re-runs its default on every
    /// view init — takes its loop with it instead of ticking forever on nothing.
    private var task: Task<Void, Never>?

    init(range: ClosedRange<Double> = 0.0...1.0, delay: TimeInterval = 1, averageFrequency: TimeInterval = 1, initialValue: Double = 0.0) {
        self.range = range
        self.averageFrequency = averageFrequency
        self.value = initialValue

        // `self` is resolved after each sleep, never held across one, so a discarded generator can deinit.
        task = Task { [weak self] in
            var nextDelay = delay
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(nextDelay))
                guard let self else { return }
                self.value = Double.random(in: self.range)
                nextDelay = self.averageFrequency * Double.random(in: 0.75...1.25)
            }
        }
    }

    isolated deinit {
        task?.cancel()
    }
}

/// Generate ints in a increasing/decreasing sequence and allow SwiftUI to observe them
@MainActor @Observable
final class IntSequencer {

    let frequency: TimeInterval
    let maxValue: Int

    var isPlaying: Bool
    private var task: Task<Void, Never>?

    var value: Int

    init(isPlaying: Bool = true, frequency: TimeInterval = 1, initialValue: Int = 0, maxValue: Int) {
        self.isPlaying = isPlaying
        self.frequency = frequency
        self.value = initialValue
        self.maxValue = maxValue

        if isPlaying {
            startIncreasing()
        }
    }

    func startIncreasing() {
        start(step: 1)
    }

    func startDecreasing() {
        start(step: -1)
    }

    private func start(step: Int) {
        self.isPlaying = true
        self.task?.cancel()
        // `self` is resolved after each sleep, never held across one, so a discarded sequencer can deinit.
        self.task = Task { [weak self] in
            while !Task.isCancelled {
                guard let frequency = self?.frequency else { return }
                try? await Task.sleep(for: .seconds(frequency))
                guard !Task.isCancelled, let self else { return }
                self.advance(by: step)
            }
        }
    }

    /// Steps the value one place, wrapping around either end of `0...maxValue`.
    private func advance(by step: Int) {
        let count = maxValue + 1
        value = (value + step + count) % count
    }

    func stop() {
        self.isPlaying = false
        self.task?.cancel()
        self.task = nil
    }

    isolated deinit {
        task?.cancel()
    }
}
