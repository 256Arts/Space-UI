//
//  LayoutFuncs.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2022-08-01.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

import SwiftUI

/// Returns a score for how different the 2 ratios are. 0 = the same.
func aspectRatioDifference(_ size1: CGSize, _ size2: CGSize) -> CGFloat {
    var ratio1 = size1.width / size1.height
    var ratio2 = size2.width / size2.height
    
    // Map 0...1 to -inf...-1
    if ratio1 < 1 {
        ratio1 = -1 / ratio1
    }
    if ratio2 < 1 {
        ratio2 = -1 / ratio2
    }
    
    return abs(ratio2 - ratio1)
}

extension ProposedViewSize {
    var aspectRatio: CGSize {
        if let width, let height {
            return CGSize(width: width, height: height)
        } else {
            // Default proposal is square
            return CGSize(width: 1, height: 1)
        }
    }
}

extension LayoutSubview {
    var idealSize: CGSize {
        var ideal = sizeThatFits(.unspecified)
        let max = sizeThatFits(.infinity)
        
        // Bug: Many views of infinite size report 10 as their ideal size. We try to ignore those values.
        if ideal.width <= 10 {
            ideal.width = max.width
        }
        if ideal.height <= 10 {
            ideal.height = max.height
        }
        return ideal
    }
}
