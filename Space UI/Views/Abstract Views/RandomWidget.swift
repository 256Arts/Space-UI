//
//  RandomWidget.swift
//  Space UI
//
//  Created by Jayden Irwin on 2022-10-07.
//  Copyright © 2022 Jayden Irwin. All rights reserved.
//

import SwiftUI

struct RandomWidget: View {
    
    enum WidgetType {
        case circularWidget, almostThereText, binary, boxes, largeIcons, knobs
    }
    
    let did: Int // Design ID
    let vid: Int // Value ID
    
    @Environment(\.elementSize) private var elementSize
    
    @State var widgetType: WidgetType
    @State var notificationShadowColor = Color(color: .primary, opacity: .medium)
    @State var notificationOpacity = 1.0
    @StateObject private var almostThereNumber = IntSequencer(frequency: TimeInterval.random(in: 0.1...5.0), initialValue: Int.random(in: 0...9999), maxValue: 9999)
    
    var almostThereDigitCount: Int {
        switch elementSize {
        case .small:
            return 3
        case .mini:
            return 2
        default:
            return 4
        }
    }
    
    var body: some View {
        switch widgetType {
        case .circularWidget:
            RandomCircularWidget(did: did + 7, vid: vid)
        case .almostThereText:
            AlmostThereNumberText(number: self.$almostThereNumber.value, digitCount: almostThereDigitCount)
        case .binary:
            VStack {
                BinaryView(value: (Int(system.seed) + vid) % 64)
                BinaryView(value: (Int(system.seed) + (vid + 7)) % 64)
            }
        case .boxes:
            DecorativeBoxesView()
        case .largeIcons:
            HStack {
                ForEach(0..<(1 + (vid % 2))) { index in
                    LargeIcon.image(vid: vid + index)
                        .foregroundColor(Color(color: .primary, opacity: .max))
                        .shadow(color: self.notificationShadowColor, radius: 10, x: 0, y: 0)
                        .opacity(self.notificationOpacity)
                }
            }
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                    self.notificationShadowColor = .clear
                    self.notificationOpacity = 0.5
                }
            }
        case .knobs:
            Knobs(did: did + 7, vid: vid)
        }
    }
    
    init(did: Int, vid: Int) {
        self.did = did
        self.vid = vid
        
        let widgetValue: WidgetType
        switch (Int(system.seed) + did) % 10 {
        case 0:
            widgetValue = .almostThereText
        case 1:
            widgetValue = .binary
        case 2:
            widgetValue = .boxes
        case 3:
            widgetValue = .largeIcons
        case 4:
            widgetValue = .knobs
        default:
            widgetValue = .circularWidget
        }
        _widgetType = State(initialValue: widgetValue)
    }
    
}

struct RandomWidget_Previews: PreviewProvider {
    static var previews: some View {
        RandomWidget(did: 0, vid: 0)
    }
}
