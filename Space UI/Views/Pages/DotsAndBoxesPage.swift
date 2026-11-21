import SwiftUI

// Board geometry, in points. The board's size in boxes belongs to the rules — see `DotsAndBoxesGame`.
private let dotSpacing: CGFloat = 84
private let boardInset: CGFloat = 18

struct DotsAndBoxesPage: View {

    let playerName = "YOU"
    let opponentName = "AI"

    @IDGen private var idGen
    @Environment(\.system) private var system

    /// The rules; this page is only the board they are drawn on. See `DotsAndBoxesGame`.
    @State private var game = DotsAndBoxesGame()

    private var lineWidth: CGFloat { max(3, system.mediumLineWidth) }
    private var dotDiameter: CGFloat { lineWidth * 2.2 }
    private var boardSide: CGFloat { boardInset * 2 + dotSpacing * CGFloat(max(game.boxRows, game.boxCols)) }

    var body: some View {
        VStack {
            HStack(spacing: 16) {
                NavigationButton(to: .lockScreen)
                NavigationButton(to: .ticTacToe)
            }
            .frame(idealWidth: system.shapeButtonFrameWidth, maxWidth: 2 * system.shapeButtonFrameWidth, idealHeight: system.shapeButtonFrameHeight, maxHeight: 2 * system.shapeButtonFrameHeight, alignment: .center)
            Spacer()
            board
                .frame(width: boardSide, height: boardSide, alignment: .center)
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

    private var board: some View {
        ZStack(alignment: .topLeading) {
            // Claimed boxes (drawn first, behind the lines and dots)
            ForEach(0..<game.boxRows, id: \.self) { r in
                ForEach(0..<game.boxCols, id: \.self) { c in
                    if let owner = game.boxOwners[r][c] {
                        ZStack {
                            RoundedRectangle(cornerRadius: system.cornerRadius(forLength: dotSpacing / 2))
                                .foregroundColor(fillColor(owner))
                            Text(owner == .player ? String(playerName.prefix(1)) : String(opponentName.prefix(1)))
                                .font(Font.spaceFont(size: 28))
                                .foregroundColor(strokeColor(owner))
                        }
                        .frame(width: dotSpacing - dotDiameter, height: dotSpacing - dotDiameter)
                        .position(boxCenter(row: r, col: c))
                    }
                }
            }
            // Horizontal edges
            ForEach(0...game.boxRows, id: \.self) { r in
                ForEach(0..<game.boxCols, id: \.self) { c in
                    edgeView(.horizontal(row: r, col: c), horizontal: true)
                }
            }
            // Vertical edges
            ForEach(0..<game.boxRows, id: \.self) { r in
                ForEach(0...game.boxCols, id: \.self) { c in
                    edgeView(.vertical(row: r, col: c), horizontal: false)
                }
            }
            // Dots (on top)
            ForEach(0...game.boxRows, id: \.self) { r in
                ForEach(0...game.boxCols, id: \.self) { c in
                    Circle()
                        .foregroundColor(system.colors.color(.primary, opacity: .max))
                        .frame(width: dotDiameter, height: dotDiameter)
                        .position(dotPos(row: r, col: c))
                }
            }
        }
    }

    private func edgeView(_ edge: DotsAndBoxesGame.Edge, horizontal: Bool) -> some View {
        let drawn = game.isDrawn(edge)
        let length = dotSpacing - dotDiameter
        let thickness = drawn ? lineWidth : max(1, lineWidth / 3)
        let color = drawn ? system.colors.color(.primary, opacity: .max) : system.colors.color(.primary, opacity: .low)
        let tapAcross: CGFloat = 26
        return Capsule()
            .foregroundColor(color)
            .frame(width: horizontal ? length : thickness, height: horizontal ? thickness : length)
            .frame(width: horizontal ? length : tapAcross, height: horizontal ? tapAcross : length)
            .contentShape(Rectangle())
            .position(edgeCenter(edge))
            .onTapGesture {
                tap(edge)
            }
    }

    /// The page's whole half of the game: a sound per outcome, and holding the finished board on screen
    /// before it clears.
    private func tap(_ edge: DotsAndBoxesGame.Edge) {
        switch game.tap(edge) {
        case .rejected:
            AudioController.shared.play(.notAllowed)
        case .played:
            AudioController.shared.play(.button)
        case .gameOver:
            AudioController.shared.play(.button)
            Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false) { _ in
                Task { @MainActor in
                    game.startNextGame()
                }
            }
        }
    }

    // MARK: - Geometry

    private func dotPos(row r: Int, col c: Int) -> CGPoint {
        CGPoint(x: boardInset + CGFloat(c) * dotSpacing, y: boardInset + CGFloat(r) * dotSpacing)
    }
    private func boxCenter(row r: Int, col c: Int) -> CGPoint {
        CGPoint(x: boardInset + (CGFloat(c) + 0.5) * dotSpacing, y: boardInset + (CGFloat(r) + 0.5) * dotSpacing)
    }
    private func edgeCenter(_ edge: DotsAndBoxesGame.Edge) -> CGPoint {
        switch edge {
        case let .horizontal(r, c):
            return CGPoint(x: boardInset + (CGFloat(c) + 0.5) * dotSpacing, y: boardInset + CGFloat(r) * dotSpacing)
        case let .vertical(r, c):
            return CGPoint(x: boardInset + CGFloat(c) * dotSpacing, y: boardInset + (CGFloat(r) + 0.5) * dotSpacing)
        }
    }

    private func fillColor(_ owner: DotsAndBoxesGame.CellOwner) -> Color {
        owner == .player ? system.colors.color(.primary, opacity: .medium) : system.colors.color(.tertiary, opacity: .medium)
    }
    private func strokeColor(_ owner: DotsAndBoxesGame.CellOwner) -> Color {
        owner == .player ? system.colors.color(.primary, opacity: .max) : system.colors.color(.tertiary, opacity: .max)
    }
}

#Preview {
    DotsAndBoxesPage()
}
