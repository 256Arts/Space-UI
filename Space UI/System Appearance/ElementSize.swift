//
//  ElementSize.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2022-10-07.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

import SwiftUI

enum ElementSize {
    case mini, small, regular, large
}

struct ElementSizeKey: EnvironmentKey {
    
    static let defaultValue: ElementSize = .regular
    
}

extension EnvironmentValues {
    
    var elementSize: ElementSize {
        get {
            return self[ElementSizeKey.self]
        }
        set {
            self[ElementSizeKey.self] = newValue
        }
    }
    
}
