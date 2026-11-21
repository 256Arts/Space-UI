#if DEBUG
import SwiftUI

struct FontTestView: View {
    var body: some View {
        List {
            ForEach(Font.Name.allCases) { fontName in
                // The suffix marks the faces theme generation only reaches with Extra Fonts on
                Text(fontName.rawValue + (fontName.isExtra ? " (Extra)" : ""))
                    .font(Font.custom(fontName.rawValue, fixedSize: fontName.defaultFontSize))
                    #if os(tvOS)
                    .focusable()
                    #endif
            }
        }
        .navigationTitle("Fonts Test")
    }
}

#Preview {
    FontTestView()
}

extension Font.Name: Identifiable {
    var id: Self { self }
}
#endif
