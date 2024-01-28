//
//  CircularProgressExtPageLeft.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2022-10-28.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct CircularProgressExtPageLeft: View {
    
    struct CircularProgressRow: View {
        
        let did: Int
        let vid: Int
        
        @StateObject private var progressPublisher1 = DoubleGenerator(averageFrequency: 8)
        @StateObject private var progressPublisher2 = DoubleGenerator(averageFrequency: 8)
        @StateObject private var progressPublisher3 = DoubleGenerator(averageFrequency: 8)
        
        var body: some View {
            HStack {
                CircularProgressView(did: did, value: .constant(1)) {
                    CircularProgressView(did: did, value: $progressPublisher1.value) {
                        TextPair(did: did, label: Lorem.word(vid: vid + 1), value: Lorem.word(vid: vid + 2))
                            .padding(20)
                    }
                    .padding(20)
                }
                VStack {
                    RoundedRectangle(cornerRadius: system.cornerRadius(forLength: system.thinLineWidth))
                        .frame(height: system.thinLineWidth)
                        .foregroundColor(Color(color: .primary, opacity: .medium))
                    HStack {
                        CircularProgressView(did: did, value: $progressPublisher2.value, lineWidth: 10) {
                            CircularProgressView(did: did, value: .constant(1)) {
                                Hexagon()
                                    .stroke(style: system.strokeStyle(.medium))
                                    .padding(20)
                            }
                            .padding(20)
                            #if os(tvOS)
                            .environment(\.elementSize, .regular)
                            #endif
                        }
                        .overlay(alignment: .topLeading) {
                            Text(Lorem.word(vid: vid + 3))
                                .lineLimit(1)
                                .offset(x: -20, y: -60)
                        }
                        CircularProgressView(did: did, value: $progressPublisher3.value, lineWidth: 10) {
                            CircularProgressView(did: did, value: .constant(1)) {
                                Hexagon()
                                    .stroke(style: system.strokeStyle(.medium))
                                    .padding(20)
                            }
                            .padding(20)
                            #if os(tvOS)
                            .environment(\.elementSize, .regular)
                            #endif
                        }
                        .overlay(alignment: .topLeading) {
                            Text(Lorem.word(vid: vid + 4))
                                .lineLimit(1)
                                .offset(x: -20, y: -60)
                        }
                        VStack(spacing: 30) {
                            Triangle()
                                .stroke(style: system.strokeStyle(.thin))
                                .rotationEffect(.degrees(90))
                            Triangle()
                                .stroke(style: system.strokeStyle(.thin))
                                .rotationEffect(.degrees(90))
                        }
                        .frame(height: 100)
                        Spacer()
                    }
                    RoundedRectangle(cornerRadius: system.cornerRadius(forLength: system.thinLineWidth))
                        .frame(height: system.thinLineWidth)
                        .foregroundColor(Color(color: .primary, opacity: .medium))
                }
            }
            .overlay(alignment: .bottomTrailing) {
                MorseCodeLine(vid: vid + 5)
                    .frame(width: 80)
                    .offset(x: -80)
            }
        }
    }
    
    @IDGen private var idGen
    
    let circularProgressRowPadding: CGFloat = 30
    
    var body: some View {
        HStack {
            VStack {
                CircularProgressRow(did: idGen(1), vid: idGen(1))
                    .padding(circularProgressRowPadding)
                
                RoundedRectangle(cornerRadius: system.cornerRadius(forLength: system.thinLineWidth))
                    .frame(height: system.thinLineWidth)
                    .foregroundColor(Color(color: .primary, opacity: .min))
                
                CircularProgressRow(did: idGen(1), vid: idGen(2))
                    .padding(circularProgressRowPadding)
            }
            
            GeometryReader { geometry in
                ZStack {
                    DecorativeRaysView(cycleCount: 100)
                        .frame(width: geometry.size.height * 0.9, height: geometry.size.height * 0.9)
                    Hexagon()
                        .foregroundColor(Color.screenBackground)
                        .frame(width: geometry.size.height * 0.25, height: geometry.size.height * 0.25)
                    GridShape(rows: 10, columns: 10)
                        .stroke(style: system.strokeStyle(.thin))
                        .foregroundColor(Color(color: .primary, opacity: .min))
                    AsteriskShape(ticks: 64, innerRadiusFraction: 0.94)
                        .stroke(Color(color: .primary, brightness: .max), style: system.strokeStyle(.thick))
                    Hexagon()
                        .stroke(style: system.strokeStyle(.medium))
                        .frame(width: geometry.size.height * 0.75, height: geometry.size.height * 0.75)
                    Hexagon()
                        .stroke(style: system.strokeStyle(.medium))
                        .frame(width: geometry.size.height * 0.5, height: geometry.size.height * 0.5)
                    Hexagon()
                        .stroke(style: system.strokeStyle(.medium))
                        .frame(width: geometry.size.height * 0.25, height: geometry.size.height * 0.25)
                }
                .overlay(alignment: .top) {
                    HStack(spacing: 0) {
                        ForEach(0..<10) { index in
                            Text(Lorem.word(vid: index))
                                .lineLimit(1)
                                .padding(8)
                                .frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fill)
            }
            .aspectRatio(0.5, contentMode: .fit)
        }
    }
}

#Preview {
    CircularProgressExtPageLeft()
}
