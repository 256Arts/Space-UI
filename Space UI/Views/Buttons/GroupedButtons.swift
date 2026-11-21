import SwiftUI

struct GroupedButtons {
    
    enum Style {
        case roundedRect, capsule
    }
    enum SegmentPosition {
        case leading, middle, trailing
    }
    
//    @State var titles: [String]
//    @State var selectedIndex: Int?
//
//    var body: some View {
//        HStack {
//            Button(action: {
//                AudioController.shared.play(.button)
//            }, label: {
//                Text(self.titles.first!)
//            }).buttonStyle(GroupedButtonStyle(segmentPosition: .leading, isSelected: self.selectedIndex == 0))
//
//            ForEach(Array(self.titles[1..<self.titles.count-1]), id: \.self) { title in
//                Button(action: {
//                    AudioController.shared.play(.button)
//                }, label: {
//                    Text(title)
//                }).buttonStyle(GroupedButtonStyle(segmentPosition: .middle, isSelected: self.selectedIndex == 1))
//            }
//
//            Button(action: {
//                AudioController.shared.play(.button)
//            }, label: {
//                Text(self.titles.last!)
//            }).buttonStyle(GroupedButtonStyle(segmentPosition: .trailing, isSelected: self.selectedIndex == 2))
//        }
//    }
}

struct GroupedButtonStyle: BS {
    
    let segmentPosition: GroupedButtons.SegmentPosition
    
    @Environment(\.system) private var system
    
    var width: CGFloat?
    var isSelected: Bool = false
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .accentColor(system.colors.color(.secondary, brightness: .max))
            .foregroundColor(system.colors.color(.secondary, brightness: .max))
            .multilineTextAlignment(.center)
            .padding(8)
            .frame(width: width ?? system.shapeButtonFrameWidth, height: system.flexButtonFrameHeight)
            .background {
                self.isSelected ? system.colors.color(.tertiary, brightness: .medium) : system.colors.color(.primary, brightness: .low)
            }
            .clipShape(GroupedButtonShape(system: system, segmentPosition: segmentPosition))
            .overlay {
                if system.prefersButtonBorders {
                    GroupedButtonShape(system: system, segmentPosition: segmentPosition)
                        .strokeBorder(system.colors.color(self.isSelected ? .tertiary : .primary, brightness: .max), style: system.strokeStyle(.medium))
                }
            }
            #if os(visionOS)
            // Gaze affordance: scale the whole composed button toward the viewer. The system `.highlight`
            // effect can't be used here — it re-renders the effect content as an opaque highlight layer over
            // the label, washing buttons to a solid block with no visible text. See FlexButtonStyle.
            .contentShape(.hoverEffect, GroupedButtonShape(system: system, segmentPosition: segmentPosition))
            .hoverEffect { effect, isActive, _ in
                effect.scaleEffect(isActive ? 1.06 : 1.0)
            }
            .onTapGesture(perform: configuration.trigger)
            #else
            .opacity(configuration.isPressed ? 0.5 : 1.0)
            #endif
            .depthOffset(8) // Lift slightly off the screen plane on visionOS
    }
}

struct GroupedButtonShape: InsettableShape {

    let system: SystemStyles
    var segmentPosition: GroupedButtons.SegmentPosition
    var insetAmount: CGFloat = 0.0

    init(system: SystemStyles, segmentPosition: GroupedButtons.SegmentPosition, insetAmount: CGFloat = 0.0) {
        self.system = system
        self.segmentPosition = segmentPosition
        self.insetAmount = insetAmount
    }

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let largeCornerRadius: CGFloat
        let smallCornerRadius: CGFloat
        
        if case .sharp = system.cornerStyle {
            largeCornerRadius = insetRect.height/4
            smallCornerRadius = 0
        } else {
            largeCornerRadius = system.cornerRadius(forLength: insetRect.height)
            smallCornerRadius = system.cornerRadius(forLength: insetRect.height)/3
        }
        
        switch segmentPosition {
        case .leading:
            return Path.roundedRectPath(in: insetRect, leadingCornerRadius: largeCornerRadius, trailingCornerRadius: smallCornerRadius)
        case .trailing:
            return Path.roundedRectPath(in: insetRect, leadingCornerRadius: smallCornerRadius, trailingCornerRadius: largeCornerRadius)
        default:
            return Path.roundedRectPath(in: insetRect, leadingCornerRadius: smallCornerRadius, trailingCornerRadius: smallCornerRadius)
        }
    }
    
    func inset(by amount: CGFloat) -> some InsettableShape {
        var arc = self
        arc.insetAmount += amount
        return arc
    }
}

//#Preview {
//    GroupedButtons(titles: ["<", "O", ">"])
//}
