//
//  DebugControls.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-04-27.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

#if DEBUG
import SwiftUI

struct DebugControls: View {
    var body: some View {
        VStack {
            Button {
                system.fontOverride.toggle()
            } label: {
                Image(systemName: "textformat")
            }
            .buttonStyle(FlexButtonStyle())
            
            Button {
                if ShipData.shared.isInEmergency {
                    ShipData.shared.endEmergency()
                } else {
                    ShipData.shared.beginEmergency()
                }
            } label: {
                Image(systemName: "exclamationmark.triangle")
            }
            .buttonStyle(FlexButtonStyle())
            
            Button {
                system = SystemStyles(seed: UInt64(arc4random()))
                DispatchQueue.main.async {
                    if AppController.shared.debugShowingExternalDisplay {
                        AppController.shared.visiblePage = AppController.shared.savedPage
                    } else {
                        AppController.shared.savedPage = AppController.shared.visiblePage
                        AppController.shared.visiblePage = system.screen.externalDisplayPage
                    }
                    AppController.shared.debugShowingExternalDisplay.toggle()
                }
            } label: {
                #if targetEnvironment(macCatalyst)
                Image(systemName: AppController.shared.debugShowingExternalDisplay ? "tv" : "desktopcomputer")
                #else
                Image(systemName: AppController.shared.debugShowingExternalDisplay ? "tv" : "iphone")
                #endif
            }
            .buttonStyle(FlexButtonStyle())
            
            Button {
                system = SystemStyles(seed: UInt64(arc4random()))
            } label: {
                Image(systemName: "arrow.2.circlepath")
            }
            .buttonStyle(FlexButtonStyle())
        }
        .font(Font.system(size: 18, weight: .semibold, design: .rounded))
    }
}

#Preview {
    DebugControls()
}
#endif
