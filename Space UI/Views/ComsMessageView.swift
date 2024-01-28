//
//  ComsMessageView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-22.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct ComsMessageView: View {
    
    @EnvironmentObject private var system: SystemStyles
    @Environment(\.shapeDirection) private var shapeDirection: ShapeDirection
    
    let messageContent: MessageContent
    
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Text(self.messageContent.body)
            .font(Font.spaceFont(size: 20))
            .foregroundColor({
                switch self.messageContent.style {
                case .secondaryColor:
                    return Color(color: .secondary, opacity: .max)
                case .tertiaryColor:
                    return Color(color: .tertiary, opacity: .max)
                case .filledBackground:
                    return Color.screenBackground
                case .filledBackgroundWithSecondaryTextColor:
                    if system.colors.paletteStyle == .monochrome {
                        return Color.screenBackground
                    } else {
                        return Color(color: .secondary, opacity: .max)
                    }
                default:
                    return Color(color: .primary, opacity: .max)
                }
            }())
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            .background(
                RoundedRectangle(cornerRadius: system.cornerRadius(forLength: 24.0))
                    .foregroundColor(self.messageContent.style == .filledBackground || self.messageContent.style == .filledBackgroundWithSecondaryTextColor ? Color(color: .primary, opacity: .max) : Color.clear)
            )
            .overlay(
                HStack(spacing: -22) {
                    if self.messageContent.style == .tagged1 {
                        AutoShape(direction: shapeDirection)
                            .frame(width: 16, height: 16, alignment: .leading)
                            .foregroundColor(Color(color: .primary, opacity: .max))
                    } else if self.messageContent.style == .tagged2 {
                        ForEach(0..<2) { _ in
                            AutoShape(direction: shapeDirection)
                                .frame(width: 16, height: 16, alignment: .leading)
                                .foregroundColor(Color(color: .primary, opacity: .max))
                                .overlay(AutoShape(direction: shapeDirection)
                                    .stroke(Color(color: .primary, opacity: .min), style: system.strokeStyle(.medium))
                                            .frame(width: 16, height: 16)
                                )
                        }
                    } else {
                        Spacer()
                    }
                }
                .offset(x: -10, y: 0)
            , alignment: .leading)
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
            .opacity(self.opacity)
            .onAppear {
                if self.messageContent.style == .flashing {
                    withAnimation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                        self.opacity = 0.0
                    }
                }
            }
    }
}

#Preview {
    ComsMessageView(messageContent: .init(vid: 1))
}
