import SwiftUI

struct FillAndBorder {
    
    let fill: Color
    let border: Color?
    
    init(fill: Color, border: Color? = nil) {
        self.fill = fill
        self.border = border
    }
    
}
