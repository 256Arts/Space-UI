//
//  FillAndBorder.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-11-29.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct FillAndBorder {
    
    let fill: Color
    let border: Color?
    
    init(fill: Color, border: Color? = nil) {
        self.fill = fill
        self.border = border
    }
    
}
