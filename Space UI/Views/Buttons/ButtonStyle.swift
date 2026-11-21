import SwiftUI

#if os(visionOS)
typealias BS = PrimitiveButtonStyle
#else
typealias BS = ButtonStyle
#endif

struct FlexButtonStyle: BS {
    
    @Environment(\.system) private var system
    
    var isSelected: Bool = false
    var isDisabled: Bool = false
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .lineLimit(1)
            .accentColor(system.buttonTextColor(isDisabled: isDisabled))
            .foregroundColor(system.buttonTextColor(isDisabled: isDisabled))
            .multilineTextAlignment(.center)
            .padding(12)
            .frame(
                minWidth: system.flexButtonFrameHeight,
                minHeight: system.flexButtonFrameHeight
            )
            .background {
                RoundedRectangle(cornerRadius: system.cornerRadius(forLength: system.flexButtonFrameHeight))
                    .fill(system.buttonBackgroundColor(isDisabled: isDisabled, isSelected: isSelected))
            }
            .overlay {
                if system.prefersButtonBorders {
                    RoundedRectangle(cornerRadius: system.cornerRadius(forLength: system.flexButtonFrameHeight))
                        .strokeBorder(system.colors.color(self.isSelected ? .tertiary : .primary, brightness: self.isDisabled ? .medium : .max), style: system.strokeStyle(.medium))
                }
            }
            #if os(visionOS)
            // Gaze affordance: `.lift` raises the whole composed button (fill + label together) toward the
            // viewer along Z on hover. The system `.highlight` effect can't be used here — it re-renders the
            // effect content as an opaque highlight layer composited over the label, washing prominent buttons
            // to a solid block with no visible text; `.lift` leaves the text on top and always readable.
            .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: system.cornerRadius(forLength: system.flexButtonFrameHeight)))
            .hoverEffect(.lift)
            .onTapGesture(perform: configuration.trigger)
            #else
            .opacity(configuration.isPressed ? 0.5 : 1.0)
            #endif
            .fixedSize()
            .depthOffset(8) // Lift slightly off the screen plane on visionOS
    }
}

extension BS where Self == FlexButtonStyle {
    static var flex: Self { Self() }
}

struct ShapeButtonStyle: BS {
    
    @Environment(\.system) private var system
    
    let shapeDirection: ShapeDirection
    
    var isSelected: Bool = false
    var isDisabled: Bool = false
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .lineLimit(1)
            .accentColor(system.buttonTextColor(isDisabled: isDisabled))
            .foregroundColor(system.buttonTextColor(isDisabled: isDisabled))
            .multilineTextAlignment(.center)
            .padding(buttonTextPadding())
            .frame(width: system.shapeButtonFrameWidth, height: system.shapeButtonFrameHeight)
            .background {
                system.buttonBackgroundColor(isDisabled: isDisabled, isSelected: isSelected)
            }
            .clipShape(AutoShape(system: system, direction: shapeDirection))
            .overlay {
                if system.prefersButtonBorders {
                    AutoShape(system: system, direction: shapeDirection)
                        .strokeBorder(system.colors.color(self.isSelected ? .tertiary : .primary, brightness: self.isDisabled ? .medium : .max), style: system.strokeStyle(.medium))
                }
            }
            #if os(visionOS)
            // Gaze affordance: `.lift` raises the whole composed button toward the viewer along Z on hover. The
            // system `.highlight` effect can't be used here — it re-renders the effect content as an opaque
            // highlight layer over the label, washing prominent buttons to a solid block. See FlexButtonStyle.
            .contentShape(.hoverEffect, AutoShape(system: system, direction: shapeDirection))
            .hoverEffect(.lift)
            .onTapGesture(perform: configuration.trigger)
            #else
            .opacity(configuration.isPressed ? 0.5 : 1.0)
            #endif
            .depthOffset(8) // Lift slightly off the screen plane on visionOS
    }

    func buttonTextPadding() -> EdgeInsets {
        switch system.basicShape {
        case .triangle:
            return EdgeInsets(top: shapeDirection == .up ? 26 : 18, leading: 22, bottom: shapeDirection == .up ? 18 : 26, trailing: 22)
        case .trapezoid:
            return EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)
        case .diamond:
            return EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        default:
            return EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        }
    }
}

extension BS where Self == ShapeButtonStyle {
    static func shape(direction: ShapeDirection) -> Self { Self(shapeDirection: direction) }
}

/// Applies the button style the theme prefers: `ShapeButtonStyle` when `preferredButtonSizingMode == .fixed`,
/// otherwise `FlexButtonStyle`. Use `.autoButtonStyle(...)` so call sites don't duplicate the whole `Button`
/// once per sizing mode.
private struct AutoButtonStyleModifier: ViewModifier {

    @Environment(\.system) private var system

    let shapeDirection: ShapeDirection
    let isSelected: Bool
    let isDisabled: Bool

    func body(content: Content) -> some View {
        if system.preferredButtonSizingMode == .fixed {
            content.buttonStyle(ShapeButtonStyle(shapeDirection: shapeDirection, isSelected: isSelected, isDisabled: isDisabled))
        } else {
            content.buttonStyle(FlexButtonStyle(isSelected: isSelected, isDisabled: isDisabled))
        }
    }
}

extension View {
    func autoButtonStyle(shapeDirection: ShapeDirection = .up, isSelected: Bool = false, isDisabled: Bool = false) -> some View {
        modifier(AutoButtonStyleModifier(shapeDirection: shapeDirection, isSelected: isSelected, isDisabled: isDisabled))
    }
}

#Preview {
    HStack {
        Button(action: { }) {
            Text("Hello")
        }.buttonStyle(FlexButtonStyle())
        
        Button(action: { }) {
            Text("Hello")
        }.buttonStyle(ShapeButtonStyle(shapeDirection: .up))
    }
}
