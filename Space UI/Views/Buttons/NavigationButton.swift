//
//  NavigationButton.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-18.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct NavigationButton<Label: View>: View {
    
    @Environment(\.shapeDirection) var shapeDirection: ShapeDirection
    @EnvironmentObject private var system: SystemStyles
    
    let label: Label
    var page: Page
    
    var body: some View {
        if system.preferedButtonSizingMode == .fixed {
            Button {
                AudioController.shared.play(.button)
                AppController.shared.visiblePage = self.page
            } label: {
                label
            }
            .buttonStyle(ShapeButtonStyle(shapeDirection: shapeDirection))
        } else {
            Button {
                AudioController.shared.play(.button)
                AppController.shared.visiblePage = self.page
            } label: {
                label
            }
            .buttonStyle(FlexButtonStyle())
        }
    }
    
    init(to page: Page, @ViewBuilder label: () -> Label) {
        self.page = page
        self.label = label()
    }
}

extension NavigationButton where Label == Text {
    init(to page: Page) {
        self.page = page
        self.label = Text(page.rawValue.prefix(6))
    }
}

#Preview {
    NavigationButton(to: .ticTacToe) {
        Text("Label")
    }
}
