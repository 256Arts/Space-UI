//
//  RandomCircularWidget.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-12-04.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct RandomCircularWidget: View {
    
    enum WidgetType {
        case circularProgressView, circularSegmentedView, decorativePolygon, spirograph
    }
    
    @Environment(\.elementSize) private var elementSize
    var idealWidgetLength: CGFloat {
        switch elementSize {
        case .mini:
            return 32
        case .small:
            return 56
        case .regular:
            return 64
        case .large:
            return 96
        }
    }
    
    @State var widgetType: WidgetType
    @State var label: String
    @StateObject private var progress = DoubleGenerator(averageFrequency: 8)
    @State private var spirographDistance: CGFloat = 26
    
    var body: some View {
        switch widgetType {
        case .circularProgressView:
            CircularProgressView(did: 0, value: self.$progress.value) {
                if elementSize != .mini {
                    Text(label)
                }
            }
            .frame(minWidth: 32, idealWidth: idealWidgetLength, maxWidth: 96, minHeight: 32, idealHeight: idealWidgetLength, maxHeight: 96)
        case .circularSegmentedView:
            CircularSegmentedView()
                .frame(minWidth: 32, idealWidth: idealWidgetLength, maxWidth: 96, minHeight: 32, idealHeight: idealWidgetLength, maxHeight: 96)
        case .decorativePolygon:
            DecorativePolygon(sides: 7)
                .stroke(Color(color: .primary, opacity: system.colors.paletteStyle == .monochrome ? .low : .medium), style: system.strokeStyle(.thin))
                .frame(minWidth: 32, idealWidth: idealWidgetLength, maxWidth: 96, minHeight: 32, idealHeight: idealWidgetLength, maxHeight: 96)
                .overlay {
                    if elementSize != .mini {
                        Text(label).multilineTextAlignment(.center).padding(16)
                    }
                }
        case .spirograph:
            Spirograph(innerRadius: 32, outerRadius: 22, distance: spirographDistance)
                .stroke(Color(color: .primary, opacity: system.colors.paletteStyle == .monochrome ? .low : .medium), style: system.strokeStyle(.thin))
                .frame(minWidth: 32, idealWidth: idealWidgetLength, maxWidth: 96, minHeight: 32, idealHeight: idealWidgetLength, maxHeight: 96)
                .overlay {
                    if elementSize != .mini {
                        Text(label).multilineTextAlignment(.center).padding(16)
                    }
                }
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                        self.spirographDistance = 34
                    }
                }
        }
    }
    
    init(did: Int, vid: Int) {
        let widgetValue: WidgetType
        switch did % 5 {
        case 0:
            widgetValue = .circularProgressView
        case 1:
            widgetValue = .circularSegmentedView
        case 2:
            widgetValue = .decorativePolygon
        default:
            widgetValue = .spirograph
        }
        _widgetType = State(initialValue: widgetValue)
        _label = State(initialValue: Lorem.word(vid: vid + 27))
    }
    
}

#Preview {
    RandomCircularWidget(did: 0, vid: 0)
}
