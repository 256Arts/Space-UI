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
    var largerFontSize: CGFloat?
    private var finalLargerFontSize: CGFloat {
        system.defaultFontSize
    }
    
    @Environment(\.system) private var system
    
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
                .font(Font.spaceFont(size: finalLargerFontSize * 0.8))
                .foregroundColor(monochrome ? system.colors.color(.primary, opacity: .medium) : system.colors.color(.primary, opacity: .max))
            Text(value)
                .lineLimit(1)
                .font(Font.spaceFont(size: finalLargerFontSize))
                .foregroundColor(monochrome ? system.colors.color(.primary, opacity: .max) : system.colors.color(.secondary, opacity: .max))
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    TextPair(did: 0, label: "Name", value: "Steve")
}
