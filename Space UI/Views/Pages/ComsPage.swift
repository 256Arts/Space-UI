import SwiftUI

struct ComsPage: View {
    
    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    var messagesState = ShipState.shared.messagesState
    
    var body: some View {
        LayoutThatFits(hSizeClass == .compact ? [VStackLayout()] : [HStackLayout()]) {
            AutoStack {
                NavigationButton(to: .nearby)
                NavigationButton(to: .squad)
            }
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    ForEach(self.messagesState.messages) { message in
                        ComsMessageView(messageContent: message)
                    }
                    .scrollTransition { content, phase in
                        content
                            .scaleEffect(phase.isIdentity ? 1 : 0, anchor: .leading)
                            .opacity(phase.isIdentity ? 1 : 0)
                    }
                }
            }
            .defaultScrollAnchor(.bottom)
            .scrollClipDisabled()
            .frame(width: 375)
            
            KeyboardView()
        }
    }
}

#Preview {
    ComsPage()
}
