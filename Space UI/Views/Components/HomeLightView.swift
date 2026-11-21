import SwiftUI

struct HomeLightView: View {
    
    @Environment(\.system) private var system
    
    var light: HomeLight
    
    let did: Int
    
    var body: some View {
        GridRow {
            Text(light.accessory.name)
            
            Slider(insetInnerBar: did % 2 == 0, value: Binding(get: {
                light.brightness / 100
            }, set: { newValue in
                light.brightness = newValue * 100
            }))
            .gridCellUnsizedAxes(.horizontal)
        }
        
        GridRow {
            Button("Sync") {
                light.colorMode = light.colorMode == nil ? .primary : nil
            }
            .buttonStyle(FlexButtonStyle(isSelected: light.colorMode != nil))
            
            ViewThatFits {
                HStack {
                    Button(HomeLight.ColorMode.primary.rawValue) {
                        light.colorMode = .primary
                    }
                    .buttonStyle(GroupedButtonStyle(segmentPosition: .leading, width: 110, isSelected: light.colorMode == .primary))
                    
                    Button(HomeLight.ColorMode.secondary.rawValue) {
                        light.colorMode = .secondary
                    }
                    .buttonStyle(GroupedButtonStyle(segmentPosition: .middle, width: 110, isSelected: light.colorMode == .secondary))
                    
                    Button(HomeLight.ColorMode.white.rawValue) {
                        light.colorMode = .white
                    }
                    .buttonStyle(GroupedButtonStyle(segmentPosition: .middle, width: 110, isSelected: light.colorMode == .white))
                    
                    Button(HomeLight.ColorMode.off.rawValue) {
                        light.colorMode = .off
                    }
                    .buttonStyle(GroupedButtonStyle(segmentPosition: .trailing, width: 110, isSelected: light.colorMode == .off))
                }
                
                HStack {
                    Button(HomeLight.ColorMode.primary.rawValue, systemImage: "square.2.layers.3d.top.filled") {
                        light.colorMode = .primary
                    }
                    .buttonStyle(GroupedButtonStyle(segmentPosition: .leading, width: system.flexButtonFrameHeight, isSelected: light.colorMode == .primary))
                    
                    Button(HomeLight.ColorMode.secondary.rawValue, systemImage: "square.2.layers.3d.bottom.filled") {
                        light.colorMode = .secondary
                    }
                    .buttonStyle(GroupedButtonStyle(segmentPosition: .middle, width: system.flexButtonFrameHeight, isSelected: light.colorMode == .secondary))
                    
                    Button(HomeLight.ColorMode.white.rawValue, systemImage: "w.circle") {
                        light.colorMode = .white
                    }
                    .buttonStyle(GroupedButtonStyle(segmentPosition: .middle, width: system.flexButtonFrameHeight, isSelected: light.colorMode == .white))
                    
                    Button(HomeLight.ColorMode.off.rawValue, systemImage: "lightbulb.slash.fill") {
                        light.colorMode = .off
                    }
                    .buttonStyle(GroupedButtonStyle(segmentPosition: .trailing, width: system.flexButtonFrameHeight, isSelected: light.colorMode == .off))
                }
                .labelStyle(.iconOnly)
            }
        }
    }
}
