import SwiftUI

struct CustomTextPage: View {
    @Environment(\.system) private var system

    @AppStorage(UserDefaults.Key.customTextMarkdown) private var customTextMarkdownRaw = ""
    
    @IDGen private var idGen
    @Environment(\.safeCornerOffsets) private var safeCornerOffsets
    
    @State var isEditing = false
    
    var styledText: AttributedString {
        (try? AttributedString(markdown: customTextMarkdownRaw, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(customTextMarkdownRaw)
    }
    
    var body: some View {
        VStack {
            HStack {
                HStack {
                    NavigationButton(to: .lockScreen)
                    NavigationButton(to: .music) {
                        Image(systemName: "waveform")
                    }
                    NavigationButton(to: .homeKit) {
                        Image(systemName: "homekit")
                    }
                }
                .offset(safeCornerOffsets.topLeading)
                
                Button("Edit") {
                    isEditing.toggle()
                }
                .offset(safeCornerOffsets.topTrailing)
            }
            .padding(.bottom, min(safeCornerOffsets.topLeading.height, safeCornerOffsets.topTrailing.height))
            
            if isEditing {
                TextEditor(text: $customTextMarkdownRaw)
                    .overlay {
                        if customTextMarkdownRaw.isEmpty {
                            Text("Add text here")
                                .foregroundColor(system.colors.color(.primary, brightness: .low))
                        }
                    }
                    .font(.english())
                    .multilineTextAlignment(.center)
                    .scrollContentBackground(.hidden) // For mac
            } else {
                Spacer()
                Text(styledText)
                    .font(.english())
                    .multilineTextAlignment(.center)
                Spacer()
            }
        }
        .frame(idealWidth: .infinity, maxWidth: .infinity, idealHeight: .infinity, maxHeight: .infinity)
        .widgetCorners(did: idGen(0), topLeading: false, topTrailing: false, bottomLeading: true, bottomTrailing: true)
    }
}

#if os(macOS)
extension NSTextView {
    open override var frame: CGRect {
        didSet {
            backgroundColor = .clear
            drawsBackground = true
        }
    }
}
#endif

#Preview {
    CustomTextPage()
}
