//
//  SafeCornerOffsets.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2022-09-06.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct SafeCornerOffsets: Equatable {
    let topLeading: CGSize
    let topTrailing: CGSize
    let bottomLeading: CGSize
    let bottomTrailing: CGSize
}

struct SafeCornerOffsetsKey: EnvironmentKey {
    
    static let defaultValue: SafeCornerOffsets = .init(topLeading: .zero, topTrailing: .zero, bottomLeading: .zero, bottomTrailing: .zero)
    
}

extension EnvironmentValues {
    
    var safeCornerOffsets: SafeCornerOffsets {
        get {
            return self[SafeCornerOffsetsKey.self]
        }
        set {
            self[SafeCornerOffsetsKey.self] = newValue
        }
    }
    
}
