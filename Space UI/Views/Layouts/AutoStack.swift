//
//  AutoStack.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-28.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

/// Wrapper for `StackThatFits`
struct AutoStack<Content: View>: View {
    
    let spacing: CGFloat?
    let content: Content
    
    @inlinable public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        StackThatFits(spacing: spacing) {
            content
        }
    }
    
}

struct AutoStack_Previews: PreviewProvider {
    static var previews: some View {
        AutoStack {
            Text("1")
            Text("2")
            Text("3")
            Text("4")
            Text("5")
        }
    }
}
