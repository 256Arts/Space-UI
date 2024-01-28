//
//  KeyboardView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-31.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI
import GameplayKit

struct KeyboardButtonShape: InsettableShape {
    
    var insetAmount: CGFloat = 0.0
    
    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        if system.basicShape == .circle {
            return Circle().path(in: insetRect)
        } else {
            return RoundedRectangle(cornerRadius: system.cornerRadius(forLength: rect.width)).path(in: insetRect)
        }
    }
    
    func inset(by amount: CGFloat) -> some InsettableShape {
        var arc = self
        arc.insetAmount += amount
        return arc
    }
}

struct KeyboardButtonStyle: ButtonStyle {
    
    @EnvironmentObject private var system: SystemStyles
    
    let keyHeight: CGFloat
    var special = false
    var disabled = false
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
        .accentColor(Color(color: .secondary, opacity: .max))
        .foregroundColor(Color(color: .secondary, opacity: .max))
        .multilineTextAlignment(.center)
        .font(Font.spaceFont(size: 22))
        .padding(8)
        .frame(width: 66, height: keyHeight)
        .background(disabled ? .clear : Color(color: special ? .tertiary : .primary, opacity: .low))
        .clipShape(KeyboardButtonShape())
        .overlay(
            KeyboardButtonShape()
            .strokeBorder(Color(color: special ? .tertiary : .primary, opacity: disabled ? .medium : .max), style: system.strokeStyle(.thin))
        )
        .opacity(configuration.isPressed ? 0.5 : 1.0)
    }
}

struct KeyboardView: View {
    
    @Environment(\.elementSize) private var elementSize
    
    @State var string = ""
    
    var keyHeight: CGFloat {
        switch elementSize {
        case .mini, .small:
            system.basicShape == .circle ? 62 : 56
        case .regular, .large:
            system.basicShape == .circle ? 70 : 62
        }
    }
    
    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
                Text(self.string)
                    .font(Font.spaceFont(size: 22))
                    .truncationMode(.head)
                    .padding()
                    .frame(idealWidth: .infinity, maxWidth: .infinity)
                    .frame(height: keyHeight * 0.75)
                    .background(Color(color: .primary, opacity: .medium))
                    .cornerRadius(system.cornerRadius(forLength: keyHeight))
                    .gridCellColumns(5)
                    .gridCellUnsizedAxes(.horizontal)
            }
            GridRow {
                KeyboardKeyView(key: "A", height: keyHeight, string: $string)
                KeyboardKeyView(key: "B", height: keyHeight, string: $string)
                KeyboardKeyView(key: "C", height: keyHeight, string: $string)
                KeyboardKeyView(key: "D", height: keyHeight, string: $string)
                Button(action: {
                    guard !self.string.isEmpty, ShipData.shared.powerState.comsHavePower else {
                        AudioController.shared.play(.notAllowed)
                        return
                    }
                    AudioController.shared.play(.action)
                    ShipData.shared.messagesState.addMessage(MessageContent(sender: "You", body: self.string, style: .tertiaryColor))
                    for i in 1...Int.random(in: 1...3) {
                        Timer.scheduledTimer(withTimeInterval: TimeInterval(i*30), repeats: false) { (_) in
                            AudioController.shared.play(.message)
                            ShipData.shared.messagesState.addMessage(MessageContent(vid: Int.random(in: 0...9999)))
                        }
                    }
                    self.string = ""
                }, label: { Image(systemName: "dot.radiowaves.left.and.right") })
                .buttonStyle(KeyboardButtonStyle(keyHeight: keyHeight, special: true, disabled: self.string.isEmpty || !ShipData.shared.powerState.comsHavePower))
            }
            GridRow {
                KeyboardKeyView(key: "E", height: keyHeight, string: $string)
                KeyboardKeyView(key: "F", height: keyHeight, string: $string)
                KeyboardKeyView(key: "G", height: keyHeight, string: $string)
                KeyboardKeyView(key: "H", height: keyHeight, string: $string)
                Button(action: {
                    guard !self.string.isEmpty else {
                        AudioController.shared.play(.notAllowed)
                        return
                    }
                    AudioController.shared.play(.action)
                    self.string.removeLast()
                }, label: { Image(systemName: "backward.end") })
                .buttonStyle(KeyboardButtonStyle(keyHeight: keyHeight, special: true, disabled: self.string.isEmpty))
            }
            GridRow {
                KeyboardKeyView(key: "I", height: keyHeight, string: $string)
                KeyboardKeyView(key: "J", height: keyHeight, string: $string)
                KeyboardKeyView(key: "K", height: keyHeight, string: $string)
                KeyboardKeyView(key: "L", height: keyHeight, string: $string)
                KeyboardKeyView(key: " ", height: keyHeight, string: $string)
            }
        }
    }
}

#Preview {
    KeyboardView()
}
