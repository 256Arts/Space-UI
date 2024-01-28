//
//  AppSettingsPage.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-01-10.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct AppSettingsPage: View {
    
    @AppStorage(UserDefaults.Key.screenShapeOverride) private var screenShapeOverrideValue = ""
    @AppStorage(UserDefaults.Key.externalDisplayOnTop) private var externalDisplayOnTop = false
    @AppStorage(UserDefaults.Key.externalDisplayOnBottom) private var externalDisplayOnBottom = false
    @AppStorage(UserDefaults.Key.externalDisplayOnLeft) private var externalDisplayOnLeft = false
    @AppStorage(UserDefaults.Key.externalDisplayOnRight) private var externalDisplayOnRight = false
    @AppStorage(UserDefaults.Key.externalDisplaySeemlessMode) private var externalDisplaySeemlessMode = false
    
    @Environment(\.shapeDirection) private var shapeDirection
    @Environment(\.elementSize) private var elementSize
    @EnvironmentObject private var appController: AppController
    
    var isLocked: Bool {
        !peerSessionController.mcSession.connectedPeers.isEmpty && !PeerSessionController.shared.isHost
    }
    var syncOverNetworkBody: String {
        if peerSessionController.mcSession.connectedPeers.isEmpty {
            switch (peerSessionController.canHost, peerSessionController.canJoin) {
            case (true, true):
                return "Looking to host/join..."
            case (true, false):
                return "Looking to host..."
            case (false, true):
                return "Looking to join..."
            case (false, false):
                return "Disabled"
            }
        } else if peerSessionController.isHost {
            return "Hosting \(peerSessionController.mcSession.connectedPeers.count) Peers"
        } else {
            return "Connected To Peers"
        }
    }
    
    @State var seedCopy = String(system.seed)
    @State private var showingDesignPrinciples = false
    @State private var showingScreenShapePicker = false
    @State private var showingHomeKit = false
    #if DEBUG
    @State private var showingFontTest = false
    #endif
    @FocusState var seedIsFocused: Bool
    
    @ObservedObject var peerSessionController = PeerSessionController.shared
    
    var body: some View {
        AutoStack(spacing: 20) {
            AutoStack {
                if system.preferedButtonSizingMode == .fixed {
                    Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                        Image(systemName: "gear")
                    }
                    .buttonStyle(ShapeButtonStyle(shapeDirection: shapeDirection))
                } else {
                    Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                        Image(systemName: "gear")
                    }
                    .buttonStyle(FlexButtonStyle())
                }
                
                NavigationButton(to: .lockScreen) {
                    Image(systemName: "xmark")
                }
            }
            
            ScrollView(showsIndicators: false) {
                LayoutThatFits([HStackLayout(), VStackLayout()]) {
                    VStack {
                        Section {
                            AutoStack {
                                TextField("Seed", text: self.$seedCopy, onCommit: {
                                    saveSeed()
                                })
                                .foregroundColor(isLocked ? Color(color: .primary, opacity: .high) : nil)
                                .padding()
                                .frame(width: elementSize == .large ? 220 : 178, height: system.flexButtonFrameHeight)
                                .background(Color(color: .primary, opacity: isLocked ? .low : .medium))
                                .cornerRadius(system.cornerRadius(forLength: system.flexButtonFrameHeight))
                                .keyboardType(.numberPad)
                                .submitLabel(.done)
                                .disabled(isLocked)
                                .focused($seedIsFocused)
                                
                                HStack {
                                    Button {
                                        AudioController.shared.play(.action)
                                        showingDesignPrinciples = true
                                    } label: { Image(systemName: "info.circle") }
                                        .buttonStyle(FlexButtonStyle())
                                        .popover(isPresented: $showingDesignPrinciples) {
                                            NavigationStack {
                                                VStack {
                                                    ProgressView(value: system.design.simplicity) {
                                                        Text("Simplicity")
                                                    }
                                                    ProgressView(value: system.design.sharpness) {
                                                        Text("Sharpness")
                                                    }
                                                    ProgressView(value: system.design.order) {
                                                        Text("Order")
                                                    }
                                                    ProgressView(value: system.design.balance) {
                                                        Text("Balance")
                                                    }
                                                    ProgressView(value: system.design.boldness) {
                                                        Text("Boldness")
                                                    }
                                                }
                                                .padding()
                                                .navigationTitle("Design Principles")
                                                .navigationBarTitleDisplayMode(.inline)
                                            }
                                            .frame(width: 260, height: 260)
                                        }
                                    
                                    Button {
                                        AudioController.shared.play(.action)
                                        self.seedCopy = String(arc4random())
                                        self.saveSeed()
                                    } label: { Image(systemName: "arrow.2.circlepath") }
                                        .buttonStyle(FlexButtonStyle(isDisabled: self.isLocked))
                                        .disabled(isLocked)
                                    
                                    #if !os(tvOS)
                                    Button {
                                        AudioController.shared.play(.action)
                                        UIPasteboard.general.string = self.seedCopy
                                    } label: { Image(systemName: "doc.on.doc") }
                                        .buttonStyle(FlexButtonStyle())
                                    #endif
                                }
                            }
                            .padding(8)
                        } header: {
                            Text("Seed")
                        }
                        
                        Section {
                            Button {
                                showingScreenShapePicker = true
                            } label: {
                                HStack {
                                    Text(ScreenShapeType(rawValue: screenShapeOverrideValue)?.name ?? "Automatic")
                                    Image(systemName: "chevron.up.chevron.down")
                                }
                            }
                            .buttonStyle(FlexButtonStyle())
                            .popover(isPresented: $showingScreenShapePicker) {
                                Picker(selection: $screenShapeOverrideValue) {
                                    Text("Automatic")
                                        .tag("")
                                    ForEach(ScreenShapeType.allCases) { shapeCase in
                                        Text(shapeCase.name)
                                            .tag(shapeCase.rawValue)
                                    }
                                } label: {
                                    Label("Screen Shape", systemImage: "rectangle.dashed")
                                }
                                .pickerStyle(.inline)
                            }
                            .padding(8)
                        } header: {
                            Text("Screen Shape")
                        }
                        
                        Section {
                            ZStack {
                                Grid {
                                    GridRow {
                                        Spacer()
                                            .gridCellUnsizedAxes([.horizontal, .vertical])
                                        Button {
                                            externalDisplayOnTop.toggle()
                                        } label: {
                                            Image(systemName: "display")
                                                .opacity(externalDisplayOnTop ? 1 : 0.5)
                                        }
                                        .buttonStyle(FlexButtonStyle(isSelected: externalDisplayOnTop))
                                    }
                                    GridRow {
                                        Button {
                                            externalDisplayOnLeft.toggle()
                                        } label: {
                                            Image(systemName: "display")
                                                .opacity(externalDisplayOnLeft ? 1 : 0.5)
                                        }
                                        .buttonStyle(FlexButtonStyle(isSelected: externalDisplayOnLeft))
                                        Image(systemName: "display")
                                        Button {
                                            externalDisplayOnRight.toggle()
                                        } label: {
                                            Image(systemName: "display")
                                                .opacity(externalDisplayOnRight ? 1 : 0.5)
                                        }
                                        .buttonStyle(FlexButtonStyle(isSelected: externalDisplayOnRight))
                                    }
                                    GridRow {
                                        Spacer()
                                            .gridCellUnsizedAxes([.horizontal, .vertical])
                                        Button {
                                            externalDisplayOnBottom.toggle()
                                        } label: {
                                            Image(systemName: "display")
                                                .opacity(externalDisplayOnBottom ? 1 : 0.5)
                                        }
                                        .buttonStyle(FlexButtonStyle(isSelected: externalDisplayOnBottom))
                                    }
                                }
                            }
                            .frame(idealWidth: .infinity, maxWidth: .infinity)
                            .overlay(alignment: .bottomTrailing) {
                                Button("Seemless") {
                                    externalDisplaySeemlessMode.toggle()
                                }
                                .buttonStyle(FlexButtonStyle(isSelected: externalDisplaySeemlessMode))
                            }
                            .padding(8)
                        } header: {
                            Text("External Display Positions")
                        }
                    }
                    
                    VStack {
                        Section {
                            HStack(spacing: 8) {
                                if syncOverNetworkBody != "Disabled" {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(Color(color: .secondary, brightness: .medium))
                                }
                                Text(syncOverNetworkBody)
                                    .foregroundColor(Color(color: .secondary, brightness: .medium))
                            }
                            .padding(8)
                        } header: {
                            Label("Sync Displays", systemImage: "display.2")
                        }
                        
                        Section {
                            Button("Open Details") {
                                showingHomeKit = true
                            }
                            .buttonStyle(FlexButtonStyle())
                            .padding(8)
                        } header: {
                            Label("Sync Lights", systemImage: "lightbulb")
                        }
                        
                        Section {
                            VStack {
                                Link(destination: URL(string: "https://www.jaydenirwin.com/")!) {
                                    Label("Developer Website", systemImage: "safari")
                                }
                                .buttonStyle(FlexButtonStyle())
                                Link(destination: URL(string: "https://www.256arts.com/joincommunity/")!) {
                                    Label("Join Community", systemImage: "bubble.left.and.bubble.right")
                                }
                                .buttonStyle(FlexButtonStyle())
                                Link(destination: URL(string: "https://github.com/256Arts/Space-UI")!) {
                                    Label("Contribute on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                                }
                                .buttonStyle(FlexButtonStyle())
                            }
                            .padding(8)
                        } header: {
                            Label("Links", systemImage: "link")
                        }
                        
                        #if DEBUG
                        Section {
                            Button {
                                showingFontTest = true
                            } label: {
                                Label("Test Fonts", systemImage: "checkmark.diamond")
                            }
                            .buttonStyle(FlexButtonStyle())
                            .padding(8)
                        } header: {
                            Label("Debug", systemImage: "ant")
                        }
                        #endif
                    }
                }
            }
        }
        .scrollClipDisabled()
        .font(.english(scale: elementSize == .mini || elementSize == .small ? 0.75 : 1))
        .onTapGesture {
            seedIsFocused = false
            saveSeed()
        }
        .sheet(isPresented: $showingHomeKit) {
            NavigationStack {
                HomeSettingsView()
            }
            .foregroundColor(.primary)
        }
        #if DEBUG
        .sheet(isPresented: $showingFontTest) {
            NavigationStack {
                FontTestView()
            }
            .foregroundColor(.primary)
        }
        #endif
        .onChange(of: screenShapeOverrideValue) {
            ScreenShape.pathCache.removeAll()
            appController.reloadRootView()
        }
        .onChange(of: externalDisplayOnTop) {
            ScreenShape.pathCache.removeAll()
            appController.reloadRootView()
        }
        .onChange(of: externalDisplayOnBottom) {
            ScreenShape.pathCache.removeAll()
            appController.reloadRootView()
        }
        .onChange(of: externalDisplayOnLeft) {
            ScreenShape.pathCache.removeAll()
            appController.reloadRootView()
        }
        .onChange(of: externalDisplayOnRight) {
            ScreenShape.pathCache.removeAll()
            appController.reloadRootView()
        }
    }
    
    func saveSeed() {
        guard let newSeed = UInt64(self.seedCopy), newSeed != system.seed else { return }
        
        if peerSessionController.isHost {
            peerSessionController.send(message: .seed(newSeed))
        }
        system = SystemStyles(seed: newSeed)
        
        UserDefaults.standard.set(newSeed, forKey: UserDefaults.Key.seed)
    }
}

#Preview {
    AppSettingsPage()
}
