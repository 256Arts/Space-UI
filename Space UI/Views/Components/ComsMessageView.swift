import SwiftUI

struct ComsMessageView: View {
    
    @Environment(\.system) private var system
    @Environment(\.shapeDirection) private var shapeDirection: ShapeDirection
    
    let messageContent: MessageContent
    
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Text(self.messageContent.body)
            .font(Font.spaceFont(size: 20))
            .foregroundColor({
                switch self.messageContent.style {
                case .secondaryColor:
                    return system.colors.color(.secondary, opacity: .max)
                case .tertiaryColor:
                    return system.colors.color(.tertiary, opacity: .max)
                case .filledBackground:
                    return system.colors.screenBackground
                case .filledBackgroundWithSecondaryTextColor:
                    if system.colors.paletteStyle == .monochrome {
                        return system.colors.screenBackground
                    } else {
                        return system.colors.color(.secondary, opacity: .max)
                    }
                default:
                    return system.colors.color(.primary, opacity: .max)
                }
            }())
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            .background(
                self.messageContent.style == .filledBackground || self.messageContent.style == .filledBackgroundWithSecondaryTextColor ? system.colors.color(.primary, opacity: .max) : Color.clear,
                in: RoundedRectangle(cornerRadius: system.cornerRadius(forLength: 24.0)))
            .overlay(alignment: .leading) {
                HStack(spacing: -22) {
                    if self.messageContent.style == .tagged1 {
                        AutoShape(system: system, direction: shapeDirection)
                            .frame(width: 16, height: 16, alignment: .leading)
                            .foregroundColor(system.colors.color(.primary, opacity: .max))
                    } else if self.messageContent.style == .tagged2 {
                        ForEach(0..<2) { _ in
                            AutoShape(system: system, direction: shapeDirection)
                                .frame(width: 16, height: 16, alignment: .leading)
                                .foregroundColor(system.colors.color(.primary, opacity: .max))
                                .overlay(AutoShape(system: system, direction: shapeDirection)
                                    .stroke(system.colors.color(.primary, opacity: .min), style: system.strokeStyle(.medium))
                                    .frame(width: 16, height: 16)
                                )
                        }
                    } else {
                        Spacer()
                    }
                }
                .offset(x: -10, y: 0)
            }
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
            .opacity(self.opacity)
            .onAppear {
                if self.messageContent.style == .flashing {
                    withAnimation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                        self.opacity = 0.0
                    }
                }
            }
    }
}

#Preview {
    ComsMessageView(messageContent: .init(vid: 1))
}
