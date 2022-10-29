//
//  TextPair.swift
//  Space UI
//
//  Created by Jayden Irwin on 2020-03-16.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import SwiftUI

struct TextPair: View {
    
    var did: Int = Int.random(in: 0..<Int.max)
    var prefersMonochrome: Bool {
        (Int(system.seed) + did) % 2 == 0
    }
    var monochrome: Bool {
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
                .font(Font.spaceFont(size: largerFontSize * 0.8))
                .foregroundColor(monochrome ? Color(color: .primary, opacity: .medium) : Color(color: .primary, opacity: .max))
            Text(value)
                .font(Font.spaceFont(size: largerFontSize))
                .foregroundColor(monochrome ? Color(color: .primary, opacity: .max) : Color(color: .secondary, opacity: .max))
        }
        .padding(.vertical, 2)
    }
}

struct TextPair_Previews: PreviewProvider {
    static var previews: some View {
        TextPair(did: 0, label: "Name", value: "Steve")
    }
}
