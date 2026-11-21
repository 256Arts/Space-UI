import SwiftUI

struct Panel<Content: View, Header: View>: View {
    
    let content: Content
    let header: Header
    
    @Environment(\.system) private var system
    
    var body: some View {
        VStack {
            header
                .padding(.top, 12)
                .padding(.bottom, -4)
            content
        }
        .frame(idealWidth: .infinity, maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: system.cornerStyle == .sharp ? 0 : 24)
                .foregroundColor(system.colors.color(.primary, brightness: .min))
        }
        .overlay {
            if system.prefersBorders {
                RoundedRectangle(cornerRadius: system.cornerStyle == .sharp ? 0 : 24)
                    .strokeBorder(system.colors.color(.primary, brightness: .medium), style: system.strokeStyle(.medium, dashed: true))
            }
        }
        // Lift the panel toward the viewer so it sits clearly in front of overlaid content (e.g. the
        // galaxy planets it would otherwise intersect) on visionOS.
        .depthOffset(20)
    }
    
    @inlinable public init(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Header = { EmptyView() }) {
        self.content = content()
        self.header = header()
    }
}

#Preview {
    Panel {
        Text("Hello")
    }
}
