import SwiftUI

struct LockScreenPage: View {
    @Environment(\.system) private var system

    enum BrandNamePosition {
        case topCorner, centerRing
    }
    
    let hasRingViews: Bool
    let hasTopBottomRings: Bool
    let hasCircularSegmentedView: Bool
    let brandNamePosition: BrandNamePosition
    let extraBottomCircleIcon: Bool
    let shipName = "S-Wing"
    let shipManufacturer = "Space Corp."
    
    @IDGen private var idGen
    @Environment(\.elementSize) private var elementSize
    @Environment(\.safeCornerOffsets) private var safeCornerOffsets
    @Environment(AppController.self) private var appController
    
    @State var topBottomRingsAngle = Angle.zero
    @State var tutorialIsShown = !UserDefaults.standard.bool(forKey: UserDefaults.Key.tutorialShown)
    
    var bottomCircleIconCount: Int {
        switch elementSize {
        case .small:
            return 2 + (extraBottomCircleIcon ? 1 : 0)
        case .mini:
            return 1 + (extraBottomCircleIcon ? 1 : 0)
        default:
            return 3 + (extraBottomCircleIcon ? 1 : 0)
        }
    }
    
    var body: some View {
        ZStack {
            if hasRingViews {
                DecorativeRingView(animateSize: true, opacity: .low)
                DecorativeRingView(animateSize: true, opacity: .low)
            }
            if hasTopBottomRings {
                GeometryReader { geometry in
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 10.0, lineCap: .round, dash: [0.001, 28.0]))
                        .foregroundColor(system.colors.color(.primary, opacity: .medium))
                        .frame(height: geometry.size.width)
                        .rotationEffect(topBottomRingsAngle)
                        .position(x: geometry.size.width/2, y: -geometry.size.height * 0.4)
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 10.0, lineCap: .round, dash: [0.001, 28.0]))
                        .foregroundColor(system.colors.color(.primary, opacity: .medium))
                        .frame(height: geometry.size.width)
                        .rotationEffect(topBottomRingsAngle)
                        .position(x: geometry.size.width/2, y: geometry.size.height * 1.4)
                }
            }
            VStack {
                HStack {
                    if brandNamePosition == .topCorner {
                        TextPair(did: idGen(0), label: shipManufacturer, value: shipName, largerFontSize: 28)
                            .multilineTextAlignment(.leading)
                            .offset(safeCornerOffsets.topLeading)
                    }
                    Spacer()
                }
                Spacer()
                HStack {
                    ForEach(0..<bottomCircleIconCount, id: \.self) { index in
                        CircleIcon.image(vid: idGen(index))
                            .foregroundColor(system.colors.color(.primary, opacity: .high))
                    }

                    // The way in to settings, hidden in plain sight: drawn as one more of the decorative icons
                    // beside it — no button chrome — so it doesn't invite a tap from someone exploring the
                    // console, but it is always the last icon in this row for anyone who is looking for it.
                    // The lock screen carries it because that is where a first run starts and the other paths
                    // (Mac menu, right-edge swipe, quick start) are hidden or off-device.
                    Button {
                        AudioController.shared.play(.button)
                        appController.openPageModally(.settings)
                    } label: {
                        CircleIcon.image(vid: idGen(bottomCircleIconCount))
                            .foregroundColor(system.colors.color(.primary, opacity: .high))
                    }
                    .buttonStyle(.plain)
                    .contentShape(.rect)
                    .accessibilityLabel("Settings")
                }
            }
            AutoStack(spacing: 16) {
                NavigationButton(to: .powerManagement)
                NavigationButton(to: .customText)
            }
            .background {
                if brandNamePosition == .centerRing {
                    ZStack {
                        CircularText(string: shipName, radius: 150, onTopEdge: true)
                            .foregroundColor(system.colors.color(.primary, opacity: .max))
                        CircularText(string: shipManufacturer, radius: 150, onTopEdge: false)
                            .foregroundColor(system.colors.color(.primary, opacity: .medium))
                    }
                }
            }
        }
        .widgetCorners(did: idGen(27), topLeading: brandNamePosition != .topCorner, topTrailing: true, bottomLeading: true, bottomTrailing: true)
        .onAppear {
            withAnimation(Animation.linear(duration: 100.0).repeatForever(autoreverses: false)) {
                self.topBottomRingsAngle = Angle.degrees(360)
            }
        }
        .alert("UI is generated using a seed.", isPresented: self.$tutorialIsShown) {
            Button("OK", role: .cancel) {
                UserDefaults.standard.set(true, forKey: UserDefaults.Key.tutorialShown)
            }
        } message: {
            #if targetEnvironment(macCatalyst)
            Text("Go to **View > Show Settings** to modify the seed.")
            #else
            Text("Tap the last icon at the bottom of the lock screen for settings, and modify the seed.")
            #endif
        }
    }
    
    init() {
        let random = SeededRandom(seed: Space_UI.system.seed)
        
        hasRingViews = random.nextBool(chance: 0.666)
        hasTopBottomRings = random.nextBool()
        hasCircularSegmentedView = random.nextBool()
        brandNamePosition = random.nextBool() ? .topCorner : .centerRing
        extraBottomCircleIcon = random.nextBool()
    }
}

#Preview {
    LockScreenPage()
}
