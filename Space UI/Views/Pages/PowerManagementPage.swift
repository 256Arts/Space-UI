import SwiftUI

struct PowerManagementPage: View {

    private struct Subsystem: Identifiable {
        let id: Int
        let name: LocalizedStringKey
        let keyPath: ReferenceWritableKeyPath<ShipState.PowerState, Bool>
    }

    private let subsystems: [Subsystem] = [
        Subsystem(id: 0, name: "Shield 1", keyPath: \.shield1HasPower),
        Subsystem(id: 1, name: "Shield 2", keyPath: \.shield2HasPower),
        Subsystem(id: 2, name: "Coms", keyPath: \.comsHavePower),
        Subsystem(id: 3, name: "Engine", keyPath: \.engineHasPower),
        Subsystem(id: 4, name: "Weapons", keyPath: \.weaponsHavePower)
    ]
    private let coordSpace = "powerDistribution"

    @IDGen private var idGen
    @Environment(\.system) private var system

    @State private var dragLocation: CGPoint?
    @State private var corePulse = false

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let nodeSize = min(max(min(geometry.size.width, geometry.size.height) * 0.17, 60), 104)
            let radiusX = min(300, geometry.size.width / 2 - nodeSize / 2 - 10)
            let radiusY = min(320, geometry.size.height / 2 - nodeSize / 2 - 12)
            let power = ShipState.shared.powerState

            ZStack {
                // Persistent flowing conduits for every powered subsystem.
                ForEach(subsystems) { subsystem in
                    if power[keyPath: subsystem.keyPath] {
                        FlowingArrowsView(
                            did: idGen(1),
                            start: center,
                            end: position(for: subsystem, center: center, radiusX: radiusX, radiusY: radiusY)
                        )
                    }
                }

                // Live preview conduit that follows the finger while dragging.
                if let dragLocation {
                    FlowingArrowsView(did: idGen(1), start: center, end: dragLocation, colorRole: .secondary, isPreview: true)
                }

                // Subsystem nodes.
                ForEach(subsystems) { subsystem in
                    subsystemNode(subsystem, isPowered: power[keyPath: subsystem.keyPath], size: nodeSize)
                        .position(position(for: subsystem, center: center, radiusX: radiusX, radiusY: radiusY))
                }

                // Central power core — the drag source.
                coreNode(size: nodeSize * 1.3)
                    .position(center)
                    .gesture(
                        DragGesture(minimumDistance: 4, coordinateSpace: .named(coordSpace))
                            .onChanged { value in
                                dragLocation = value.location
                            }
                            .onEnded { value in
                                routePower(to: value.location, center: center, radiusX: radiusX, radiusY: radiusY, nodeSize: nodeSize)
                                dragLocation = nil
                            }
                    )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .coordinateSpace(.named(coordSpace))
        }
        .overlay(alignment: .bottom) {
            HStack(spacing: 16) {
                NavigationButton(to: .lockScreen)
                NavigationButton(to: .shield)
                NavigationButton(to: .coms)
                NavigationButton(to: .nearby)
            }
            .padding()
        }
        .widgetCorners(did: idGen(0), topLeading: true, topTrailing: true, bottomLeading: true, bottomTrailing: true)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                corePulse = true
            }
        }
    }

    // MARK: - Geometry

    private func position(for subsystem: Subsystem, center: CGPoint, radiusX: CGFloat, radiusY: CGFloat) -> CGPoint {
        // Evenly distribute the subsystems around the core, starting at the top.
        let angle = -CGFloat.pi / 2 + CGFloat(subsystem.id) * (2 * .pi / CGFloat(subsystems.count))
        return CGPoint(x: center.x + cos(angle) * radiusX, y: center.y + sin(angle) * radiusY)
    }

    private func routePower(to dropPoint: CGPoint, center: CGPoint, radiusX: CGFloat, radiusY: CGFloat, nodeSize: CGFloat) {
        let hitSubsystem = subsystems.first { subsystem in
            let pos = position(for: subsystem, center: center, radiusX: radiusX, radiusY: radiusY)
            return hypot(pos.x - dropPoint.x, pos.y - dropPoint.y) < nodeSize * 0.8
        }
        guard let hitSubsystem else { return }
        let power = ShipState.shared.powerState
        let willPowerOn = !power[keyPath: hitSubsystem.keyPath]
        withAnimation(.easeInOut(duration: 0.35)) {
            power[keyPath: hitSubsystem.keyPath] = willPowerOn
        }
        AudioController.shared.play(willPowerOn ? .action : .notAllowed)
    }

    // MARK: - Nodes

    private func coreNode(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(system.colors.color(.primary, opacity: .low))
            Circle()
                .strokeBorder(system.colors.color(.primary, opacity: .max), style: system.strokeStyle(.thick))
            Circle()
                .strokeBorder(system.colors.color(.secondary, opacity: .high), style: system.strokeStyle(.thin))
                .padding(size * 0.2)
            Text("Power")
                .font(Font.spaceFont(size: size * 0.15))
                .foregroundColor(system.colors.color(.primary, opacity: .max))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(size * 0.28)
        }
        .frame(width: size, height: size)
        .shadow(color: system.colors.color(.primary, opacity: .medium), radius: corePulse ? 22 : 8)
    }

    private func subsystemNode(_ subsystem: Subsystem, isPowered: Bool, size: CGFloat) -> some View {
        let tint = isPowered ? system.colors.color(.primary, opacity: .max) : system.colors.color(.primary, opacity: .low)
        return Text(subsystem.name)
            .font(Font.spaceFont(size: size * 0.16))
            .foregroundColor(tint)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.5)
            .padding(size * 0.14)
            .frame(width: size, height: size)
            .background {
                Circle()
                    .fill(system.colors.color(.primary, opacity: isPowered ? .low : .min))
                    .overlay {
                        Circle()
                            .strokeBorder(tint, style: system.strokeStyle(isPowered ? .medium : .thin))
                    }
            }
            .shadow(color: isPowered ? system.colors.color(.primary, opacity: .medium) : .clear, radius: isPowered ? 12 : 0)
            .animation(.easeInOut(duration: 0.4), value: isPowered)
    }
}

#Preview {
    PowerManagementPage()
}
