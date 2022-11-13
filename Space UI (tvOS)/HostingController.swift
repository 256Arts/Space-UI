//
//  HostingController.swift
//  Space UI (tvOS)
//
//  Created by Jayden Irwin on 2020-03-29.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import SwiftUI

class HostingController: UIHostingController<RootView> {
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.backgroundColor = .black
        overrideUserInterfaceStyle = .dark
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)
        
        guard presses.contains(where: { $0.type == .select }) else { return }
        
        NotificationCenter.default.post(name: NSNotification.Name("showSeedView"), object: nil)
    }
    
}
