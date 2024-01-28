//
//  TextPair.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-03-16.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct TextPair: View {
    
    var did: Int
    private var prefersMonochrome: Bool {
        did % 2 == 0
    }
    private var monochrome: Bool {
        prefersMonochrome || system.colors.paletteStyle == .monochrome
    }
    var label: String
    var value: String
    var largerFontSize: CGFloat = system.defaultFontSize
    
    @Environment(\.multilineTextAlignment) private var multilineTextAlignment
    var stackAlignment: HorizontalAlignment {
        switch multilineTextAlignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }
    
    var body: some View {
        VStack(alignment: stackAlignment) {
            Text(label)
                .lineLimit(1)
                .font(Font.spaceFont(size: largerFontSize * 0.8))
                .foregroundColor(monochrome ? Color(color: .primary, opacity: .medium) : Color(color: .primary, opacity: .max))
            Text(value)
                .lineLimit(1)
                .font(Font.spaceFont(size: largerFontSize))
                .foregroundColor(monochrome ? Color(color: .primary, opacity: .max) : Color(color: .secondary, opacity: .max))
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    TextPair(did: 0, label: "Name", value: "Steve")
}
