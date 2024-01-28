//
//  DoubleGenerator.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2022-09-16.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

import Foundation

/// Generate random ints and allow SwiftUI to observe them
class IntGenerator: ObservableObject {
    
    let range: ClosedRange<Int>
    let averageFrequency: TimeInterval
    
    @Published var value: Int
    
    init(range: ClosedRange<Int>, delay: TimeInterval = 1, averageFrequency: TimeInterval = 1, initialValue: Int = 0) {
        self.range = range
        self.averageFrequency = averageFrequency
        self.value = initialValue
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.refreshValue()
        }
    }
    
    private func refreshValue() {
        self.value = Int.random(in: range)
        
        let delay = averageFrequency * Double.random(in: 0.75...1.25)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.refreshValue()
        }
    }
}

/// Generate random doubles and allow SwiftUI to observe them
class DoubleGenerator: ObservableObject {
    
    let range: ClosedRange<Double>
    let averageFrequency: TimeInterval
    
    @Published var value: Double
    
    init(range: ClosedRange<Double> = 0.0...1.0, delay: TimeInterval = 1, averageFrequency: TimeInterval = 1, initialValue: Double = 0.0) {
        self.range = range
        self.averageFrequency = averageFrequency
        self.value = initialValue
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.refreshValue()
        }
    }
    
    private func refreshValue() {
        self.value = Double.random(in: range)
        
        let delay = averageFrequency * Double.random(in: 0.75...1.25)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.refreshValue()
        }
    }
}

/// Generate ints in a sequence and allow SwiftUI to observe them
class IntSequencer: ObservableObject {
    
    let frequency: TimeInterval
    let maxValue: Int
    
    var isPlaying: Bool
    private var timer: Timer?
    
    @Published var value: Int
    
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
        self.isPlaying = true
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: frequency, repeats: true, block: { _ in
            if self.value == self.maxValue {
                self.value = 0
            } else {
                self.value += 1
            }
        })
    }
    func startDecreasing() {
        self.isPlaying = true
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: frequency, repeats: true, block: { _ in
            if self.value == 0 {
                self.value = self.maxValue
            } else {
                self.value -= 1
            }
        })
    }
    
    func stop() {
        self.isPlaying = false
        self.timer?.invalidate()
    }
}
