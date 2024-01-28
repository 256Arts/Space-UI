//
//  OrbitsExtPage.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-15.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI
import GameplayKit

struct AutoCompass: View {
    
    let useGridCompassStyle: Bool
    
    var body: some View {
        if self.useGridCompassStyle {
            GridCompass()
        } else {
            Compass()
        }
    }
}

struct OrbitsExtPage: View {
    
    let has2textLists = Bool.random()
    let hasLongNumericalSection = Bool.random()
    let useGridCompassStyle = Bool.random()
    
    @IDGen private var idGen
    @Environment(\.safeCornerOffsets) private var safeCornerOffsets
    
    @ObservedObject var music = MusicController.shared
    
    @StateObject private var progressPublisher1 = DoubleGenerator(averageFrequency: 8)
    @StateObject private var progressPublisher2 = DoubleGenerator(averageFrequency: 8)
    @StateObject private var progressPublisher3 = DoubleGenerator(averageFrequency: 8)
    @StateObject private var progressPublisher4 = DoubleGenerator(averageFrequency: 8)
    @StateObject private var progressPublisher5 = DoubleGenerator(averageFrequency: 8)
    @StateObject private var progressPublisher6 = DoubleGenerator(averageFrequency: 8)
    
    var body: some View {
        VStack {
            OrbitsView()
                .overlay(alignment: .topLeading) {
                    TextPair(did: idGen(0), label: "Realtime", value: "Orbits", largerFontSize: 50)
                        .multilineTextAlignment(.leading)
                        .offset(safeCornerOffsets.topLeading)
                }
                .overlay(alignment: .topTrailing) {
                    AutoCompass(useGridCompassStyle: self.useGridCompassStyle)
                        .frame(width: 150, height: 150)
                        .offset(safeCornerOffsets.topTrailing)
                }
            if system.screen.screenShapeType != .verticalHexagon {
                HStack {
                    if self.has2textLists {
                        ViewThatFits {
                            VStack(spacing: 10) {
                                RoundedRectangle(cornerRadius: system.cornerRadius(forLength: 40))
                                    .stroke(Color(color: .primary, opacity: .max), style: system.strokeStyle(.medium))
                                    .foregroundColor(Color.clear)
                                    .frame(height: 40)
                                    .frame(idealWidth: .infinity, maxWidth: .infinity)
                                    .overlay(Text(Lorem.words(vid: idGen(1), count: 2)))
                                ForEach(0..<8) { index in
                                    HStack {
                                        Text(Lorem.word(vid: idGen(30) + index))
                                        Spacer()
                                        Text(Lorem.word(vid: idGen(38) + index))
                                    }
                                    .lineLimit(1)
                                }
                            }
                            EmptyView()
                        }
                    }
                    VStack {
                        HStack(alignment: .top) {
                            VStack {
                                BinaryView(value: 53)
                                Text(Lorem.word(vid: idGen(4)))
                            }
                            AutoGrid(spacing: 16, ignoreMaxSize: false) {
                                ForEach(0..<4) { index in
                                    CircleIcon.image(vid: idGen(index))
                                }
                            }
                            VStack {
                                BinaryView(value: 13)
                                Text(Lorem.word(vid: idGen(99)))
                            }
                        }
                        HStack {
                            RandomCircularWidget(did: idGen(6), vid: idGen(6))
                                .frame(width: 120, height: 100)
                            VStack {
                                BinaryView(value: 23)
                                Text(Lorem.word(vid: idGen(6)))
                            }
                            RandomCircularWidget(did: idGen(7), vid: idGen(7))
                                .frame(width: 120, height: 100)
                        }
                        HStack(spacing: 16) {
                            CircularProgressView(did: idGen(1), value: $progressPublisher1.value) {
                                Text(Lorem.word(vid: idGen(7)))
                            }
                            CircularProgressView(did: idGen(1), value: $progressPublisher2.value) {
                                Text(Lorem.word(vid: idGen(8)))
                            }
                            CircularProgressView(did: idGen(1), value: $progressPublisher3.value) {
                                Text(Lorem.word(vid: idGen(9)))
                            }
                            CircularProgressView(did: idGen(1), value: $progressPublisher4.value) {
                                Text(Lorem.word(vid: idGen(10)))
                            }
                            if hasLongNumericalSection {
                                CircularProgressView(did: idGen(1), value: $progressPublisher5.value) {
                                    Text(Lorem.word(vid: idGen(11)))
                                }
                                CircularProgressView(did: idGen(1), value: $progressPublisher6.value) {
                                    Text(Lorem.word(vid: idGen(12)))
                                }
                            }
                        }
                        .aspectRatio(hasLongNumericalSection ? 6 : 4, contentMode: .fit)
                    }
                    .multilineTextAlignment(.center)
                    VStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: system.cornerRadius(forLength: 40))
                            .stroke(Color(color: .primary, opacity: .max), style: system.strokeStyle(.medium))
                            .foregroundColor(Color.clear)
                            .frame(height: 40)
                            .frame(idealWidth: .infinity, maxWidth: .infinity)
                            .overlay(Text(Lorem.words(vid: idGen(13), count: 2)))
                        ForEach(0..<8) { index in
                            HStack {
                                Text(Lorem.word(vid: idGen(14) + index))
                                Spacer()
                                Text(Lorem.word(vid: idGen(22) + index))
                            }
                            .lineLimit(1)
                        }
                    }
                }
                .frame(maxHeight: 500)
                .environment(\.elementSize, .regular)
            }
        }
        .animation(.linear(duration: 8), value: progressPublisher1.value)
        .animation(.linear(duration: 8), value: progressPublisher2.value)
        .animation(.linear(duration: 8), value: progressPublisher3.value)
        .animation(.linear(duration: 8), value: progressPublisher4.value)
        .animation(.linear(duration: 8), value: progressPublisher5.value)
        .animation(.linear(duration: 8), value: progressPublisher6.value)
        #if os(tvOS)
        .fullScreenCover(isPresented: $music.isStarWarsMainTitleSoundtrack) {
            MainTitleScrollView()
        }
        #endif
    }
}

#Preview {
    OrbitsExtPage()
}
