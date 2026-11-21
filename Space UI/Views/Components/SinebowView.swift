import SwiftUI

struct SinebowView: View {
    
    @Environment(\.system) private var system
    
    @State private var startTime = Date.now

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = startTime.distance(to: timeline.date)
            // Resolve the colour out here so the escaping `visualEffect` closure captures a value rather than
            // the view (and with it the environment lookup).
            let baseColor = system.colors.color(.primary, opacity: .max)
            Rectangle()
                .visualEffect { content, proxy in
                    content
                        .colorEffect(
                            MyShaders.sinebow(
                                size: proxy.size,
                                baseColor: baseColor,
                                time: time))
                }
        }
    }
}

struct LightspeedView: View {

    @State private var startTime = Date.now

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = startTime.distance(to: timeline.date)
            Rectangle()
                .visualEffect { content, proxy in
                    content
                        .colorEffect(
                            MyShaders.lightspeed(
                                size: proxy.size,
                                time: time))
                }
        }
    }
}

#Preview {
    SinebowView()
}
