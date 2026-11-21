import SwiftUI

struct SafeCornerOffsets: Equatable {
    let topLeading: CGSize
    let topTrailing: CGSize
    let bottomLeading: CGSize
    let bottomTrailing: CGSize
}

extension EnvironmentValues {
    
    @Entry var safeCornerOffsets: SafeCornerOffsets = .init(topLeading: .zero, topTrailing: .zero, bottomLeading: .zero, bottomTrailing: .zero)
    
}
