//
//  RootView.swift
//  Space UI (tvOS)
//
//  Created by Jayden Irwin on 2019-12-27.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import SwiftUI

var visiblePage = system.screen.externalDisplayPage

enum Page {
    case lockScreen, settings, powerManagement, targeting, coms, nearby, planet, galaxy, ticTacToe, shield, music
    case extOrbits, extCircularProgressLeft, extCircularProgressRight
}

struct RootView: View {
    
    private enum DisplayOrientation: String {
        case `default`, left, right
        
        var angle: Angle {
            switch self {
            case .left:
                return .degrees(90)
            case .right:
                return .degrees(-90)
            default:
                return .zero
            }
        }
    }
    
    @AppStorage(UserDefaults.Key.displayOrientation) private var displayOrientationRawValue = "default"
    private var displayOrientation: DisplayOrientation {
        DisplayOrientation(rawValue: displayOrientationRawValue) ?? .default
    }
    
    private var elementSize: ElementSize {
        if system.screen.screenShapeType != .circle && system.screen.screenShapeType != .triangle {
            return .large
        } else {
            return .regular
        }
    }
    
    @State var currentPage: Page
    @State var showSettingsView = false
    @ObservedObject private var systemAppearance: SystemAppearance = system
    
    var body: some View {
        ScreenView {
            switch visiblePage {
            case .extCircularProgressLeft:
                CircularProgressExtPageLeft()
            case .extCircularProgressRight:
                CircularProgressExtPageLeft()
                    .scaleEffect(x: -1, y: 1)
            default:
                OrbitsExtPage()
            }
            
        }
        .sheet(isPresented: self.$showSettingsView) {
            AppSettingsPage()
        }
        .ignoresSafeArea()
        .frame(width: displayOrientation == .default ? 1920 : 1080, height: displayOrientation == .default ? 1080 : 1920)
        .rotationEffect(displayOrientation.angle)
        .font(Font.spaceFont(size: system.defaultFontSize))
        .foregroundColor(Color(color: .secondary, opacity: .max))
        .environmentObject(systemAppearance)
        .environment(\.elementSize, elementSize)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("showSeedView"))) { _ in
            self.showSettingsView = true
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(currentPage: system.screen.externalDisplayPage)
    }
}
