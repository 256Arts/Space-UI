//
//  PowerManagementPage.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-15.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI
import GameplayKit

struct PowerManagementPage: View {
    
    var model: String {
        let seedInt = Int(system.seed)
        let alphaNum = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numberOfDigits = Int.numberOfDigits(for: seedInt, inBase: alphaNum.count)
        let digits = Int.representation(of: seedInt, inBase: alphaNum.count, withDigitCount: numberOfDigits)
        var alphaNumRepresentation = ""
        for digit in digits {
            let index = alphaNum.index(alphaNum.startIndex, offsetBy: digit)
            alphaNumRepresentation.append(alphaNum[index])
        }
        return alphaNumRepresentation
    }
    
    @IDGen private var idGen
    @EnvironmentObject private var system: SystemStyles
    
    @State var slider1 = 0.0
    @State var slider2 = 0.0
    
    var body: some View {
        AutoStack {
            ZStack {
                ShipData.shared.icon
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color(color: .secondary, opacity: .max))
                    .frame(maxWidth: 700, maxHeight: 700)
                VStack(spacing: 20) {
                    NavigationButton(to: .shield)
                    NavigationButton(to: .coms)
                    NavigationButton(to: .powerManagement)
                    NavigationButton(to: .powerManagement)
                    NavigationButton(to: .ticTacToe)
                }
            }
            VStack {
                Text("Model: \(self.model)")
                    .font(Font.spaceFont(size: 22))
                    .padding()
                AutoStack(spacing: 16) {
                    NavigationButton(to: .lockScreen)
                    NavigationButton(to: .nearby)
                }
            }
        }
        .frame(idealWidth: .infinity, maxWidth: .infinity, idealHeight: .infinity, maxHeight: .infinity)
        .widgetCorners(did: idGen(0), topLeading: true, topTrailing: true, bottomLeading: true, bottomTrailing: true)
    }
}

#Preview {
    PowerManagementPage()
}
