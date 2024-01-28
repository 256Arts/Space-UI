//
//  RootView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-12-15.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

enum Page: String {
    case lockScreen, settings, powerManagement, targeting, coms, nearby, planet, galaxy, ticTacToe, shield, squad, music, homeKit, customText, sudokuPuzzle, lightsOutPuzzle, unlabeledKeypadPuzzle
    
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
    
    let isExternal: Bool
    
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    private var elementSize: ElementSize {
        #if targetEnvironment(macCatalyst)
        return .large
        #else
        if (vSizeClass == .regular && hSizeClass == .regular) &&
            systemStyles.screen.screenShapeType != .circle && systemStyles.screen.screenShapeType != .triangle {
            return .regular
        } else {
            return .small
        }
        #endif
    }
    
    @ObservedObject private var systemStyles: SystemStyles = system
    @ObservedObject private var appController: AppController = .shared
    
    var body: some View {
        VStack {
            if vSizeClass == .regular, let segs = systemStyles.screen.topMorseCodeSegments {
                MorseCodeLine(segments: segs)
                    .padding(.horizontal, 20)
                    #if targetEnvironment(macCatalyst)
                    // Avoid window controls
                    .padding(.leading, 60)
                    #endif
            }
            ScreenView {
                switch appController.visiblePage {
                case .extOrbits:
                    OrbitsExtPage()
                case .extCircularProgressLeft:
                    CircularProgressExtPageLeft()
                case .extCircularProgressRight:
                    CircularProgressExtPageLeft()
                        .scaleEffect(x: -1, y: 1)
                case .lockScreen:
                    LockScreenPage()
                case .settings:
                    AppSettingsPage()
                case .powerManagement:
                    PowerManagementPage()
                case .targeting:
                    TargetingPage()
                case .coms:
                    ComsPage()
                case .nearby:
                    NearbyPage()
                case .planet:
                    PlanetPage()
                case .galaxy:
                    GalaxyPage()
                case .customText:
                    CustomTextPage()
                case .ticTacToe:
                    TicTacToePage()
                case .shield:
                    ShieldPage()
                case .squad:
                    SquadPage()
                case .music:
                    MusicPage()
                case .homeKit:
                    HomeKitPage()
                case .sudokuPuzzle:
                    SudokuPage()
                case .lightsOutPuzzle:
                    LightsOutPage()
                case .unlabeledKeypadPuzzle:
                    UnlabeledKeypadPage()
                }
            }
            if vSizeClass == .regular, let segs = systemStyles.screen.bottomMorseCodeSegments {
                MorseCodeLine(segments: segs)
                    .padding(.horizontal, 20)
            }
        }
        #if !os(visionOS)
        .ignoresSafeArea(edges: systemStyles.screen.edgesIgnoringSafeAreaForScreenShape(screenSize: UIScreen.main.bounds.size, traitCollection: UIScreen.main.traitCollection))
        #endif
        
        #if DEBUG
        .overlay(alignment: .leading) {
            if !isExternal, appController.showingDebugControls {
                DebugControls()
                    .padding()
                    .transition(.move(edge: .leading))
                    .environment(\.colorScheme, systemStyles.colors.useLightAppearance ? .light : .dark)
                    .onAppear {
                        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { (_) in // Animation with delay will prevent taps
                            withAnimation {
                                appController.showingDebugControls = false
                            }
                        }
                    }
            }
        }
        #if !targetEnvironment(macCatalyst)
        .gesture(
            DragGesture()
                .onEnded({ gesture in
                    if gesture.startLocation.x < 10 {
                        withAnimation {
                            appController.showingDebugControls = true
                        }
                    } else if gesture.translation.width < 0, abs(gesture.translation.width) > abs(gesture.translation.height) {
                        withAnimation {
                            appController.showingDebugControls = false
                        }
                    }
                })
        )
        #endif
        #endif
            
        .statusBar(hidden: true)
        .persistentSystemOverlays(.hidden)
        .font(Font.spaceFont(size: systemStyles.defaultFontSize))
        .buttonStyle(ShapeButtonStyle(shapeDirection: systemStyles.shapeDirection))
        .lineSpacing(10)
        .foregroundColor(Color(color: .secondary, opacity: .max))
        #if !targetEnvironment(macCatalyst)
        .onTapGesture(count: 2, perform: {
            appController.visiblePage = .settings
        })
        #endif
        .environmentObject(systemStyles)
        .environmentObject(appController)
        .environment(\.elementSize, elementSize)
        .environment(\.page, appController.visiblePage)
    }
}

#Preview {
    RootView(isExternal: false)
}
