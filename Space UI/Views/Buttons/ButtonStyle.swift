//
//  SpaceButtonStyle.swift
//  Space UI
//
//  Created by Jayden Irwin on 2019-12-15.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import SwiftUI

struct FlexButtonStyle: ButtonStyle {
    
    var isSelected: Bool = false
    var isDisabled: Bool = false
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .lineLimit(1)
            .accentColor(Color(color: .secondary, opacity: .max))
            .foregroundColor(Color(color: .secondary, opacity: .max))
            .multilineTextAlignment(.center)
            .padding(12)
            .frame(height: system.flexButtonFrameHeight)
            .frame(minWidth: system.flexButtonFrameHeight)
            .background(self.isDisabled ? .clear : (self.isSelected ? Color(color: .tertiary, brightness: .medium) : Color(color: .primary, brightness: .low)))
            .cornerRadius(system.cornerRadius(forLength: system.flexButtonFrameHeight))
            .overlay(
                system.prefersButtonBorders ?
                RoundedRectangle(cornerRadius: system.cornerRadius(forLength: system.flexButtonFrameHeight))
                    .strokeBorder(Color(color: self.isSelected ? .tertiary : .primary, brightness: self.isDisabled ? .medium : .max), style: system.strokeStyle(.medium))
                : nil
            )
            .opacity(configuration.isPressed ? 0.5 : 1.0)
            .fixedSize()
    }
}

struct ShapeButtonStyle: ButtonStyle {
    
    let shapeDirection: ShapeDirection
    
    var isSelected: Bool = false
    var isDisabled: Bool = false
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .lineLimit(1)
            .accentColor(Color(color: .secondary, opacity: .max))
            .foregroundColor(Color(color: .secondary, opacity: .max))
            .multilineTextAlignment(.center)
            .padding(buttonTextPadding())
            .frame(width: system.shapeButtonFrameWidth, height: system.shapeButtonFrameHeight)
            .background(self.isDisabled ? .clear : (self.isSelected ? Color(color: .tertiary, brightness: .medium) : Color(color: .primary, brightness: .low)))
            .clipShape(AutoShape(direction: shapeDirection))
            .overlay(
                system.prefersButtonBorders ?
                AutoShape(direction: shapeDirection)
                    .strokeBorder(Color(color: self.isSelected ? .tertiary : .primary, brightness: self.isDisabled ? .medium : .max), style: system.strokeStyle(.medium))
                : nil
            )
            .opacity(configuration.isPressed ? 0.5 : 1.0)
    }
    
    func buttonTextPadding() -> EdgeInsets {
        switch system.basicShape {
        case .triangle:
            return EdgeInsets(top: shapeDirection == .up ? 26 : 18, leading: 22, bottom: shapeDirection == .up ? 18 : 26, trailing: 22)
        case .trapezoid:
            return EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)
        case .diamond:
            return EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        default:
            return EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        }
    }
    
}

struct SpaceButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            Button(action: { }) {
                Text("Hello")
            }.buttonStyle(FlexButtonStyle())
            Button(action: { }) {
                Text("Hello")
            }.buttonStyle(ShapeButtonStyle(shapeDirection: .up))
        }
    }
}
