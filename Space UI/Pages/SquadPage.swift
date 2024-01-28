//
//  SquadPage.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2022-05-30.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

import SwiftUI
import GameplayKit

struct SquadPage: View {
    
    let helmetNumber: Int
    
    @IDGen private var idGen
    @Environment(\.elementSize) private var elementSize
    
    @State var showingDeaths = 1.0
    
    var imageSize: CGFloat {
        switch elementSize {
        case .mini:
            return 100
        case .small:
            return 130
        case .regular:
            return 180
        case .large:
            return 220
        }
    }
    
    var body: some View {
        AutoStack {
            AutoStack {
                NavigationButton(to: .nearby)
                NavigationButton(to: .coms)
            }
            AutoGrid(spacing: 16) {
                ForEach(0..<8) { index in
                    HStack(alignment: .bottom) {
                        Image("Helmet \(helmetNumber)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: imageSize, maxHeight: imageSize)
                            .saturation(0)
                            .colorMultiply(Color(color: .primary, opacity: .max))
                            .overlay {
                                Image(systemName: "xmark")
                                    .font(.system(size: imageSize * 0.75))
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
        .widgetCorners(did: idGen(72), topLeading: true, topTrailing: true, bottomLeading: true, bottomTrailing: true)
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
        let random: GKRandom = {
            let source = GKMersenneTwisterRandomSource(seed: system.seed)
            return GKRandomDistribution(randomSource: source, lowestValue: 0, highestValue: Int.max)
        }()
        helmetNumber = random.nextWeightedElement(in: allHelmetNumbers)!
    }
    
}

#Preview {
    SquadPage()
}
