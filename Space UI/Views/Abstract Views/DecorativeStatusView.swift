import SwiftUI

struct DecorativeStatusView: View {
    
    @Environment(\.system) private var system

    let binaryBase: Int
    
    var data: ShipState.StatusState
    var peerSessionController = PeerSessionController.shared
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 10) {
                if !peerSessionController.connectedPeerIDs.isEmpty {
                    Image(systemName: "bonjour")
                        .foregroundColor(system.colors.color(.primary, opacity: .high))
                }
                switch geometry.size.width {
                case ..<88:
                    EmptyView()
                case ..<100:
                    BinaryView(value: self.data.binary1/4, maxValue: 7)
                case ..<200:
                    BinaryView(value: self.data.binary1/2, maxValue: 15)
                default:
                    BinaryView(value: self.data.binary1, maxValue: 31)
                }
                if 250 < geometry.size.width {
                    Image(self.data.circleIconName1)
                        .resizable()
                        .foregroundColor(system.colors.color(.primary, opacity: .high))
                        .frame(width: 26, height: 26, alignment: .center)
                }
                if 275 < geometry.size.width {
                    Image(self.data.circleIconName2)
                        .resizable()
                        .foregroundColor(system.colors.color(.primary, opacity: .high))
                        .frame(width: 26, height: 26, alignment: .center)
                }
                if 300 < geometry.size.width {
                    Image(self.data.circleIconName3)
                        .resizable()
                        .foregroundColor(system.colors.color(.primary, opacity: .high))
                        .frame(width: 26, height: 26, alignment: .center)
                }
                if 460 < geometry.size.width {
                    BinaryView(value: self.data.binary2, maxValue: 31)
                }
            }
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
    }
    
    init(data: ShipState.StatusState) {
        let random = SeededRandom(seed: Space_UI.system.seed)
        self.binaryBase = random.nextBool(chance: 0.22) ? 3 : 2
        self.data = data
    }
    
}

#Preview {
    DecorativeStatusView(data: .init(binary1: 5, circleIconName1: "a", circleIconName2: "b", circleIconName3: "c", binary2: 5))
}
