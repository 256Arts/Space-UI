import SwiftUI

struct Slider: View {
    @Environment(\.system) private var system

    let insetInnerBar: Bool
    private var innerBarInset: CGFloat {
        insetInnerBar ? system.thinLineWidth : 0
    }
    
    @Environment(\.elementSize) private var elementSize
    private var idealHeight: CGFloat {
        switch elementSize {
        case .large:
            return 38
        case .regular:
            return 28
        case .small:
            return 22
        case .mini:
            return 16
        }
    }
    
    @Binding var value: Double
    
    @State private var dragStartValue: Double?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: system.cornerRadius(forLength: geometry.size.height))
                    .fill(system.colors.color(.primary, brightness: .min))
                if 0 < value {
                    RoundedRectangle(cornerRadius: system.cornerRadius(forLength: geometry.size.height - innerBarInset * 2))
                        .fill(system.colors.color(.primary, brightness: .max))
                        .padding(innerBarInset)
                        .frame(width: max(system.cornerRadius(forLength: geometry.size.height) * 2, geometry.size.width * value))
                }
            }
            #if !os(tvOS)
            .gesture(
                DragGesture()
                    .onChanged({ gesture in
                        if dragStartValue == nil {
                            dragStartValue = value
                        }
                        let delta = gesture.translation.width / geometry.size.width
                        value = max(0, min(dragStartValue! + delta, 1))
                    })
                    .onEnded({ _ in
                        dragStartValue = nil
                    })
            )
            #endif
        }
        .frame(height: idealHeight)
    }
}

#Preview {
    Slider(insetInnerBar: true, value: .constant(0.5))
}
