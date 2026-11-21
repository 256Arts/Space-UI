import SwiftUI

// Example of what this looks like:
// [][][]
// []  []
// []

struct DecorativeBoxesView: View {
    
    let values: [Int]
    let hasExtraColumn: Bool
    
    @Environment(\.elementSize) private var elementSize
    @Environment(\.system) private var system
    
    var columns: Int {
        switch elementSize {
        case .mini, .small:
            return 1 + (hasExtraColumn ? 1 : 0)
        case .regular:
            return 3 + (hasExtraColumn ? 1 : 0)
        case .large:
            return 5 + (hasExtraColumn ? 1 : 0)
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 3) {
            ForEach(0..<columns, id: \.self) { x in
                VStack(spacing: 3) {
                    ForEach(0..<self.values[x], id: \.self) { _ in
                        RoundedRectangle(cornerRadius: system.cornerRadius(forLength: 8))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
    }
    
    init(vid: Int) {
        let random = SeededRandom(seed: UInt64(vid))
        values = (0..<6).map { _ in
            random.nextInt(in: 1...3)
        }
        hasExtraColumn = random.nextBool()
    }
    
}

#Preview {
    DecorativeBoxesView(vid: 0)
}
