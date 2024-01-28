//
//  FontTestView.swift
//  Space UI (tvOS)
//
//  Created by 256 Arts Developer on 2022-11-05.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

#if DEBUG
import SwiftUI

struct FontTestView: View {
    var body: some View {
        List {
            ForEach(Font.Name.allCases) { fontName in
                Text(fontName.rawValue)
                    .font(Font.custom(fontName.rawValue, fixedSize: fontName.defaultFontSize))
                    #if os(tvOS)
                    .focusable()
                    #endif
            }
        }
        .navigationTitle("Fonts Test")
    }
}

struct FontTestView_Previews: PreviewProvider {
    static var previews: some View {
        FontTestView()
    }
}

extension Font.Name: Identifiable {
    var id: Self { self }
}
#endif
