//
//  Section.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2022-10-06.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct Section<Content: View, Header: View>: View {
    
    let content: Content
    let header: Header
    
    @EnvironmentObject private var system: SystemStyles
    
    var body: some View {
        VStack {
            header
                .padding(.top, 4)
                .padding(.bottom, -4)
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
        .scrollTransition { content, phase in
            content
                .scaleEffect(phase.isIdentity ? 1 : 0)
                .opacity(phase.isIdentity ? 1 : 0)
        }
    }
    
    @inlinable public init(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Header = { EmptyView() }) {
        self.content = content()
        self.header = header()
    }
}

#Preview {
    Section {
        Text("Hello")
    }
}
