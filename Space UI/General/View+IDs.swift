//
//  View+IDs.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2022-12-13.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

import SwiftUI

/// Generates DID and VIDs. Only use this in Page files.
@propertyWrapper struct IDGen: DynamicProperty {
    
    @Environment(\.page) private var page
    
    var wrappedValue: (Int) -> Int {
        get {
            return { suffix in
                abs(Int(system.seed) + page.hashValue + suffix)
            }
        }
    }
}

// DID = Design ID. The seed used to generate the view's style.
// VID = Value ID. The seed used to generate the view's state.
