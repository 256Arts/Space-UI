import SwiftUI

struct RandomWidget: View {
    @Environment(\.system) private var system

    enum WidgetType {
        case circularWidget, almostThereText, binary, boxes, largeIcons, knobs, sliders
    }
    
    let did: Int
    let vid: Int
    
    @Environment(\.elementSize) private var elementSize
    
    let widgetType: WidgetType
    // The one place a view still reads the `system` global on purpose: a `@State` default is evaluated before
    // the view has an environment, so `@Environment` isn't available here. Safe because the root rebuilds this
    // subtree on a theme change (`AppController.configID`), which re-runs the default against the new theme.
    @State var notificationShadowColor = Space_UI.system.colors.color(.primary, opacity: .medium)
    @State var notificationOpacity = 1.0
    @State var slider1: Double
    @State var slider2: Double
    @State private var intGen = IntGenerator(range: 0...9999, averageFrequency: 8)
    @State private var almostThereNumber = IntSequencer(frequency: TimeInterval.random(in: 0.1...5.0), initialValue: Int.random(in: 0...9999), maxValue: 9999)
    
    var almostThereDigitCount: Int {
        switch elementSize {
        case .small:
            return 3
        case .mini:
            return 2
        default:
            return 4
        }
    }
    
    var sliderWidth: CGFloat {
        switch elementSize {
        case .mini:
            return 80
        case .small:
            return 100
        case .regular:
            return 160
        case .large:
            return 220
        }
    }
    
    var body: some View {
        switch widgetType {
        case .circularWidget:
            RandomCircularWidget(did: did + 7, vid: vid)
        case .almostThereText:
            AlmostThereNumberText(number: self.$almostThereNumber.value, digitCount: almostThereDigitCount)
        case .binary:
            VStack {
                BinaryView(value: vid % 64)
                BinaryView(value: (vid + 7) % 64)
            }
        case .boxes:
            DecorativeBoxesView(vid: vid + intGen.value)
        case .largeIcons:
            HStack {
                ForEach(0..<(1 + (vid % 2)), id: \.self) { index in
                    LargeIcon.image(vid: vid + index)
                        .foregroundColor(system.colors.color(.primary, opacity: .max))
                        .shadow(color: self.notificationShadowColor, radius: 10, x: 0, y: 0)
                        .opacity(self.notificationOpacity)
                }
            }
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                    self.notificationShadowColor = .clear
                    self.notificationOpacity = 0.5
                }
            }
        case .knobs:
            Knobs(did: did + 7, vid: vid + intGen.value)
        case .sliders:
            VStack {
                Slider(insetInnerBar: did % 2 == 0, value: $slider1)
                Slider(insetInnerBar: did % 2 == 0, value: $slider2)
            }
            .frame(maxWidth: sliderWidth)
        }
    }
    
    init(did: Int, vid: Int) {
        self.did = did
        self.vid = vid
        
        let designRandom = SeededRandom(seed: UInt64(did))
        widgetType = {
            switch designRandom.nextInt(in: 0..<11) {
            case 0:
                return .almostThereText
            case 1:
                return .binary
            case 2:
                return .boxes
            case 3:
                return .largeIcons
            case 4:
                return .knobs
            case 5:
                return .sliders
            default:
                return .circularWidget
            }
        }()
        
        let valueRandom = SeededRandom(seed: UInt64(vid))
        slider1 = valueRandom.nextFraction()
        slider2 = valueRandom.nextFraction()
    }
    
}

#Preview {
    RandomWidget(did: 0, vid: 0)
}
