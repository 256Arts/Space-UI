//
//  ComsPage.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-15.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct ComsPage: View {
    
    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    @ObservedObject var messagesState = ShipData.shared.messagesState
    
    var body: some View {
        LayoutThatFits(hSizeClass == .compact ? [VStackLayout()] : [HStackLayout()]) {
            AutoStack {
                NavigationButton(to: .nearby)
                NavigationButton(to: .squad)
            }
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    ForEach(self.messagesState.messages) { message in
                        ComsMessageView(messageContent: message)
                    }
                    .scrollTransition { content, phase in
                        content
                            .scaleEffect(phase.isIdentity ? 1 : 0, anchor: .leading)
                            .opacity(phase.isIdentity ? 1 : 0)
                    }
                }
            }
            .defaultScrollAnchor(.bottom)
            .scrollClipDisabled()
            .frame(width: 375)
            
            KeyboardView()
        }
    }
}

#Preview {
    ComsPage()
}
