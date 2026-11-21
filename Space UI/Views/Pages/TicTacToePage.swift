import SwiftUI

struct TicTacToePage: View {

    let playerName = "YOU"
    let opponentName = "AI"

    @IDGen private var idGen
    @Environment(\.system) private var system

    /// The rules; this page is only the board they are drawn on. See `TicTacToeGame`.
    @State private var game = TicTacToeGame()

    var body: some View {
        VStack {
            HStack(spacing: 16) {
                NavigationButton(to: .lockScreen)
                NavigationButton(to: .dotsAndBoxes)
            }
            .frame(idealWidth: system.shapeButtonFrameWidth, maxWidth: 2 * system.shapeButtonFrameWidth, idealHeight: system.shapeButtonFrameHeight, maxHeight: 2 * system.shapeButtonFrameHeight, alignment: .center)
            Spacer()
            PuzzleGridView(rows: 3, columns: 3, cellLength: 100) { coord in
                makeButton(coord: TicTacToeGame.CellCoord(row: coord.row, column: coord.column))
            }
            AutoStack {
                TextPair(did: idGen(0), label: playerName, value: "\(game.playerWins)", largerFontSize: 32)
                TextPair(did: idGen(0), label: opponentName, value: "\(game.opponentWins)", largerFontSize: 32)
            }
                .frame(height: 60)
            Spacer()
        }
        .frame(idealWidth: .infinity, maxWidth: .infinity)
        .widgetCorners(did: idGen(1), topLeading: true, topTrailing: true, bottomLeading: true, bottomTrailing: true)
    }

    func makeButton(coord: TicTacToeGame.CellCoord) -> some View {
        let cellOwner = game[coord]
        let cellIsOnWinLine = game.winningLine?.contains(coord) ?? false

        return ZStack {
                Rectangle()
                    .foregroundColor(cellIsOnWinLine ? system.colors.color(.primary, opacity: .medium) : .clear)
                Text(cellOwner == nil ? "" : (cellOwner == .player ? playerName : opponentName))
                    .foregroundColor(cellOwner == .player ? nil : system.colors.color(.tertiary, opacity: .max))
                    .font(Font.spaceFont(size: 40))
            }
            .frame(width: 100, height: 100, alignment: .center)
            .contentShape(Rectangle())
            .onTapGesture {
                selectCell(coord: coord)
            }
    }

    /// The page's whole half of the game: a sound per outcome, and holding a won line on screen before the
    /// board clears.
    private func selectCell(coord: TicTacToeGame.CellCoord) {
        switch game.select(coord) {
        case .rejected:
            AudioController.shared.play(.notAllowed)
        case .played:
            AudioController.shared.play(.button)
        case .roundOver:
            AudioController.shared.play(.button)
            Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { (_) in
                Task { @MainActor in
                    game.startNextRound()
                }
            }
        }
    }

}

#Preview {
    TicTacToePage()
}
