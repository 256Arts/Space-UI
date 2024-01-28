//
//  MainTitleScrollView.swift
//  Space UI (tvOS)
//
//  Created by 256 Arts Developer on 2022-07-31.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct MainTitleScrollView: View {

    enum AnimationDuration {
        static let titleZooming: TimeInterval = 5
        static let textScrolling: TimeInterval = 75
        static let textFadingOut: TimeInterval = 20
        static let cameraPanning: TimeInterval = 8
    }
    
    @State var showingTitle = true
    @State var titleScale: CGFloat = 1
    @State var showingTextScroll = true
    @State var textScrollOffsetY: CGFloat = 1.6
    @State var cameraPosition: CGPoint = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ParallaxView(layers: [
                    .init(imageName: "Stars", position: CGPoint(x: -73, y: 372), movementMultiplier: 0.3),
                    .init(imageName: "Stars", position: CGPoint(x: -313, y: 427), movementMultiplier: 0.4),
                    .init(imageName: "Stars", position: CGPoint(x: 285, y: 571), movementMultiplier: 0.5),
                    .init(imageName: "Planet", position: CGPoint(x: 0, y: 1000), movementMultiplier: 1)
                ], cameraPosition: $cameraPosition)
                
                Text("SPACE\nWARS")
                    .font(Font.spaceFont(size: geometry.size.height * 0.3))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .scaleEffect(titleScale)
                    .opacity(showingTitle ? 1 : 0)
                
                Text("""
            Episode 4
            HOPE 'TIS NEWETH
            
            It is a period of civil war, The spaceships of the rebels striking swift from bases unseen have gained a victory o’er the cruel galactic kingdom now adrift. Amidst the battle, rebel spies prevailed and stole the plans to a space station vast whose powerful beams will later be unveiled and crush a planet, ‘tis the Death Globe blast.
            
            Pursued by agents sinister and cold, now princess to her home doth flee, delivering plans and a new hope they hold of bringing freedom to the galaxy. In times so long ago, begins our play, in star-crossed galaxy far, far away....
            """)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 750)
                .offset(x: 0, y: geometry.size.height * textScrollOffsetY)
                .rotation3DEffect(.degrees(70), axis: (x: 1, y: 0, z: 0))
                .opacity(showingTextScroll ? 1 : 0)
            }
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
        .font(Font.spaceFont(size: 30))
        .foregroundColor(.yellow)
        .background(Color.black, ignoresSafeAreaEdges: .all)
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.linear(duration: AnimationDuration.titleZooming)) {
                titleScale = 0.00001
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + AnimationDuration.titleZooming) {
                withAnimation(.linear(duration: AnimationDuration.textScrolling)) {
                    textScrollOffsetY = -1.6
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + (AnimationDuration.textScrolling - AnimationDuration.textFadingOut)) {
                    withAnimation(.linear(duration: AnimationDuration.textFadingOut)) {
                        showingTextScroll = false
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + AnimationDuration.textScrolling) {
                    withAnimation(.linear(duration: AnimationDuration.cameraPanning)) {
                        cameraPosition = CGPoint(x: 0, y: 1000)
                    }
                }
            }
        }
    }
}

#Preview {
    MainTitleScrollView()
}
