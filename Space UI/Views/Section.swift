//
//  Section.swift
//  Space UI
//
//  Created by Jayden Irwin on 2022-10-06.
//  Copyright © 2022 Jayden Irwin. All rights reserved.
//

import SwiftUI

struct Section<Content: View>: View {
    
    let content: Content
    
    @EnvironmentObject private var system: SystemAppearance
    
    var body: some View {
        VStack {
            content
        }
        .frame(idealWidth: .infinity, maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: system.cornerStyle == .sharp ? 0 : 24)
                .foregroundColor(Color(color: .primary, brightness: .min))
        }
        .overlay {
            if system.prefersBorders {
                RoundedRectangle(cornerRadius: system.cornerStyle == .sharp ? 0 : 24)
                    .strokeBorder(Color(color: .primary, brightness: .medium), style: system.strokeStyle(.medium, dashed: true))
            }
        }
    }
    
    @inlinable public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
}

struct Section_Previews: PreviewProvider {
    static var previews: some View {
        Section {
            Text("Hello")
        }
    }
}
