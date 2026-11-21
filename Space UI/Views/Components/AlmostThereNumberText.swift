import SwiftUI

struct AlmostThereNumberText: View {
    
    @Environment(\.system) private var system
    
    @Binding var number: Int
    let digitCount: Int
    var fontSize: CGFloat {
        system.defaultFontSize * 2
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            Text(String(repeating: "0", count: digitCount))
                .font(Font.custom(Font.Name.almostThere.rawValue, size: fontSize))
                .foregroundColor(system.colors.color(.primary, opacity: .low))
            Text(String(number).prefix(digitCount))
                .font(Font.custom(Font.Name.almostThere.rawValue, size: fontSize))
                .foregroundColor(system.colors.color(.secondary, opacity: .max))
        }
        .fixedSize()
    }
}

#Preview {
    AlmostThereNumberText(number: .constant(12345), digitCount: 5)
}
