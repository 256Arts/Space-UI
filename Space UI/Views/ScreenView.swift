//
//  ScreenView.swift
//  Space UI
//
//  Created by Jayden Irwin on 2019-10-04.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import SwiftUI
import CoreImage.CIFilterBuiltins // Import required for tvOS

struct ScreenView<Content: View>: View {
    
    let content: Content
    
    let maxMaskOffset: CGFloat = 100.0
    let maskLines: Image? = {
        guard system.screen.filter == .hLines || system.screen.filter == .vLines, !UIAccessibility.isReduceMotionEnabled else { return nil }
        
        let lineWidth: CGFloat = 4.0
        let imageRect = CGRect(origin: .zero, size: CGSize(width: lineWidth * 2.0, height: lineWidth * 2.0))
        let lineFilter = CIFilter.lineScreen()
        lineFilter.angle = system.screen.filter == .hLines ? .pi/2.0 : 0.0
        lineFilter.width = Float(lineWidth)
        lineFilter.sharpness = 0.0
        lineFilter.inputImage = CIImage(color: .white).cropped(to: imageRect)
        let alphaFilter = CIFilter.maskToAlpha()
        alphaFilter.inputImage = lineFilter.outputImage
        if let output = alphaFilter.outputImage, let cgImage = CIContext().createCGImage(output, from: output.extent) {
            return Image(uiImage: UIImage(cgImage: cgImage))
        }
        return nil
    }()
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var hSizeClass
    private var regularHSizeClass: Bool {
        hSizeClass == .regular
    }
    #else
    private let regularHSizeClass = true
    #endif
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    
    @State private var maskOffset: CGSize = CGSize(width: 100.0 / 2.0, height: 100.0 / 2.0)
    
    private var screenStrokeStyle: StrokeStyle? {
        system.prefersBorders ? StrokeStyle(lineWidth: system.thickLineWidth, lineCap: system.lineCap, dash: system.lineDash(lineWidth: system.thickLineWidth)) : nil
    }
    
    var body: some View {
        GeometryReader { geometry in
            content
//                #if DEBUG
//                .overlay {
//                    Rectangle()
//                        .strokeBorder(Color.white, lineWidth: 1)
//                }
//                .overlay(alignment: .topLeading) {
//                    Color.white
//                        .frame(width: 5, height: 5)
//                        .offset(system.screen.safeCornerOffsets(screenSize: geometry.size).topLeading)
//                }
//                .overlay(alignment: .topTrailing) {
//                    Color.white
//                        .frame(width: 5, height: 5)
//                        .offset(system.screen.safeCornerOffsets(screenSize: geometry.size).topTrailing)
//                }
//                .overlay(alignment: .bottomLeading) {
//                    Color.white
//                        .frame(width: 5, height: 5)
//                        .offset(system.screen.safeCornerOffsets(screenSize: geometry.size).bottomLeading)
//                }
//                .overlay(alignment: .bottomTrailing) {
//                    Color.white
//                        .frame(width: 5, height: 5)
//                        .offset(system.screen.safeCornerOffsets(screenSize: geometry.size).bottomTrailing)
//                }
//                #endif
                .padding(system.screen.mainContentInsets(screenSize: geometry.size))
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
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
                .clipShape(ScreenShape(screenShapeType: system.screen.actualScreenShapeType(screenSize: geometry.size)))
                .overlay {
                    if let style = screenStrokeStyle {
                        ScreenShape(screenShapeType: system.screen.actualScreenShapeType(screenSize: geometry.size))
                            .inset(by: system.borderInsetAmount)
                            .strokeBorder(Color(color: .primary, opacity: system.colors.useLightAppearance ? .medium : .max), style: style)
                    }
                }
                .mask {
                    if let maskLines = maskLines {
                        maskLines
                            .resizable(resizingMode: .tile)
                            .frame(width: geometry.size.width + maxMaskOffset, height: geometry.size.height + maxMaskOffset)
                            .offset(maskOffset)
                    } else {
                        Color.black
                    }
                }
                .environment(\.colorScheme, system.colors.useLightAppearance ? .light : .dark)
                .overlay(alignment: .top) {
                    if let cutoutFrame = system.screen.cutoutFrame(screenSize: geometry.size, forTop: true), regularHSizeClass {
                        DecorativeStatusView(data: ShipData.shared.topStatusState)
                            .frame(width: cutoutFrame.size.width, height: cutoutFrame.size.height)
                            .offset(x: cutoutFrame.origin.x)
                    }
                }
                .overlay(alignment: .bottom) {
                    if let cutoutFrame = system.screen.cutoutFrame(screenSize: geometry.size, forTop: false) {
                        DecorativeStatusView(data: ShipData.shared.bottomStatusState)
                            .frame(width: cutoutFrame.size.width, height: cutoutFrame.size.height)
                            .offset(x: cutoutFrame.origin.x)
                    }
                }
//                .position(x: geometry.size.width/2, y: geometry.size.height/2)
                .onAppear {
                    guard system.screen.filter == .hLines || system.screen.filter == .vLines, !reducedMotion else { return }
                    
                    maskOffset = CGSize(width: maxMaskOffset / 2.0, height: maxMaskOffset / 2.0)
                    if system.screen.filter == .hLines {
                        withAnimation(Animation.linear(duration: 10).repeatForever(autoreverses: false)) {
                            maskOffset.height -= maxMaskOffset
                        }
                    } else {
                        withAnimation(Animation.linear(duration: 10).repeatForever(autoreverses: false)) {
                            maskOffset.width -= maxMaskOffset
                        }
                    }
                }
                .environment(\.safeCornerOffsets, system.screen.safeCornerOffsets(screenSize: geometry.size))
        }
    }
    
    @inlinable public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
}

struct ScreenView_Previews: PreviewProvider {
    static var previews: some View {
        ScreenView {
            Text("Hello")
        }
    }
}
