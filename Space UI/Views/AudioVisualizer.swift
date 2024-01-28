//
//  AudioVisualizer.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-03-15.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI
import GameplayKit

struct AudioVisualizer: View {
    
    static let frameCount: Int32 = 150
    
    let barWidth: CGFloat
    let primaryBarsMaxHeight: CGFloat = 200.0
    let secondaryBarsMaxDifferance: CGFloat = 80.0
    let bins: Int32
    let noiseMap: [vector_int2: CGFloat]
    let noiseMap2: [vector_int2: CGFloat]?
    let layers: Int
    let symmetrical: Bool
    let alignBarsToBottom: Bool
    
    @ObservedObject var music = MusicController.shared
    
    @State var frame: Int32 = 0
    @State var volume: CGFloat = 1.0
    @State var frameTimer: Timer?
    
    var body: some View {
        ZStack {
            ForEach(0..<layers) { layer in
                VStack {
                    if self.alignBarsToBottom {
                        Spacer()
                    }
                    HStack(alignment: self.alignBarsToBottom ? .bottom : .center, spacing: self.barWidth+2) {
                        ForEach(0..<self.bins, id: \.self) { x in
                            RoundedRectangle(cornerRadius: system.cornerStyle == .sharp ? 0 : self.barWidth/2)
                                .foregroundColor(Color(color: .primary, opacity: (self.layers == 2 && layer == 0) ? .medium : .max))
                                .frame(width: self.barWidth, height: self.level(x: x, layer: layer))
                        }
                    }
                }
            }
        }
        .frame(height: self.primaryBarsMaxHeight + self.secondaryBarsMaxDifferance)
        .animation(Animation.linear, value: frame)
        .onAppear {
            frameTimer = Timer.scheduledTimer(withTimeInterval: 0.033333, repeats: true) { (_) in
                if self.music.isPlaying {
                    self.frame += 1
                    self.frame %= AudioVisualizer.frameCount
                    if self.volume < 1.0 {
                        self.volume += 0.02
                    }
                }
            }
        }
        .onChange(of: music.artwork) { (_) in
            self.frame = 0
            self.volume = 0
        }
        .onDisappear {
            frameTimer?.invalidate()
        }
        .drawingGroup()
    }
    
    init(width: CGFloat) {
        let random: GKRandom = {
            let source = GKMersenneTwisterRandomSource(seed: system.seed)
            return GKRandomDistribution(randomSource: source, lowestValue: 0, highestValue: Int.max)
        }()
        self.barWidth = CGFloat(random.nextInt(in: 5...8))
        self.bins = Int32(width / ((barWidth*2) + 2))
        self.layers = random.nextInt(in: 1...2)
        self.symmetrical = random.nextBool()
        self.alignBarsToBottom = random.nextBool(chance: 0.25)
        
        let noise = GKNoise(GKPerlinNoiseSource())
        let map = GKNoiseMap(noise, size: vector_double2(x: 4, y: 12), origin: vector_double2(), sampleCount: vector_int2(x: bins, y: AudioVisualizer.frameCount), seamless: true)
        var values = [vector_int2: CGFloat]()
        let generatedBins = symmetrical ? Int32(ceil(Double(bins)/2.0)) : bins
        for x in 0..<generatedBins {
            for t in 0..<AudioVisualizer.frameCount {
                var val = abs(CGFloat(map.value(at: vector_int2(x: x, y: t)))) * (primaryBarsMaxHeight - barWidth)
                switch x {
                case 0, bins-1:
                    val *= 0.15
                case 1, bins-2:
                    val *= 0.3
                case 2, bins-3:
                    val *= 0.55
                case 3, bins-4:
                    val *= 0.8
                default:
                    break
                }
                values[vector_int2(x: x, y: t)] = barWidth + val
            }
        }
        if symmetrical {
            // Mirrored bins
            for x in generatedBins..<bins {
                for t in 0..<AudioVisualizer.frameCount {
                    values[vector_int2(x: x, y: t)] = values[vector_int2(x: bins-1-x, y: t)]
                }
            }
        }
        self.noiseMap = values
        
        if 1 < layers {
            let source2 = GKPerlinNoiseSource()
            source2.seed = Int32.random(in: Int32.min...Int32.max)
            let noise2 = GKNoise(source2)
            let map2 = GKNoiseMap(noise2, size: vector_double2(x: 24, y: 12), origin: vector_double2(), sampleCount: vector_int2(x: bins, y: AudioVisualizer.frameCount), seamless: true)
            var values2 = [vector_int2: CGFloat]()
            for x in 0..<generatedBins {
                for t in 0..<AudioVisualizer.frameCount {
                    var val = CGFloat(map2.value(at: vector_int2(x: x, y: t))) * self.secondaryBarsMaxDifferance
                    switch x {
                    case 0, bins-1:
                        val *= 0.15
                    case 1, bins-2:
                        val *= 0.3
                    case 2, bins-3:
                        val *= 0.55
                    case 3, bins-4:
                        val *= 0.8
                    default:
                        break
                    }
                    values2[vector_int2(x: x, y: t)] = val
                }
            }
            if symmetrical {
                // Mirrored bins
                for x in generatedBins..<bins {
                    for t in 0..<AudioVisualizer.frameCount {
                        values2[vector_int2(x: x, y: t)] = values2[vector_int2(x: bins-1-x, y: t)]
                    }
                }
            }
            self.noiseMap2 = values2
        } else {
            self.noiseMap2 = nil
        }
    }
    
    func level(x: Int32, layer: Int) -> CGFloat {
        guard self.music.isPlaying else { return barWidth }
        let noiseValue: CGFloat
        if layer == 1 || layers == 1 {
            noiseValue = noiseMap[vector_int2(x: x, y: self.frame)]!
        } else {
            noiseValue = max(0, noiseMap[vector_int2(x: x, y: self.frame)]! + noiseMap2![vector_int2(x: x, y: self.frame)]!)
        }
        return noiseValue * self.volume
    }
    
}

#Preview {
    AudioVisualizer(width: 400)
}
