import SwiftUI

enum ElementSize {
    case mini, small, regular, large
}

extension EnvironmentValues {
    
    @Entry var elementSize: ElementSize = .regular
    
}
