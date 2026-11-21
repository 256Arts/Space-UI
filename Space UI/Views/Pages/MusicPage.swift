import SwiftUI
import AVKit

struct MusicPage: View {
    
    @IDGen private var idGen
    @Environment(\.shapeDirection) var shapeDirection: ShapeDirection
    @Environment(\.system) private var system
    
    let showAlbumArtwork: Bool
    
    @Bindable private var music = MusicController.shared
    
    var body: some View {
        VStack(spacing: 8) {
            AutoStack {
                AutoStack(spacing: 16) {
                    NavigationButton(to: .lockScreen)
                    NavigationButton(to: .customText) {
                        Image(systemName: "line.3.horizontal")
                    }
                    NavigationButton(to: .homeKit) {
                        Image(systemName: "homekit")
                    }
                }
                
                if UserDefaults.standard.bool(forKey: UserDefaults.Key.showAlbumArtwork) && showAlbumArtwork && music.artwork != nil {
                    Image(uiImage: music.artwork!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .colorMultiply(system.colors.color(.primary, opacity: .max))
                        .clipShape(AutoShape(system: system, direction: shapeDirection))
                }
            }
            Spacer()
            GeometryReader { geometry in
                AudioVisualizer(
                    width: geometry.size.width,
                    highComplexitySound: true,
                    isPlaying: Binding(get: { music.isPlaying }, set: { _ in })
                )
                .position(x: geometry.size.width/2, y: geometry.size.height/2)
            }
            Spacer()
            HStack {
                Button {
                    AudioController.shared.play(.action)
                    self.music.skipToPrevious()
                } label: {
                    Image(systemName: "circle.lefthalf.fill")
                }
                .buttonStyle(GroupedButtonStyle(segmentPosition: .leading))
                Button {
                    AudioController.shared.play(.action)
                    self.music.playPause()
                } label: {
                    Image(systemName: "circle")
                }
                .buttonStyle(GroupedButtonStyle(segmentPosition: .middle, isSelected: self.music.isPlaying))
                Button {
                    AudioController.shared.play(.action)
                    self.music.skipToNext()
                } label: {
                    Image(systemName: "circle.righthalf.fill")
                }
                .buttonStyle(GroupedButtonStyle(segmentPosition: .trailing))
            }
            HStack {
                CircularProgressView(did: idGen(1), value: $music.volume)
                    .frame(maxWidth: 80, maxHeight: 80)
                    .padding()
                Button {
                    AudioController.shared.play(.action)
                    self.music.toggleRepeat()
                } label: {
                    Text("Repeat")
                }
                .buttonStyle(ShapeButtonStyle(shapeDirection: shapeDirection, isSelected: !(self.music.systemPlayer.repeatMode == .none)))
            }
        }
    }
    
    init() {
        let random = SeededRandom(seed: Space_UI.system.seed)
        showAlbumArtwork = random.nextBool()
    }
}

#Preview {
    MusicPage()
}
