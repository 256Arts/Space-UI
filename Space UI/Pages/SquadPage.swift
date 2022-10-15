//
//  SquadPage.swift
//  Space UI
//
//  Created by Jayden Irwin on 2022-05-30.
//  Copyright © 2022 Jayden Irwin. All rights reserved.
//

import SwiftUI
import GameplayKit

struct SquadPage: View {
    
    let random: GKRandom = {
        let source = GKMersenneTwisterRandomSource(seed: system.seed)
        return GKRandomDistribution(randomSource: source, lowestValue: 0, highestValue: Int.max)
    }()
    let helmetNumber: Int
    
    @State var showingDeaths = 1.0
    
    var body: some View {
        AutoStack {
            NavigationButton(to: .nearby) {
                Text("Nearby")
            }
            NavigationButton(to: .coms) {
                Text("Coms")
            }
            AutoGrid(spacing: 16) {
                ForEach(0..<8) { index in
                    HStack(alignment: .bottom) {
                        Image("Helmet \(helmetNumber)")
                            .saturation(0)
                            .colorMultiply(Color(color: .primary, opacity: .max))
                            .overlay {
                                Image(systemName: "xmark")
                                    .font(.system(size: 150))
                                    .opacity(showingDeaths)
                            }
                        VStack {
                            CircularSegmentedView()
                                .frame(width: 50, height: 50)
                            Text(String(index + 1))
                                .font(.spaceFont(size: 40))
                        }
                    }
                }
            }
        }
        .widgetCorners(did: 72, topLeading: true, topTrailing: true, bottomLeading: true, bottomTrailing: true)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever()) {
                showingDeaths = 0
            }
        }
    }
    
    init() {
        let allHelmetNumbers: [WeightedElement<Int>] = [
            .init(weight: 2, element: 1),
            .init(weight: 2, element: 2),
            .init(weight: 2, element: 3),
            .init(weight: 1, element: 4),
            .init(weight: 1, element: 5),
            .init(weight: 1, element: 6)
        ]
        helmetNumber = random.nextWeightedElement(in: allHelmetNumbers)!
    }
    
}

struct SquadPage_Previews: PreviewProvider {
    static var previews: some View {
        SquadPage()
    }
}
