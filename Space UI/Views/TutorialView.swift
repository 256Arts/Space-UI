//
//  TutorialView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-06-17.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct TutorialView: View {
    
    var howToViewSeed: String {
        #if targetEnvironment(macCatalyst)
        "Go to \"Show Settings\" in the View menu to modify the seed."
        #else
        "Double tap on any screen to view settings, and modify the seed."
        #endif
    }
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("UI is generated using a seed.")
            Text(howToViewSeed)
            Spacer()
            Button("Continue") {
                UserDefaults.standard.set(true, forKey: UserDefaults.Key.tutorialShown)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
            .font(Font.system(size: 20, weight: .medium, design: .rounded))
            .multilineTextAlignment(.center)
            .padding()
            .frame(idealWidth: .infinity, maxWidth: .infinity)
            .background(
                Color(UIColor.secondarySystemBackground)
                    .ignoresSafeArea()
            )
            .environment(\.colorScheme, .dark)
    }
}

#Preview {
    TutorialView()
}
