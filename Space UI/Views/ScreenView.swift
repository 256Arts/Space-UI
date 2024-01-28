//
//  ScreenView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2019-10-04.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct ScreenView<Content: View>: View {
    
    let content: Content
    
    @AppStorage(UserDefaults.Key.externalDisplaySeemlessMode) private var externalDisplaySeemlessMode = false
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var hSizeClass
    private var regularHSizeClass: Bool {
        hSizeClass == .regular
    }
    #else
    private let regularHSizeClass = true
    #endif
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    
    @EnvironmentObject private var systemStyles: SystemStyles
    
    @State private var maskOffset: CGSize = CGSize(width: 100.0 / 2.0, height: 100.0 / 2.0)
    
    private let startDate = Date.now
    private var hLinesShaderEnabled: Bool {
        #if os(tvOS)
        // Both line filters render horizontally on tvOS
        systemStyles.screen.filter != .none && !reducedMotion
        #else
        systemStyles.screen.filter == .hLines && !reducedMotion
        #endif
    }
    private var vLinesShaderEnabled: Bool {
        systemStyles.screen.filter == .vLines && !reducedMotion
    }
    private var screenStrokeStyle: StrokeStyle? {
        guard let width = systemStyles.screenBorderWidth else { return nil }
        
        return StrokeStyle(lineWidth: width, lineCap: systemStyles.lineCap, dash: systemStyles.lineDash(lineWidth: systemStyles.thickLineWidth))
    }
    private var waveAmplitude: Float {
        #if os(tvOS)
        9
        #else
        3
        #endif
    }
    private var lineShaderLineWidth: Float {
        #if os(tvOS)
        8
        #else
        2
        #endif
    }
    
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { _ in
                content
//                    #if DEBUG
//                    .overlay {
//                        Rectangle()
//                            .strokeBorder(Color.white, lineWidth: 1)
//                    }
//                    .overlay(alignment: .topLeading) {
//                        Color.white
//                            .frame(width: 5, height: 5)
//                            .offset(system.screen.safeCornerOffsets(screenSize: geometry.size).topLeading)
//                    }
//                    .overlay(alignment: .topTrailing) {
//                        Color.white
//                            .frame(width: 5, height: 5)
//                            .offset(system.screen.safeCornerOffsets(screenSize: geometry.size).topTrailing)
//                    }
//                    .overlay(alignment: .bottomLeading) {
//                        Color.white
//                            .frame(width: 5, height: 5)
//                            .offset(system.screen.safeCornerOffsets(screenSize: geometry.size).bottomLeading)
//                    }
//                    .overlay(alignment: .bottomTrailing) {
//                        Color.white
//                            .frame(width: 5, height: 5)
//                            .offset(system.screen.safeCornerOffsets(screenSize: geometry.size).bottomTrailing)
//                    }
//                    #endif
                    .padding(systemStyles.screen.mainContentInsets(screenSize: geometry.size))
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    #if !DEBUG
                    .distortionEffect(
                        Shader(
                            function: ShaderLibrary[dynamicMember: "occasionalWave"],
                            arguments: [ .float(startDate.timeIntervalSinceNow * 18), .float(15), .float(waveAmplitude), .float(15) ]),
                        maxSampleOffset: CGSize(width: waveAmplitude, height: 0),
                        isEnabled: !reducedMotion)
                    #endif
                    .background {
                        if system.screen.backgroundStyle == .color {
                            Color.screenBackground
                        } else {
                            LinearGradient(gradient: Gradient(colors: (system.screen.backgroundStyle == .gradientDown ? [
                                Color(color: .primary, brightnessMultiplier: 0.05),
                                Color(color: .primary, brightnessMultiplier: -0.05)
                            ] : [
                                Color(color: .primary, brightnessMultiplier: -0.05),
                                Color(color: .primary, brightnessMultiplier: 0.05)
                            ])), startPoint: .top, endPoint: .bottom)
                        }
                    }
                    .clipShape(ScreenShape(screenShapeType: system.screen.resolvedScreenShapeType(screenSize: geometry.size)))
                    .colorEffect(
                        Shader(
                            function: ShaderLibrary[dynamicMember: "hLines"],
                            arguments: [ .float(startDate.timeIntervalSinceNow * 2), .float(lineShaderLineWidth) ]),
                        isEnabled: hLinesShaderEnabled)
                    #if !os(tvOS) // Cannot use multiple effects on tvOS 17.3
                    .colorEffect(
                        Shader(
                            function: ShaderLibrary[dynamicMember: "vLines"],
                            arguments: [ .float(startDate.timeIntervalSinceNow * 2), .float(lineShaderLineWidth) ]),
                        isEnabled: vLinesShaderEnabled)
                    #endif
                    .environment(\.colorScheme, systemStyles.colors.useLightAppearance ? .light : .dark)
                    .background(alignment: .top) {
                        if let cutoutFrame = systemStyles.screen.cutoutFrame(screenSize: geometry.size, forTop: true), regularHSizeClass {
                            DecorativeStatusView(data: ShipData.shared.topStatusState)
                                .frame(width: cutoutFrame.size.width, height: cutoutFrame.size.height)
                                .offset(x: cutoutFrame.origin.x)
                        }
                    }
                    .background(alignment: .bottom) {
                        if let cutoutFrame = systemStyles.screen.cutoutFrame(screenSize: geometry.size, forTop: false) {
                            DecorativeStatusView(data: ShipData.shared.bottomStatusState)
                                .frame(width: cutoutFrame.size.width, height: cutoutFrame.size.height)
                                .offset(x: cutoutFrame.origin.x)
                        }
                    }
                    .environment(\.safeCornerOffsets, systemStyles.screen.safeCornerOffsets(screenSize: geometry.size))
            }
            .overlay {
                if let style = screenStrokeStyle {
                    ScreenShape(screenShapeType: systemStyles.screen.resolvedScreenShapeType(screenSize: geometry.size))
                        .inset(by: systemStyles.screenBorderInsetAmount)
                        .strokeBorder(Color(color: .primary, opacity: systemStyles.colors.useLightAppearance ? .medium : .max), style: style)
                        .padding(.top, seemlessBorderOffset(.top))
                        .padding(.bottom, seemlessBorderOffset(.bottom))
                        .padding(.leading, seemlessBorderOffset(.left))
                        .padding(.trailing, seemlessBorderOffset(.right))
                }
            }
        }
    }
    
    @inlinable public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    private func seemlessBorderOffset(_ edge: ScreenStyles.RectEdge) -> CGFloat {
        system.screen.connectedEdges.contains(edge) ? -system.screenBorderInsetAmount - (system.screenBorderWidth ?? 0) : 0
    }
}

#Preview {
    ScreenView {
        Text("Hello")
    }
}
