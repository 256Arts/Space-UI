//
//  CircularText.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-08-21.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

private struct TextViewSizeKey: PreferenceKey {
    static var defaultValue: [CGSize] { [] }
    static func reduce(value: inout [CGSize], nextValue: () -> [CGSize]) {
        value.append(contentsOf: nextValue())
    }
}

private struct PropagateSize<V: View>: View {
    var content: () -> V
    var body: some View {
        content()
            .background(GeometryReader { proxy in
                Color.clear.preference(key: TextViewSizeKey.self, value: [proxy.size])
            })
    }
}

private struct IdentifiableCharacter: Identifiable {
    var id: String { "\(index) \(character)" }
    
    let index: Int
    let character: Character
}

// MARK: - Curved Text

struct CircularText: View {
    
    private var visibleString: String {
        let availableWidth = radius * 2 * .pi
        let totalArcWidth = string.size(withAttributes: [.font: UIFont(name: system.fontName?.rawValue ?? "", size: system.defaultFontSize) ?? UIFont.systemFont(ofSize: 26.0), .kern: spacing]).width
        if totalArcWidth < availableWidth {
            return string
        } else {
            let fraction = availableWidth / totalArcWidth * 0.9
            let lastCharIndex = Int(CGFloat(string.count) * fraction)
            return String(string.prefix(lastCharIndex))
        }
    }
    
    @State var string: String
    @State var radius: CGFloat
    @State var onTopEdge: Bool
    @State var spacing: CGFloat = 1.0
    @State private var sizes: [CGSize] = []
    
    public var body: some View {
        ZStack {
            ForEach(textAsCharacters()) { item in
                PropagateSize {
                    Text(String(item.character))
                }
                    .fixedSize()
                    .offset(x: 0, y: self.textRadius(at: item.index))
                    .rotationEffect(self.angle(at: item.index))
            }
        }
        .frame(width: radius * 2, height: radius * 2)
        .onPreferenceChange(TextViewSizeKey.self) { sizes in
            self.sizes = sizes
        }
        .accessibility(label: Text(string))
    }
    
    private func textRadius(at index: Int) -> CGFloat {
        (onTopEdge ? -1 : 1) * (radius - size(at: index).height / 2)
    }
    
    private func textAsCharacters() -> [IdentifiableCharacter] {
        let string2 = onTopEdge ? visibleString : String(visibleString.reversed())
        return string2.enumerated().map(IdentifiableCharacter.init)
    }
    
    private func size(at index: Int) -> CGSize {
        sizes.indices.contains(index) ? sizes[index] : CGSize(width: 1000000, height: 0)
    }
    
    private func angle(at index: Int) -> Angle {
        let arcSpacing = Double(spacing / radius)
        let letterWidths = sizes.map { $0.width }
        let totalArcWidth = Double(letterWidths.reduce(0, +) / radius)
        let arcSpacingOffset = -arcSpacing * Double(letterWidths.count - 1) / 2
        
        let prevWidth = index < letterWidths.count ? letterWidths.dropLast(letterWidths.count - index).reduce(0, +) : 0
        let prevArcWidth = Double(prevWidth / radius)
        let prevArcSpacingWidth = arcSpacing * Double(index)
        let charWidth = letterWidths.indices.contains(index) ? letterWidths[index] : 0
        let charOffset = Double(charWidth / 2 / radius)
        let arcCharCenteringOffset = -totalArcWidth / 2
        let charArcOffset = prevArcWidth + charOffset + arcCharCenteringOffset + arcSpacingOffset + prevArcSpacingWidth
        return Angle(radians: charArcOffset)
    }
    
}


#Preview {
    CircularText(string: "Hello World!", radius: 150, onTopEdge: true)
}

