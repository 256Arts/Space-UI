//
//  ComsPage.swift
//  Space UI
//
//  Created by Jayden Irwin on 2019-12-15.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import SwiftUI
import GameplayKit

struct ComsPage: View {
    
    @ObservedObject var messagesState = ShipData.shared.messagesState
    
    var body: some View {
        AutoStack {
            AutoStack {
                NavigationButton(to: .nearby) {
                    Text("Nearby")
                }
                NavigationButton(to: .squad) {
                    Text("Squad")
                }
            }
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    ForEach(self.messagesState.messages) { message in
                        ComsMessageView(messageContent: message)
                    }
                }
                .padding(.vertical, 100)
            }
            .padding(.vertical, -100)
            .fadeScrollEdges(length: 100)
            .frame(width: 375)
            
            KeyboardView()
        }
    }
}

struct ComsView_Previews: PreviewProvider {
    static var previews: some View {
        ComsPage()
    }
}
