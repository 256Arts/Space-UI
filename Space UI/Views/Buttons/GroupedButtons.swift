//
//  GroupedButtons.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-26.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct GroupedButtons {
    
    enum Style {
        case roundedRect, capsule
    }
    enum SegmentPosition {
        case leading, middle, trailing
    }
    
//    @State var titles: [String]
//    @State var selectedIndex: Int?
//
//    var body: some View {
//        HStack {
//            Button(action: {
//                AudioController.shared.play(.button)
//            }, label: {
//                Text(self.titles.first!)
//            }).buttonStyle(GroupedButtonStyle(segmentPosition: .leading, isSelected: self.selectedIndex == 0))
//
//            ForEach(Array(self.titles[1..<self.titles.count-1]), id: \.self) { title in
//                Button(action: {
//                    AudioController.shared.play(.button)
//                }, label: {
//                    Text(title)
//                }).buttonStyle(GroupedButtonStyle(segmentPosition: .middle, isSelected: self.selectedIndex == 1))
//            }
//
//            Button(action: {
//                AudioController.shared.play(.button)
//            }, label: {
//                Text(self.titles.last!)
//            }).buttonStyle(GroupedButtonStyle(segmentPosition: .trailing, isSelected: self.selectedIndex == 2))
//        }
//    }
}

struct GroupedButtonStyle: ButtonStyle {
    
    let segmentPosition: GroupedButtons.SegmentPosition
    var width: CGFloat = system.shapeButtonFrameWidth
    var isSelected: Bool = false
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .accentColor(Color(color: .secondary, brightness: .max))
            .foregroundColor(Color(color: .secondary, brightness: .max))
            .multilineTextAlignment(.center)
            .padding(8)
            .frame(width: width, height: system.flexButtonFrameHeight)
            .background(self.isSelected ? Color(color: .tertiary, brightness: .medium) : Color(color: .primary, brightness: .low))
            .clipShape(GroupedButtonShape(segmentPosition: segmentPosition))
            .overlay {
                if system.prefersButtonBorders {
                    GroupedButtonShape(segmentPosition: segmentPosition)
                        .strokeBorder(Color(color: self.isSelected ? .tertiary : .primary, brightness: .max), style: system.strokeStyle(.medium))
                }
            }
            .opacity(configuration.isPressed ? 0.5 : 1.0)
    }
}

struct GroupedButtonShape: InsettableShape {
    
    var segmentPosition: GroupedButtons.SegmentPosition
    var insetAmount: CGFloat = 0.0
    
    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let largeCornerRadius: CGFloat
        let smallCornerRadius: CGFloat
        
        if case .sharp = system.cornerStyle {
            largeCornerRadius = insetRect.height/4
            smallCornerRadius = 0
        } else {
            largeCornerRadius = system.cornerRadius(forLength: insetRect.height)
            smallCornerRadius = system.cornerRadius(forLength: insetRect.height)/3
        }
        
        switch segmentPosition {
        case .leading:
            return Path.roundedRectPath(in: insetRect, leadingCornerRadius: largeCornerRadius, trailingCornerRadius: smallCornerRadius)
        case .trailing:
            return Path.roundedRectPath(in: insetRect, leadingCornerRadius: smallCornerRadius, trailingCornerRadius: largeCornerRadius)
        default:
            return Path.roundedRectPath(in: insetRect, leadingCornerRadius: smallCornerRadius, trailingCornerRadius: smallCornerRadius)
        }
    }
    
    func inset(by amount: CGFloat) -> some InsettableShape {
        var arc = self
        arc.insetAmount += amount
        return arc
    }
}

//struct GroupedButtons_Previews: PreviewProvider {
//    static var previews: some View {
//        GroupedButtons(titles: ["<", "O", ">"])
//    }
//}
