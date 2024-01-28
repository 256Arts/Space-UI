//
//  KeyboardKeyView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-01-09.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct KeyboardKeyView: View {
    
    let key: String
    let height: CGFloat
    
    @Binding var string: String
    
    var body: some View {
        Button(action: {
            AudioController.shared.play(.action)
            self.string.append(self.key)
        }, label: { Text(key) })
        .buttonStyle(KeyboardButtonStyle(keyHeight: height))
    }
}

#Preview {
    KeyboardKeyView(key: "A", height: 50, string: .constant("ABC"))
}
