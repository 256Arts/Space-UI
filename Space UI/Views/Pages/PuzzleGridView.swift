import SwiftUI

/// The shared scaffold behind the emergency-puzzle and game grids: a bordered, clipped `GridShape`
/// of square cells. Callers supply only the per-cell content for a given `GridCoord`.
struct PuzzleGridView<Cell: View>: View {

    let rows: Int
    let columns: Int
    let cellLength: CGFloat
    @ViewBuilder let cell: (GridCoord) -> Cell

    @Environment(\.system) private var system

    var body: some View {
        let shape = GridShape(rows: rows, columns: columns, outsideCornerRadius: system.cornerRadius(forLength: cellLength))
        ZStack {
            shape
                .stroke(system.colors.color(.primary, opacity: .max), style: system.strokeStyle(.thin))
            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                ForEach(0..<rows, id: \.self) { row in
                    GridRow {
                        ForEach(0..<columns, id: \.self) { column in
                            cell(GridCoord(row: row, column: column))
                        }
                    }
                }
            }
            .clipShape(shape)
        }
        .frame(width: cellLength * CGFloat(columns), height: cellLength * CGFloat(rows), alignment: .center)
    }

}
