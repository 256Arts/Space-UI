//
//  CustomTextPage.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2023-02-04.
//  Copyright © 2023 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct CustomTextPage: View {
    
    @AppStorage(UserDefaults.Key.customTextMarkdown) private var customTextMarkdownRaw = ""
    
    @IDGen private var idGen
    @Environment(\.safeCornerOffsets) private var safeCornerOffsets
    
    @State var isEditing = false
    
    var styledText: AttributedString {
        (try? AttributedString(markdown: customTextMarkdownRaw, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(customTextMarkdownRaw)
    }
    
    var body: some View {
        VStack {
            if isEditing {
                TextEditor(text: $customTextMarkdownRaw)
                    .overlay {
                        if customTextMarkdownRaw.isEmpty {
                            Text("Add text here")
                                .foregroundColor(Color(color: .primary, brightness: .low))
                        }
                    }
                    .font(.english())
                    .multilineTextAlignment(.center)
            } else {
                Spacer()
                Text(styledText)
                    .font(.english())
                    .multilineTextAlignment(.center)
                Spacer()
            }
        }
        .frame(idealWidth: .infinity, maxWidth: .infinity, idealHeight: .infinity, maxHeight: .infinity)
        .widgetCorners(did: idGen(0), topLeading: false, topTrailing: false, bottomLeading: true, bottomTrailing: true)
        .overlay(alignment: .topLeading) {
            HStack {
                NavigationButton(to: .lockScreen)
                NavigationButton(to: .music) {
                    Image(systemName: "waveform")
                }
                NavigationButton(to: .homeKit) {
                    Image(systemName: "circle.hexagongrid")
                }
            }
            .offset(safeCornerOffsets.topLeading)
        }
        .overlay(alignment: .topTrailing) {
            Button("Edit") {
                isEditing.toggle()
            }
            .offset(safeCornerOffsets.topTrailing)
        }
    }
}

#if os(macOS)
extension NSTextView {
    open override var frame: CGRect {
        didSet {
            backgroundColor = .clear
            drawsBackground = true
        }
    }
}
#endif

#Preview {
    CustomTextPage()
}
