import SwiftUI

struct PlanetDetailsView: View {
    
    @IDGen private var idGen
    @Environment(\.system) private var system
    
    @Binding var planet: GalaxyView.Planet
    
    let showPlanetImage: Bool

    private static let planetImageNames = ["Mercury", "Planet3", "Venus"]

    /// Derived from `planet.id` so the image and its rotation stay fixed across re-renders instead of
    /// re-rolling (and flickering) every time the body re-evaluates.
    private var planetImageName: String {
        Self.planetImageNames[Int(planet.id.magnitude % UInt(Self.planetImageNames.count))]
    }
    private var planetImageAngle: Angle {
        Angle(degrees: Double(planet.id.magnitude % 360))
    }

    var body: some View {
        Panel {
            VStack(alignment: .leading) {
                TextPair(did: 0, label: "Name", value: planet.detailTexts[0])
                TextPair(did: 0, label: "Races", value: planet.detailTexts[1])
                TextPair(did: 0, label: "Leadership", value: planet.detailTexts[2])
                TextPair(did: 0, label: "Population", value: planet.detailTexts[3])
                TextPair(did: 0, label: "Currency", value: planet.detailTexts[4])
                
                HStack(alignment: .top) {
                    DecorativeBoxesView(vid: idGen(1))
                    CircularProgressView(did: idGen(1), value: .constant(planet.progress1), lineWidth: nil)
                        .frame(width: 56, height: 56)
                    DecorativeBoxesView(vid: idGen(2))
                    CircularProgressView(did: idGen(1), value: .constant(planet.progress2), lineWidth: nil)
                        .frame(width: 56, height: 56)
                }
            }
            .multilineTextAlignment(.leading)
            .frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .frame(maxWidth: 320)
        .background(alignment: .bottomTrailing) {
            if self.showPlanetImage {
                Image(planetImageName)
                    .colorMultiply(system.colors.color(.primary, opacity: .max))
                    .rotationEffect(planetImageAngle)
                    .offset(x: 100, y: 100)
                    .opacity(0.5)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: system.cornerStyle == .sharp ? 0 : 24))
    }
    
}

#Preview {
    PlanetDetailsView(
        planet: .constant(.init(id: 1, coord: .zero, diameter: 10, isBlackHole: false, nebulaShapeNumber: nil, hasRing: false)),
        showPlanetImage: true)
}
