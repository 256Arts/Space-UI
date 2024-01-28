//
//  ParallaxView.swift
//  Space UI (tvOS)
//
//  Created by 256 Arts Developer on 2022-07-31.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct ParallaxView: View {
    
    struct Layer: Identifiable {
        let imageName: String
        let position: CGPoint
        let movementMultiplier: Double
        
        var image: Image {
            Image(imageName)
        }
        var id: Double {
            movementMultiplier
        }
    }
    
    let pixelScale: CGFloat = 5
    let layers: [Layer]
    
    @Binding var cameraPosition: CGPoint
    
    var body: some View {
        ZStack {
            ForEach(layers) { layer in
                layer.image
                    .interpolation(.none)
                    .scaleEffect(pixelScale)
                    .offset(x: layer.position.x - (cameraPosition.x * layer.movementMultiplier), y: layer.position.y - (cameraPosition.y * layer.movementMultiplier))
            }
        }
    }
}

#Preview {
    ParallaxView(layers: [.init(imageName: "Stars", position: .zero, movementMultiplier: 0.5)], cameraPosition: .constant(.zero))
}
