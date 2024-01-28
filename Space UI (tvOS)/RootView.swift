//
//  RootView.swift
//  Space UI (tvOS)
//
//  Created by 256 Arts Developer on 2019-12-27.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

enum Page: String {
    case lockScreen, settings, powerManagement, targeting, coms, nearby, planet, galaxy, ticTacToe, shield, music
    
    // External
    case extOrbits, extCircularProgressLeft, extCircularProgressRight
}

struct PageKey: EnvironmentKey {
    
    static let defaultValue: Page = .lockScreen
    
}

extension EnvironmentValues {
    
    var page: Page {
        get {
            return self[PageKey.self]
        }
        set {
            self[PageKey.self] = newValue
        }
    }
    
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
        switch systemStyles.screen.screenShapeType {
        case .circle, .triangle:
            return .regular
        default:
            return .large
        }
    }
    
    @State var showSettingsView = false
    
    @ObservedObject private var systemStyles: SystemStyles = system
    @ObservedObject private var appController: AppController = .shared
    
    var body: some View {
        ScreenView {
            switch appController.visiblePage {
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
        .font(Font.spaceFont(size: systemStyles.defaultFontSize))
        .foregroundColor(Color(color: .secondary, opacity: .max))
        .environmentObject(systemStyles)
        .environmentObject(appController)
        .environment(\.elementSize, elementSize)
        .focusable()
        .onExitCommand {
            showSettingsView = true
        }
    }
}

#Preview {
    RootView()
}
