import SwiftUI

// Created by 256 Arts Developer on 2026-07-17.

extension View {
    /// Pushes the view along the Z axis on visionOS to give the flat UI a sense of layered depth.
    /// Positive values bring the view toward the viewer; negative values recede it. A no-op on every
    /// other platform so call sites can stay conditional-free.
    @ViewBuilder func depthOffset(_ z: CGFloat) -> some View {
        #if os(visionOS)
        offset(z: z)
        #else
        self
        #endif
    }
}
